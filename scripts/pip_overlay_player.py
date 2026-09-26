"""Small libmpv/GTK GLArea adapter; mpv renders directly into the overlay.

Only asynchronous playback commands are used on the GL thread. This avoids
libmpv's render-thread/core-thread lock inversion; see mpv/render.h.
"""

import ctypes as C
from ctypes.util import find_library
import logging
import locale
import os
from pathlib import Path

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk, GLib, Gtk

LOG = logging.getLogger("pip-overlay")


class Param(C.Structure):
    _fields_ = [("type", C.c_int), ("data", C.c_void_p)]


GET_PROC = C.CFUNCTYPE(C.c_void_p, C.c_void_p, C.c_char_p)
UPDATE = C.CFUNCTYPE(None, C.c_void_p)


class GLInit(C.Structure):
    _fields_ = [("get_proc_address", GET_PROC), ("context", C.c_void_p)]


class FBO(C.Structure):
    _fields_ = [("fbo", C.c_int), ("w", C.c_int), ("h", C.c_int), ("format", C.c_int)]


class Event(C.Structure):
    _fields_ = [("id", C.c_int), ("error", C.c_int), ("userdata", C.c_uint64), ("data", C.c_void_p)]


class Property(C.Structure):
    _fields_ = [("name", C.c_char_p), ("format", C.c_int), ("data", C.c_void_p)]


class EndFile(C.Structure):
    _fields_ = [("reason", C.c_int), ("error", C.c_int)]


def pointer(value):
    return C.cast(C.byref(value), C.c_void_p)


def function(lib, name, result, *args):
    fn = getattr(lib, name)
    fn.restype, fn.argtypes = result, args
    return fn


class Player:
    def __init__(self, changed, failed, finished):
        # GTK initializes the user's locale; libmpv requires C numeric parsing.
        locale.setlocale(locale.LC_NUMERIC, "C")
        self.changed, self.failed, self.finished = changed, failed, finished
        self.lib = C.CDLL(find_library("mpv") or "libmpv.so.2")
        self.egl = C.CDLL(find_library("EGL") or "libEGL.so.1")
        self.gl = C.CDLL(find_library("GL") or "libGL.so.1")
        self.create = function(self.lib, "mpv_create", C.c_void_p)
        self.initialize = function(self.lib, "mpv_initialize", C.c_int, C.c_void_p)
        self.set_option = function(self.lib, "mpv_set_option_string", C.c_int, C.c_void_p, C.c_char_p, C.c_char_p)
        self.command_async = function(self.lib, "mpv_command_async", C.c_int, C.c_void_p, C.c_uint64, C.POINTER(C.c_char_p))
        self.observe = function(self.lib, "mpv_observe_property", C.c_int, C.c_void_p, C.c_uint64, C.c_char_p, C.c_int)
        self.wait_event = function(self.lib, "mpv_wait_event", C.POINTER(Event), C.c_void_p, C.c_double)
        self.error_string = function(self.lib, "mpv_error_string", C.c_char_p, C.c_int)
        self.terminate = function(self.lib, "mpv_terminate_destroy", None, C.c_void_p)
        self.render_create = function(self.lib, "mpv_render_context_create", C.c_int, C.POINTER(C.c_void_p), C.c_void_p, C.POINTER(Param))
        self.render_update = function(self.lib, "mpv_render_context_update", C.c_uint64, C.c_void_p)
        self.render_frame = function(self.lib, "mpv_render_context_render", C.c_int, C.c_void_p, C.POINTER(Param))
        self.render_free = function(self.lib, "mpv_render_context_free", None, C.c_void_p)
        self.set_update = function(self.lib, "mpv_render_context_set_update_callback", None, C.c_void_p, UPDATE, C.c_void_p)
        self.get_proc = function(self.egl, "eglGetProcAddress", C.c_void_p, C.c_char_p)
        self.get_integer = function(self.gl, "glGetIntegerv", None, C.c_uint, C.POINTER(C.c_int))
        self.handle = self.create()
        if not self.handle:
            raise RuntimeError("Cannot create libmpv player")
        self.context = C.c_void_p()
        self.props = {}
        self.frames = 0
        self.last_frame_at = None
        self.pending_draw = False
        self.area = Gtk.GLArea()
        self.area.set_required_version(3, 2)
        self.area.set_auto_render(False)
        self.area.connect("realize", self.realize)
        self.area.connect("render", self.render)
        self.proc_callback = GET_PROC(lambda _, name: self.get_proc(name))
        self.update_callback = UPDATE(self.updated)
        self.event_timer = None
        self.ready_callback = None
        try:
            options = {
                "config": "no", "load-scripts": "no", "vo": "libmpv",
                "terminal": "no", "idle": "yes", "keep-open": "no",
                "hwdec": "vaapi,vaapi-copy", "gpu-hwdec-interop": "vaapi", "video-timing-offset": "0",
                "osc": "no", "osd-level": "0", "input-default-bindings": "no",
                "ytdl": "no", "cache": "yes", "demuxer-max-bytes": "64MiB",
                "audio-client-name": "YouTube PiP Overlay",
                "log-file": str(Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "pip-overlay/player.log"),
            }
            for key, value in options.items():
                self.check(self.set_option(self.handle, key.encode(), value.encode()))
            self.check(self.initialize(self.handle))
            for index, prop in enumerate(("pause", "time-pos", "duration", "media-title", "dwidth", "dheight", "volume")):
                self.check(self.observe(self.handle, index, prop.encode(), 1))
            self.event_timer = GLib.timeout_add(50, self.events)
        except Exception:
            self.close()
            raise

    def check(self, result):
        if result < 0:
            raise RuntimeError(self.error_string(result).decode())

    def command(self, *args):
        if self.handle:
            argv = (C.c_char_p * (len(args) + 1))(*(str(arg).encode() for arg in args), None)
            self.check(self.command_async(self.handle, 0, argv))

    def realize(self, area):
        try:
            area.make_current()
            if area.get_error():
                raise RuntimeError(str(area.get_error()))
            api = C.create_string_buffer(b"opengl")
            init = GLInit(self.proc_callback, None)
            # Give VA-API the actual Wayland display for hardware decoding.
            capsule_pointer = function(C.pythonapi, "PyCapsule_GetPointer", C.c_void_p, C.py_object, C.c_char_p)
            gdk = C.CDLL(find_library("gdk-3") or "libgdk-3.so.0")
            get_display = function(gdk, "gdk_wayland_display_get_wl_display", C.c_void_p, C.c_void_p)
            display = get_display(capsule_pointer(Gdk.Display.get_default().__gpointer__, None))
            params = (Param * 4)(Param(1, pointer(api)), Param(2, pointer(init)), Param(9, display), Param())
            self.check(self.render_create(C.byref(self.context), self.handle, params))
            self.set_update(self.context, self.update_callback, None)
            if self.ready_callback:
                self.ready_callback()
        except Exception as error:
            GLib.idle_add(self.failed, str(error))

    def updated(self, _):
        if not self.pending_draw:
            self.pending_draw = True
            GLib.idle_add(self.queue_draw)

    def queue_draw(self):
        self.pending_draw = False
        if self.context and self.handle:
            self.area.queue_render()
        return GLib.SOURCE_REMOVE

    def render(self, area, _):
        if not self.context or not self.handle:
            return True
        try:
            flags = self.render_update(self.context)
            framebuffer = C.c_int()
            self.get_integer(0x8CA6, C.byref(framebuffer))  # GL_DRAW_FRAMEBUFFER_BINDING
            scale = area.get_scale_factor()
            fbo = FBO(framebuffer.value, area.get_allocated_width() * scale,
                      area.get_allocated_height() * scale, 0)
            flip = C.c_int(1)
            params = (Param * 3)(Param(3, pointer(fbo)), Param(4, pointer(flip)), Param())
            self.check(self.render_frame(self.context, params))
            if flags & 1:
                self.frames += 1
                self.last_frame_at = GLib.get_monotonic_time()
        except Exception as error:
            GLib.idle_add(self.failed, str(error))
        return True

    def events(self):
        if not self.handle:
            return GLib.SOURCE_REMOVE
        for _ in range(100):
            event = self.wait_event(self.handle, 0).contents
            if event.id == 0:
                break
            if event.id == 22:  # MPV_EVENT_PROPERTY_CHANGE
                prop = C.cast(event.data, C.POINTER(Property)).contents
                if prop.data and prop.format == 1:
                    value = C.cast(prop.data, C.POINTER(C.c_char_p)).contents.value
                    self.props[prop.name.decode()] = value.decode() if value else None
                    self.changed(prop.name.decode())
            elif event.id == 8:  # MPV_EVENT_FILE_LOADED
                self.changed("file-loaded")
            elif event.id == 7:  # MPV_EVENT_END_FILE
                end = C.cast(event.data, C.POINTER(EndFile)).contents
                if end.reason == 4:
                    GLib.idle_add(self.failed, self.error_string(end.error).decode())
                elif end.reason == 0:
                    GLib.idle_add(self.finished)
        return GLib.SOURCE_CONTINUE

    def close(self):
        if self.event_timer:
            GLib.source_remove(self.event_timer)
            self.event_timer = None
        if self.context:
            self.area.make_current()
            self.render_free(self.context)
            self.context = C.c_void_p()
        if self.handle:
            self.terminate(self.handle)
            self.handle = None

"""Media-key/playerctl support for the YouTube overlay."""

import dbus
import dbus.service

ROOT = "org.mpris.MediaPlayer2"
PLAYER = ROOT + ".Player"
PROPERTIES = "org.freedesktop.DBus.Properties"
TRACK = "/dev/drew/PipOverlay/video"


class MediaPlayer(dbus.service.Object):
    def __init__(self, app):
        self.app = app
        self.bus = dbus.SessionBus()
        self.name = dbus.service.BusName(ROOT + ".pip_overlay", bus=self.bus, do_not_queue=True)
        super().__init__(self.name, "/org/mpris/MediaPlayer2")

    def properties(self, interface):
        if interface == ROOT:
            return {"CanQuit": True, "CanRaise": False, "HasTrackList": False,
                    "Identity": "YouTube PiP Overlay", "DesktopEntry": "dev.drew.PipOverlay",
                    "SupportedUriSchemes": dbus.Array(["https"], signature="s"),
                    "SupportedMimeTypes": dbus.Array([], signature="s")}
        if interface != PLAYER:
            raise dbus.exceptions.DBusException("Unknown interface", name=PROPERTIES + ".UnknownInterface")
        props = self.app.player.props
        metadata = dbus.Dictionary({
            "mpris:trackid": dbus.ObjectPath(TRACK),
            "mpris:length": dbus.Int64(int(float(props.get("duration") or 0) * 1_000_000)),
            "xesam:title": props.get("media-title") or "YouTube PiP Overlay",
            "xesam:url": self.app.url,
        }, signature="sv")
        return {"PlaybackStatus": "Paused" if props.get("pause") == "yes" else "Playing",
                "LoopStatus": "None", "Rate": 1.0, "Shuffle": False, "Metadata": metadata,
                "Volume": float(props.get("volume") or 100) / 100,
                "Position": dbus.Int64(int(float(props.get("time-pos") or 0) * 1_000_000)),
                "MinimumRate": 1.0, "MaximumRate": 1.0,
                "CanGoNext": False, "CanGoPrevious": False, "CanPlay": True,
                "CanPause": True, "CanSeek": True, "CanControl": True}

    @dbus.service.method(PROPERTIES, in_signature="ss", out_signature="v")
    def Get(self, interface, name):
        return self.properties(interface)[name]

    @dbus.service.method(PROPERTIES, in_signature="s", out_signature="a{sv}")
    def GetAll(self, interface):
        return self.properties(interface)

    @dbus.service.method(PROPERTIES, in_signature="ssv", out_signature="")
    def Set(self, interface, name, value):
        if interface == PLAYER and name == "Volume":
            self.app.player.command("set", "volume", max(0, min(100, float(value) * 100)))
        else:
            raise dbus.exceptions.DBusException("Read-only property", name=PROPERTIES + ".PropertyReadOnly")

    @dbus.service.signal(PROPERTIES, signature="sa{sv}as")
    def PropertiesChanged(self, interface, changed, invalidated):
        pass

    def changed(self):
        props = self.properties(PLAYER)
        self.PropertiesChanged(PLAYER, {key: props[key] for key in ("PlaybackStatus", "Metadata", "Volume")}, [])

    @dbus.service.method(ROOT)
    def Raise(self):
        pass

    @dbus.service.method(ROOT)
    def Quit(self):
        self.app.disable()

    @dbus.service.method(PLAYER)
    def PlayPause(self):
        self.app.player.command("cycle", "pause")

    @dbus.service.method(PLAYER)
    def Play(self):
        self.app.player.command("set", "pause", "no")

    @dbus.service.method(PLAYER)
    def Pause(self):
        self.app.player.command("set", "pause", "yes")

    @dbus.service.method(PLAYER)
    def Stop(self):
        self.app.disable()

    @dbus.service.method(PLAYER)
    def Next(self):
        pass

    @dbus.service.method(PLAYER)
    def Previous(self):
        pass

    @dbus.service.method(PLAYER, in_signature="x")
    def Seek(self, offset):
        self.app.player.command("seek", float(offset) / 1_000_000, "relative")

    @dbus.service.method(PLAYER, in_signature="ox")
    def SetPosition(self, track, position):
        if track == TRACK:
            self.app.player.command("seek", max(0, float(position) / 1_000_000), "absolute")

    def close(self):
        self.remove_from_connection()
        self.bus.release_name(ROOT + ".pip_overlay")

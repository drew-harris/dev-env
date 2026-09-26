"""Cancellable YouTube downloads into a small, application-owned cache."""

import json
import logging
import os
from pathlib import Path
import shutil
import signal
import subprocess
import threading
from urllib.parse import parse_qs, urlparse

from gi.repository import GLib

LOG = logging.getLogger("pip-overlay")
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "pip-overlay/videos"


class Download:
    def __init__(self, url, done, failed):
        self.done, self.failed = done, failed
        self.cancelled = False
        self.process = None
        self.video_id = parse_qs(urlparse(url).query)["v"][0]
        self.media = CACHE / (self.video_id + ".mkv")
        self.marker = CACHE / (self.video_id + ".complete.json")
        CACHE.mkdir(parents=True, exist_ok=True)
        if self.marker.exists() and self.media.exists():
            self.marker.touch()
            GLib.idle_add(self.deliver)
            return
        # A desktop session may still have an older mise version in PATH after
        # an upgrade. The stable shim resolves the currently selected version.
        shim = Path.home() / ".local/share/mise/shims/yt-dlp"
        ytdlp = str(shim) if os.access(shim, os.X_OK) else shutil.which("yt-dlp")
        if not ytdlp or not shutil.which("ffmpeg"):
            raise RuntimeError("Install yt-dlp and ffmpeg to play YouTube videos.")
        command = [ytdlp, "--ignore-config", "--no-playlist", "--force-ipv4", "--quiet",
                   "--no-progress", "--no-simulate", "--no-mtime", "--write-info-json",
                   "--http-chunk-size", "1M",
                   "--socket-timeout", "20", "--retries", "3", "--fragment-retries", "3",
                   "--format", "bv[height<=720]+ba/b[height<=720]/b",
                   "--merge-output-format", "mkv", "--remux-video", "mkv",
                   "--output", str(CACHE / (self.video_id + ".%(ext)s")),
                   "--print", "after_move:filepath"]
        for name in ("node", "bun", "deno"):
            runtime = shutil.which(name)
            if runtime:
                command += ["--js-runtimes", name + ":" + runtime]
                break
        command += ["--", url]
        self.process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                        text=True, start_new_session=True)
        threading.Thread(target=self.wait, daemon=True).start()

    def wait(self):
        try:
            self.finish_download()
        except Exception as error:
            LOG.exception("Download/cache operation failed")
            GLib.idle_add(self.report_failure, str(error))

    def finish_download(self):
        stdout, stderr = self.process.communicate()
        if self.cancelled:
            return
        if self.process.returncode != 0 or not self.media.exists() or self.media.stat().st_size == 0:
            LOG.error("yt-dlp failed: %s\n%s", stderr, stdout)
            GLib.idle_add(self.report_failure, stderr.strip()[-1200:] or "YouTube download failed.")
            return
        self.marker.write_text(json.dumps({"id": self.video_id}) + "\n")
        # Keep the three most recently used completed downloads. Ignore partials
        # and any other files that are not represented by our completion markers.
        entries = sorted(CACHE.glob("*.complete.json"), key=lambda p: p.stat().st_mtime, reverse=True)
        for marker in entries[3:]:
            video_id = marker.name.removesuffix(".complete.json")
            if video_id == self.video_id:
                continue
            for suffix in (".mkv", ".info.json", ".complete.json"):
                (CACHE / (video_id + suffix)).unlink(missing_ok=True)
        GLib.idle_add(self.deliver)

    def deliver(self):
        if not self.cancelled:
            title = "YouTube video"
            try:
                title = json.loads((CACHE / (self.video_id + ".info.json")).read_text())["title"]
            except (OSError, ValueError, KeyError):
                pass
            self.done(str(self.media), title)
        return GLib.SOURCE_REMOVE

    def report_failure(self, error):
        if not self.cancelled:
            self.failed(error)
        return GLib.SOURCE_REMOVE

    def close(self):
        self.cancelled = True
        if self.process and self.process.poll() is None:
            try:
                os.killpg(self.process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass

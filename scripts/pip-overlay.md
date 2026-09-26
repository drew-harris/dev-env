# YouTube PiP Overlay

A desktop application that plays YouTube above **true fullscreen** games on
stock Niri. Uses GTK layer-shell's overlay layer, libmpv/OpenGL for video and
audio, and yt-dlp for local downloads. The window is click-through and cannot
take keyboard focus from the game.

## Everyday use

1. Copy a YouTube video link in Helium. **Copy video URL at current time** also
   works if you want to pick up partway through a video.
2. Open the application launcher (`Mod+D`) and run **YouTube PiP Overlay**.
3. It downloads up to 720p into a local cache and plays in the bottom-right
   corner of the gaming monitor. Helium's media player is paused once the
   replacement video successfully loads, so browser audio does not double up.
4. Launch **YouTube PiP Overlay** again to stop. Your position is saved for
   next time. Copy a different link to switch videos.

On the first launch without a YouTube link in the clipboard, a URL dialog opens.
Subsequent launches can resume the last video even if the clipboard has changed.
The browser's original PiP window can be closed; playback now belongs to the
overlay application.

The launcher also has **Enable**, **Disable**, **Pause / Resume**, and
**Open another YouTube video** desktop actions (where the launcher supports them).

### Keyboard and media controls

- `Mod+Ctrl+P`: toggle on/off (works even with the game's shortcut inhibitor).
- `Mod+Ctrl+Space`: pause/resume the overlay specifically.
- Standard media keys work through MPRIS / `playerctl` (player: `pip_overlay`).

```sh
~/dev-env/scripts/pip-overlay status
~/dev-env/scripts/pip-overlay enable 'https://youtu.be/VIDEO_ID?t=2m30s'
~/dev-env/scripts/pip-overlay enable --width 480 --position top-right
~/dev-env/scripts/pip-overlay enable --output HDMI-A-1
~/dev-env/scripts/pip-overlay open
~/dev-env/scripts/pip-overlay disable
playerctl -p pip_overlay play-pause
playerctl -p pip_overlay position 10+
playerctl -p pip_overlay volume 0.5
```

Default width is 320 logical pixels. Aspect ratio follows the video. Output
selection follows Gamescope / Steam Big Picture / Rocket League, falling back
to the focused monitor. `--output` can override this for a particular run.

## Installation / dependencies

Installed on this machine by linking:

```sh
ln -s ~/dev-env/dots/.local/share/applications/dev.drew.PipOverlay.desktop \
    ~/.local/share/applications/dev.drew.PipOverlay.desktop
update-desktop-database ~/.local/share/applications
```

Dependencies: Python 3, python-gobject, python-cairo, python-dbus, GTK 3,
gtk-layer-shell, libmpv (the `mpv` package), yt-dlp, ffmpeg, wl-clipboard,
playerctl, and a yt-dlp JavaScript runtime (Node, Bun, or Deno).

The `pip_overlay_*.py` modules must stay beside the executable. Dependencies
were already available; yt-dlp was upgraded to 2026.08.19 to fix YouTube HTTP 403
errors with the older release. The desktop entry uses this checkout's
absolute path; adjust it if moving the repository.

## Cache and diagnostics

- Video cache: `~/.cache/pip-overlay/videos/` (three most recently used completed videos).
- Saved playback position: `~/.local/state/pip-overlay/resume.json`.
- Application log: `~/.local/state/pip-overlay/overlay.log`.
- Player log: `~/.local/state/pip-overlay/player.log`.
- `pip-overlay status` reports the output, rendered frame count, playback
  position, pause state, download state, and latest error.

The first play waits for download/merge; reopening a cached video is immediate.
Disabling also cancels an in-progress download. YouTube downloads use IPv4,
1 MiB HTTP chunks, and yt-dlp's downloader. yt-dlp's user config is ignored for
predictable downloads.

If YouTube changes its site and extraction fails, update yt-dlp. Login-restricted
videos and live streams are not the target of this download-first workflow.

## Why direct video playback?

The original per-window PipeWire mirror successfully appeared above fullscreen,
but stock Niri 26.04 throttles hidden source windows to about 1 FPS, including
actively screencast windows. Decoding the YouTube video inside the visible
overlay avoids that throttle. This implementation runs entirely as a normal
desktop application on stock Niri.

Verified on this machine: 29.96 rendered FPS with changing video pixels above
fullscreen Rocket League, VA-API decoding, and game keyboard focus preserved.

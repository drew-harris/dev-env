# Linux migration settings

`etc/` mirrors system files that must be installed separately from the Stow
package in `dots/`. Review hardware-specific settings before installing them.
These commands are restore instructions, not part of automatic shell startup.

## Shell configuration

Source `~/dev-env/zshrc` from `~/.zshrc`. Do not copy the current wrapper into
the repo file: it already sources the repo. The repo configuration includes the
live Bun, pnpm, Cargo, local-bin, and FNOX key-path settings; mise activation is
handled by its existing Oh My Zsh plugin. Oh My Zsh and its custom plugins must
be installed separately.

`dots/.config/nushell/env.nu` has the same initialization as the live file; only
generated comments differed. Back up the regular live file before replacing it
with a Stow link. Neither shell configuration contains the private SSH key.

## Niri eGPU startup wait

Install the script before enabling/restoring the user-service drop-in:

```sh
install -Dm755 scripts/wait-egpu-render-node "$HOME/.local/bin/wait-egpu-render-node"
```

Stow `dots/` to restore `.config/systemd/user/niri.service.d/wait-egpu.conf`,
or copy that file into the matching directory under `~/.config`. Run
`systemctl --user daemon-reload` afterward. It takes effect on the next Niri
start; restarting Niri now would end the desktop session.

The default render-node path is specific to the current RX 9060 XT USB4 eGPU.
Check `/dev/dri/by-path/` on the new PC. Override it in the drop-in if needed:

```ini
[Service]
Environment=EGPU_RENDER_NODE=/dev/dri/by-path/pci-0000:08:00.0-render
```

The script waits for six consecutive successful half-second checks and gives up
after about 45 seconds, allowing login without the eGPU.

## Bluetooth autosuspend workarounds

The Realtek rule targets USB vendor/product `0bda:a728`; verify with `lsusb`.
The btusb module option disables autosuspend for all Bluetooth USB adapters
using that driver. Keep these only if the new hardware needs the workaround.

```sh
sudo install -Dm644 system/etc/modprobe.d/99-btusb-no-autosuspend.conf /etc/modprobe.d/99-btusb-no-autosuspend.conf
sudo install -Dm644 system/etc/udev/rules.d/99-realtek-bluetooth-no-autosuspend.rules /etc/udev/rules.d/99-realtek-bluetooth-no-autosuspend.rules
sudo udevadm control --reload-rules
```

Reboot to apply the module option and device rule without unloading Bluetooth
during an active session. If btusb is included in your initramfs, rebuild it
with `sudo mkinitcpio -P` before rebooting.

## Steam Big Picture / Gamescope

The launchers in `scripts/` preserve the live Gamescope settings (1080p, 60 Hz,
fullscreen, no forced cursor grab). The existing shutdown guard is retained so
an absent Steam client is not launched just to shut it down.

Build the Rocket League X11 helper from source rather than tracking its binary.
On Arch, the build needs a C compiler and `libx11` (`base-devel` and `libx11`):

```sh
mkdir -p "$HOME/.local/bin"
cc -O2 -Wall -Wextra scripts/gamescope-rocket-league-fix.c -o "$HOME/.local/bin/gamescope-rocket-league-fix" -lX11
install -m755 scripts/steam-bigpicture scripts/steam-bigpicture-gamescope scripts/steam-bigpicture-session "$HOME/.local/bin/"
```

The Gamescope launcher finds the session launcher alongside itself, so both the
repo scripts and the installed copies work. The session launcher uses the built
helper at `~/.local/bin/gamescope-rocket-league-fix`.

The helper source was recovered from the existing local Steam backup. It targets
Rocket League class `steam_app_252950` and non-Steam shortcut ID `3450285581`;
verify that shortcut ID against the new Steam library. Its runtime behavior has
not been tested by launching a game during this migration update.

The tracked desktop entry assumes this repo is at `/home/drew/dev-env`.
Adjust its `Exec` path if the new username or checkout location changes. Stow
`dots/` after backing up any conflicting regular desktop-entry file.

## Package inventory

`paclist.txt` is a sorted snapshot of `pacman -Qqe`: explicitly installed
packages, including foreign/AUR packages. It is not an all-packages lockfile,
and it is not intended to be passed blindly to `pacman -S` because some entries
require an AUR helper. Refresh with `pacman -Qqe | LC_ALL=C sort > paclist.txt`.

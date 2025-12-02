# Airpods
`ACTION=="remove" SUBSYSTEM=="bluetooth", NAME="*AirPods*", RUN+="/home/drew/dev-env/scripts/airpods --block-if-not-connected"`

In /etc/udev/rules.d/99-bluetooth.rules

Reload rules: `sudo udevadm control --reload-rules`


# Surfing Keys Config
```js
api.map('h', '<Ctrl-6>');
api.map('<Ctrl-i>', '<Alt-s>');
```


curl -sSL https://raw.githubusercontent.com/DeprecatedLuar/better-curl-saul/main/install.sh | bash


Dark mode:
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

Setup sesh via aur: sesh-bin


Install zed preview
curl -f https://zed.dev/install.sh | ZED_CHANNEL=preview sh

make sure you install sonokai theme




# Tmux cursor isn't thin: make sure you have vi mode zsh plugin
git clone https://github.com/jeffreytse/zsh-vi-mode \
  $ZSH_CUSTOM/plugins/zsh-vi-mode



golang migrate
`curl -L https://github.com/golang-migrate/migrate/releases/download/$version/migrate.$os-$arch.tar.gz | tar xvz`

/etc/pam.d/greetd:
#%PAM-1.0

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so
auth       include      system-local-login
auth       optional     pam_gnome_keyring.so
account    include      system-local-login
session    include      system-local-login
session    optional     pam_gnome_keyring.so auto_start


/etc/greetd/config.toml
[terminal]
# The VT to run the greeter on. Can be "next", "current" or a number
# designating the VT.
vt = 1

# The default session, also known as the greeter.
[default_session]

# `agreety` is the bundled agetty/login-lookalike. You can replace `/bin/sh`
# with whatever you want started, such as `sway`.
command = "niri-session"

# The user to run the command as. The privileges this user must have depends
# on the greeter. A graphical greeter may for example require the user to be
# in the `video` group.
user = "drew"


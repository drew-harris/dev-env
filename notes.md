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

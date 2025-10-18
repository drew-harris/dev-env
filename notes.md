# Airpods
`ACTION=="remove" SUBSYSTEM=="bluetooth", NAME="*AirPods*", RUN+="/home/drew/dev-env/scripts/airpods --block-if-not-connected"`

In /etc/udev/rules.d/99-bluetooth.rules

# Surfing Keys Config
```js
api.map('h', '<Ctrl-6>');
api.map('<Ctrl-i>', '<Alt-s>');
```


curl -sSL https://raw.githubusercontent.com/DeprecatedLuar/better-curl-saul/main/install.sh | bash


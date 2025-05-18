# Airpods
`ACTION=="remove" SUBSYSTEM=="bluetooth", NAME="*AirPods*", RUN+="/home/drew/dev-env/scripts/airpods --block-if-not-connected"`

In /etc/udev/rules.d/99-bluetooth.rules


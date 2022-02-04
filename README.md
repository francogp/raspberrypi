# Common commands

## Clean lines from log

example for source "src_host": "192.168.1.150"

```
sed -i '/\"src_host\"\: \"192.168.1.150\"/d' /var/tmp/opencanary.log
```

## updating program

```
sudo git -C raspberrypi pull && sudo bash raspberrypi/updateOpenCanary.sh
```

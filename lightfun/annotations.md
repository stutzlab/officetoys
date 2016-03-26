This device is based on ESP8266 for WIFI and MQTT commands

#flash nodemcu firmware to esp8266 on MacOS using esptool
python ./esptool.py --baud 921600 --port /dev/tty.SLAB_USBtoUART write_flash -fm dio 0x00000 build/nodemcu_XXX.bin



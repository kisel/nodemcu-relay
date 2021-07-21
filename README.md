# nodemcu-relay

nodemcu mqtt-controlled relay with ON timer

used for reporting uptime(powered) time and load power cutoff with a normally-open relay

# initial upload
nodemcu-tool is good for initial upload, but can upload corrupted files due to serial port buffer overflow
could be better to just upload telnet.lua and upload the rest via upload.py script

    npm install nodemcu-tool
    ./node_modules/.bin/nodemcu-tool  upload config.lua wifi.lua telnet.lua mqtt.lua app.lua init.lua 

# upload over telnet

    # cp config.example.lua config.lua
    # vim config.lua
    ./upload.py ESP_TELNET_HOST config.lua wifi.lua telnet.lua mqtt.lua app.lua init.lua 

# Usage

config.lua and lconfig.lua (local config) define wifi connection settings, timer setup and mqtt host

lconfig.lua is optional and can be used to override timer without touching wifi config(just in case)

## Manual Relay on/off

    mosquitto_pub -L mqtt://mqtt/switch/NODE-11A21A/ctrl -m ch0=1
    mosquitto_pub -L mqtt://mqtt/switch/NODE-11A21A/ctrl -m ch0=0

## Online reconfigure

    #mosquitto_pub -L mqtt://mqtt/switch/NODE-11A21A/ctrl/lconfig -m 'print("hello from lconfig.lua")'
    #mosquitto_pub -L mqtt://mqtt/switch/NODE-11A21A/ctrl/schedule -m 'print("hello from schedule.lua")'

## Online reconfigure
    mosquitto_pub -L mqtt://mqtt/switch/NODE-11A21A/ctrl -m restart=1

## Receive relay events

    mosquitto_sub -v -L mqtt://mqtt/switch/#

example output:

    switch/NODE-11A21A/status uptime=2883 rssi=-76 ch0=0
    switch/NODE-11A21A/offline uptime=2883



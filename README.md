
# initial upload
nodemcu-tool is good for initial upload, but can upload corrupted files due to serial port buffer overflow
could be better to just upload telnet.lua and upload the rest via upload.py script

    npm install nodemcu-tool
    ./node_modules/.bin/nodemcu-tool  upload config.lua wifi.lua telnet.lua mqtt.lua app.lua init.lua 

# upload over telnet

    ./upload.py ESP_TELNET_HOST config.lua wifi.lua telnet.lua mqtt.lua app.lua init.lua 

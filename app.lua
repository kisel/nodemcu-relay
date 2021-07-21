print("Loading app.lua")
dofile("mqtt.lua")
ch0 = 0
tmr_status = tmr.create()
tmr_status:alarm(UPD_INTERVAL, tmr.ALARM_AUTO, function()
  if mqtt_client ~= nil then
      payload="uptime="..tmr.time().." rssi="..wifi.sta.getrssi().." ch0="..ch0
      mqtt_client:publish(switch_topic.."/status", payload, 0, 0)
      mqtt_client:lwt(switch_topic.."/offline"..clientid, 'uptime='..tmr.time(), 0, 0)
  end
end)

-- low-level powered relays on GPIO5(preferred) or GPIO0(esp8266-01 boards)
function pwr_on()
    gpio.write(3, 0)
    gpio.write(1, 0)
    ch0 = 1
end
function pwr_off()
    gpio.mode(3, gpio.INPUT)
    gpio.mode(1, gpio.INPUT)
    ch0 = 0
end

m:on("message", function(client, topic, data)
  if data == "ch0=1" then
      pwr_on()
  elseif data == "ch0=0" then
      pwr_off()
  end
end)

mqtt_connect()


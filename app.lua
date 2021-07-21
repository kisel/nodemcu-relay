print("Loading app.lua")
dofile("mqtt.lua")

tmr_status = tmr.create()
tmr_status:alarm(5000, tmr.ALARM_AUTO, function()
  if mqtt_client ~= nil then
      payload="uptime="..tmr.time().." rssi="..wifi.sta.getrssi()
      mqtt_client:publish(switch_topic.."/status", payload, 0, 0)
      mqtt_client:lwt(switch_topic.."/duration"..clientid, tmr.time(), 0, 0)
  end
end)

-- low-level powered relays on GPIO5(preferred) or GPIO0(esp8266-01 boards)
function pwr_on()
    gpio.write(3, 0)
    gpio.write(1, 0)
end
function pwr_off()
    gpio.mode(3, gpio.INPUT)
    gpio.mode(1, gpio.INPUT)
end

m:on("message", function(client, topic, data)
  if data == "pwr=1" then
      pwr_on()
  elseif data == "pwr=0" then
      pwr_off()
  end
end)

mqtt_connect()


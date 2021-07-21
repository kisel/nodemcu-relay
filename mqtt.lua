clientid = ID
if clientid == nil then
  clientid = wifi.sta.gethostname()
end
m = mqtt.Client(clientid, 120)
mqtt_client = nil
switch_topic = "switch/"..clientid 

function mqtt_connect()
  -- 0 for legacy, true for new mqtt
  print("mqtt connecting")
  m:connect(MQTT_HOST, 1883, 0, function(client)
    print("mqtt connected", client)
    mqtt_client = client
    mqtt_client:lwt(switch_topic.."/offline"..clientid, 'uptime='..tmr.time(), 0, 0)
    mqtt_client:subscribe(switch_topic.."/ctrl", 0, function(client) print("subscribed") end)
  end,
  function(client, reason)
    print("Connection failed reason: " .. reason)
    tmr.create():alarm(5000, tmr.ALARM_SINGLE, mqtt_connect)
  end)
end

m:on("offline", function(client)
    print ("offline")
    mqtt_client = nil
    tmr.create():alarm(5000, tmr.ALARM_SINGLE, mqtt_connect)
end)


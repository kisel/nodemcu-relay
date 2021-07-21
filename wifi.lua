wifi_connect_event = function(T)
  print("Connected to AP "..T.SSID)
  if disconnect_ct ~= nil then disconnect_ct = nil end
end

wifi_got_ip_event = function(T)
  print("IP: "..T.IP)
end

wifi_disconnect_event = function(T)
  if T.reason == wifi.eventmon.reason.ASSOC_LEAVE then
    return
  end
  local total_tries = 75
  print("\nConnection to AP "..T.SSID..") failed!")
  for key,val in pairs(wifi.eventmon.reason) do
    if val == T.reason then
      print("Reason: "..val.."("..key..")")
      break
    end
  end

  if disconnect_ct == nil then
    disconnect_ct = 1
  else
    disconnect_ct = disconnect_ct + 1
  end
  if disconnect_ct < total_tries then
    print("Retrying connection...(attempt "..(disconnect_ct+1).." of "..total_tries..")")
  else
    --wifi.sta.disconnect()
    --print("Aborting connection to AP!")
    disconnect_ct = nil
  end
end

wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_connect_event)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnect_event)

print("Connecting to WiFi access point...")
wifi.setmode(wifi.STATION)
if ID ~= nil then
    wifi.sta.sethostname(ID)
end
wifi.sta.config({ssid=SSID, pwd=PASSWORD})
-- wifi.sta.connect() not necessary because config() uses auto-connect=true by default


print("Loading app.lua")
dofile("mqtt.lua")
tmr_status = tmr.create()
tmr_status:alarm(UPD_INTERVAL, tmr.ALARM_AUTO, function()
  if mqtt_client ~= nil then
      payload="uptime="..tmr.time().." rssi="..wifi.sta.getrssi()
      mqtt_client:publish(switch_topic.."/status", payload, 0, 0)
      mqtt_client:lwt(switch_topic.."/offline"..clientid, 'uptime='..tmr.time(), 0, 0)
  end
end)

tmr_zone = tmr.create()
-- LOW-triggered relay
function on_pin(pin)
    gpio.write(pin, 0)
    gpio.mode(pin, gpio.OUTPUT)
    mqtt_client:publish(switch_topic.."/event", "on_pin "..pin, 0, 0)
end
function off_pin(pin)
    gpio.mode(pin, gpio.INPUT)
    gpio.write(pin, 1)
    mqtt_client:publish(switch_topic.."/event", "off_pin "..pin, 0, 0)
end

function off_all()
    mqtt_client:publish(switch_topic.."/event", "off_all", 0, 0)
    tmr_zone:unregister()
    gpio.mode(1, gpio.INPUT)
    gpio.mode(2, gpio.INPUT)
    gpio.mode(5, gpio.INPUT)
    gpio.mode(6, gpio.INPUT)
end

-- high-level functions
function zone_on(pin, time_s)
    zone_off()
    on_pin(pin)
    tmr_zone:alarm(time_s * 1000, tmr.ALARM_SINGLE, off_all)
end

function zone_off()
    sched_clear()
    off_all()
end

---
function endswith(a, b)
    return string.sub(a, -b:len()) == b
end

function wr_config(fn, data)
    print('writing config '..fn..' with '..data)
    local f = file.open(fn, 'w')
    f:write(data)
    f:flush()
    f:close()
    print('wrote config '..fn..' data='..data)
    -- do NOT restart immediately - it can corrupt filesystem :(
    tmr.create():alarm(5000, tmr.ALARM_SINGLE, function() node.restart() end)
end

m:on("message", function(client, topic, data)
  if endswith(topic, '/exec') then
      node.input(data..'\n')
  elseif endswith(topic, '/schedule') then
      wr_config('schedule.lua', data)
  elseif endswith(topic, '/lconfig') then
      wr_config('lconfig.lua', data)
  end
end)

mqtt_connect()

-- schedule utility func
min=60000
sec=1000
sched_tmr = {}
-- interval
-- rep = 0 = tmr.ALARM_SINGLE
function sched(interval_ms, rep, fn)
  local tm = tmr.create()
  table.insert(sched_tmr, tm)
  tm:alarm(interval_ms, rep, fn)
end
function sched_clear()
  for k, v in pairs(sched_tmr) do v:unregister() end
  sched_tmr = {}
end

if file.exists('schedule.lua') then
  dofile("schedule.lua")
end


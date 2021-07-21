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
  if endswith(topic, '/ctrl') then
      if data == "ch0=1" then
          pwr_on()
      elseif data == "ch0=0" then
          pwr_off()
      elseif data == "restart=1" then
          node.restart()
      end
  elseif endswith(topic, '/exec') then
      node.input(data)
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
  sched_tmr[#sched_tmr + 1] = tm
  tm:alarm(interval_ms, rep, fn)
end

if file.exists('schedule.lua') then
  dofile("schedule.lua")
end


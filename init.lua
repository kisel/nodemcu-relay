dofile("config.lua")
if file.exists('lconfig.lua') then
  dofile("lconfig.lua")
end
dofile("wifi.lua")
dofile("telnet.lua"):open()
if file.exists('app.lua') then
  dofile("app.lua")
end


-- file : setup.lua
-- WiFi configuration

local module = {}

local function wifi_wait_ip()
  if wifi.sta.getip() == nil then
    print("IP unavalable. Waiting...")
  else
    tmr.stop(1)   -- stop timer 1
    print("\n=================================")
    print("ESP8266 mode is : " .. wifi.getmode())
    print("MY address is   : " .. wifi.ap.getmac())
    print("IP is           : " .. wifi.sta.getip())
    print("=================================\n")
    app.start()
  end
end

local function wifi_start(list_aps)
  if list_aps then
    for key,value in pairs(list_aps) do
      if config.SSID and config.SSID[key] then
        wifi.setmode(wifi.STATION)
	wifi.sta.config(key,config.SSID[key])
	wifi.sta.connect()
	print("Connecting to " .. key .. " ...")
	tmr.alarm(1, 2500, tmr.ALARM_AUTO, wifi_wait_ip)
      else
        print("Skipping SSID " .. key)
      end
    end
  else
    print("Error getting AP list")
  end
end


function module.start()
  print("Configuring Wifi ...")
  wifi.setmode(wifi.STATION)
  wifi.sta.getap(wifi_start)
end

return module

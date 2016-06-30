-- file : application.lua

local module = {}

local temperature = nil
local humidity

local polling = 20		-- hw polling period in seconds
local update  = 60		-- send message to broker (sec)

m = nil


-- send a simple ping to the broker
local function send_ping()
  m:publish(config.ENDPOINT .. "ping", "id=" .. config.ID,0,0)
end


-- send my id to the broker for registration
local function register_myself()
  m:subscribe(config.ENDPOINT .. config.ID,0,function(conn)
      print("Successfully subscribed to data endpoint")
    end)
end


local function mqtt_start()
  m = mqtt.Client(config.ID, 120)  -- 120 sec keepalive, no user/pass

  m:lwt(config.ENDPOINT .. config.ID, "offline",0,0)

  -- register message callback beforehead
  m:on("message", function(conn, topic, data)
    if data ~= nil then
      print(topic .. ": " .. data)
      -- do domething, we have received a message
      if (data == "query") then
        updateBroker()
      elseif (data == "reset") then
        node.restart()
      end
    end
  end)

  -- connect to broker
  -- host, port, not_secure, autoreconnect, callback when connected
  m:connect(config.HOST, config.PORT, 0, 1, function(con)
    register_myself()
    -- ping every 60 seconds
    tmr.stop(6)
    tmp.alarm(6, 60000, 1 send_ping)
  end
  , function(conn, reason)
    print("Could not connect! Reason = " .. reason)
  end)
end


function module.start()
  mqtt_start()
  hardware_start()
end


local function hardware_start()
  hw.setup()
  pollHW()
  tmr.stop(5)
  tmr.alarm(5, polling * 1000, tmr.ALARM_AUTO, pollHW)
  tmr.stop(4)
  tmr.alarm(4, update * 1000, tmr.ALARM_AUTO, updateBroker)
end
 


local function updateBroker()
  if (temperature == nil) then
    return
  end
  

  local msg = {}
  msg.temperature = temperature
  msg.humdity = humidity
  msg.irrigation = hw.isValveOpen()

  m:publish(config.ENDPOINT .. config.ID, cjson.encode(msg))
end


local function pollHW()
  temperature = hw.readTemp()
  humidity = hw.readSoilHumidity()
end




function module.send(data)
  m:publish(config.ENDPOINT .. config.ID, data, 0,0)
end


return module

-- File : hardware.lua
-- Management of hardware events

local module = {}

local tempPin = 1	-- DS18B20
local valvePin = 6	-- relais for valve

local addr		-- address of 1wire DS18B20

local valveOpen = false	-- valve status


function module.setup()

  --ensure that ADC is reading pin and not internal voltage
  if adc.force_init_mode(adc.INIT_ADC) then
    node.restart()
    return  -- restart is scheduled, just wait for reboot
  end

  -- setup ralais pin
  gpio.mode(valvePin, gpio.OUTPUT)

  -- setup DS18B20 wire
  ow.setup(tempPin)
  local count = 0
  local crc
  repeat
    count = count + 1
    ow.reset_search(tempPin)
    addr = ow.search(tempPin)
    tmr.wdclr()
  until ( (addr == nil) or (count > 100) )
  if (addr == nul) then
    print("No address for temperature sensor!")
  else
    print(addr:byte(1,8))
    crc = ow.crc8(string.sub(addr,1,7))
    if (crc == addr:byte(8)) then
      if ((addr:byte(1) == 0x10) or (addr:byte(1) == 0x28)) then
        print("Device is a DS18S20 family device")
      else
        print("Device family is not recognized")
	addr = nil
      end
    else
      print("CRC is not valid")
      addr = nil
    end
  end
end


function module.readSoilHumidity()
  local value
  value = adc.read(0)	-- work needed to calibrate and average
  return value
end


function module.openValve()
  gpio.write(valvePin, gpio.HIGH)
  valveOpen = true
end


function module.closeValve()
  gpio.write(valvePin, gpio.LOW)
  valveOpen = false
end


function module.isValveOpen()
  return valveOpen
end


function module.readTemp()
  local present
  local data
  local i
  local crc
  local t

  if (addr == nil) then
    print "Temperature sensor not ready"
    return "Not ready"
  end

  ow.reset(tempPin)
  ow.select(pin, addr)
  ow.write(tempPin, 0x44, 1)
  tmr.delay(1000000)
  present = ow.reset(tempPin)
  ow.select(tempPin, addr)
  ow.write(tempPin, 0xBE, 1)
  print("P="..present)
  data = nil
  data = string.char(ow.read(tempPin))
  for i = 1, 8 do
    data = data .. string.char(ow.read(tempPin))
  end
  print(dta:byte(1,9))
  crc = ow.crc8(string.sub(data,1,8))
  print("CRC="..crc)
  if (crc == data:byte(9)) then
    t = (data:byte(1) + data:byte(2) * 256)

    -- handle negative temperatures
    if (t > 0x7fff) then
      t = t - 0x10000
    end

    if (addr:byte(1) == 0x28) then
      t = t * 625      -- DS18B20, 4 fractional bits
    else
      t = t * 5000     -- DS18S20, 1 fractional bit
    end

    local sign = ""
    if (t<0) then
      sign = "-"
      t = -1 * t
    end

    -- Separate integral and decimal portions, for integer firmware only
    local t1 = string.format("%d", t / 10000)
    local t2 = string.format("%04u", t % 10000)
    local temp = sign .. t1 .. "." .. t2
    print("Temperature= " .. temp .. " Celsius")
    return temp
  end
  tmr.wdclr()
end

return module

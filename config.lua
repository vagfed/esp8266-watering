-- file : config.lua
-- module containing configuration data

local module = {}

module.SSID = {}
module.SSID["myWifi1"] = "the password"
module.SSID["myWifi2"] = "the password"

module.HOST = "the.server"
module.PORT = 1883

module.ID = node.chipid()
module.ENDPOINT = "nodemcu/"

return module


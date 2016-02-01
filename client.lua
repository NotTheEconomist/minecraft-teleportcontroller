local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
local serialization = require("serialization")

local dialer = component.dialing_device
local modem = component.modem

local PORT = 15245

local ok = modem.open(PORT)

while true do
	_, _, remoteAddress, port, _, payload = event.pull("modem_message")
	if port == PORT then
		payload = serialization.unserialize(payload)
		_, _, _, code, playerName = table.unpack(payload)
		print(code, playerName)
		if code == keyboard.keys.up then print("UP!")
		elseif code == keyboard.keys.down then print("DOWN!")
		elseif code == keyboard.keys.left then print("LEFT!")
		elseif code == keyboard.keys.right then print("RIGHT!")
		end
	end

end
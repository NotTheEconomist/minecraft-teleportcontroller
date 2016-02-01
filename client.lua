local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
local serialization = require("serialization")

local dialer = component.dialing_device
local modem = component.modem

local PORT = 15245

local ok = modem.open(PORT)

-- get remote list
function getReceivers()
	modem.send(SERVER, PORT, "getReceivers", modem.address)
	local data = {event.pull("modem_message", nil, nil, PORT, nil, "sendReceivers")}[7]
	return serialization.unserialize(data)
end

-- update remove list
function updateReceivers(newversion)
	modem.send(SERVER, PORT, "updateReceivers", modem.address, serialization.serialize(newversion))
	e = event.pull(5, "modem_message", nil, nil, PORT, nil, "ok")
	if e != nil
		return 0
	else
		return 1
	end
end

local receivers = getReceivers()

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
		elseif code == keyboard.keys.enter then print("----ENTER----")
		end
	end

end

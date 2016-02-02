local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
local serialization = require("serialization")

local dialer = component.dialing_device
local modem = component.modem

local PORT = 15245
local SERVER = "65025979-1f4c-4302-83ca-686bd11e3da1"

local ok = modem.open(PORT)

-- get remote list
function getReceivers()
	print("Getting receivers")
	print("sending to " .. SERVER .. ":" .. PORT .. " with payload {\"getReceivers\", " .. modem.address .. "}")
	modem.send(SERVER, PORT, "getReceivers", modem.address)
	local data = {event.pull(10, "modem_message", nil, nil, PORT, nil, "sendReceivers")}
	if #data == 0 then
		print("Timeout while getting receiver list")
		return ""
	else
		print("Got receivers")
		return serialization.unserialize(data[7])
	end
end

-- update remote list
function updateReceivers(newversion)
	modem.send(SERVER, PORT, "updateReceivers", modem.address, serialization.serialize(newversion))
	e = event.pull(5, "modem_message", nil, nil, PORT, nil, "ok")
	if e ~= nil then
		return 0
	else
		return 1
	end
end

local receivers = getReceivers()

while true do
	print("entering event loop")
	local e = {event.pull("modem_message", nil, nil, PORT, nil, "key_down")}
	local port = e[4]

	if port == PORT then
		_, _, _, code, playerName = table.unpack(e, 6)
		if code == keyboard.keys.up then print("UP!")
		elseif code == keyboard.keys.down then print("DOWN!")
		elseif code == keyboard.keys.left then print("LEFT!")
		elseif code == keyboard.keys.right then print("RIGHT!")
		elseif code == keyboard.keys.enter then print("----ENTER----")
		end
	end

end

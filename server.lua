local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
local serialization = require("serialization")
local modem = component.modem

local PORT = 15245
local DEST = "388a64b3-cd16-4a52-8701-1a3bb031a50a"

local RECEIVERDBPATH = "/etc/receiversdb.lua"

local allowedPlayers = {["Areskale"]=true, ["Drunkensaint"]=true, ["rowenlemmings"]=true, }

local receivers = {}

local ok = modem.open(PORT)
if not ok then
	print("FAILED TO OPEN PORT")
	os.exit(1)
end

function _loadReceiverList(f)
	function Receiver(t)
		table.insert(receivers, t)
	end
	dofile(f)
	return receivers
end

function _saveReceiverList(f)
	-- receivers should always be a table like:
	--   Receiver{
	--     x = 123,
	--     y = 456,
	--     z = 789,
	--   }
	io.output(f)
	io.write("Receiver{\n")
	for k,v in pairs(receivers) do
		io.write("  " .. k .. " = ", v, ",\n")
	end
	io.write("}\n")
end

function saveReceivers()
	_saveReceiverList(RECEIVERDBPATH)

function loadReceivers()
	return _loadReceiverlist(RECEIVERDBPATH)
end

function updateReceivers(newReceivers)
	oldReceivers = _loadReceiverList(RECEIVERDBPATH)
	oldSet = {}
	new = {}
	for _, t in ipairs(oldReceivers) do
		oldSet["x " .. t.x .. ", " ..
		       "y " .. t.y .. ", " ..
		       "z " .. t.z] = true
    end
    for _, t in ipairs(newReceivers) do
    	if oldSet["x " .. t.x .. ", " ..
		          "y " .. t.y .. ", " ..
		          "z " .. t.z] == nil then
			table.insert(new, t)
		end
	end
	for _, t in ipairs(new) do
		table.insert(receivers, t)
	end
	saveReceivers()
end

function handleKeyPress(name, ...)
	address, char, code, playerName = ...

	if allowedPlayers[playerName] == nil then
		return
	end

	if code == keyboard.keys.up or
	   code == keyboard.keys.down or
	   code == keyboard.keys.left or
	   code == keyboard.keys.right or
	   code == keyboard.keys.enter then
	    data = {name, address, char, code, playerName}
		modem.send(DEST, PORT, serialization.serialize(data))
	end
end

function handleRemoteInput(name, rcvAddr, sndAddr, port, distance, ...)
	-- we don't have to check this at all right now, just pass it through
	local data = {...}
	--
	if data[1] == "getReceivers" then
		loadReceivers()
		modem.send(data[2], port, "sendReceivers", serialization.serialize(receivers))
	end
	if data[1] == "updateReceivers" then
		updateReceivers(serialization.unserialize(data[3]))
		modem.send(data[2], port, "ok")
	end
	if #data == 4 then
		modem.send(DEST, PORT, serialization.serialize(...))
	end
end

loadReceivers()

event.listen("key_down", handleKeyPress)
event.listen("modem_message", handleRemoteInput)

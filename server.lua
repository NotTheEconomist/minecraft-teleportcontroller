local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
local serialization = require("serialization")
local modem = component.modem

local PORT = 15245
local DEST = "388a64b3-cd16-4a52-8701-1a3bb031a50a"

local allowedPlayers = {["Areskale"]=true, ["Drunkensaint"]=true, ["rowenlemmings"]=true, }

local ok = modem.open(PORT)
if not ok then
	print("FAILED TO OPEN PORT")
	os.exit(1)
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
	if #... == 4 then
		modem.send(DEST, PORT, serialization.serialize(...))
	end
end


event.listen("key_down", handleKeyPress)
event.listen("modem_message", handleRemoteInput)
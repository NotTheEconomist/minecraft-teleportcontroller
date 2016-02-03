local component = require("component")
local event = require("event")
local fs = require("filesystem")
local keyboard = require("keyboard")
local serialization = require("serialization")
local modem = component.modem

local PORT = 15245
local DEST = "388a64b3-cd16-4a52-8701-1a3bb031a50a"

local RECEIVERDBPATH = "/etc/receiversdb.lua"

local allowedPlayers = {["Areskale"]=true, ["Drunkensaint"]=true, ["rowenlemmings"]=true, }

-- an array of tables with the following structure:
--   {label="some string",
--    address = {dim=0, x=1, y=2, z=3}}
-- each object describes a teleport receiver pad.
local receivers = {}

local ok = modem.open(PORT)
if not ok then
	modem.close(PORT)
	ok = modem.open(PORT)
	if not ok then
		print("FAILED TO OPEN PORT")
		os.exit(1)
	end
end

function Receiver(t)
	table.insert(receivers, t)
end

function _loadReceiverList(f)
	print("entering _loadReceiverList")
	print("checking if f exists")
	if not fs.exists(f) then
		print("It doesn't")
		io.open(f, "w"):close()
	else
		print("It does, so I'm executing it")
		dofile(f)
		print("Executed successfully")
	end
	print("exiting _loadReceiverList")
end

function _saveReceiverList(f)
	print("entering _saveReceiverList with f = " .. f)
	-- receivers should always be a table like:
	--   Receiver{
	--     label = "",
	--     address = {dim = 0 x = 123, y = 456, z = 789},
	--   }
	local file, err = io.open(f, "w")
	print("Opened f, file = " .. tostring(file))
	if err ~= nil then
		print(err)
		return
	end
	print("#receivers is " .. #receivers)
	if #receivers > 0 then
		for _, t in ipairs(receivers) do
			file:write("Receiver{\n")
			file:write("  label = \"" .. t.label .. "\",\n")
			file:write("  address = {dim = " .. t.dim ..
			           ", x = " .. t.x ..
			           ", y = " .. t.y ..
			           ", z = " .. t.z .. "},\n")
			file:write("}\n")
		end
	end
	file:close()
	print("exiting _saveReceiverList")
end

function saveReceivers()
	print("entering saveReceivers")
	_saveReceiverList(RECEIVERDBPATH)
	print("exiting saveReceivers")
end

function loadReceivers()
	print("entering loadReceivers")
	receivers = _loadReceiverList(RECEIVERDBPATH)
	print("exiting loadReceivers")
end

function updateReceivers(newReceivers)
	print("entering updateReceivers")
	local oldReceivers = receivers
	local oldSet = {}
	local new = {}
	-- print("old receivers include: ")
	for _, t in ipairs(oldReceivers) do
		s = "dim " .. t.address.dim .. ", " ..
		    "x " .. t.address.x .. ", " ..
		    "y " .. t.address.y .. ", " ..
		    "z " .. t.address.z
		oldSet[s] = true
		-- print(s)
    end
    print("updateReceivers: built oldSet")
    -- print("new receivers include: ")
    for _, t in ipairs(newReceivers) do
    	-- new receivers come string from the dialing device
    	-- and are just a Receiver.address table.
		s = "dim " .. t.dim .. ", " ..
		    "x " .. t.x .. ", " ..
		    "y " .. t.y .. ", " ..
		    "z " .. t.z
		-- print(s)
    	if oldSet[s] == nil then
			table.insert(new, t)
		end
	end
	for _, t in ipairs(new) do
		new_t = {label="", address=t}
		table.insert(receivers, new_t)
	end
	saveReceivers()
	print("exiting updateReceivers")
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
		modem.send(DEST, PORT, table.unpack(data))
	end
end

function handleRemoteInput(name, rcvAddr, sndAddr, port, distance, ...)
	local data = {...}

	if data[1] == "getReceivers" then
		print("Request received: getReceivers")
		loadReceivers()
		print("Receivers loaded")
		modem.send(data[2], port, "sendReceivers", serialization.serialize(receivers))
		print("Receivers sent to " .. data[2] .. ":" .. port)
	end
	if data[1] == "updateReceivers" then
		print("Request received: updateReceivers")
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

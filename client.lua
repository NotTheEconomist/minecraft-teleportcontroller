local component = require("component")
local event = require("event")
local keyboard = require("keyboard")
local serialization = require("serialization")

local gpu = component.gpu
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

-- an array of tables with the following structure:
--   {label="some string",
--    address = {dim=0, x=1, y=2, z=3}}
-- each object describes a teleport receiver pad.
local receivers = getReceivers()

Cursor = {}
-- cursor describes the ">" that indicates where the user has selected.
-- if cursor.x is columnsize * 0 + 1, the user is selecting receivers[cursor.y - 2]
-- if cursor.x is columnsize * 3 + 1, the user is editing receivers[cursor.y - 2]

function Cursor:init()
	-- Initializes the Cursor inside the columns and rows context.
	self.x = columns[1] - 1
	self.y = rows[1]
	self.last = {x=0, y=0}
end

function Cursor:get()
	-- gets the object selected by the cursor at its current position
	-- returns a second value `true` if user is editing that object, else `false`.
	local target = receivers[rows:getRow(self.y)]
	if self.x == columns[4] - 1 then
		return target, true
	else
		return target, false
	end
end

function Cursor:move(direction)
	-- Moves the cursor and prompts a call to Cursor:draw
	local curRow = rows:getRow(self.y)
	local newY, newX = self.y, self.x
	if direction == "down" then
		newY = rows[math.min(#receivers, curRow+1)]
	elseif direction == "up" then
		newY = rows[math.max(1, curRow-1)]
	elseif direction == "right" then
		newX = columns[4] - 1
	elseif direction == "left" then
		newX = columns[1] - 1
	end
	self.last.x, self.last.y = self.x, self.y
	self.x, self.y = newX, newY
	Cursor.draw()
end

function Cursor.draw()
	-- redraws the cursor
	gpu.set(self.x, self.y, ">")
	gpu.set(self.last.x, self.last.y, " ")
end

------------------------- GUI DRAWING ----------------------------

local rX, rY = component.gpu.getResolution()
NUMCOLUMNS = 4
local columns = {}
local rows = {}
function rows:getRow(x)
	return x - 2
end
for i=0, NUMCOLUMNS do
	columns.insert(i * math.floor((rX - NUMCOLUMNS - 1) / NUMCOLUMNS) + i + 1)
end
for i=3, rY-2 do
	rows.insert(i)
end

for i, receiver in receivers do
	gpu.set(columns[1], receiver.label)
	gpu.set(columns[2], rows[i], string.format("dim: %d, x: %d, z: %d, y: %d",
	                                   receiver.address.dim, receiver.address.x, receiver.address.z, receiver.address.y)
	-- this will span two rows!
	gpu.set(columns[4], rows[i], "edit")
end

Cursor:init()
Cursor:draw()

------------------------- EVENT LOOP ----------------------------

while true do
	print("entering event loop")
	local e = {event.pull("modem_message", nil, nil, PORT, nil, "key_down")}
	local port = e[4]

	if port == PORT then
		_, _, _, code, playerName = table.unpack(e, 6)
		if code == keyboard.keys.up then Cursor:move("up")
		elseif code == keyboard.keys.down then Cursor:move("down")
		elseif code == keyboard.keys.left then Cursor:move("left")
		elseif code == keyboard.keys.right then Cursor:move("right")
		elseif code == keyboard.keys.enter then
			recv, edit = Cursor:get()
			if not edit then
				dd.dialOnce(trans.x, trans.z, trans.y, recv.dim, recv.x, recv.z, recv.y)
			else
				print("WIP") -- TODO: we need to figure out how to edit this crap!
			end
		end
	end

end

local DISPLAYED = {
	dealers = {
		["default"] = true,
		["rebel"] = true,
		["armoury"] = true,
	},
	money = {
		["safes"] = true,
		["registers"] = true,
	},
}

local Workspace = game:GetService("Workspace")
local GameMap = Workspace["Map"]
local GameAtm = GameMap["ATMz"]
local GameMoney = GameMap["BredMakurz"]

local function isDisplayedMoneyItem(item)
	local displayConfig = DISPLAYED["money"]
	local displaySafes = displayConfig["safes"]
	local displayRegister = displayConfig["registers"]

	if displaySafes and string.find(item.Name, "Safe") then
		return true
	end
	if displayRegister and string.find(item.Name, "Register") then
		return true
	end

	return false
end

local function getDisplayedMoneyItems()
	local children = GameMoney:GetChildren()
	local results = {}

	for _, child in next, children do
		if isDisplayedMoneyItem(child) then
			results[#results + 1] = child
		end
	end

	children = nil
	return results
end

local function CreatePool(newFn)
	local pool = {}
	local store = {}

	function pool:Put(value)
		if math.random(1, 4) == 4 then
			if value["Remove"] ~= nil then
				value:Remove()
			end

			value = nil
			return
		end

		table.insert(store, value)
	end

	function pool:Get()
		if #store == 0 then
			return newFn()
		end

		return table.remove(store, 1)
	end

	return pool
end

-- VECTOR POOLS
-- Since vectors are a userdata type
-- i am storing them in pools.
local Vector3Pool = CreatePool(function()
	return Vector3(0, 0, 0)
end)

local LinePool = CreatePool(function()
	return Drawing.new("Line")
end)

local zeroVector = Vector3(0, 0, 0)
local zeroVector2 = Vector2(0,0)
local zeroColor = Color3(0, 0, 0)
local box3DEdges = {
	{ 1, 2 },
	{ 1, 3 },
	{ 1, 5 },
	{ 2, 4 },
	{ 2, 6 },
	{ 3, 4 },
	{ 3, 7 },
	{ 4, 8 },
	{ 5, 6 },
	{ 5, 7 },
	{ 6, 8 },
	{ 7, 8 },
}

local function New3DBox()
	local box = {}
	local pos = zeroVector
	local col = zeroColor
	local vis = false

	local szX = 0
	local szY = 0
	local szZ = 0

	local corners = {
		Vector3Pool:Get(),
		Vector3Pool:Get(),
		Vector3Pool:Get(),
		Vector3Pool:Get(),
		Vector3Pool:Get(),
		Vector3Pool:Get(),
		Vector3Pool:Get(),
		Vector3Pool:Get(),
	}

	local lines = {
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
		LinePool:Get(),
	}

	function box:SetPosition(vec)
		pos = nil
		pos = vec
	end
	function box:SetSize(vec)
		szX = nil
		szY = nil
		szZ = nil

		szX = vec.x / 2
		szY = vec.y / 2
		szZ = vec.z / 2

		vec = nil
	end
	function box:SetColor(color)
		col = nil
		col = color
	end
	function box:SetVisible(state)
		vis = state
	end
	function box:Render()
		if vis == false then
			for _, line in next, lines do
				line.Visible = false
			end
			return
		end

		local cornersIdx = 1
		for dx = -1, 1, 2 do
			for dy = -1, 1, 2 do
				for dz = -1, 1, 2 do
					corners[cornersIdx].x = pos.x + (dx * szX)
					corners[cornersIdx].y = pos.y + (dy * szY)
					corners[cornersIdx].z = pos.z + (dz * szZ)
					cornersIdx = cornersIdx + 1
				end
			end
		end
		cornersIdx = nil

		local linesIdx = 1
		for _, edge in ipairs(box3DEdges) do
			local cornerIndex1 = corners[edge[1]]
			local cornerIndex2 = corners[edge[2]]

			local screenPos1, screenPos1Ok = WorldToScreen(cornerIndex1)
			local screenPos2, screenPos2Ok = WorldToScreen(cornerIndex2)

			if screenPos1Ok and screenPos2Ok then
				lines[linesIdx].Visible = true
				lines[linesIdx].From = screenPos1
				lines[linesIdx].To = screenPos2
				lines[linesIdx].Color = col
			else
				lines[linesIdx].Visible = false
			end

			screenPos1 = nil
			screenPos2 = nil
			screenPos1Ok = nil
			screenPos2Ok = nil
			linesIdx = linesIdx + 1
		end
		linesIdx = nil
	end

	function box:Reset()
		pos = zeroVector
		col = zeroColor
		vis = false

		szX = 0
		szY = 0
		szZ = 0

		box:Render()
	end

	function box:Remove()
		pos = nil
		col = nil
		szX = nil
		szY = nil
		szZ = nil

		for _, line in next, lines do
			line.From = zeroVector2
			line.To = zeroVector2
			line.Color = zeroColor
			line.Visible = false

			LinePool:Put(line)
		end

		for _, corner in next, corners do
			corner.x = 0
			corner.y = 0
			corner.z = 0

			Vector3Pool:Put(corner)
		end

		corners = nil
		lines = nil
		box = nil
	end

	return box
end

-- SCREEN SIZE CAPTURING LOGIC
-- I discovered CaptureOverlay in screengui
-- This has the exact size of the screen
-- As of writing this matcha has no function for this
local CoreGui = game:GetService("CoreGui")
local CaptOverlay = CoreGui.CaptureOverlay
local CaptOverlayFrame = CaptOverlay.CaptureOverlay
local function getScreenSize()
	return CaptOverlayFrame.Size
end

local function getTracersStartPosition()
	local screenSize = getScreenSize()

	local outputPosition = Vector2(screenSize.x / 2, screenSize.y - 1)
	screenSize = nil

	return outputPosition
end

local Box3DPool = CreatePool(New3DBox)
local TextPool = CreatePool(function()
	return Drawing.new("Text")
end)

local function CreateObjectESP(inst, name, size, color)
	local partESP = {}
	local partTracer
	local partBox = Box3DPool:Get()
	local partText = TextPool:Get()

	
	partTracer = LinePool:Get()


	function partESP:Render()
		local position = inst.Position
		local screenPos, visible = WorldToScreen(position)

		if not visible then
			position = nil
			screenPos = nil
			partText.Visible = false

			partBox:SetVisible(false)
			partBox:Render()
			partText.Visible = false
			if partTracer ~= nil then
				partTracer.Visible = false
			end

			return
		end

		if partTracer ~= nil then
			local startPosition = getTracersStartPosition()
			partTracer.From = startPosition
			partTracer.To = screenPos
			partTracer.Color = color
			partTracer.Visible = true

			startPosition = nil
		end

		local textPosition = Vector3Pool:Get()
		textPosition.x = position.x
		textPosition.y = position.y + (size.y / 2)
		textPosition.z = position.z

		local screenPosition, visible = WorldToScreen(textPosition)
		if visible then
			local xOffset = #name * 2

			local position = Vector2(screenPosition.x - xOffset, screenPosition.y)
			partText.Position = position
			partText.Text = name
			partText.Center = false
			partText.Size = Vector2(10, 10)
			partText.Visible = true
			partText.Color = color

			position = nil
			screenPosition = nil
		else
			partText.Visible = false
		end

		partBox:SetPosition(position)
		partBox:SetSize(size)
		partBox:SetVisible(true)
		partBox:SetColor(color)
		partBox:Render()
	end

	function partESP:SetColor(col)
		color = nil
		color = col
	end

	function partESP:Remove()
		inst = nil
		color = nil
		partESP = nil
		size = nil

		partText.Visible = false
		partTracer.Visible = false
		partBox:SetVisible(false)
		partBox:Render()

		TextPool:Put(partText)
		Box3DPool:Put(partBox)
		if partTracer ~= nil then
			LinePool:Put(partTracer)
		end
	end

	return partESP
end

local drawing_objects = {}
local drawn_objects = {}

local moneyColor = Color3(0, 1, 0)
local moneySize = Vector3(4,4,4)

local dealerColor = Color3(0, 0, 1)
local dealerSize = Vector3(3,6,3)

local function espStep()
	drawn_objects = {}
	for _, item in next, getDisplayedMoneyItems() do
		local esp = drawing_objects[item.Address]
		if esp == nil then
			local espPart = item.PrimaryPart
			local espName = item.Name

            esp = CreateObjectESP(espPart, espName, moneySize, moneyColor)
		end

        esp:Render()
        drawing_objects[item.Address] = esp
        drawn_objects[item.Address] = true
    end

    for addr, rendered in pairs(drawing_objects) do
        if drawn_objects[addr] == nil then
            rendered:Remove()
            rendered = nil

            drawing_objects[addr] = nil
        end
    end

end

while true do
    espStep()
end

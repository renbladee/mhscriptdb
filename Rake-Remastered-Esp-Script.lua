local rakeRootPart = nil
local espText = nil
local espBox = {}
local espBoxOutline = {}
local tracerLine = nil
local running = true
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Location esp data
local locations = {
    { Name = "BaseCamp", Position = Vector3(-41.77, 22.47, 201.64) },
    { Name = "SafeHouse", Position = Vector3(-370.01, 20.28, 76.56) },
    { Name = "Station", Position = Vector3(-291.21, 21.44, -211.72) },
    { Name = "Shop", Position = Vector3(-25.16, 17.21, -258.36) },
    { Name = "Tower", Position = Vector3(52.75, 43.32, -53.76) }
}
local locationTexts = {}

-- Settings esp
local ESP_SETTINGS = {
    boxWidth = 50,
    boxHeight = 100,
    minBoxWidth = 20,
    minBoxHeight = 40,
    boxOffsetY = 20,
    baseTextSize = 14,
    minTextSize = 12,
    textOffsetFromBox = 5,
    minTextOffset = 5,
    textShiftLeft = 10,
    baseDistance = 50,
    minScale = 0.2,
    maxScale = 1.5,
    fixedDistanceThreshold = 35,
    boxColor = Color3(1, 0, 0),
    textColor = Color3(1, 0, 0),
    boxThickness = 1,
    tracerEnabled = true,
    tracerColor = Color3(1, 1, 1),
    tracerThickness = 1,
    showDistance = true,
    rainbowEnabled = true,
    rainbowSpeed = 0.5,
    cornerLineLength = 10,
    cornerBoxEnabled = true,
    tracerType = "bottom",  -- "bottom", "top", or "cursor"
    locationEspEnabled = true  -- Toggle for Location ESP
}

local rainbowTime = 0
local function getRainbowColor()
    rainbowTime = rainbowTime + ESP_SETTINGS.rainbowSpeed * 0.01
    local r = math.sin(rainbowTime) * 0.5 + 0.5
    local g = math.sin(rainbowTime + 2.094) * 0.5 + 0.5
    local b = math.sin(rainbowTime + 4.188) * 0.5 + 0.5
    return Color3(r, g, b)
end

local function findRake()
    rake = workspace:FindFirstChild("Rake")
    if not rake then
        return false
    end
    rakeRootPart = rake:FindFirstChild("HumanoidRootPart")
    if not rakeRootPart then
        for _, child in pairs(rake:GetChildren()) do
            if child.ClassName == "Part" then
                rakeRootPart = child
                break
            end
        end
    end
    return rakeRootPart ~= nil
end

local function createRakeESP()
    if espText then
        espText:Remove()
    end
    for i, line in pairs(espBox) do
        line:Remove()
    end
    espBox = {}
    for i, line in pairs(espBoxOutline) do
        line:Remove()
    end
    espBoxOutline = {}
    if tracerLine then
        tracerLine:Remove()
    end
    espText = Drawing.new("Text")
    espText.Text = "Rake"
    espText.Color = ESP_SETTINGS.textColor
    espText.Visible = false
    espText.Outline = true
    if espText.Size then
        espText.Size = ESP_SETTINGS.baseTextSize
    end
    if espText.Center then
        espText.Center = false
    end
    if ESP_SETTINGS.tracerEnabled then
        tracerLine = Drawing.new("Line")
        tracerLine.Color = ESP_SETTINGS.tracerColor
        tracerLine.Thickness = ESP_SETTINGS.tracerThickness
        tracerLine.Visible = false
    end
    local lineCount = ESP_SETTINGS.cornerBoxEnabled and 8 or 4
    for i = 1, lineCount do
        local outlineLine = Drawing.new("Line")
        outlineLine.Color = Color3(0, 0, 0)
        outlineLine.Thickness = ESP_SETTINGS.boxThickness + 2
        outlineLine.Visible = false
        espBoxOutline[i] = outlineLine
        local line = Drawing.new("Line")
        line.Color = ESP_SETTINGS.boxColor
        line.Thickness = ESP_SETTINGS.boxThickness
        line.Visible = false
        espBox[i] = line
    end
end

local function createLocationESP()
    for i, loc in ipairs(locations) do
        local text = Drawing.new("Text")
        text.Text = loc.Name
        text.Color = Color3(1, 1, 1)
        text.Visible = false
        text.Outline = true
        if text.Size then
            text.Size = 14
        end
        if text.Center then
            text.Center = false
        end
        locationTexts[i] = { TextObj = text, Position = loc.Position, Name = loc.Name }
    end
end

local function calculateDistance(pos1, pos2)
    local x1, y1, z1, x2, y2, z2
    if pos1[1] and pos1[2] and pos1[3] then
        x1, y1, z1 = pos1[1], pos1[2], pos1[3]
    else
        local str1 = tostring(pos1)
        x1, y1, z1 = str1:match("Vector3%(([%d%.%-]+),%s*([%d%.%-]+),%s*([%d%.%-]+)%)")
        if x1 then x1, y1, z1 = tonumber(x1), tonumber(y1), tonumber(z1) end
    end
    if pos2[1] and pos2[2] and pos2[3] then
        x2, y2, z2 = pos2[1], pos2[2], pos2[3]
    else
        local str2 = tostring(pos2)
        x2, y2, z2 = str2:match("Vector3%(([%d%.%-]+),%s*([%d%.%-]+),%s*([%d%.%-]+)%)")
        if x2 then x2, y2, z2 = tonumber(x2), tonumber(y2), tonumber(z2) end
    end
    if not (x1 and y1 and z1 and x2 and y2 and z2) then
        return 0
    end
    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

local function getScreenBottomCenter()
    local camera = workspace.CurrentCamera
    if camera then
        local viewportSize = camera.ViewportSize
        if viewportSize then
            local centerX, screenHeight
            if viewportSize[1] and viewportSize[2] then
                centerX, screenHeight = viewportSize[1], viewportSize[2]
            else
                local str = tostring(viewportSize)
                centerX, screenHeight = str:match("Vector2%(([%d%.%-]+),%s*([%d%.%-]+)%)")
                if centerX and screenHeight then
                    centerX = tonumber(centerX)
                    screenHeight = tonumber(screenHeight)
                end
            end
            if centerX and screenHeight then
                return Vector2(centerX / 2, screenHeight)
            end
        end
    end
    return Vector2(960, 1080)
end

local function getScreenTopCenter()
    local camera = workspace.CurrentCamera
    if camera then
        local viewportSize = camera.ViewportSize
        if viewportSize then
            local centerX, screenHeight
            if viewportSize[1] and viewportSize[2] then
                centerX, screenHeight = viewportSize[1], viewportSize[2]
            else
                local str = tostring(viewportSize)
                centerX, screenHeight = str:match("Vector2%(([%d%.%-]+),%s*([%d%.%-]+)%)")
                if centerX and screenHeight then
                    centerX = tonumber(centerX)
                    screenHeight = tonumber(screenHeight)
                end
            end
            if centerX and screenHeight then
                return Vector2(centerX / 2, 0)
            end
        end
    end
    return Vector2(960, 0)
end

local function getMousePosition()
    return Vector2(Mouse.X, Mouse.Y)
end

local function updateRakeESP()
    if not rake or not rake.Parent then
        if not findRake() then
            if espText then
                espText.Visible = false
            end
            for _, line in pairs(espBox) do
                line.Visible = false
            end
            for _, line in pairs(espBoxOutline) do
                line.Visible = false
            end
            if tracerLine then
                tracerLine.Visible = false
            end
            return
        end
    end
    if not rakeRootPart or not rakeRootPart.Parent then
        if not findRake() then
            if espText then
                espText.Visible = false
            end
            for _, line in pairs(espBox) do
                line.Visible = false
            end
            for _, line in pairs(espBoxOutline) do
                line.Visible = false
            end
            if tracerLine then
                tracerLine.Visible = false
            end
            return
        end
    end
    local rakePosition = rakeRootPart.Position
    local player = Players.LocalPlayer
    local playerCharacter = player.Character
    local playerPosition = nil
    if playerCharacter then
        local playerRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
        if playerRootPart then
            playerPosition = playerRootPart.Position
        end
    end
    local screenPos, onScreen = WorldToScreen(rakePosition)
    if onScreen and screenPos then
        local posX, posY = screenPos[1], screenPos[2]
        if not posX or not posY then
            local str = tostring(screenPos)
            posX, posY = str:match("Vector2%(([%d%.%-]+),%s*([%d%.%-]+)%)")
            if posX and posY then
                posX = tonumber(posX)
                posY = tonumber(posY)
            else
                posX, posY = 960, 540
            end
        end
        if type(posX) == "number" and type(posY) == "number" then
            local boxWidth = ESP_SETTINGS.boxWidth
            local boxHeight = ESP_SETTINGS.boxHeight
            local distance = 0
            local scaleFactor = 1
            if playerPosition then
                distance = calculateDistance(rakePosition, playerPosition)
                local effectiveDistance = math.max(distance, ESP_SETTINGS.fixedDistanceThreshold)
                scaleFactor = math.max(ESP_SETTINGS.minScale, math.min(ESP_SETTINGS.maxScale, ESP_SETTINGS.baseDistance / effectiveDistance))
                boxWidth = math.max(ESP_SETTINGS.minBoxWidth, boxWidth * scaleFactor)
                boxHeight = math.max(ESP_SETTINGS.minBoxHeight, boxHeight * scaleFactor)
            end
            local currentColor = ESP_SETTINGS.rainbowEnabled and getRainbowColor() or ESP_SETTINGS.textColor
            local currentBoxColor = ESP_SETTINGS.rainbowEnabled and getRainbowColor() or ESP_SETTINGS.boxColor
            local currentTracerColor = ESP_SETTINGS.rainbowEnabled and getRainbowColor() or ESP_SETTINGS.tracerColor
            local boxCenterY = posY + ESP_SETTINGS.boxOffsetY * scaleFactor
            local displayText = "Rake"
            if ESP_SETTINGS.showDistance then
                displayText = string.format("Rake [%.1f]", distance)
            end
            espText.Text = displayText
            local scaledTextSize = math.max(ESP_SETTINGS.minTextSize, ESP_SETTINGS.baseTextSize * scaleFactor)
            if espText.Size then
                espText.Size = scaledTextSize
            end
            espText.Color = currentColor
            local textOffset = math.max(ESP_SETTINGS.minTextOffset, ESP_SETTINGS.textOffsetFromBox * scaleFactor)
            local textX = posX - (boxWidth / 2) + ESP_SETTINGS.textShiftLeft * scaleFactor
            local textY = boxCenterY - boxHeight/2 - textOffset - scaledTextSize
            espText.Position = Vector2(textX, textY)
            espText.Visible = true
            if ESP_SETTINGS.tracerEnabled and tracerLine then
                local tracerFrom
                if ESP_SETTINGS.tracerType == "bottom" then
                    local boxBottomY = boxCenterY + boxHeight / 2
                    tracerFrom = Vector2(posX, boxBottomY)
                elseif ESP_SETTINGS.tracerType == "top" then
                    local boxTopY = boxCenterY - boxHeight / 2
                    tracerFrom = Vector2(posX, boxTopY)
                elseif ESP_SETTINGS.tracerType == "cursor" then
                    tracerFrom = Vector2(posX, boxCenterY)
                else
                    local boxBottomY = boxCenterY + boxHeight / 2
                    tracerFrom = Vector2(posX, boxBottomY)
                end
                local tracerTo
                if ESP_SETTINGS.tracerType == "cursor" then
                    tracerTo = getMousePosition()
                else
                    tracerTo = ESP_SETTINGS.tracerType == "top" and getScreenTopCenter() or getScreenBottomCenter()
                end
                tracerLine.From = tracerFrom
                tracerLine.To = tracerTo
                tracerLine.Color = currentTracerColor
                tracerLine.Visible = true
            end
            local topLeft = Vector2(posX - boxWidth/2, boxCenterY - boxHeight/2)
            local topRight = Vector2(posX + boxWidth/2, boxCenterY - boxHeight/2)
            local bottomLeft = Vector2(posX - boxWidth/2, boxCenterY + boxHeight/2)
            local bottomRight = Vector2(posX + boxWidth/2, boxCenterY + boxHeight/2)
            local topLeftX, topLeftY
            if topLeft.x and topLeft.y then
                topLeftX, topLeftY = topLeft.x, topLeft.y
            elseif topLeft.X and topLeft.Y then
                topLeftX, topLeftY = topLeft.X, topLeft.Y
            else
                local str = tostring(topLeft)
                topLeftX, topLeftY = str:match("Vector2%(([%d%.%-]+),%s*([%d%.%-]+)%)")
                if topLeftX and topLeftY then
                    topLeftX, topLeftY = tonumber(topLeftX), tonumber(topLeftY)
                else
                    espText.Visible = false
                    for _, line in pairs(espBox) do
                        line.Visible = false
                    end
                    for _, line in pairs(espBoxOutline) do
                        line.Visible = false
                    end
                    if tracerLine then
                        tracerLine.Visible = false
                    end
                    return
                end
            end
            local topRightX, topRightY
            if topRight.x and topRight.y then
                topRightX, topRightY = topRight.x, topRight.y
            elseif topRight.X and topRight.Y then
                topRightX, topRightY = topRight.X, topRight.Y
            else
                local str = tostring(topRight)
                topRightX, topRightY = str:match("Vector2%(([%d%.%-]+),%s*([%d%.%-]+)%)")
                topRightX, topRightY = tonumber(topRightX), tonumber(topRightY)
            end
            local bottomLeftX, bottomLeftY
            if bottomLeft.x and bottomLeft.y then
                bottomLeftX, bottomLeftY = bottomLeft.x, bottomLeft.y
            elseif bottomLeft.X and bottomLeft.Y then
                bottomLeftX, bottomLeftY = bottomLeft.X, bottomLeft.Y
            else
                local str = tostring(bottomLeft)
                bottomLeftX, bottomLeftY = str:match("Vector2%(([%d%.%-]+),%s*([%d%.%-]+)%)")
                bottomLeftX, bottomLeftY = tonumber(bottomLeftX), tonumber(bottomLeftY)
            end
            local bottomRightX, bottomRightY
            if bottomRight.x and bottomRight.y then
                bottomRightX, bottomRightY = bottomRight.x, bottomRight.y
            elseif bottomRight.X and bottomRight.Y then
                bottomRightX, bottomRightY = bottomRight.X, bottomRight.Y
            else
                local str = tostring(bottomRight)
                bottomRightX, bottomRightY = str:match("Vector2%(([%d%.%-]+),%s*([%d%.%-]+)%)")
                bottomRightX, bottomRightY = tonumber(bottomRightX), tonumber(bottomRightY)
            end
            if ESP_SETTINGS.cornerBoxEnabled then
                local cornerLength = math.max(5, ESP_SETTINGS.cornerLineLength * scaleFactor)
                local tl1 = Vector2(topLeftX + cornerLength, topLeftY)
                local tl2 = Vector2(topLeftX, topLeftY + cornerLength)
                local tr1 = Vector2(topRightX - cornerLength, topRightY)
                local tr2 = Vector2(topRightX, topRightY + cornerLength)
                local bl1 = Vector2(bottomLeftX + cornerLength, bottomLeftY)
                local bl2 = Vector2(bottomLeftX, bottomLeftY - cornerLength)
                local br1 = Vector2(bottomRightX - cornerLength, bottomRightY)
                local br2 = Vector2(bottomRightX, bottomRightY - cornerLength)
                espBox[1].From = Vector2(topLeftX, topLeftY); espBox[1].To = tl1; espBox[1].Color = currentBoxColor; espBox[1].Visible = true
                espBox[2].From = Vector2(topLeftX, topLeftY); espBox[2].To = tl2; espBox[2].Color = currentBoxColor; espBox[2].Visible = true
                espBox[3].From = Vector2(topRightX, topRightY); espBox[3].To = tr1; espBox[3].Color = currentBoxColor; espBox[3].Visible = true
                espBox[4].From = Vector2(topRightX, topRightY); espBox[4].To = tr2; espBox[4].Color = currentBoxColor; espBox[4].Visible = true
                espBox[5].From = Vector2(bottomLeftX, bottomLeftY); espBox[5].To = bl1; espBox[5].Color = currentBoxColor; espBox[5].Visible = true
                espBox[6].From = Vector2(bottomLeftX, bottomLeftY); espBox[6].To = bl2; espBox[6].Color = currentBoxColor; espBox[6].Visible = true
                espBox[7].From = Vector2(bottomRightX, bottomRightY); espBox[7].To = br1; espBox[7].Color = currentBoxColor; espBox[7].Visible = true
                espBox[8].From = Vector2(bottomRightX, bottomRightY); espBox[8].To = br2; espBox[8].Color = currentBoxColor; espBox[8].Visible = true
                espBoxOutline[1].From = Vector2(topLeftX, topLeftY); espBoxOutline[1].To = tl1; espBoxOutline[1].Color = Color3(0, 0, 0); espBoxOutline[1].Visible = true
                espBoxOutline[2].From = Vector2(topLeftX, topLeftY); espBoxOutline[2].To = tl2; espBoxOutline[2].Color = Color3(0, 0, 0); espBoxOutline[2].Visible = true
                espBoxOutline[3].From = Vector2(topRightX, topRightY); espBoxOutline[3].To = tr1; espBoxOutline[3].Color = Color3(0, 0, 0); espBoxOutline[3].Visible = true
                espBoxOutline[4].From = Vector2(topRightX, topRightY); espBoxOutline[4].To = tr2; espBoxOutline[4].Color = Color3(0, 0, 0); espBoxOutline[4].Visible = true
                espBoxOutline[5].From = Vector2(bottomLeftX, bottomLeftY); espBoxOutline[5].To = bl1; espBoxOutline[5].Color = Color3(0, 0, 0); espBoxOutline[5].Visible = true
                espBoxOutline[6].From = Vector2(bottomLeftX, bottomLeftY); espBoxOutline[6].To = bl2; espBoxOutline[6].Color = Color3(0, 0, 0); espBoxOutline[6].Visible = true
                espBoxOutline[7].From = Vector2(bottomRightX, bottomRightY); espBoxOutline[7].To = br1; espBoxOutline[7].Color = Color3(0, 0, 0); espBoxOutline[7].Visible = true
                espBoxOutline[8].From = Vector2(bottomRightX, bottomRightY); espBoxOutline[8].To = br2; espBoxOutline[8].Color = Color3(0, 0, 0); espBoxOutline[8].Visible = true
            else
                espBox[1].From = Vector2(topLeftX, topLeftY); espBox[1].To = Vector2(topRightX, topRightY); espBox[1].Color = currentBoxColor; espBox[1].Visible = true
                espBox[2].From = Vector2(topRightX, topRightY); espBox[2].To = Vector2(bottomRightX, bottomRightY); espBox[2].Color = currentBoxColor; espBox[2].Visible = true
                espBox[3].From = Vector2(bottomRightX, bottomRightY); espBox[3].To = Vector2(bottomLeftX, bottomLeftY); espBox[3].Color = currentBoxColor; espBox[3].Visible = true
                espBox[4].From = Vector2(bottomLeftX, bottomLeftY); espBox[4].To = Vector2(topLeftX, topLeftY); espBox[4].Color = currentBoxColor; espBox[4].Visible = true
                espBoxOutline[1].From = Vector2(topLeftX, topLeftY); espBoxOutline[1].To = Vector2(topRightX, topRightY); espBoxOutline[1].Color = Color3(0, 0, 0); espBoxOutline[1].Visible = true
                espBoxOutline[2].From = Vector2(topRightX, topRightY); espBoxOutline[2].To = Vector2(bottomRightX, bottomRightY); espBoxOutline[2].Color = Color3(0, 0, 0); espBoxOutline[2].Visible = true
                espBoxOutline[3].From = Vector2(bottomRightX, bottomRightY); espBoxOutline[3].To = Vector2(bottomLeftX, bottomLeftY); espBoxOutline[3].Color = Color3(0, 0, 0); espBoxOutline[3].Visible = true
                espBoxOutline[4].From = Vector2(bottomLeftX, bottomLeftY); espBoxOutline[4].To = Vector2(topLeftX, topLeftY); espBoxOutline[4].Color = Color3(0, 0, 0); espBoxOutline[4].Visible = true
            end
        end
    else
        espText.Visible = false
        for _, line in pairs(espBox) do
            line.Visible = false
        end
        for _, line in pairs(espBoxOutline) do
            line.Visible = false
        end
        if tracerLine then
            tracerLine.Visible = false
        end
    end
end

local function updateLocationESP()
    if not ESP_SETTINGS.locationEspEnabled then
        for _, esp in ipairs(locationTexts) do
            esp.TextObj.Visible = false
        end
        return
    end

    local player = Players.LocalPlayer
    local playerPosition = nil
    if player and player.Character then
        local playerRootPart = player.Character:FindFirstChild("HumanoidRootPart")
        if playerRootPart then
            playerPosition = playerRootPart.Position
        end
    end

    for _, esp in ipairs(locationTexts) do
        local screenPos, isOnScreen = WorldToScreen(esp.Position)
        local distance = playerPosition and calculateDistance(esp.Position, playerPosition) or 0
        esp.TextObj.Text = esp.Name .. " (" .. string.format("%.1f", distance) .. "m)"
        if isOnScreen and screenPos then
            esp.TextObj.Position = screenPos
            esp.TextObj.Visible = true
        else
            esp.TextObj.Visible = false
        end
    end
end

createRakeESP()
createLocationESP()

while running do
    updateRakeESP()
    updateLocationESP()
    if isrbxactive() then
        wait(0)
    else
        wait(0)
    end
end

if espText then
    espText:Remove()
end
for i, line in pairs(espBox) do
    line:Remove()
end
for i, line in pairs(espBoxOutline) do
    line:Remove()
end
if tracerLine then
    tracerLine:Remove()
end
for i, esp in ipairs(locationTexts) do
    esp.TextObj:Remove()
end

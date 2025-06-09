local texts = {}
local players = game:GetService("Players")
local workspace = game.Workspace

local DISTANCE_LIMIT = 500

local DISTANCE_LIMIT_ENABLED = true

local RAINBOW_ESP_ENABLED = true

local function calculateDistance(pos1, pos2)
    local success, result = pcall(function()
        local dx = pos1.x - pos2.x
        local dy = pos1.y - pos2.y
        local dz = pos1.z - pos2.z
        return math.sqrt(dx * dx + dy * dy + dz * dz)
    end)
    if not success then
        return math.huge
    end
    return result
end

local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    if i % 6 == 0 then
        r, g, b = v, t, p
    elseif i % 6 == 1 then
        r, g, b = q, v, p
    elseif i % 6 == 2 then
        r, g, b = p, v, t
    elseif i % 6 == 3 then
        r, g, b = p, q, v
    elseif i % 6 == 4 then
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end

    return r, g, b
end

local function initializeESP()
    local botsFolder = workspace:FindFirstChild("bots")
    if not botsFolder then
        return false
    end

    local botModels = {}
    local success, result = pcall(function()
        for _, folder in ipairs(botsFolder:GetChildren()) do
            for _, model in ipairs(folder:GetChildren()) do
                local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")
                if humanoidRootPart then
                    table.insert(botModels, model)
                end
            end
        end
        return true
    end)
    if not success then
        return false
    end

    for i, bot in ipairs(botModels) do
        local success, humanoidRootPart = pcall(function()
            return bot:FindFirstChild("HumanoidRootPart")
        end)
        if success and humanoidRootPart then
            local text = Drawing.new("Text")
            text.Text = bot.Name
            text.Color = Color3(1, 0, 0)
            text.Outline = true
            text.OutlineColor = Color3(0, 0, 0)
            text.Visible = false
            texts[i] = {
                TextObj = text,
                Position = humanoidRootPart.Position,
                Name = bot.Name,
                RootPart = humanoidRootPart,
                LastText = bot.Name
            }
        end
    end
    return true
end

local function updateESP()
    while true do
        local playerPos = nil
        local success, result = pcall(function()
            local player = players.LocalPlayer
            if player and player.Character then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    playerPos = rootPart.Position
                end
            end
            return true
        end)

        local r, g, b
        if RAINBOW_ESP_ENABLED then
            local hue = (os.clock() % 5) / 5
            r, g, b = hsvToRgb(hue, 1, 1)
        else
            r, g, b = 1, 0, 0
        end

        for _, esp in ipairs(texts) do
            local success, result = pcall(function()
                local newPosition = nil
                local posSuccess, posResult = pcall(function()
                    newPosition = esp.RootPart.Position
                    return newPosition ~= nil
                end)
                if not posSuccess or not posResult then
                    return false
                end
                esp.Position = newPosition

                local screenPos, isOnScreen = WorldToScreen(esp.Position)
                local distance = playerPos and calculateDistance(esp.Position, playerPos) or math.huge
                local newText = esp.Name .. " (" .. string.format("%.1f", distance) .. "m)"
                
                if esp.LastText ~= newText then
                    esp.TextObj.Text = newText
                    esp.LastText = newText
                end

                local withinDistance = not DISTANCE_LIMIT_ENABLED or (distance <= DISTANCE_LIMIT)
                if isOnScreen and screenPos and withinDistance then
                    esp.TextObj.Color = Color3(r, g, b)
                    esp.TextObj.Position = screenPos
                    esp.TextObj.Visible = true
                else
                    esp.TextObj.Visible = false
                end
            end)
            if not success then
                esp.TextObj.Visible = false
            end
        end
        wait(0.01)
    end
end

local success, result = pcall(initializeESP)
if success and result then
    pcall(updateESP)
end

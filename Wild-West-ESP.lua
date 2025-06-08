-- normal animals are yellow and legendary are pinky matcha :3

local WORKSPACE_EntitiesFolder = workspace:FindFirstChild("WORKSPACE_Entities")
if not WORKSPACE_EntitiesFolder then
    print("WORKSPACE_Entities folder not found")
    return
end

local AnimalsFolder = WORKSPACE_EntitiesFolder:FindFirstChild("Animals")
if not AnimalsFolder then
    print("Animals folder not found inside WORKSPACE_Entities")
    return
end

local prevItemsTable = {}

-- lista de nombres a excluir
local excludedNames = {
    Horse = true,
    WendigoHorse = true,
    SkeletonHorse = true,
    Cow = true
}

while true do
    -- delete dead animals ESP i think
    for _, entry in pairs(prevItemsTable) do
        if entry[3] then pcall(function() entry[3]:Remove() end) end
    end

    local newItemsTable = {}

    for _, item in pairs(AnimalsFolder:GetChildren()) do
        if item:IsA("Model") and not excludedNames[item.Name] then
            local reference = item.PrimaryPart
            if not reference then
                for _, part in pairs(item:GetChildren()) do
                    if part:IsA("MeshPart") or part:IsA("Part") then
                        reference = part
                        break
                    end
                end
            end

            if reference then
                local healthValue = item:FindFirstChild("Health")
                local health = healthValue and healthValue.Value or 0

                local label = item.Name
                if health > 300 then
                    label = label .. " [LEGENDARYYYY]"
                end 

                local nameText = Drawing.new("Text")
                nameText.Text = string.format("%s (%.0f HP)", label, health)
                nameText.TextSize = 60
                nameText.Outline = true
                nameText.OutlineColor = Color3(0, 0, 0)
                nameText.Visible = true

                if health > 300 then
                    nameText.Color = Color3(1, 0.75, 0.85) -- pinky matcha
                else
                    nameText.Color = Color3(1, 1, 0) -- yellow
                end

                table.insert(newItemsTable, {item, reference, nameText})
            end
        end
    end

    for _, entry in pairs(newItemsTable) do
        local model, reference, nameText = entry[1], entry[2], entry[3]
        local pos, onScreen = WorldToScreen(reference.Position + Vector3(0, 1, 0))
        if pos and onScreen then
            nameText.Position = pos
            nameText.Visible = true
        else
            nameText.Visible = false
        end
    end

    prevItemsTable = newItemsTable
    wait(0.17)
end

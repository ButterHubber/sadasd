--// Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Globals
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local HRP = LocalPlayer.Character and LocalPlayer.Character:WaitForChild("HumanoidRootPart")

-- GUI CREATION
local function createProcessOverlay()
    if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    guiOverlay = Instance.new("ScreenGui")
    guiOverlay.Name = "MoneyDupeOverlay"
    guiOverlay.IgnoreGuiInset = true
    guiOverlay.ResetOnSpawn = false
    guiOverlay.ZIndexBehavior = Enum.ZIndexBehavior.Global
    guiOverlay.Parent = playerGui

    local Background = Instance.new("Frame")
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = Color3.new(0, 0, 0)
    Background.Parent = ScreenGui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0.1, 0)
    label.Position = UDim2.new(0.2, 0, 0.3, 0)
    label.Text = "Velo.cc | Generating Max Money"
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.BackgroundTransparency = 1
    label.Parent = Background

    local loadingBarBG = Instance.new("Frame")
    loadingBarBG.Size = UDim2.new(0.6, 0, 0.05, 0)
    loadingBarBG.Position = UDim2.new(0.2, 0, 0.52, 0)
    loadingBarBG.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    loadingBarBG.BorderSizePixel = 0
    loadingBarBG.ZIndex = 9
    loadingBarBG.Parent = frame

    loadingBar = Instance.new("Frame")
    loadingBar.Size = UDim2.new(0, 0, 1, 0)
    loadingBar.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    loadingBar.BorderSizePixel = 0
    loadingBar.ZIndex = 10
    loadingBar.Parent = loadingBarBG
end

-- PROGRESS TRACKER
local function advanceProgress()
    currentPhase += 1
    local progress = math.clamp(currentPhase / totalPhases, 0, 1)
    if loadingBar then
        loadingBar:TweenSize(UDim2.new(progress, 0, 1, 0), "Out", "Sine", 0.5, true)
    end
end

local function destroyOverlay()
    if guiOverlay then
        guiOverlay:Destroy()
        guiOverlay = nil
    end
end

--// Constants
local AUTO_LOOP_DELAY = 0.25
local RANGE = 5

--// Flags
local pitcherCupFilled = false

--// Target Names
local cookingTargetNames = {
    ["CookPart"] = true, ["CookingPart"] = true, ["CookingPot"] = true, ["CookingPots"] = true,
    ["Stove"] = true, ["Oven"] = true
}
local specialPromptNames = {
    ["Mix Items"] = true, ["Turn On"] = true, ["Fill Cup"] = true, ["Fill Pitcher Cup"] = true
}

--// Utilities
local function getRoot()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return character:WaitForChild("HumanoidRootPart")
end

local function isNear(part, range)
    local root = getRoot()
    return part and (part.Position - root.Position).Magnitude <= range
end

local function tryFirePrompt(prompt, tag, callback)
    if not prompt:IsA("ProximityPrompt") or not prompt.Enabled then return end
    pcall(function()
        fireproximityprompt(prompt, 0)
    end)
    print(">> [" .. (tag or "Prompt") .. "] Fired at:", prompt:GetFullName())

    if tag == "Fill Pitcher Cup" and not pitcherCupFilled then
        pitcherCupFilled = true
        print(">> Pitcher Cup filled via prompt. Triggering duplication.")
        if typeof(callback) == "function" then callback() end
    end
end

-- STEP 1: BUY & TELEPORT
local function step1_buyAndTeleport(callback)
    advanceProgress()
    local backpack = LocalPlayer.Backpack
    local items = { "FreshWater", "Ice-Fruit Bag", "FijiWater", "Ice-Fruit Cupz" }
    for _, name in ipairs(items) do
        if not backpack:FindFirstChild(name) then
            ReplicatedStorage:WaitForChild("ExoticShopRemote"):InvokeServer(name)
            task.wait(0.5)
        end
    end

    getgenv().FreeFallMethod = true
    task.wait(0.8)
    HRP.CFrame = CFrame.new(-1040.95618, 253.924194, -1217.70349)
    getgenv().FreeFallMethod = false

    print(">> STEP 1 complete.")
    task.wait(1.25)
    if typeof(callback) == "function" then callback() end
end

-- STEP 2: AUTO COOK LOOP
local function step2_automationCook(callback)
    advanceProgress()
    print(">> STEP 2: Starting auto-cook...")
    local automationRunning = true
    local lastPos = getRoot().Position

    local function useBackpackItems()
        local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
        if not backpack then return end
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name ~= "Phone" and tool.Name ~= "Fists" then
                LocalPlayer.Character.Humanoid:EquipTool(tool)
                task.wait(0.2)
            end
        end
    end

    local function monitorTeleport()
        task.spawn(function()
            while automationRunning do
                if (getRoot().Position - lastPos).Magnitude > 50 then
                    automationRunning = false
                    warn(">> Player moved too far. Stopping automation.")
                    break
                end
                lastPos = getRoot().Position
                task.wait(1)
            end
        end)
    end

    local function scanPrompts()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local parent = obj.Parent
                if parent and parent:IsA("BasePart") and isNear(parent, RANGE) then
                    local pName, prName = parent.Name, obj.Name
                    if cookingTargetNames[pName] or specialPromptNames[prName] then
                        tryFirePrompt(obj, prName, callback)
                    end
                end
            end
        end
    end

    monitorTeleport()

    task.spawn(function()
        while automationRunning and not pitcherCupFilled do
            pcall(function()
                useBackpackItems()
                scanPrompts()
            end)
            task.wait(AUTO_LOOP_DELAY)
        end
        automationRunning = false
        print(">> STEP 2 complete.")
    end)
end

-- STEP 3: DUPLICATE
local function step3_duplicate()
    advanceProgress()
    if not pitcherCupFilled then return end
    print(">> STEP 3: Starting duplication...")

    local oldPos = HRP.CFrame

    local function hideScreen()
        RunService:BindToRenderStep("HideScreenRender", Enum.RenderPriority.Camera.Value + 1, function()
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.new(1e6, 1e6, 1e6)
        end)
    end

    local function unhideScreen()
        RunService:UnbindFromRenderStep("HideScreenRender")
        Camera.CameraType = Enum.CameraType.Custom
    end

    local function hideUI(state)
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, name in ipairs({ "Hunger", "HealthGui", "Run", "SleepGui", "MoneyGui", "NewMoneyGui" }) do
                local g = pg:FindFirstChild(name)
                if g then g.Enabled = not state end
            end
        end
    end

    local function lagSwitch(state)
        sethiddenproperty(LocalPlayer, "MaximumSimulationRadius", state and math.huge or 100)
        sethiddenproperty(LocalPlayer, "SimulationRadius", state and math.huge or 100)
        settings().Network.IncomingReplicationLag = state and 10 or 0
    end

    local function resetLag()
        for i = 10, 0, -1 do
            settings().Network.IncomingReplicationLag = i
            task.wait(0.1)
        end
        sethiddenproperty(LocalPlayer, "SimulationRadius", 100)
        sethiddenproperty(LocalPlayer, "MaximumSimulationRadius", 100)
    end

    local sell = Workspace:FindFirstChild("IceFruit Sell")
    if not sell or not sell:FindFirstChild("ProximityPrompt") then
        warn(">> Sell prompt not found.")
        return
    end

    hideUI(true)
    hideScreen()

    HRP.CFrame = sell.CFrame + Vector3.new(0, 3, 0)
    lagSwitch(true)
    task.wait(0.25)

    local prompt = sell:FindFirstChild("ProximityPrompt")
    for i = 1, 10000 do
        task.spawn(function()
            pcall(function() fireproximityprompt(prompt) end)
        end)
        if i % 1000 == 0 then task.wait(0.05) end
    end

    task.wait(6)
    resetLag()
    hideUI(false)
    HRP.CFrame = oldPos
    unhideScreen()

    print(">> Duplication done. Go wash your money.")
    destroyOverlay()
end

-- ENHANCED GUI MONITORING
local function monitorCupFilledMessage()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local function checkText(obj)
        if not pitcherCupFilled and obj:IsA("TextLabel") or obj:IsA("TextBox") then
            if obj.Text and obj.Text:lower():find("cup already filled") then
                pitcherCupFilled = true
                print(">> Detected GUI message: 'cup already filled'. Triggering Function 3.")
                step3_duplicate()
            end
        end
    end

    for _, gui in ipairs(playerGui:GetDescendants()) do
        checkText(gui)
        if gui:IsA("TextLabel") or gui:IsA("TextBox") then
            gui:GetPropertyChangedSignal("Text"):Connect(function()
                checkText(gui)
            end)
        end
    end

    playerGui.DescendantAdded:Connect(function(child)
        checkText(child)
        if child:IsA("TextLabel") or child:IsA("TextBox") then
            child:GetPropertyChangedSignal("Text"):Connect(function()
                checkText(child)
            end)
        end
    end)
end

-- START EXECUTION
createProcessOverlay()
monitorCupFilledMessage()

step1_buyAndTeleport(function()
    step2_automationCook(function()
        step3_duplicate()
    end)
end)

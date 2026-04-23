

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- === Variables Setup ===
local hitboxEnabled = false
local hitboxSize = 2
local hitboxTransparency = 0.5
local hitboxColor = Color3.fromRGB(255, 0, 0)

local walkSpeedEnabled = false
local walkSpeedValue = 16
local jumpPowerEnabled = false
local jumpPowerValue = 50
local noclipEnabled = false
local infiniteJumpEnabled = false
local espEnabled = true
local espDistance = 1200 -- ตัวแปรระยะทาง ESP

-- Visual Variables
local fullbrightEnabled = false
local xrayEnabled = false
local originalMaterials = {}

-- === 1. Setup Window ===
local Window = WindUI:CreateWindow({
    Title   = "STATIC HUB",
    Author  = "by Project Static",
    Folder  = "static_hub",
    Icon    = "rbxassetid://81317526990537",
    Theme   = "Midnight", 
    Acrylic = true,
    Transparent = true,
    Size    = UDim2.fromOffset(680, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    ToggleKey  = Enum.KeyCode.RightShift,
    Resizable  = true,
    AutoScale  = true,
    NewElements = true,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    SideBarWidth = 200,
    Topbar = { Height = 44, ButtonsType = "Default" },
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function() print("clicked") end,
    },
})

-- [[ เพิ่มระบบ Config Manager ]]
local ConfigManager = Window.ConfigManager
local myConfig = ConfigManager:CreateConfig("static_hub_config") 

Window:Tag({
    Title = "Seeker vs Hider",
    Icon = "eye-off",
    Color = Color3.fromHex("#0093ff"),
    Radius = 9,
})

Window:EditOpenButton({ Enabled = false })

-- === สร้างปุ่ม Logo Static (Floating Icon) ===
local ScreenGui = Instance.new("ScreenGui")
local ImageButton = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Name = "StaticFloatingIcon"
ScreenGui.Parent = (RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui"))
ScreenGui.ResetOnSpawn = false

ImageButton.Parent = ScreenGui
ImageButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ImageButton.BackgroundTransparency = 0.4 
ImageButton.Position = UDim2.new(0.9, 0, 0.5, 0)
ImageButton.Size = UDim2.new(0, 55, 0, 55)
ImageButton.Image = "rbxassetid://81317526990537"
ImageButton.BorderSizePixel = 0
UICorner.CornerRadius = UDim.new(0, 15) 
UICorner.Parent = ImageButton

local dragStart, startPos
ImageButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragStart = input.Position
        startPos = ImageButton.Position
    end
end)

ImageButton.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragStart then
        local delta = input.Position - dragStart
        ImageButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

ImageButton.InputEnded:Connect(function(input) dragStart = nil end)
ImageButton.MouseButton1Click:Connect(function() Window:Toggle() end)

-- === 2. Enhanced ESP System (With Distance Check) ===
local function applyESP(p)
    if p == LocalPlayer then return end
    local function setupESP(char)
        local hum = char:WaitForChild("Humanoid", 10)
        local root = char:WaitForChild("HumanoidRootPart", 10)
        if char:FindFirstChild("StaticESP") then char.StaticESP:Destroy() end
        if char:FindFirstChild("StaticGui") then char.StaticGui:Destroy() end

        local hl = Instance.new("Highlight")
        hl.Name = "StaticESP"
        hl.FillTransparency = 1
        hl.OutlineTransparency = 0.2
        hl.OutlineColor = Color3.fromRGB(0, 0, 0)
        hl.Parent = char

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "StaticGui"
        billboard.Adornee = root
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = char

        local infoLabel = Instance.new("TextLabel")
        infoLabel.BackgroundTransparency = 1
        infoLabel.Size = UDim2.new(1, 0, 0.5, 0)
        infoLabel.Font = Enum.Font.GothamBold
        infoLabel.TextSize = 13
        infoLabel.RichText = true
        infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        infoLabel.TextStrokeTransparency = 0
        infoLabel.Parent = billboard

        local healthBarBg = Instance.new("Frame")
        healthBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        healthBarBg.BorderSizePixel = 0
        healthBarBg.Position = UDim2.new(0.25, 0, 0.55, 0)
        healthBarBg.Size = UDim2.new(0.5, 0, 0.08, 0)
        healthBarBg.Parent = billboard
        
        local healthStroke = Instance.new("UIStroke")
        healthStroke.Color = Color3.fromRGB(0, 0, 0)
        healthStroke.Thickness = 1.5
        healthStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        healthStroke.Parent = healthBarBg

        local healthBar = Instance.new("Frame")
        healthBar.BorderSizePixel = 0
        healthBar.Size = UDim2.new(1, 0, 1, 0)
        healthBar.Parent = healthBarBg

        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or hum.Health <= 0 then
                if billboard then billboard:Destroy() end
                if hl then hl:Destroy() end
                connection:Disconnect()
                return
            end

            -- ตรวจสอบระยะทาง
            local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude or 0
            
            if espEnabled and distance <= espDistance then
                billboard.Enabled = true
                hl.Enabled = true
                hl.OutlineColor = Color3.fromRGB(0, 0, 0)
                
                local hasItems = #p.Backpack:GetChildren() > 0 or char:FindFirstChildOfClass("Tool")
                if hasItems then
                    infoLabel.Text = p.DisplayName .. ' <font color="rgb(255, 0, 0)">[No Safe]</font>'
                else
                    infoLabel.Text = p.DisplayName .. ' <font color="rgb(130, 240, 205)">[Safe]</font>'
                end
                
                local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                healthBar.Size = UDim2.new(hpPercent, 0, 1, 0)
                healthBar.BackgroundColor3 = Color3.fromHSV(hpPercent * 0.3, 1, 1)
            else
                billboard.Enabled = false
                hl.Enabled = false
            end
        end)
    end
    p.CharacterAdded:Connect(setupESP)
    if p.Character then setupESP(p.Character) end
end

local function refreshAllESP()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then applyESP(p) end
    end
end

-- === 3. Tabs ===
local MainTab = Window:Tab({ Title = "Main", Icon = "house" })
MainTab:Section({ Title = "ESP Settings" })
MainTab:Toggle({ Title = "Enable ESP", Flag = "esp_enabled", Value = true, Callback = function(state) espEnabled = state end })

-- [[ เพิ่ม Slider ระยะ ESP ตามสั่ง ]]
MainTab:Slider({ 
    Title = "ESP Distance", 
    Flag = "esp_distance_slider",
    Step = 10, 
    Value = { Min = 1, Max = 1200, Default = 1200 }, 
    Callback = function(v) 
        espDistance = v 
    end 
})

MainTab:Button({ Title = "Refresh ESP (Fix Bug)", Callback = function() refreshAllESP() WindUI:Notify({Title="ESP", Content="Refreshed!"}) end })

local CombatTab = Window:Tab({ Title = "Combat", Icon = "swords" })
CombatTab:Section({ Title = "Hitbox Expander" })
CombatTab:Toggle({ Title = "Enable Hitbox", Flag = "hitbox_enabled", Value = false, Callback = function(state) hitboxEnabled = state end })
CombatTab:Slider({ Title = "Hitbox Size", Flag = "hitbox_size_slider", Step = 1, Value = { Min = 2, Max = 100, Default = 2 }, Callback = function(v) hitboxSize = v end })
CombatTab:Slider({ Title = "Transparency", Flag = "hitbox_trans_slider", Step = 0.1, Value = { Min = 0, Max = 1, Default = 0.5 }, Callback = function(v) hitboxTransparency = v end })
CombatTab:Colorpicker({ Title = "Hitbox Color", Flag = "hitbox_color", Default = Color3.fromRGB(255, 0, 0), Callback = function(color) hitboxColor = color end })

local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })
VisualTab:Section({ Title = "World Settings" })
VisualTab:Toggle({ Title = "Fullbright", Flag = "fullbright_toggle", Value = false, Callback = function(state) fullbrightEnabled = state end })
VisualTab:Toggle({ Title = "X-Ray", Flag = "xray_toggle", Value = false, Callback = function(state) 
    xrayEnabled = state
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and not v:IsDescendantOf(LocalPlayer.Character) and not v:IsDescendantOf(Players) then
            v.LocalTransparencyModifier = state and 0.7 or 0
        end
    end
end})

VisualTab:Section({ Title = "Atmosphere" })
VisualTab:Colorpicker({
    Title = "Ambient Color",
    Flag = "ambient_color",
    Default = Lighting.Ambient,
    Callback = function(color)
        Lighting.Ambient = color
        Lighting.OutdoorAmbient = color
    end
})

local MoveTab = Window:Tab({ Title = "Movement", Icon = "zap" })
MoveTab:Toggle({ Title = "Enable WalkSpeed", Flag = "ws_enabled", Value = false, Callback = function(state) walkSpeedEnabled = state end })
MoveTab:Slider({ Title = "Speed Value", Flag = "ws_slider", Step = 1, Value = { Min = 16, Max = 250, Default = 16 }, Callback = function(v) walkSpeedValue = v end })
MoveTab:Toggle({ Title = "Enable JumpPower", Flag = "jp_enabled", Value = false, Callback = function(state) jumpPowerEnabled = state end })
MoveTab:Slider({ Title = "Jump Value", Flag = "jp_slider", Step = 1, Value = { Min = 50, Max = 500, Default = 50 }, Callback = function(v) jumpPowerValue = v end })
MoveTab:Toggle({ Title = "Noclip", Flag = "noclip_toggle", Value = false, Callback = function(state) noclipEnabled = state end })
MoveTab:Toggle({ Title = "Infinite Jump", Flag = "infjump_toggle", Value = false, Callback = function(state) infiniteJumpEnabled = state end })

local PlayerTab = Window:Tab({ Title = "Players", Icon = "users" })
local selectedPlayerName = ""
local function getPlayerList()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(names, p.DisplayName) end end
    return names
end
local PlayerDropdown = PlayerTab:Dropdown({ Title = "Select Target", Values = getPlayerList(), Callback = function(selected) selectedPlayerName = selected end })
PlayerTab:Button({ Title = "Refresh List", Callback = function() PlayerDropdown:SetValues(getPlayerList()) end })
PlayerTab:Toggle({ 
    Title = "View Player", 
    Value = false, 
    Callback = function(state)
        local target = nil
        for _, p in pairs(Players:GetPlayers()) do if p.DisplayName == selectedPlayerName then target = p break end end
        Camera.CameraSubject = (state and target and target.Character) and target.Character.Humanoid or LocalPlayer.Character.Humanoid
    end
})
PlayerTab:Button({ Title = "Teleport", Callback = function()
    for _, p in pairs(Players:GetPlayers()) do if p.DisplayName == selectedPlayerName and p.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3) end end
end})

local ThemeTab = Window:Tab({ Title = "Settings", Icon = "settings" })
ThemeTab:Section({ Title = "Configurations" })

-- [[ ปุ่ม Save/Load Config ]]
ThemeTab:Button({
    Title = "Save Config",
    Callback = function()
        myConfig:Save()
        WindUI:Notify({Title = "Config", Content = "Saved Successfully!"})
    end
})
ThemeTab:Button({
    Title = "Load Config",
    Callback = function()
        myConfig:Load()
        WindUI:Notify({Title = "Config", Content = "Loaded Successfully!"})
    end
})

ThemeTab:Section({ Title = "UI Customization" })
ThemeTab:Dropdown({
    Title  = "Theme",
    Values = (function()
        local names = {}
        for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end
        table.sort(names)
        return names
    end)(),
    Value    = "Midnight",
    Callback = function(selected) WindUI:SetTheme(selected) end,
})
ThemeTab:Toggle({ Title = "Acrylic", Value = true, Callback = function() WindUI:ToggleAcrylic(not WindUI.Window.Acrylic) end })
ThemeTab:Toggle({ Title = "Transparent", Value = true, Callback = function(state) Window:ToggleTransparency(state) end })
ThemeTab:Keybind({ Title = "Toggle UI Key", Value = Enum.KeyCode.RightShift, Callback = function(v) Window:SetToggleKey(v) end })

-- === 4. Core Logic ===
RunService.Stepped:Connect(function()
    if fullbrightEnabled then
        Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.GlobalShadows = false
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local char = p.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                if hitboxEnabled and hum.Health > 0 then
                    hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                    hrp.Shape = Enum.PartType.Ball; hrp.Transparency = hitboxTransparency; hrp.Color = hitboxColor; hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1); hrp.Shape = Enum.PartType.Block; hrp.Transparency = 1
                end
            end
        end
    end

    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local myHum = LocalPlayer.Character.Humanoid
        if walkSpeedEnabled then myHum.WalkSpeed = walkSpeedValue end
        if jumpPowerEnabled then myHum.UseJumpPower = true; myHum.JumpPower = jumpPowerValue end
        if noclipEnabled then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState("Jumping")
    end
end)

for _, p in pairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(applyESP)

-- Auto Load เมื่อรันสคริปต์
myConfig:Load()
WindUI:Notify({ Title = "Static Hub", Content = "System Ready & Config Loaded!" })

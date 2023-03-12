getgenv().SlamWare = {
    SilentAim = {
        Key = "",
        Enabled = false,
        Prediction = 0.119,
        AimingType = "Default", -- ClosestPart, Default
        AimPart = "HumanoidRootPart",
        
        ChanceData = {UseChance = false, Chance = 100},
        FOVData = {Radius = 80, Visibility = false, Filled = false},

        AimingData = {CheckKnocked = false, CheckGrabbed = false,
        CheckWalls = false},

    },
    Tracing = {
        Key = 'Q',
        Enabled = true,
        Prediction = 8,
        AimPart = "HumanoidRootPart",
        TracingOptions = {Strength = "Hard", AimingType = "Default",  Smoothness = 0.11} 
                            -- Hard, Soft
    }
}

local Ordium = {functions = {}}

local Vector2New, Cam, Mouse, client, find, Draw, Inset, players, RunService, UIS=
    Vector2.new,
    workspace.CurrentCamera,
    game.Players.LocalPlayer:GetMouse(),
    game.Players.LocalPlayer,
    table.find,
    Drawing.new,
    game:GetService("GuiService"):GetGuiInset().Y,
    game.Players, 
    game.RunService,
    game:GetService("UserInputService")


local mf, rnew = math.floor, Random.new

local Targetting
local lockedCamTo

local Circle = Draw("Circle")
Circle.Thickness = 1
Circle.Transparency = 0.7
Circle.Color = Color3.new(1,1,1)

Ordium.functions.update_FOVs = function ()
    if not (Circle) then
        return Circle
    end
    Circle.Radius =  getgenv().SlamWare.SilentAim.FOVData.Radius * 3
    Circle.Visible = getgenv().SlamWare.SilentAim.FOVData.Visibility
    Circle.Filled = getgenv().SlamWare.SilentAim.FOVData.Filled
    Circle.Position = Vector2New(Mouse.X, Mouse.Y + (Inset))
    return Circle
end

Ordium.functions.onKeyPress = function(inputObject)
    if inputObject.KeyCode == Enum.KeyCode[getgenv().SlamWare.SilentAim.Key:upper()] then
        getgenv().SlamWare.SilentAim.Enabled = not getgenv().SlamWare.SilentAim.Enabled
    end

    if inputObject.KeyCode == Enum.KeyCode[getgenv().SlamWare.Tracing.Key:upper()] then
        getgenv().SlamWare.Tracing.Enabled = not getgenv().SlamWare.Tracing.Enabled
        if getgenv().SlamWare.Tracing.Enabled then
            lockedCamTo = Ordium.functions.returnClosestPlayer(getgenv().SlamWare.SilentAim.ChanceData.Chance)
        end
    end
end

UIS.InputBegan:Connect(Ordium.functions.onKeyPress)


Ordium.functions.wallCheck = function(direction, ignoreList)
    if not getgenv().SlamWare.SilentAim.AimingData.CheckWalls then
        return true
    end

    local ray = Ray.new(Cam.CFrame.p, direction - Cam.CFrame.p)
    local part, _, _ = game:GetService("Workspace"):FindPartOnRayWithIgnoreList(ray, ignoreList)

    return not part
end

Ordium.functions.pointDistance = function(part)
    local OnScreen = Cam.WorldToScreenPoint(Cam, part.Position)
    if OnScreen then
        return (Vector2New(OnScreen.X, OnScreen.Y) - Vector2New(Mouse.X, Mouse.Y)).Magnitude
    end
end

Ordium.functions.returnClosestPart = function(Character)
    local data = {
        dist = math.huge,
        part = nil,
        filteredparts = {},
        classes = {"Part", "BasePart", "MeshPart"}
    }

    if not (Character and Character:IsA("Model")) then
        return data.part
    end
    local children = Character:GetChildren()
    for _, child in pairs(children) do
        if table.find(data.classes, child.ClassName) then
            table.insert(data.filteredparts, child)
            for _, part in pairs(data.filteredparts) do
                local dist = Ordium.functions.pointDistance(part)
                if Circle.Radius > dist and dist < data.dist then
                    data.part = part
                    data.dist = dist
                end
            end
        end
    end
    return data.part
end

Ordium.functions.returnClosestPlayer = function (amount)
    local data = {
        dist = 1/0,
        player = nil
    }

    amount = amount or nil

    for _, player in pairs(players:GetPlayers()) do
        if (player.Character and player ~= client) then
            local dist = Ordium.functions.pointDistance(player.Character.HumanoidRootPart)
            if Circle.Radius > dist and dist < data.dist and 
            Ordium.functions.wallCheck(player.Character.Head.Position,{client, player.Character}) then
                data.dist = dist
                data.player = player
            end
        end
    end
    local calc = mf(rnew().NextNumber(rnew(), 0, 1) * 100) / 100
    local use = getgenv().SlamWare.SilentAim.ChanceData.UseChance
    if use and calc <= mf(amount) / 100 then
        return calc and data.player
    else
        return data.player
    end
end

Ordium.functions.setAimingType = function (player, type)
    local previousSilentAimPart = getgenv().SlamWare.SilentAim.AimPart
    local previousTracingPart = getgenv().SlamWare.Tracing.AimPart
    if type == "ClosestPart" then
        getgenv().SlamWare.SilentAim.AimPart = tostring(Ordium.functions.returnClosestPart(player.Character))
        getgenv().SlamWare.Tracing.AimPart = tostring(Ordium.functions.returnClosestPart(player.Character))
    elseif type == "Closest Point" then
        Ordium.functions.returnClosestPoint()
    elseif type == "Default" then
        getgenv().SlamWare.SilentAim.AimPart = previousSilentAimPart
        getgenv().SlamWare.Tracing.AimPart = previousTracingPart
    else
        getgenv().SlamWare.SilentAim.AimPart = previousSilentAimPart
        getgenv().SlamWare.Tracing.AimPart = previousTracingPart
    end
end

Ordium.functions.aimingCheck = function (player)
    if getgenv().SlamWare.SilentAim.AimingData.CheckKnocked == true and player and player.Character then
        if player.Character.BodyEffects["K.O"].Value then
            return true
        end
    end
    if getgenv().SlamWare.SilentAim.AimingData.CheckGrabbed == true and player and player.Character then
        if player.Character:FindFirstChild("GRABBING_CONSTRAINT") then
            return true
        end
    end
    return false
end


local lastRender = 0
local interpolation = 0.01

RunService.RenderStepped:Connect(function(delta)
    local valueTypes = 1.375
    lastRender = lastRender + delta
    while lastRender > interpolation do
        lastRender = lastRender - interpolation
    end
    if getgenv().SlamWare.Tracing.Enabled and lockedCamTo ~= nil and getgenv().SlamWare.Tracing.TracingOptions.Strength == "Hard" then
        local Vel =  lockedCamTo.Character[getgenv().SlamWare.Tracing.AimPart].Velocity / (getgenv().SlamWare.Tracing.Prediction * valueTypes)
        local Main = CFrame.new(Cam.CFrame.p, lockedCamTo.Character[getgenv().SlamWare.Tracing.AimPart].Position + (Vel))
        Cam.CFrame = Cam.CFrame:Lerp(Main ,getgenv().SlamWare.Tracing.TracingOptions.Smoothness , Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        Ordium.functions.setAimingType(lockedCamTo, getgenv().SlamWare.Tracing.TracingOptions.AimingType)
    elseif getgenv().SlamWare.Tracing.Enabled and lockedCamTo ~= nil and getgenv().SlamWare.Tracing.TracingOptions.Strength == "Soft" then
        local Vel =  lockedCamTo.Character[getgenv().SlamWare.Tracing.AimPart].Velocity / (getgenv().SlamWare.Tracing.Prediction / valueTypes)
        local Main = CFrame.new(Cam.CFrame.p, lockedCamTo.Character[getgenv().SlamWare.Tracing.AimPart].Position + (Vel))
        Cam.CFrame = Cam.CFrame:Lerp(Main ,getgenv().SlamWare.Tracing.TracingOptions.Smoothness , Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        Ordium.functions.setAimingType(lockedCamTo, getgenv().SlamWare.Tracing.TracingOptions.AimingType)
    else

    end
end)

task.spawn(function ()
    while task.wait() do
        if Targetting then
            Ordium.functions.setAimingType(Targetting, getgenv().SlamWare.SilentAim.AimingType)
        end
        Ordium.functions.update_FOVs()
    end
end)


local __index
__index = hookmetamethod(game,"__index", function(Obj, Property)
    if Obj:IsA("Mouse") and Property == "Hit" then
        Targetting = Ordium.functions.returnClosestPlayer(getgenv().SlamWare.SilentAim.ChanceData.Chance)
        if Targetting ~= nil and getgenv().SlamWare.SilentAim.Enabled and not Ordium.functions.aimingCheck(Targetting) then
            local currentvelocity = Targetting.Character[getgenv().SlamWare.SilentAim.AimPart].Velocity
            local currentposition = Targetting.Character[getgenv().SlamWare.SilentAim.AimPart].CFrame

            return currentposition + (currentvelocity * getgenv().SlamWare.SilentAim.Prediction)
        end
    end
    return __index(Obj, Property)
end)

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/vozoid/ui-libraries/main/drawing/void/source.lua"))()

local watermark = library:Watermark("SlamWare Prviate")


local main = library:Load{
    Name = "SlamWare Private",
    SizeX = 530,
    SizeY = 650,
    Theme = "Default",
    Extension = "json", -- config file extension
    Folder = "vozoid ui or something" -- config folder name
}

local tab = main:Tab("Main")

local section = tab:Section{
    Name = "Silent Aim",
    Side = "Left"
}

local cam = tab:Section{
    Name = "Camlock",
    Side = "Right"
}

local toggle = section:Toggle{
    Name = "Enable",
    Flag = "Toggleeqe 1",
    Default = false,
    Callback  = function(bool)
     getgenv().SlamWare.SilentAim.Enabled = bool
    end
}


local box = section:Box{
    Name = "Prediction",
    --Default = "hi",
    Placeholder = "Enter Prediction",
    Flag = "predictionm21",
    Callback = function(text)
       getgenv().SlamWare.SilentAim.Prediction = text
    end
}

local dropdown = section:Dropdown{
 Name = "Aim Part",
    Default = "HumanoidRootPart",
    Content = {
        "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "LeftFoot", "LeftLowerLeg",  "LeftUpperLeg", "RightLowerLeg", "RightFoot",  "RightUpperLeg"
       
    },
 
    Flag = "qeq",
    Callback = function(option)
      getgenv().SlamWare.SilentAim.AimPart = option
    end
}


local dropdown = section:Dropdown{
 Name = "Aim Type",
    Default = "Default",
    Content = {
        "Default",
        "ClosestPart"
       
    },
 
    Flag = "eeceeeee",
    Callback = function(option)
         getgenv().SlamWare.SilentAim.AimingType = option
    end
}

local toggle3 = section:Toggle{
    Name = "Use Hitchance",
    Flag = "Tseomeshit",
  
    Callback  = function(bool)
      getgenv().SlamWare.SilentAim.ChanceData.UseChance = bool
    end
}

local box = section:Box{
    Name = "Hit Chance",
    --Default = "hi",
    Placeholder = "Enter Hitchance",
    Flag = "hitachacne",
    Callback = function(text)
         getgenv().SlamWare.SilentAim.ChanceData.Chance = text
    end
}
local seperator = section:Separator("FOV Settings")
local toggle3 = section:Toggle{
    Name = "Show FOV",
    Flag = "Dontruindontrtrip",
  
    Callback  = function(bool)
      getgenv().SlamWare.SilentAim.FOVData.Visibility = bool
    end
}

local toggle3 = section:Toggle{
    Name = "Filled FOV",
    Flag = "dontrudnsrtopdtriop",
  
    Callback  = function(bool)
  getgenv().SlamWare.SilentAim.FOVData.Filled = bool
    end
}

local box = section:Box{
    Name = "FOV Size",
    --Default = "hi",
    Placeholder = "Enter FOV Size",
    Flag = "sizeoffov",
    Callback = function(text)
       getgenv().SlamWare.SilentAim.FOVData.Radius = text
    end
}
local seperator = section:Separator("Checks")
local toggle3 = section:Toggle{
    Name = "Knocked Check",
    Flag = "Dontruidndontrtriwqdqwp",
  
    Callback  = function(bool)
      getgenv().SlamWare.SilentAim.AimingData.CheckKnocked = bool
    end
}

local toggle3 = section:Toggle{
    Name = "Grabbed Check",
    Flag = "Donqqqtruindontrtrip",
  
    Callback  = function(bool)
       getgenv().SlamWare.SilentAim.AimingData.CheckGrabbed = bool
    end
}

local toggle3 = section:Toggle{
    Name = "Wall Check",
    Flag = "Dontrqdqwwqdwqdwqduindontrtrip",
  
    Callback  = function(bool)
       getgenv().SlamWare.SilentAim.AimingData.CheckWalls = bool
    end
}

local toggle = cam:Toggle{
    Name = "Enable",
    Flag = "Twwwoggle 1",

    Callback  = function(bool)
        getgenv().SlamWare.Tracing.Enabled = bool
    end
}

local keybind = cam:Keybind{
 Name = "Aiming Keybind",
    Default = "Q",
    Blacklist = {Enum.UserInputType.MouseButton1},
    Flag = "Togguuile 2 Keybind 1",
    Mode = "nil", -- mode to nil if u dont want it to toggle the toggle
    Callback = function(key)
      getgenv().SlamWare.Tracing.Key = key
    end
}


local dropdown = cam:Dropdown{
 Name = "AimPart",
    Default = "HumanoidRootPart",
    Content = {
        "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "LeftHand", "RightHand", "LeftLowerArm", "RightLowerArm", "LeftUpperArm", "RightUpperArm", "LeftFoot", "LeftLowerLeg",  "LeftUpperLeg", "RightLowerLeg", "RightFoot",  "RightUpperLeg"
       
    },
 
    Flag = "eeeeqdeee",
    Callback = function(option)
         getgenv().SlamWare.Tracing.AimPart = option
    end
}

local dropdown = cam:Dropdown{
 Name = "AimType",
    Default = "Default",
    Content = {
        "Default",
        "ClosestPart"
       
    },
 
    Flag = "eeeeeyyyytu6ee",
    Callback = function(option)
        getgenv().SlamWare.Tracing.TracingOptions.AimingType = bool
    end
}

local box = cam:Box{
    Name = "Smoothness",
    --Default = "hi",
    Placeholder = "Enter Smoothness",
    Flag = "Boxwqwed 1",
    Callback = function(text)
        getgenv().SlamWare.Tracing.TracingOptions.Smoothness = text
    end
}


local dropdown = cam:Dropdown{
 Name = "Strength Type",
    Default = "Hard",
    Content = {
        "Hard",
        "Soft"
       
    },
 
    Flag = "eeeeyeee",
    Callback = function(option)
         getgenv().SlamWare.Tracing.TracingOptions.Strength = option
    end
}

local configs = main:Tab("Configuration")

local themes = configs:Section{Name = "Theme", Side = "Left"}

local themepickers = {}

local themelist = themes:Dropdown{
    Name = "Theme",
    Default = library.currenttheme,
    Content = library:GetThemes(),
    Flag = "Theme Dropdown",
    Callback = function(option)
        if option then
            library:SetTheme(option)

            for option, picker in next, themepickers do
                picker:Set(library.theme[option])
            end
        end
    end
}



library:ConfigIgnore("Theme Dropdown")

local namebox = themes:Box{
    Name = "Custom Theme Name",
    Placeholder = "Custom Theme",
    Flag = "Custom Theme"
}

library:ConfigIgnore("Custom Theme")

themes:Button{
    Name = "Save Custom Theme",
    Callback = function()
        if library:SaveCustomTheme(library.flags["Custom Theme"]) then
            themelist:Refresh(library:GetThemes())
            themelist:Set(library.flags["Custom Theme"])
            namebox:Set("")
        end
    end
}

local customtheme = configs:Section{Name = "Custom Theme", Side = "Right"}

themepickers["Accent"] = customtheme:ColorPicker{
    Name = "Accent",
    Default = library.theme["Accent"],
    Flag = "Accent",
    Callback = function(color)
        library:ChangeThemeOption("Accent", color)
    end
}

library:ConfigIgnore("Accent")

themepickers["Window Background"] = customtheme:ColorPicker{
    Name = "Window Background",
    Default = library.theme["Window Background"],
    Flag = "Window Background",
    Callback = function(color)
        library:ChangeThemeOption("Window Background", color)
    end
}

library:ConfigIgnore("Window Background")

themepickers["Window Border"] = customtheme:ColorPicker{
    Name = "Window Border",
    Default = library.theme["Window Border"],
    Flag = "Window Border",
    Callback = function(color)
        library:ChangeThemeOption("Window Border", color)
    end
}

library:ConfigIgnore("Window Border")

themepickers["Tab Background"] = customtheme:ColorPicker{
    Name = "Tab Background",
    Default = library.theme["Tab Background"],
    Flag = "Tab Background",
    Callback = function(color)
        library:ChangeThemeOption("Tab Background", color)
    end
}

library:ConfigIgnore("Tab Background")

themepickers["Tab Border"] = customtheme:ColorPicker{
    Name = "Tab Border",
    Default = library.theme["Tab Border"],
    Flag = "Tab Border",
    Callback = function(color)
        library:ChangeThemeOption("Tab Border", color)
    end
}

library:ConfigIgnore("Tab Border")

themepickers["Tab Toggle Background"] = customtheme:ColorPicker{
    Name = "Tab Toggle Background",
    Default = library.theme["Tab Toggle Background"],
    Flag = "Tab Toggle Background",
    Callback = function(color)
        library:ChangeThemeOption("Tab Toggle Background", color)
    end
}

library:ConfigIgnore("Tab Toggle Background")

themepickers["Section Background"] = customtheme:ColorPicker{
    Name = "Section Background",
    Default = library.theme["Section Background"],
    Flag = "Section Background",
    Callback = function(color)
        library:ChangeThemeOption("Section Background", color)
    end
}

library:ConfigIgnore("Section Background")

themepickers["Section Border"] = customtheme:ColorPicker{
    Name = "Section Border",
    Default = library.theme["Section Border"],
    Flag = "Section Border",
    Callback = function(color)
        library:ChangeThemeOption("Section Border", color)
    end
}

library:ConfigIgnore("Section Border")

themepickers["Text"] = customtheme:ColorPicker{
    Name = "Text",
    Default = library.theme["Text"],
    Flag = "Text",
    Callback = function(color)
        library:ChangeThemeOption("Text", color)
    end
}

library:ConfigIgnore("Text")

themepickers["Disabled Text"] = customtheme:ColorPicker{
    Name = "Disabled Text",
    Default = library.theme["Disabled Text"],
    Flag = "Disabled Text",
    Callback = function(color)
        library:ChangeThemeOption("Disabled Text", color)
    end
}

library:ConfigIgnore("Disabled Text")

themepickers["Object Background"] = customtheme:ColorPicker{
    Name = "Object Background",
    Default = library.theme["Object Background"],
    Flag = "Object Background",
    Callback = function(color)
        library:ChangeThemeOption("Object Background", color)
    end
}

library:ConfigIgnore("Object Background")

themepickers["Object Border"] = customtheme:ColorPicker{
    Name = "Object Border",
    Default = library.theme["Object Border"],
    Flag = "Object Border",
    Callback = function(color)
        library:ChangeThemeOption("Object Border", color)
    end
}

library:ConfigIgnore("Object Border")

themepickers["Dropdown Option Background"] = customtheme:ColorPicker{
    Name = "Dropdown Option Background",
    Default = library.theme["Dropdown Option Background"],
    Flag = "Dropdown Option Background",
    Callback = function(color)
        library:ChangeThemeOption("Dropdown Option Background", color)
    end
}

library:ConfigIgnore("Dropdown Option Background")

local configsection = configs:Section{Name = "Configs", Side = "Left"}

local configlist = configsection:Dropdown{
    Name = "Configs",
    Content = library:GetConfigs(), -- GetConfigs(true) if you want universal configs
    Flag = "Config Dropdown"
}

library:ConfigIgnore("Config Dropdown")

local loadconfig = configsection:Button{
    Name = "Load Config",
    Callback = function()
        library:LoadConfig(library.flags["Config Dropdown"]) -- LoadConfig(library.flags["Config Dropdown"], true)  if you want universal configs
    end
}

local delconfig = configsection:Button{
    Name = "Delete Config",
    Callback = function()
        library:DeleteConfig(library.flags["Config Dropdown"]) -- DeleteConfig(library.flags["Config Dropdown"], true)  if you want universal configs
        configlist:Refresh(library:GetConfigs())
    end
}


local configbox = configsection:Box{
    Name = "Config Name",
    Placeholder = "Config Name",
    Flag = "Config Name"
}

library:ConfigIgnore("Config Name")

local save = configsection:Button{
    Name = "Save Config",
    Callback = function()
        library:SaveConfig(library.flags["Config Dropdown"] or library.flags["Config Name"]) -- SaveConfig(library.flags["Config Name"], true) if you want universal configs
        configlist:Refresh(library:GetConfigs())
    end
}

local keybindsection = configs:Section{Name = "UI Toggle Keybind", Side = "Left"}

keybindsection:Keybind{
    Name = "UI Toggle",
    Flag = "UI Toggle",
    Default = Enum.KeyCode.RightShift,
    Blacklist = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3},
    Callback = function(_, fromsetting)
        if not fromsetting then
            library:Close()
        end
    end
}

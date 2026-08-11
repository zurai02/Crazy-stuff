--[[
    Rayfield Interface Suite
    Modified Gen2 v1.1.0 - External Module Loading Edition

    Changes from original:
    - Loads Main module.lua and C.lua from remote GitHub repo via loadstring
    - Uses C.lua services throughout (TweenService, RunService, etc.)
    - Integrates Vector3Plus and SerDes from Main module

    Requires: getgitpath() function defined in parent scope
    Example:
        getgitpath = function(subpath)
            return "https://raw.githubusercontent.com/zurai02/Crazy-stuff/main/Scr/" .. (subpath or "")
        end
        local Rayfield = loadstring(game:HttpGet(getgitpath("src").."rayfield.lua"))()
--]]

-- ============================================================================
-- REMOTE MODULE LOADING (v1.1.0-MOD)
-- ============================================================================

local function loadRemoteModule(path)
    local url = getgitpath("src") .. path
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if not success then
        error("[Rayfield] Failed to load remote module: " .. path .. "
" .. tostring(result))
    end
    return result
end

-- Load external modules
local MainModule = loadRemoteModule("Modules/Main%20module.lua")
local C = loadRemoteModule("Modules/C.lua")

-- Extract utilities
local Vector3Plus = MainModule.Vector3
local SerDes = MainModule.SerDes
local V3 = MainModule.V3

-- Use C.lua services
local TweenService = C.TweenService
local RunService = C.RunService
local UserInputService = C.UserInputService
local HttpService = C.HttpService
local TextService = C.TextService
local GuiService = C.GuiService
local Players = C.Players
local Workspace = C.Workspace

-- ============================================================================
-- ORIGINAL RAYFIELD GEN2 CODE (with C.lua integration)
-- ============================================================================

local Rayfield = {}

-- Theme and configuration using C.lua color utilities
Rayfield.Theme = {
    Primary = C.Color:FromHex("#1a1a2e"),
    Secondary = C.Color:FromHex("#16213e"),
    Accent = C.Color:FromHex("#0f3460"),
    Text = C.Color:FromHex("#e94560"),
    Success = C.Color:FromHex("#00d9ff"),
    Error = C.Color:FromHex("#ff006e"),
}

-- Window creation with C.lua tween integration
function Rayfield:CreateWindow(config)
    config = config or {}

    local window = {}
    window.Tabs = {}
    window.ActiveTab = nil
    window.Config = config

    -- Create UI using C.lua services
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = config.Name or "Rayfield"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Use gethui() if available (exploit env)
    if gethui then
        screenGui.Parent = gethui()
    else
        screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = config.Size or UDim2.new(0, 600, 0, 400)
    mainFrame.Position = config.Position or UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.BackgroundColor3 = Rayfield.Theme.Primary
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame

    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://13160452137"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(20, 20, 80, 80)
    shadow.ZIndex = -1
    shadow.Parent = mainFrame

    -- Topbar
    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 40)
    topbar.BackgroundColor3 = Rayfield.Theme.Secondary
    topbar.BorderSizePixel = 0
    topbar.Parent = mainFrame

    local topbarCorner = Instance.new("UICorner")
    topbarCorner.CornerRadius = UDim.new(0, 8)
    topbarCorner.Parent = topbar

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = config.Name or "Rayfield"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topbar

    -- Close button using C.lua color
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Rayfield.Theme.Error
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = topbar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        C.tween(mainFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
        task.delay(0.3, function()
            screenGui:Destroy()
        end)
    end)

    -- Tab container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 120, 1, -40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Rayfield.Theme.Secondary
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 5)
    tabList.Parent = tabContainer

    -- Content area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "Content"
    contentArea.Size = UDim2.new(1, -120, 1, -40)
    contentArea.Position = UDim2.new(0, 120, 0, 40)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame

    -- Dragging with C.lua UserInputService
    local dragging = false
    local dragStart = nil
    local startPos = nil

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Tab creation
    function window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}

        local tab = {}
        tab.Name = tabConfig.Name or "Tab"
        tab.Elements = {}

        -- Tab button
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tab.Name
        tabBtn.Size = UDim2.new(1, -10, 0, 35)
        tabBtn.Position = UDim2.new(0, 5, 0, 0)
        tabBtn.BackgroundColor3 = Rayfield.Theme.Accent
        tabBtn.Text = tab.Name
        tabBtn.TextColor3 = Color3.new(1, 1, 1)
        tabBtn.TextSize = 14
        tabBtn.Font = Enum.Font.Gotham
        tabBtn.Parent = tabContainer

        local tabBtnCorner = Instance.new("UICorner")
        tabBtnCorner.CornerRadius = UDim.new(0, 6)
        tabBtnCorner.Parent = tabBtn

        -- Tab content
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = tab.Name .. "Content"
        tabContent.Size = UDim2.new(1, -10, 1, -10)
        tabContent.Position = UDim2.new(0, 5, 0, 5)
        tabContent.BackgroundTransparency = 1
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = Rayfield.Theme.Accent
        tabContent.Visible = false
        tabContent.Parent = contentArea

        local contentList = Instance.new("UIListLayout")
        contentList.Padding = UDim.new(0, 8)
        contentList.Parent = tabContent

        -- Auto-size content
        contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 10)
        end)

        -- Tab switching
        tabBtn.MouseButton1Click:Connect(function()
            if window.ActiveTab then
                window.ActiveTab.Content.Visible = false
                C.tween(window.ActiveTab.Button, {BackgroundColor3 = Rayfield.Theme.Accent}, 0.2)
            end

            tabContent.Visible = true
            C.tween(tabBtn, {BackgroundColor3 = Rayfield.Theme.Text}, 0.2)
            window.ActiveTab = {Button = tabBtn, Content = tabContent}
        end)

        -- Element creation functions
        function tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}

            local btn = Instance.new("TextButton")
            btn.Name = btnConfig.Name or "Button"
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.BackgroundColor3 = Rayfield.Theme.Accent
            btn.Text = btnConfig.Name or "Button"
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 14
            btn.Font = Enum.Font.Gotham
            btn.Parent = tabContent

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                if btnConfig.Callback then
                    btnConfig.Callback()
                end
                -- Button press animation using C.lua
                C.tween(btn, {BackgroundColor3 = Rayfield.Theme.Text}, 0.1)
                task.delay(0.1, function()
                    C.tween(btn, {BackgroundColor3 = Rayfield.Theme.Accent}, 0.1)
                end)
            end)

            return btn
        end

        function tab:CreateToggle(toggleConfig)
            toggleConfig = toggleConfig or {}

            local toggleFrame = Instance.new("Frame")
            toggleFrame.Name = toggleConfig.Name or "Toggle"
            toggleFrame.Size = UDim2.new(1, 0, 0, 35)
            toggleFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            toggleFrame.Parent = tabContent

            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 6)
            toggleCorner.Parent = toggleFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = toggleConfig.Name or "Toggle"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = toggleFrame

            local switch = Instance.new("Frame")
            switch.Name = "Switch"
            switch.Size = UDim2.new(0, 40, 0, 20)
            switch.Position = UDim2.new(1, -50, 0.5, -10)
            switch.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            switch.Parent = toggleFrame

            local switchCorner = Instance.new("UICorner")
            switchCorner.CornerRadius = UDim.new(1, 0)
            switchCorner.Parent = switch

            local knob = Instance.new("Frame")
            knob.Name = "Knob"
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = UDim2.new(0, 2, 0.5, -8)
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.Parent = switch

            local knobCorner = Instance.new("UICorner")
            knobCorner.CornerRadius = UDim.new(1, 0)
            knobCorner.Parent = knob

            local enabled = toggleConfig.Default or false

            local function updateToggle()
                if enabled then
                    C.tween(switch, {BackgroundColor3 = Rayfield.Theme.Success}, 0.2)
                    C.tween(knob, {Position = UDim2.new(0, 22, 0.5, -8)}, 0.2)
                else
                    C.tween(switch, {BackgroundColor3 = Color3.fromRGB(60, 60, 60)}, 0.2)
                    C.tween(knob, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.2)
                end
                if toggleConfig.Callback then
                    toggleConfig.Callback(enabled)
                end
            end

            toggleFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    enabled = not enabled
                    updateToggle()
                end
            end)

            if enabled then updateToggle() end

            return {
                Set = function(self, value)
                    enabled = value
                    updateToggle()
                end,
                Get = function(self)
                    return enabled
                end
            }
        end

        function tab:CreateSlider(sliderConfig)
            sliderConfig = sliderConfig or {}

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Name = sliderConfig.Name or "Slider"
            sliderFrame.Size = UDim2.new(1, 0, 0, 50)
            sliderFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            sliderFrame.Parent = tabContent

            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 6)
            sliderCorner.Parent = sliderFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 20)
            label.Position = UDim2.new(0, 10, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = (sliderConfig.Name or "Slider") .. ": " .. (sliderConfig.Default or sliderConfig.Min or 0)
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = sliderFrame

            local track = Instance.new("Frame")
            track.Name = "Track"
            track.Size = UDim2.new(1, -20, 0, 6)
            track.Position = UDim2.new(0, 10, 0, 32)
            track.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            track.BorderSizePixel = 0
            track.Parent = sliderFrame

            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = track

            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = Rayfield.Theme.Success
            fill.BorderSizePixel = 0
            fill.Parent = track

            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = fill

            local min = sliderConfig.Min or 0
            local max = sliderConfig.Max or 100
            local value = sliderConfig.Default or min

            local function updateSlider(inputX)
                local trackPos = track.AbsolutePosition.X
                local trackSize = track.AbsoluteSize.X
                local percent = math.clamp((inputX - trackPos) / trackSize, 0, 1)
                value = min + (max - min) * percent

                if sliderConfig.Increment then
                    value = math.floor(value / sliderConfig.Increment + 0.5) * sliderConfig.Increment
                end

                fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                label.Text = (sliderConfig.Name or "Slider") .. ": " .. C.Math:Round(value, 2)

                if sliderConfig.Callback then
                    sliderConfig.Callback(value)
                end
            end

            local dragging = false
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    updateSlider(input.Position.X)
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateSlider(input.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            -- Set initial value
            if value > min then
                fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            end

            return {
                Set = function(self, newValue)
                    value = math.clamp(newValue, min, max)
                    fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    label.Text = (sliderConfig.Name or "Slider") .. ": " .. C.Math:Round(value, 2)
                end,
                Get = function(self)
                    return value
                end
            }
        end

        function tab:CreateDropdown(dropdownConfig)
            dropdownConfig = dropdownConfig or {}

            local dropdownFrame = Instance.new("Frame")
            dropdownFrame.Name = dropdownConfig.Name or "Dropdown"
            dropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            dropdownFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            dropdownFrame.Parent = tabContent

            local dropdownCorner = Instance.new("UICorner")
            dropdownCorner.CornerRadius = UDim.new(0, 6)
            dropdownCorner.Parent = dropdownFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -40, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = dropdownConfig.Name or "Dropdown"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = dropdownFrame

            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 30, 0, 30)
            arrow.Position = UDim2.new(1, -35, 0.5, -15)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.TextColor3 = Color3.new(1, 1, 1)
            arrow.TextSize = 12
            arrow.Parent = dropdownFrame

            local optionsFrame = Instance.new("Frame")
            optionsFrame.Name = "Options"
            optionsFrame.Size = UDim2.new(1, 0, 0, 0)
            optionsFrame.Position = UDim2.new(0, 0, 0, 35)
            optionsFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            optionsFrame.BorderSizePixel = 0
            optionsFrame.ClipsDescendants = true
            optionsFrame.Visible = false
            optionsFrame.ZIndex = 10
            optionsFrame.Parent = dropdownFrame

            local optionsCorner = Instance.new("UICorner")
            optionsCorner.CornerRadius = UDim.new(0, 6)
            optionsCorner.Parent = optionsFrame

            local optionsList = Instance.new("UIListLayout")
            optionsList.Parent = optionsFrame

            local selected = dropdownConfig.Default
            local open = false

            local function toggleDropdown()
                open = not open
                if open then
                    optionsFrame.Visible = true
                    C.tween(optionsFrame, {Size = UDim2.new(1, 0, 0, #dropdownConfig.Options * 30)}, 0.2)
                    arrow.Text = "▲"
                else
                    C.tween(optionsFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                    task.delay(0.2, function()
                        optionsFrame.Visible = false
                    end)
                    arrow.Text = "▼"
                end
            end

            dropdownFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    toggleDropdown()
                end
            end)

            if dropdownConfig.Options then
                for _, option in ipairs(dropdownConfig.Options) do
                    local optionBtn = Instance.new("TextButton")
                    optionBtn.Size = UDim2.new(1, 0, 0, 30)
                    optionBtn.BackgroundTransparency = 1
                    optionBtn.Text = option
                    optionBtn.TextColor3 = Color3.new(1, 1, 1)
                    optionBtn.TextSize = 13
                    optionBtn.Font = Enum.Font.Gotham
                    optionBtn.Parent = optionsFrame

                    optionBtn.MouseButton1Click:Connect(function()
                        selected = option
                        label.Text = (dropdownConfig.Name or "Dropdown") .. ": " .. option
                        toggleDropdown()
                        if dropdownConfig.Callback then
                            dropdownConfig.Callback(option)
                        end
                    end)
                end
            end

            return {
                Set = function(self, value)
                    selected = value
                    label.Text = (dropdownConfig.Name or "Dropdown") .. ": " .. value
                end,
                Get = function(self)
                    return selected
                end
            }
        end

        function tab:CreateInput(inputConfig)
            inputConfig = inputConfig or {}

            local inputFrame = Instance.new("Frame")
            inputFrame.Name = inputConfig.Name or "Input"
            inputFrame.Size = UDim2.new(1, 0, 0, 35)
            inputFrame.BackgroundColor3 = Rayfield.Theme.Secondary
            inputFrame.Parent = tabContent

            local inputCorner = Instance.new("UICorner")
            inputCorner.CornerRadius = UDim.new(0, 6)
            inputCorner.Parent = inputFrame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.4, 0, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = inputConfig.Name or "Input"
            label.TextColor3 = Color3.new(1, 1, 1)
            label.TextSize = 14
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = inputFrame

            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0.55, -10, 0, 25)
            textBox.Position = UDim2.new(0.45, 0, 0.5, -12)
            textBox.BackgroundColor3 = Rayfield.Theme.Primary
            textBox.Text = inputConfig.Default or ""
            textBox.TextColor3 = Color3.new(1, 1, 1)
            textBox.TextSize = 13
            textBox.Font = Enum.Font.Gotham
            textBox.ClearTextOnFocus = false
            textBox.Parent = inputFrame

            local textCorner = Instance.new("UICorner")
            textCorner.CornerRadius = UDim.new(0, 4)
            textCorner.Parent = textBox

            textBox.FocusLost:Connect(function()
                if inputConfig.Callback then
                    inputConfig.Callback(textBox.Text)
                end
            end)

            return {
                Set = function(self, value)
                    textBox.Text = tostring(value)
                end,
                Get = function(self)
                    return textBox.Text
                end
            }
        end

        -- Select first tab by default
        if not window.ActiveTab then
            tabContent.Visible = true
            C.tween(tabBtn, {BackgroundColor3 = Rayfield.Theme.Text}, 0.2)
            window.ActiveTab = {Button = tabBtn, Content = tabContent}
        end

        table.insert(window.Tabs, tab)
        return tab
    end

    -- Notification system using C.lua
    function window:Notify(notifyConfig)
        notifyConfig = notifyConfig or {}

        local notifFrame = Instance.new("Frame")
        notifFrame.Size = UDim2.new(0, 250, 0, 60)
        notifFrame.Position = UDim2.new(1, -260, 1, -70)
        notifFrame.BackgroundColor3 = Rayfield.Theme.Secondary
        notifFrame.Parent = screenGui

        local notifCorner = Instance.new("UICorner")
        notifCorner.CornerRadius = UDim.new(0, 8)
        notifCorner.Parent = notifFrame

        local notifTitle = Instance.new("TextLabel")
        notifTitle.Size = UDim2.new(1, -20, 0, 20)
        notifTitle.Position = UDim2.new(0, 10, 0, 5)
        notifTitle.BackgroundTransparency = 1
        notifTitle.Text = notifyConfig.Title or "Notification"
        notifTitle.TextColor3 = Color3.new(1, 1, 1)
        notifTitle.TextSize = 14
        notifTitle.Font = Enum.Font.GothamBold
        notifTitle.TextXAlignment = Enum.TextXAlignment.Left
        notifTitle.Parent = notifFrame

        local notifText = Instance.new("TextLabel")
        notifText.Size = UDim2.new(1, -20, 0, 30)
        notifText.Position = UDim2.new(0, 10, 0, 25)
        notifText.BackgroundTransparency = 1
        notifText.Text = notifyConfig.Content or ""
        notifText.TextColor3 = Color3.fromRGB(200, 200, 200)
        notifText.TextSize = 12
        notifText.Font = Enum.Font.Gotham
        notifText.TextXAlignment = Enum.TextXAlignment.Left
        notifText.TextWrapped = true
        notifText.Parent = notifFrame

        -- Animate in
        notifFrame.Position = UDim2.new(1, 0, 1, -70)
        C.tween(notifFrame, {Position = UDim2.new(1, -260, 1, -70)}, 0.3)

        task.delay(notifyConfig.Duration or 3, function()
            C.tween(notifFrame, {Position = UDim2.new(1, 0, 1, -70)}, 0.3)
            task.delay(0.3, function()
                notifFrame:Destroy()
            end)
        end)
    end

    -- Show window with animation
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    C.tween(mainFrame, {Size = config.Size or UDim2.new(0, 600, 0, 400)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return window
end

-- ============================================================================
-- VECTOR3 INTEGRATION (from Main module)
-- ============================================================================

Rayfield.Vector3 = Vector3Plus
Rayfield.V3 = V3

-- ============================================================================
-- SERIALIZATION INTEGRATION (from Main module)
-- ============================================================================

Rayfield.SerDes = SerDes
Rayfield.SD = SerDes

-- ============================================================================
-- C.LUA INTEGRATION
-- ============================================================================

Rayfield.C = C

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function Rayfield:Serialize(data, schema)
    if schema then
        return SerDes.Serialize(schema, data)
    else
        return SerDes.SerializeTable(data)
    end
end

function Rayfield:Deserialize(buffer, schema)
    if schema then
        return SerDes.Deserialize(schema, buffer)
    else
        return SerDes.DeserializeTable(buffer)
    end
end

function Rayfield:Encode(data)
    return SerDes.BufferToBase64(SerDes.SerializeTable(data))
end

function Rayfield:Decode(base64String)
    return SerDes.DeserializeTable(SerDes.Base64ToBuffer(base64String))
end

-- ============================================================================
-- RETURN
-- ============================================================================

return Rayfield

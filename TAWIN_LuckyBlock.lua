-- =========================================================================
--  TAWIN | Lucky Block Auto Farm (Full Standalone + Toggle UI Button)
--  มีปุ่ม ⚡ ลอยเปิด/ปิด UI + ตัด Japan ออก 100% + อัพบ้าน 1-120
-- =========================================================================
if not game:IsLoaded() then game.Loaded:Wait() end
task.wait(1)

local Players             = game:GetService("Players")
local TweenService        = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService    = game:GetService("UserInputService")
local CoreGui             = game:GetService("CoreGui")
local RunService          = game:GetService("RunService")
local LocalPlayer         = Players.LocalPlayer

local function GetRoot()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Anti-AFK (กันหลุด 20 นาที)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LocalPlayer.Idled:Connect(function()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Unknown, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Unknown, false, game)
    end)
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Tween บิน
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function TweenTo(targetCF, speed)
    local root = GetRoot()
    if not root then return end
    speed = speed or 80
    local dist = (root.Position - targetCF.Position).Magnitude
    local t    = math.clamp(dist / speed, 0.3, 4)
    local info = TweenInfo.new(t, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local tween = TweenService:Create(root, info, {CFrame = targetCF})
    tween:Play()
    tween.Completed:Wait()
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- ค้นหา Lucky Block (NEXT GENERATION & ALTERNATIVE)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local BLOCK_KEYS = {
    ["NEXT GENERATION"] = {"next generation", "next gen", "generation", "nextgeneration"},
    ["ALTERNATIVE"]     = {"alternative", "alternate", "alt"},
}

local function NameMatch(name, blockType)
    local nameLow = name:lower()

    -- แบน JAPAN 100% ไม่ให้เก็บเด็ดขาด
    if nameLow:find("japan", 1, true) then
        return false
    end

    local keys = BLOCK_KEYS[blockType]
    if not keys then return false end
    for _, key in ipairs(keys) do
        if nameLow:find(key, 1, true) then
            return true
        end
    end
    return false
end

local function FindBlocks(blockType)
    local results = {}
    local added = {}
    local slimes = workspace:FindFirstChild("Live") and workspace.Live:FindFirstChild("Slimes")
    if not slimes then return results end

    for _, obj in ipairs(slimes:GetDescendants()) do
        if NameMatch(obj.Name, blockType) then
            local part = nil
            if obj:IsA("BasePart") then
                part = obj
            elseif obj:IsA("Model") then
                part = obj:FindFirstChild("HumanoidRootPart")
                    or obj.PrimaryPart
                    or obj:FindFirstChildWhichIsA("BasePart")
            end

            if part and not added[part] then
                added[part] = true
                table.insert(results, part)
            end
        end
    end
    return results
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- เก็บกล่อง — ProximityPrompt
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function TriggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end

    local holdTime = prompt.HoldDuration or 0.5
    if holdTime <= 0 then holdTime = 0.5 end

    pcall(function()
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 9999
    end)

    if fireproximityprompt then
        pcall(fireproximityprompt, prompt, 0)
        pcall(fireproximityprompt, prompt, holdTime)
        pcall(fireproximityprompt, prompt)
    end

    pcall(function()
        prompt:InputHoldBegin()
        task.wait(holdTime + 0.1)
        prompt:InputHoldEnd()
    end)

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(holdTime + 0.1)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

local function CollectBox(targetPart)
    local root = GetRoot()
    if not root or not targetPart then return end

    local prompts = {}
    local blockModel = targetPart:IsA("Model") and targetPart or targetPart.Parent

    for _, obj in ipairs(targetPart:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then table.insert(prompts, obj) end
    end

    if blockModel and blockModel ~= workspace then
        for _, obj in ipairs(blockModel:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and not table.find(prompts, obj) then
                table.insert(prompts, obj)
            end
        end
    end

    if #prompts == 0 then
        local slimes = workspace:FindFirstChild("Live") and workspace.Live:FindFirstChild("Slimes")
        if slimes then
            for _, obj in ipairs(slimes:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    local pPart = obj.Parent and (obj.Parent:IsA("BasePart") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("BasePart"))
                    if pPart and (pPart.Position - targetPart.Position).Magnitude <= 10 then
                        table.insert(prompts, obj)
                    end
                end
            end
        end
    end

    if #prompts > 0 then
        for _, prompt in ipairs(prompts) do TriggerPrompt(prompt) end
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.6)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end)
    end
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- Helper Remote
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local function GetRemote(name)
    local ok, rem = pcall(function()
        return game:GetService("ReplicatedStorage").SharedModules.Network.Remotes:FindFirstChild(name)
    end)
    if ok and rem then return rem end

    for _, obj in ipairs(game:GetService("ReplicatedStorage"):GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and obj.Name == name then
            return obj
        end
    end
    return nil
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- โหลด FLUENT UI
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local Fluent = loadstring(game:HttpGet(
    "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
))()
local SaveManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"
))()
local InterfaceManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"
))()

local Window = Fluent:CreateWindow({
    Title       = "TAWIN | Lucky Block",
    SubTitle    = "workspace.Live.Slimes",
    TabWidth    = 160,
    Size        = UDim2.fromOffset(550, 440),
    Acrylic     = false,
    Theme       = "Dark",
    MinimizeKey = Enum.KeyCode.RightAlt
})

local Tabs = {
    Farm    = Window:AddTab({ Title = "Auto Farm", Icon = "repeat"   }),
    Upgrade = Window:AddTab({ Title = "Auto Base", Icon = "zap"      }),
    Scan    = Window:AddTab({ Title = "Scan",      Icon = "search"   }),
    Misc    = Window:AddTab({ Title = "Misc",      Icon = "settings" }),
}
local Options = Fluent.Options

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 🔘 ปุ่มลอยบนหน้าจอสำหรับคลิกเปิด/ปิด UI (ลากได้)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "TawinToggleGui"
pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(toggleGui)
        toggleGui.Parent = CoreGui
    elseif gethui then
        toggleGui.Parent = gethui()
    else
        toggleGui.Parent = CoreGui
    end
end)
if not toggleGui.Parent then toggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "ToggleButton"
toggleBtn.Parent = toggleGui
toggleBtn.Size = UDim2.new(0, 48, 0, 48)
toggleBtn.Position = UDim2.new(0, 20, 0.5, -24)
toggleBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
toggleBtn.Text = "⚡"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 22
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Active = true
toggleBtn.AutoButtonColor = true

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toggleBtn

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(0, 170, 255)
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = toggleBtn

-- ระบบลากปุ่ม (Drag)
local dragging, dragInput, dragStart, startPos
local function update(input)
    local delta = input.Position - dragStart
    toggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = toggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
toggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- กดปุ่มเพื่อย่อ / เปิด UI
toggleBtn.MouseButton1Click:Connect(function()
    Window:Minimize()
end)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB 1: AUTO FARM
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tabs.Farm:AddParagraph({
    Title   = "Auto Farm — Lucky Block",
    Content = "บินไปหากล่อง (Tween) -> กด E เก็บ -> วาร์ปกลับจุดเซฟทันที"
})

Tabs.Farm:AddDropdown("FarmBlockType", {
    Title    = "ประเภทกล่อง",
    Values   = {"NEXT GENERATION", "ALTERNATIVE", "ทุกประเภท"},
    Default  = 3,
    Callback = function() end
})

Tabs.Farm:AddSlider("FarmSpeed", {
    Title    = "ความเร็ว Tween (studs/s)",
    Min = 20, Max = 300, Default = 80, Rounding = 10,
    Callback = function() end
})

Tabs.Farm:AddSlider("FarmDelay", {
    Title    = "หน่วงเวลาหลังเก็บ (วินาที)",
    Min = 0.1, Max = 3, Default = 0.5, Rounding = 1,
    Callback = function() end
})

local myBaseCFrame = nil

Tabs.Farm:AddButton({
    Title       = "📍 บันทึกจุดบ้านปัจจุบัน (Set Base)",
    Description = "กดเพื่อบันทึกจุดที่ยืนอยู่ตอนนี้เป็นจุดส่งของ/บ้าน",
    Callback    = function()
        local root = GetRoot()
        if root then
            myBaseCFrame = root.CFrame
            Fluent:Notify({
                Title   = "📍 บันทึกจุดบ้านแล้ว",
                Content = string.format("พิกัด: %.0f, %.0f, %.0f", root.Position.X, root.Position.Y, root.Position.Z),
                Duration = 4
            })
        else
            Fluent:Notify({Title="❌", Content="ไม่พบตัวละคร", Duration=3})
        end
    end
})

local function ReturnToBase()
    local root = GetRoot()
    if not root then return end
    if myBaseCFrame then
        root.CFrame = myBaseCFrame
        task.wait(0.2)
    end
end

local farmRunning = false

Tabs.Farm:AddToggle("AutoFarm", {
    Title       = "เริ่ม Auto Farm",
    Description = "บินไปเก็บกล่อง -> วาร์ปกลับจุดเซฟทันที -> วนเก็บเรื่อยๆ",
    Default     = false,
    Callback    = function(val)
        farmRunning = val
        if not val then
            Fluent:Notify({Title="หยุด", Content="หยุด Auto Farm แล้ว", Duration=2})
            return
        end

        task.spawn(function()
            local root = GetRoot()
            if root and not myBaseCFrame then
                myBaseCFrame = root.CFrame
            end

            Fluent:Notify({
                Title   = "🚀 เริ่ม Auto Farm",
                Content = "บินเก็บกล่อง -> วาร์ปกลับจุดเซฟ -> วนเรื่อยๆ",
                Duration = 3
            })

            while farmRunning do
                local blockType = Options.FarmBlockType and Options.FarmBlockType.Value or "ทุกประเภท"
                local delay     = Options.FarmDelay and Options.FarmDelay.Value or 0.5
                local speed     = Options.FarmSpeed and Options.FarmSpeed.Value or 80
                local types     = blockType == "ทุกประเภท"
                    and {"NEXT GENERATION", "ALTERNATIVE"}
                    or  {blockType}

                local availableBlocks = {}
                for _, bt in ipairs(types) do
                    local blocks = FindBlocks(bt)
                    for _, b in ipairs(blocks) do
                        if b and b.Parent then
                            table.insert(availableBlocks, {type = bt, part = b})
                        end
                    end
                end

                local curRoot = GetRoot()
                if curRoot and #availableBlocks > 0 then
                    local nearestObj, nearDist = nil, math.huge
                    for _, item in ipairs(availableBlocks) do
                        if item.part and item.part.Parent then
                            local d = (curRoot.Position - item.part.Position).Magnitude
                            if d < nearDist then
                                nearestObj = item
                                nearDist = d
                            end
                        end
                    end

                    if nearestObj and nearestObj.part and nearestObj.part.Parent then
                        local targetPart = nearestObj.part
                        local targetCF = CFrame.new(targetPart.Position + Vector3.new(0, 1, 2), targetPart.Position)
                        TweenTo(targetCF, speed)
                        task.wait(0.2)

                        CollectBox(targetPart)
                        task.wait(delay)

                        ReturnToBase()

                        Fluent:Notify({
                            Title   = "🏠 วาร์ปกลับแล้ว",
                            Content = "เก็บ " .. nearestObj.type .. " สำเร็จ -> กำลังไปกล่องถัดไป",
                            Duration = 2
                        })
                    end
                else
                    task.wait(1)
                end

                task.wait(0.3)
            end
        end)
    end
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB 2: AUTO BASE / UPGRADES (1-120)
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tabs.Upgrade:AddParagraph({
    Title   = "Auto Base & Upgrades",
    Content = "ระบบฟาร์มฐานอัตโนมัติ (1-120 จุด ครอบคลุมทั้งบ้าน)"
})

local autoUpgradeSlimeRunning = false
local autoOpenRunning = false
local autoCashRunning = false
local autoJumpRunning = false
local autoRebirthRunning = false

Tabs.Upgrade:AddToggle("AutoUpgradeSlime", {
    Title       = "🆙 ออโต้อัพตัวละครในบ้าน (Upgrade Slime 1-120)",
    Description = "วนอัพเกรดตัวละครหมายเลข 1 ถึง 120 ในบ้านอัตโนมัติ",
    Default     = false,
    Callback    = function(val)
        autoUpgradeSlimeRunning = val
        if val then
            task.spawn(function()
                while autoUpgradeSlimeRunning do
                    local remote = GetRemote("Upgrade Slime")
                    if remote then
                        for i = 1, 120 do
                            if not autoUpgradeSlimeRunning then break end
                            pcall(function() remote:FireServer(tostring(i)) end)
                            task.wait(0.02)
                        end
                    end
                    task.wait(0.3)
                end
            end)
        end
    end
})

Tabs.Upgrade:AddToggle("AutoOpenLuckyBlock", {
    Title       = "📦 ออโต้เปิด Lucky Block (1-120)",
    Description = "วนเปิดกล่องหมายเลข 1 ถึง 120 ในบ้านอัตโนมัติ",
    Default     = false,
    Callback    = function(val)
        autoOpenRunning = val
        if val then
            task.spawn(function()
                while autoOpenRunning do
                    local remote = GetRemote("Open Lucky Block")
                    if remote then
                        for i = 1, 120 do
                            if not autoOpenRunning then break end
                            pcall(function() remote:FireServer(tostring(i)) end)
                            task.wait(0.02)
                        end
                    end
                    task.wait(0.3)
                end
            end)
        end
    end
})

Tabs.Upgrade:AddToggle("AutoCollectCash", {
    Title       = "💰 ออโต้เก็บเงิน (Collect Earnings 1-120)",
    Description = "วนเก็บเงินหมายเลข 1 ถึง 120 ในบ้านอัตโนมัติ",
    Default     = false,
    Callback    = function(val)
        autoCashRunning = val
        if val then
            task.spawn(function()
                while autoCashRunning do
                    local remote = GetRemote("Collect Earnings")
                    if remote then
                        for i = 1, 120 do
                            if not autoCashRunning then break end
                            pcall(function() remote:FireServer(tostring(i)) end)
                            task.wait(0.02)
                        end
                    end
                    task.wait(0.3)
                end
            end)
        end
    end
})

Tabs.Upgrade:AddSlider("JumpUpgradeAmount", {
    Title    = "จำนวนการอัพเกรดกระโดดต่อครั้ง",
    Min = 1, Max = 10, Default = 3, Rounding = 1,
    Callback = function() end
})

Tabs.Upgrade:AddToggle("AutoBuyJump", {
    Title       = "⬆️ ออโต้อัพการกระโดดสูง (Buy Speed/Jump Upgrade)",
    Description = "ซื้ออัพเกรดการกระโดดสูงอัตโนมัติ",
    Default     = false,
    Callback    = function(val)
        autoJumpRunning = val
        if val then
            task.spawn(function()
                while autoJumpRunning do
                    local amount = Options.JumpUpgradeAmount and Options.JumpUpgradeAmount.Value or 3
                    local remote = GetRemote("Buy Speed Upgrade")
                    if remote then pcall(function() remote:FireServer(amount) end) end
                    task.wait(0.5)
                end
            end)
        end
    end
})

Tabs.Upgrade:AddToggle("AutoRebirth", {
    Title       = "🔄 ออโต้รีเบิร์ธ (Auto Rebirth)",
    Description = "รีเบิร์ธอัตโนมัติเมื่อเงินและเลเวลพร้อม",
    Default     = false,
    Callback    = function(val)
        autoRebirthRunning = val
        if val then
            task.spawn(function()
                while autoRebirthRunning do
                    local remote = GetRemote("Rebirth")
                    if remote then pcall(function() remote:FireServer() end) end
                    task.wait(1)
                end
            end)
        end
    end
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- TAB 3: SCAN & MISC
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tabs.Scan:AddParagraph({
    Title   = "สแกน workspace.Live.Slimes",
    Content = "ใช้ดูชื่อจริงของกล่อง เพื่อให้ detection ถูกต้อง"
})

Tabs.Scan:AddButton({
    Title    = "📊 นับกล่องแต่ละประเภท",
    Callback = function()
        local nextgen = #FindBlocks("NEXT GENERATION")
        local alt     = #FindBlocks("ALTERNATIVE")
        local msg     = string.format("NEXT GENERATION: %d\nALTERNATIVE: %d", nextgen, alt)
        Fluent:Notify({Title="ผลการค้นหา", Content=msg, Duration=6})
        print(msg)
    end
})

Tabs.Scan:AddButton({
    Title    = "📍 Position ทุกกล่อง",
    Callback = function()
        print("=== LUCKY BLOCK POSITIONS ===")
        for _, bt in ipairs({"NEXT GENERATION","ALTERNATIVE"}) do
            local blocks = FindBlocks(bt)
            print("["..bt.."] "..#blocks.." กล่อง:")
            for i, part in ipairs(blocks) do
                print(string.format("  %d. %s @ %.0f, %.0f, %.0f",
                    i, part.Name, part.Position.X, part.Position.Y, part.Position.Z))
            end
        end
        Fluent:Notify({Title="ดู Output", Content="แสดง Position ทุกกล่องใน Output แล้ว", Duration=4})
    end
})

Tabs.Misc:AddToggle("Speed", {
    Title    = "Speed Hack",
    Default  = false,
    Callback = function(val)
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = val and 100 or 16 end
    end
})

local ijConn
Tabs.Misc:AddToggle("InfJump", {
    Title    = "Infinite Jump",
    Default  = false,
    Callback = function(val)
        if val then
            ijConn = UserInputService.JumpRequest:Connect(function()
                local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        else
            if ijConn then ijConn:Disconnect(); ijConn = nil end
        end
    end
})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("TawinLuckyBlock")
SaveManager:SetFolder("TawinLuckyBlock/saves")
InterfaceManager:BuildInterfaceSection(Tabs.Misc)
SaveManager:BuildConfigSection(Tabs.Misc)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({
    Title   = "TAWIN Lucky Block",
    Content = "โหลดแล้ว! กดปุ่ม ⚡ บนจอเพื่อเปิด/ปิด UI ได้เลย",
    Duration = 5
})

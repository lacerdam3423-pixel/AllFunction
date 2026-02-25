wait("0.1")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Universal Hub ~ Atualizado 2026",
   LoadingTitle = "Carregando...",
   LoadingSubtitle = "ESP atualiza a cada ~0.1s",
   Theme = "Mayura",
   ConfigurationSaving = { Enabled = true, FolderName = "MeuHub", FileName = "Config" }
})

local TabMain    = Window:CreateTab("Principal")
local TabVisual  = Window:CreateTab("Visual")
local TabMove    = Window:CreateTab("Movimento")
local TabPlayers = Window:CreateTab("Players")
local TabOther   = Window:CreateTab("Outros")

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

local InfiniteJumpEnabled = false
local ESP_Enabled = false
local RainbowESP = false
local TeamCheckESP = true
local HealthESP = true
local DistanceESP = true
local NameTextSize = 13
local FOV_Value = 70
local WalkSpeed_Value = 16
local HitboxSize = 10
local NoFogEnabled = false

local ESP_Objects = {}
local ESP_UpdateConn

UserInputService.JumpRequest:Connect(function()
   if not InfiniteJumpEnabled then return end
   if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
      LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
   end
end)

TabMain:CreateToggle({
   Name = "Infinite Jump",
   CurrentValue = false,
   Flag = "InfJump",
   Callback = function(Value)
      InfiniteJumpEnabled = Value
   end,
})

local function RemoveESP(plr)
   if ESP_Objects[plr] then
      if ESP_Objects[plr].Billboard then
         ESP_Objects[plr].Billboard:Destroy()
      end
      if ESP_Objects[plr].Highlight then
         ESP_Objects[plr].Highlight:Destroy()
      end
      ESP_Objects[plr] = nil
   end
end

local function CreateOrUpdateESP(plr)
   if plr == LocalPlayer or not plr.Character then return end
   
   local char = plr.Character
   local rootPart = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Humanoid") and char.HumanoidRootPart
   local humanoid = char:FindFirstChildOfClass("Humanoid")
   if not rootPart or not humanoid then return end
   
   if not ESP_Objects[plr] then
      local billboard = Instance.new("BillboardGui")
      billboard.Name = "NameESP"
      billboard.Adornee = rootPart
      billboard.Size = UDim2.new(0, 180, 0, 60)
      billboard.StudsOffset = Vector3.new(0, 3.5, 0)
      billboard.AlwaysOnTop = true
      billboard.Parent = rootPart
      
      local text = Instance.new("TextLabel")
      text.Size = UDim2.new(1,0,1,0)
      text.BackgroundTransparency = 1
      text.TextStrokeTransparency = 0.4
      text.TextStrokeColor3 = Color3.fromRGB(0,0,0)
      text.Font = Enum.Font.SourceSansBold
      text.TextSize = NameTextSize
      text.Text = plr.Name
      text.Parent = billboard
      
      local highlight = Instance.new("Highlight")
      highlight.Name = "OutlineESP"
      highlight.FillTransparency = 1
      highlight.OutlineTransparency = 0
      highlight.OutlineColor = Color3.fromRGB(255,0,0)
      highlight.Adornee = char
      highlight.Parent = char
      
      ESP_Objects[plr] = { Billboard = billboard, Text = text, Highlight = highlight }
   end
   
   local obj = ESP_Objects[plr]
   local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) 
      and (LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude 
      or 0
   
   local color = RainbowESP and Color3.fromHSV(tick() % 10 / 10, 1, 1) 
      or (TeamCheckESP and plr.Team == LocalPlayer.Team and Color3.fromRGB(0,255,0) or Color3.fromRGB(255,0,0))
   
   obj.Highlight.OutlineColor = color
   obj.Text.TextColor3 = color
   
   local info = plr.Name
   if HealthESP then info = info .. " | HP: " .. math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth) end
   if DistanceESP then info = info .. " | " .. math.floor(dist) .. " studs" end
   
   obj.Text.Text = info
end

local function RefreshAllESP()
   for _, plr in ipairs(Players:GetPlayers()) do
      if ESP_Enabled then
         task.spawn(CreateOrUpdateESP, plr)
      else
         RemoveESP(plr)
      end
   end
end

local lastUpdate = tick()
ESP_UpdateConn = RunService.RenderStepped:Connect(function()
   if not ESP_Enabled then return end
   if tick() - lastUpdate < 0.1 then return end
   lastUpdate = tick()
   
   for plr, _ in pairs(ESP_Objects) do
      if not plr.Character or not plr.Character:FindFirstChild("Humanoid") or plr.Character.Humanoid.Health <= 0 then
         RemoveESP(plr)
      else
         CreateOrUpdateESP(plr)
      end
   end
end)

local function SetupPlayer(plr)
   if plr == LocalPlayer then return end
   
   plr.CharacterAdded:Connect(function(char)
      task.wait(0.4)
      if ESP_Enabled then CreateOrUpdateESP(plr) end
      local hum = char:WaitForChild("Humanoid")
      hum.Died:Connect(function()
         Rayfield:Notify({
            Title = "Player Died",
            Content = plr.Name .. " has died!",
            Duration = 2
         })
         RemoveESP(plr)
      end)
   end)
   
   if plr.Character then
      task.wait(0.4)
      if ESP_Enabled then CreateOrUpdateESP(plr) end
      local hum = plr.Character:FindFirstChildOfClass("Humanoid")
      if hum then
         hum.Died:Connect(function()
            Rayfield:Notify({
               Title = "Player Died",
               Content = plr.Name .. " has died!",
               Duration = 2
            })
            RemoveESP(plr)
         end)
      end
   end
end

for _, plr in ipairs(Players:GetPlayers()) do
   SetupPlayer(plr)
end

Players.PlayerAdded:Connect(function(plr)
   Rayfield:Notify({
      Title = "Player Joined",
      Content = plr.Name .. " has joined the server!",
      Duration = 2
   })
   SetupPlayer(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
   Rayfield:Notify({
      Title = "Player Left",
      Content = plr.Name .. " has left the server!",
      Duration = 2
   })
   RemoveESP(plr)
end)

TabVisual:CreateToggle({
   Name = ".",
   CurrentValue = false,
   Callback = function(v)
      ESP_Enabled = v
      if not v then
         for plr in pairs(ESP_Objects) do RemoveESP(plr) end
      else
         RefreshAllESP()
      end
   end
})

TabVisual:CreateToggle({ Name = "Rainbow Outline", CurrentValue = false, Callback = function(v) RainbowESP = v end })
TabVisual:CreateToggle({ Name = "Team Check (verde = aliado)", CurrentValue = true, Callback = function(v) TeamCheckESP = v end })
TabVisual:CreateToggle({ Name = "Mostrar Vida", CurrentValue = true, Callback = function(v) HealthESP = v end })
TabVisual:CreateToggle({ Name = "Mostrar Distância", CurrentValue = true, Callback = function(v) DistanceESP = v end })

TabVisual:CreateSlider({
   Name = "Tamanho do Texto do Nome",
   Range = {8, 22},
   Increment = 1,
   CurrentValue = 13,
   Callback = function(v)
      NameTextSize = v
      for _, obj in pairs(ESP_Objects) do
         if obj.Text then obj.Text.TextSize = v end
      end
   end
})

TabVisual:CreateSlider({
   Name = "Field of View (FOV)",
   Range = {10, 120},
   Increment = 1,
   CurrentValue = 70,
   Callback = function(v)
      FOV_Value = v
      Camera.FieldOfView = v
   end
})

TabMove:CreateSlider({
   Name = "WalkSpeed Permanente",
   Range = {10, 200},
   Increment = 1,
   CurrentValue = 37,
   Callback = function(v)
      WalkSpeed_Value = v
      if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
         LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = v
      end
   end
})

LocalPlayer.CharacterAdded:Connect(function(char)
   task.wait(0.5)
   char:WaitForChild("Humanoid").WalkSpeed = WalkSpeed_Value
   Camera.FieldOfView = FOV_Value
end)

local HitboxConn
TabVisual:CreateSlider({
   Name = "Hitbox Expander Size",
   Range = {1, 50},
   Increment = 1,
   CurrentValue = 10,
   Callback = function(v) HitboxSize = v end
})

TabVisual:CreateToggle({
   Name = "Hitbox Expander Permanente",
   CurrentValue = false,
   Callback = function(v)
      if v then
         for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
               local root = plr.Character:FindFirstChild("HumanoidRootPart")
               if root then
                  root.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                  root.Transparency = 0.75
                  root.CanCollide = false
               end
            end
         end
         HitboxConn = RunService.Heartbeat:Connect(function()
            for _, plr in ipairs(Players:GetPlayers()) do
               if plr ~= LocalPlayer and plr.Character then
                  local root = plr.Character:FindFirstChild("HumanoidRootPart")
                  if root then
                     root.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                     root.Transparency = 0.75
                     root.CanCollide = false
                  end
               end
            end
         end)
      else
         if HitboxConn then HitboxConn:Disconnect() end
      end
   end
})

TabOther:CreateToggle({
   Name = "No Fog",
   CurrentValue = false,
   Callback = function(v)
      if v then
         Lighting.FogEnd = 9999
         Lighting.FogStart = 0
      else
         Lighting.FogEnd = 100000
      end
   end
})

TabOther:CreateButton({
   Name = "Remover Sombras Globais (1x)",
   Callback = function()
      Lighting.GlobalShadows = false
      for _, child in ipairs(Lighting:GetChildren()) do
         if child:IsA("Atmosphere") or child:IsA("Sky") or child.Name:lower():find("shadow") then
            child:Destroy()
         end
      end
   end
})

TabOther:CreateButton({
   Name = "Load Infinite Yield",
   Callback = function()
      loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
   end
})

Rayfield:Notify({
   Title = "Script Load",
   Content = "Script Loading",
   Duration = 6
})

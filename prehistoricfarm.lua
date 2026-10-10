--=============================================================
--  🦖 PREHISTORIC FARM — HUB v4 (ES)
--  Un solo archivo • UI: Rayfield • Mobile-friendly
--  Place: 139780970631001
--=============================================================
local Players    = game:GetService("Players")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")
local LP         = Players.LocalPlayer
local LIGHT      = game:GetService("Lighting")

print("[PF Hub v4] iniciando...")

--========== ESTADO (todo arriba = sin bugs de scope) ==========
local S = {
    speed=16, jump=50, infJump=false,
    fly=false, noclip=false, follow=false, walkWater=false,
    autoDig=false, tpDig=true, autoFish=false,
    autoPrompt=false, radius=30,
    forcePrompt=false, instantHold=false,
    autoMoney=false, moneyRemote=nil,
    espP=false, espD=false, espDig=false,
    antiVoid=false, antiAfk=false, remoteLog=false,
}
local savedPos, waterY
local lastRemote, lastArgs

--========== UI ==========
local okR, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not okR then warn("[PF Hub] Rayfield no cargó:", Rayfield); return end

local Win = Rayfield:CreateWindow({
    Name = "🦖 Prehistoric Farm — Hub v4",
    LoadingTitle = "Cargando Hub...",
    LoadingSubtitle = "by Venice",
    ConfigurationSaving = { Enabled = true, FolderName = "PFHub", FileName = "cfg" },
    KeySystem = false,
})
local T_Home = Win:CreateTab("🏠 Inicio", 4483362458)
local T_Move = Win:CreateTab("🏃 Movimiento", 4483345998)
local T_Vis  = Win:CreateTab("👁️ Visuales", 6031090687)
local T_Auto = Win:CreateTab("⚙️ Auto Farm", 6023426926)
local T_Util = Win:CreateTab("🧰 Utilidades", 4483362458)

--========== HELPERS ==========
local function hum()
    local c = LP.Character or LP.CharacterAdded:Wait()
    return c:WaitForChild("Humanoid"), c:WaitForChild("HumanoidRootPart")
end
local function fire(o, ...)
    if o:IsA("RemoteFunction") then return o:InvokeServer(...) else o:FireServer(...) end
end
local function resolvePath(p)
    local o = RS
    for seg in p:gmatch("[^%.]+") do
        if seg~="ReplicatedStorage" and seg~="game" then o = o and o:FindFirstChild(seg) end
    end
    return o
end
local function notify(t, c) pcall(function() Rayfield:Notify({Title=t, Content=c, Duration=5}) end) end
local function isDig(d)
    if not d:IsA("BasePart") then return false end
    local n = d.Name:lower()
    return n:find("dig") or n:find("mound") or n:find("fossil") or n:find("dirt") or n:find("spot") or n:find("excavat")
end
local function firePrompt(p)
    pcall(function()
        if fireproximityprompt then fireproximityprompt(p)
        else p:InputHoldBegin(); task.wait(math.max(p.HoldDuration,0.05)); p:InputHoldEnd() end
    end)
end
local function getTool(m)
    local c = LP.Character; if not c then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name:lower():find(m) then return t end
    end
end

--==================== 🏠 INICIO ====================
T_Home:CreateSection("Guía")
T_Home:CreateParagraph({Title="Cómo usar", Content="1) Ve a Auto Farm -> activa Auto Cavar.\n2) Activa Bypass.\n3) O pulsa MODO FARM y listo."})
T_Home:CreateSection("Acciones")
T_Home:CreateButton({Name="⚡ MODO FARM COMPLETO (todo ON)", Callback=function()
    S.autoDig=true; S.tpDig=true; S.forcePrompt=true; S.instantHold=true; S.autoPrompt=true; S.autoMoney=true
    notify("Modo Farm", "Auto Cavar + Bypass + Auto Dinero ACTIVADOS")
end})
T_Home:CreateButton({Name="🧹 Desactivar todo", Callback=function()
    S.autoDig=false; S.autoPrompt=false; S.forcePrompt=false; S.instantHold=false; S.autoMoney=false; S.autoFish=false
    notify("Modo Farm", "Todo desactivado")
end})
T_Home:CreateSection("Servidor")
T_Home:CreateButton({Name="🔄 Rejoin", Callback=function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end})
T_Home:CreateButton({Name="👥 Jugadores", Callback=function() notify("Servidor", #Players:GetPlayers().." jugadores") end})
T_Home:CreateButton({Name="💾 Guardar config", Callback=function() pcall(function() Rayfield:SaveConfiguration() end) end})
T_Home:CreateButton({Name="📂 Cargar config", Callback=function() pcall(function() Rayfield:LoadConfiguration() end) end})
T_Home:CreateButton({Name="🔌 Unload", Callback=function() pcall(function() Rayfield:Destroy() end) end})

--==================== 🏃 MOVIMIENTO ====================
T_Move:CreateSection("Velocidad")
T_Move:CreateSlider({Name="Velocidad", Range={16,1000}, Increment=1, Suffix=" studs", CurrentValue=16, Callback=function(v)
    S.speed=v; local h=hum(); if h then h.WalkSpeed=v end end})
T_Move:CreateSlider({Name="Salto", Range={50,1000}, Increment=1, Suffix=" pw", CurrentValue=50, Callback=function(v)
    S.jump=v; local h=hum(); if h then h.UseJumpPower=true; h.JumpPower=v end end})
T_Move:CreateToggle({Name="Salto infinito", CurrentValue=false, Callback=function(v) S.infJump=v end})
UIS.JumpRequest:Connect(function()
    if S.infJump then local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

T_Move:CreateSection("Vuelo / Noclip")
local flyBV, flyConn, flyKeys = nil, nil, {}
local function startFly()
    local _, root = hum()
    flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1e5,1e5,1e5); flyBV.Velocity=Vector3.zero; flyBV.Parent=root
    flyConn = RunService.RenderStepped:Connect(function()
        if not S.fly or not root.Parent then if flyBV then flyBV:Destroy() end; if flyConn then flyConn:Disconnect() end; flyBV, flyConn = nil, nil; return end
        local cam = workspace.CurrentCamera.CFrame; local m = Vector3.zero
        if flyKeys[Enum.KeyCode.W] then m += cam.LookVector end
        if flyKeys[Enum.KeyCode.S] then m -= cam.LookVector end
        if flyKeys[Enum.KeyCode.A] then m -= cam.RightVector end
        if flyKeys[Enum.KeyCode.D] then m += cam.RightVector end
        if flyKeys[Enum.KeyCode.Space] then m += Vector3.new(0,1,0) end
        if flyKeys[Enum.KeyCode.LeftControl] then m -= Vector3.new(0,1,0) end
        flyBV.Velocity = m.Magnitude > 0 and m.Unit*90 or Vector3.zero
    end)
end
UIS.InputBegan:Connect(function(i,g) if not g then flyKeys[i.KeyCode]=true end end)
UIS.InputEnded:Connect(function(i) flyKeys[i.KeyCode]=false end)
T_Move:CreateToggle({Name="Volar (WASD + Espacio/Ctrl)", CurrentValue=false, Callback=function(v) S.fly=v; if v then startFly() end end})
T_Move:CreateToggle({Name="Noclip", CurrentValue=false, Callback=function(v) S.noclip=v end})
RunService.Stepped:Connect(function()
    if S.noclip and LP.Character then
        for _, p in ipairs(LP.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end
end)

T_Move:CreateSection("Teletransporte")
T_Move:CreateButton({Name="🖱️ TP al cursor", Callback=function()
    local m = UIS:GetMouseLocation()
    local ray = workspace.CurrentCamera:ViewportPointToRay(m.X, m.Y)
    local par = RaycastParams.new(); par.FilterDescendantsInstances = {LP.Character}
    local res = workspace:Raycast(ray.Origin, ray.Direction*3000, par)
    if res then local _, hrp = hum(); hrp.CFrame = CFrame.new(res.Position + Vector3.new(0,4,0)) end
end})
T_Move:CreateButton({Name="📍 Guardar posición", Callback=function() local _, hrp = hum(); savedPos = hrp.CFrame; notify("Posición", "Guardada") end})
T_Move:CreateButton({Name="➡️ Ir a posición", Callback=function() if savedPos then local _, hrp = hum(); hrp.CFrame = savedPos end end})
T_Move:CreateToggle({Name="Seguir jugador más cercano", CurrentValue=false, Callback=function(v)
    S.follow=v; if not v then return end
    task.spawn(function()
        while S.follow do
            task.wait(0.1)
            pcall(function()
                local _, hrp = hum(); local best, bd
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LP and p.Character then
                        local r = p.Character:FindFirstChild("HumanoidRootPart")
                        if r then local d = (r.Position-hrp.Position).Magnitude; if not bd or d<bd then best,bd = r,d end end
                    end
                end
                if best then hrp.CFrame = best.CFrame * CFrame.new(0,0,6) end
            end)
        end
    end)
end})
T_Move:CreateSection("Agua")
T_Move:CreateToggle({Name="Caminar sobre el agua", CurrentValue=false, Callback=function(v)
    S.walkWater=v
    if v then
        local _, hrp = hum(); waterY = hrp.Position.Y
        local bp = Instance.new("BodyPosition"); bp.Name="PF_WW"; bp.MaxForce=Vector3.new(1e5,1e5,1e5); bp.P=25000; bp.D=1500; bp.Position=hrp.Position; bp.Parent=hrp
        task.spawn(function()
            while S.walkWater and bp.Parent do task.wait(); bp.Position = Vector3.new(hrp.Position.X, waterY, hrp.Position.Z) end
            if bp then bp:Destroy() end
        end)
    end
end})

--==================== 👁️ VISUALES ====================
T_Vis:CreateSection("Mundo")
T_Vis:CreateToggle({Name="Fullbright", CurrentValue=false, Callback=function(v)
    LIGHT.Brightness = v and 3 or 2
    if v then LIGHT.FogEnd = 1e6; LIGHT.GlobalShadows = false end
end})
T_Vis:CreateToggle({Name="Forzar noche", CurrentValue=false, Callback=function(v) if v then LIGHT.ClockTime = 0 end end})
T_Vis:CreateToggle({Name="Forzar día", CurrentValue=false, Callback=function(v) if v then LIGHT.ClockTime = 14 end end})
T_Vis:CreateSection("ESP")
local function setHL(parent, on, color, name)
    local ex = parent:FindFirstChild(name)
    if on and not ex then local h = Instance.new("Highlight"); h.Name=name; h.FillColor=color; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; h.Parent=parent
    elseif not on and ex then ex:Destroy() end
end
T_Vis:CreateToggle({Name="ESP jugadores", CurrentValue=false, Callback=function(v)
    S.espP=v
    for _, p in ipairs(Players:GetPlayers()) do if p~=LP and p.Character then setHL(p.Character, v, Color3.fromRGB(0,255,0), "PF_EP") end end
end})
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function(c) if S.espP then setHL(c, true, Color3.fromRGB(0,255,0), "PF_EP") end end) end)
T_Vis:CreateToggle({Name="ESP dinos/NPC", CurrentValue=false, Callback=function(v)
    S.espD=v
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and d:FindFirstChildOfClass("Humanoid") and d~=LP.Character then setHL(d, v, Color3.fromRGB(255,170,0), "PF_ED") end
    end
end})
T_Vis:CreateToggle({Name="Resaltar montículos", CurrentValue=false, Callback=function(v)
    S.espDig=v
    for _, d in ipairs(workspace:GetDescendants()) do if isDig(d) then setHL(d, v, Color3.fromRGB(0,170,255), "PF_DIG") end end
end})

--==================== ⚙️ AUTO FARM ====================
T_Auto:CreateSection("Excavar")
T_Auto:CreateToggle({Name="Auto Cavar", CurrentValue=false, Callback=function(v) S.autoDig=v end})
T_Auto:CreateToggle({Name="TP al montículo", CurrentValue=true, Callback=function(v) S.tpDig=v end})
task.spawn(function()
    while true do task.wait(0.25)
        if S.autoDig then pcall(function()
            local _, hrp = hum(); local best, bd
            for _, d in ipairs(workspace:GetDescendants()) do
                if isDig(d) then local dist = (d.Position-hrp.Position).Magnitude; if not bd or dist<bd then best,bd = d,dist end end
            end
            if best then
                if S.tpDig and bd > 12 then hrp.CFrame = CFrame.new(best.Position + Vector3.new(0,4,0)) end
                local p = best:FindFirstChildWhichIsA("ProximityPrompt", true)
                if p then firePrompt(p) end
                local t = getTool("shovel") or getTool("pala") or getTool("dig")
                if t then pcall(function() t:Activate() end) end
            end
        end) end
    end
end)
T_Auto:CreateSection("Interacción")
T_Auto:CreateSlider({Name="Radio de interacción", Range={5,200}, Increment=1, Suffix=" studs", CurrentValue=30, Callback=function(v) S.radius=v end})
T_Auto:CreateToggle({Name="Auto Interactuar", CurrentValue=false, Callback=function(v) S.autoPrompt=v end})
task.spawn(function()
    while true do task.wait(0.35)
        if S.autoPrompt then pcall(function()
            local _, hrp = hum()
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") and d.Enabled then
                    local part = d.Parent
                    if part and part:IsA("BasePart") and (part.Position-hrp.Position).Magnitude <= S.radius then firePrompt(d) end
                end
            end
        end) end
    end
end)
T_Auto:CreateSection("Pesca")
T_Auto:CreateToggle({Name="Auto Pescar", CurrentValue=false, Callback=function(v) S.autoFish=v end})
task.spawn(function()
    while true do task.wait(0.5)
        if S.autoFish then local t = getTool("rod") or getTool("fishing") or getTool("caña") or getTool("fish")
            if t then pcall(function() t:Activate() end) end end
    end
end)
T_Auto:CreateSection("Bypass")
T_Auto:CreateToggle({Name="Forzar prompts (bypass pala)", CurrentValue=false, Callback=function(v) S.forcePrompt=v end})
T_Auto:CreateToggle({Name="Hold instantáneo", CurrentValue=false, Callback=function(v) S.instantHold=v end})
task.spawn(function()
    while true do task.wait(1)
        if S.forcePrompt or S.instantHold then
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ProximityPrompt") then
                    if S.forcePrompt then d.Enabled=true; d.MaxActivationDistance=1000; d.RequiresLineOfSight=false end
                    if S.instantHold then d.HoldDuration=0 end
                end
            end
        end
    end
end)
T_Auto:CreateSection("Supervivencia")
T_Auto:CreateToggle({Name="Anti-Void", CurrentValue=false, Callback=function(v) S.antiVoid=v end})
task.spawn(function()
    while true do task.wait(0.2)
        if S.antiVoid then pcall(function() local _, hrp = hum()
            if hrp.Position.Y < -50 then hrp.CFrame = CFrame.new(hrp.Position.X, 200, hrp.Position.Z) end end) end
    end
end)
T_Auto:CreateToggle({Name="Anti-AFK", CurrentValue=false, Callback=function(v) S.antiAfk=v end})
task.spawn(function()
    while true do task.wait(60)
        if S.antiAfk then pcall(function() local v = game:GetService("VirtualUser"); v:CaptureController(); v:ClickButton2(Vector2.new()) end) end
    end
end)

--==================== 🧰 UTILIDADES ====================
T_Util:CreateSection("Dinero")
local function coinStat()
    local ls = LP:FindFirstChild("leaderstats"); if not ls then return end
    for _, v in ipairs(ls:GetChildren()) do
        local n = v.Name:lower()
        if (n:find("coin") or n:find("cash") or n:find("money") or n:find("dollar") or n:find("gem")) and v:IsA("ValueBase") then return v end
    end
end
T_Util:CreateButton({Name="🔎 Detectar remote de dinero", Callback=function()
    local stat = coinStat(); local cands = {}
    for _, d in ipairs(RS:GetDescendants()) do
        if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) then
            local n = d.Name:lower()
            if n:find("sell") or n:find("claim") or n:find("collect") or n:find("reward") or n:find("money") or n:find("coin") or n:find("cash") or n:find("give") then table.insert(cands, d) end
        end
    end
    if #cands == 0 then notify("Auto-Dinero", "Sin candidatos"); return end
    local found
    for _, r in ipairs(cands) do
        local before = stat and stat.Value or 0
        pcall(function() fire(r) end); task.wait(0.45)
        if stat and stat.Value > before then found = r; break end
    end
    if found then S.moneyRemote = found:GetFullName(); notify("Auto-Dinero", "✅ Detectado: "..found.Name)
    else notify("Auto-Dinero", "Ninguno dio monedas. Usa el Logger.") end
end})
T_Util:CreateToggle({Name="💰 Auto Dinero", CurrentValue=false, Callback=function(v) S.autoMoney=v end})
task.spawn(function()
    while true do task.wait(0.15)
        if S.autoMoney and S.moneyRemote then local o = resolvePath(S.moneyRemote); if o then pcall(function() fire(o) end) end end
    end
end)
T_Util:CreateSection("Remotes")
T_Util:CreateButton({Name="📜 Volcar remotes a consola", Callback=function()
    local c = 0
    for _, d in ipairs(RS:GetDescendants()) do if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then print(d:GetFullName()); c = c + 1 end end
    notify("Remotes", c.." en consola")
end})
T_Util:CreateToggle({Name="Logger (captura último remote)", CurrentValue=false, Callback=function(v) S.remoteLog=v end})
do
    pcall(function()
        local mt = getrawmetatable(game); local old = mt.__namecall; setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local m = getnamecallmethod()
            if (m == "FireServer" or m == "InvokeServer") and typeof(self) == "Instance" then
                lastRemote = self; lastArgs = {...}
                if S.remoteLog then local a = {...}; local p = {}; for i = 1, math.min(#a,6) do p[i] = tostring(a[i]) end; print("[FIRE]", self:GetFullName(), m, table.concat(p, " | ")) end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
end
T_Util:CreateButton({Name="🔁 Repetir último remote x10", Callback=function()
    if not lastRemote then notify("Replay", "Sin remote (usa el Logger)"); return end
    for _ = 1, 10 do pcall(function() fire(lastRemote, unpack(lastArgs or {})) end); task.wait(0.05) end
end})
T_Util:CreateButton({Name="🔁 Repetir último remote x100", Callback=function()
    if not lastRemote then notify("Replay", "Sin remote (usa el Logger)"); return end
    for _ = 1, 100 do pcall(function() fire(lastRemote, unpack(lastArgs or {})) end); task.wait(0.05) end
end})
T_Util:CreateSection("Códigos")
local CODES = {"GOGRINDNESSIENEW","NESSIEISHERE","UPDATE05","SORRYFORDELAY","UICHANGES"}
T_Util:CreateButton({Name="🎁 Canjear códigos", Callback=function()
    local remote
    for _, d in ipairs(RS:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            local n = d.Name:lower()
            if n:find("code") or n:find("redeem") or n:find("promo") then remote = d; break end
        end
    end
    if not remote then notify("Códigos", "Sin remote de códigos"); return end
    for _, c in ipairs(CODES) do pcall(function() fire(remote, c) end); task.wait(0.3) end
    notify("Códigos", "Canjeados en "..remote.Name)
end})
T_Util:CreateSection("Jugador")
T_Util:CreateButton({Name="♻️ Reset", Callback=function() local c = LP.Character; if c then c:BreakJoints() end end})
T_Util:CreateButton({Name="👻 Invisible (toggle)", Callback=function()
    local c = LP.Character; if c then for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Transparency = p.Transparency == 1 and 0 or 1 end end end
end})
T_Util:CreateButton({Name="📊 Ver stats (consola)", Callback=function()
    local ls = LP:FindFirstChild("leaderstats"); if ls then for _, v in ipairs(ls:GetChildren()) do print("STAT:", v.Name, "=", v.Value) end end
    notify("Stats", "En consola")
end})
T_Util:CreateSection("Consola Lua")
T_Util:CreateInput({Name="Ejecutar Lua", PlaceholderText="print('hola')", RemoveTextAfterFocusLost=false, Callback=function(t)
    local f = loadstring(t); if f then local ok, err = pcall(f); print(ok and "[OK]" or ("[ERR] "..tostring(err))) end
end})

notify("🦖 PF Hub v4", "Cargado correctamente")

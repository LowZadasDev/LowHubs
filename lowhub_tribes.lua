local VERSION = "LowHub"
local limpar_tudo = nil

--[[
    TRAVA DE JOGO

    O hub so roda no jogo pra que foi feito. Em qualquer outro
    lugar ele nao faz NADA - so avisa e morre, antes de criar
    servico, interface ou loop.

    Jogo: "Tribes 3v3" (com S no final, e' assim mesmo o nome)

    O CreatorId abaixo e' o do GRUPO "Snick Co." (dono SnickTrix),
    nao de uma pessoa - o jogo e' de grupo. game.CreatorId devolve
    o ID do grupo nesse caso, entao a comparacao funciona igual.

    Nao confundir com o usuario 776581204: esse ID de usuario
    existe (dani20313), mas e' coincidencia de faixa - IDs de
    grupo e de usuario saem do mesmo contador. O que vale aqui
    e' o que o game.CreatorId devolve, e ele devolve este numero.

    Como o jogo e' identificado: vale o PlaceId OU o CreatorId.
    O CreatorId e' mais tolerante (pega mapa/servidor novo do
    mesmo dono); o PlaceId e' mais exato.
--]]
local JOGO_ESPERADO = {
    place   = 72169370437173,
    criador = 776581204,
    nome    = "Tribes 3v3",
}

if JOGO_ESPERADO.place or JOGO_ESPERADO.criador then
    local place_ok = JOGO_ESPERADO.place
                     and game.PlaceId == JOGO_ESPERADO.place
    local dono_ok  = JOGO_ESPERADO.criador
                     and game.CreatorId == JOGO_ESPERADO.criador

    if not (place_ok or dono_ok) then
        local function matar_aviso()
            local ok, Players = pcall(function()
                return game:GetService("Players")
            end)
            if not ok or not Players then return end

            local lp = Players.LocalPlayer
            if not lp then return end

            local alvo = lp:FindFirstChild("PlayerGui")
            if not alvo then return end

            local sg = Instance.new("ScreenGui")
            sg.Name = "LowHubBloqueado"
            sg.ResetOnSpawn = false
            sg.IgnoreGuiInset = true
            sg.DisplayOrder = 2147483647
            sg.Parent = alvo

            local f = Instance.new("Frame")
            f.Size = UDim2.new(0, 420, 0, 118)
            f.Position = UDim2.new(0.5, -210, 0.5, -59)
            f.BackgroundColor3 = Color3.fromRGB(20, 14, 16)
            f.BorderSizePixel = 0
            f.Parent = sg

            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 12)
            c.Parent = f

            local s = Instance.new("UIStroke")
            s.Color = Color3.fromRGB(200, 60, 70)
            s.Thickness = 1.5
            s.Transparency = 0.2
            s.Parent = f

            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -28, 0, 24)
            t.Position = UDim2.new(0, 14, 0, 14)
            t.BackgroundTransparency = 1
            t.Text = "LOWHUB  -  WRONG GAME"
            t.TextColor3 = Color3.fromRGB(255, 110, 120)
            t.Font = Enum.Font.GothamBold
            t.TextSize = 14
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.Parent = f

            local d = Instance.new("TextLabel")
            d.Size = UDim2.new(1, -28, 0, 62)
            d.Position = UDim2.new(0, 14, 0, 42)
            d.BackgroundTransparency = 1
            d.Text = "This hub only works in " .. JOGO_ESPERADO.nome .. ".\n"
                  .. "Current game: " .. tostring(game.PlaceId) .. "\n"
                  .. "Nothing was loaded."
            d.TextColor3 = Color3.fromRGB(200, 186, 195)
            d.Font = Enum.Font.Gotham
            d.TextSize = 12
            d.TextWrapped = true
            d.TextXAlignment = Enum.TextXAlignment.Left
            d.TextYAlignment = Enum.TextYAlignment.Top
            d.Parent = f

            task.delay(8, function()
                pcall(function() sg:Destroy() end)
            end)
        end

        pcall(matar_aviso)

        if type(warn) == "function" then
            warn("[LowHub] jogo errado: este hub e' so do "
                 .. JOGO_ESPERADO.nome)
        end

        return
    end
end

local function ambiente_global()
    if type(getgenv) == "function" then
        local ok, g = pcall(getgenv)
        if ok and type(g) == "table" then return g end
    end
    return _G
end

local G = ambiente_global()
local anterior = G.__LOWHUB_ATIVO
if type(anterior) == "table" and type(anterior.limpar) == "function" then
    pcall(anterior.limpar)
end
G.__LOWHUB_ATIVO = nil

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local StarterGui        = game:GetService("StarterGui")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local ENV = (type(getfenv) == "function" and getfenv()) or _G

local function envfn(name)
    local f = ENV[name]
    if type(f) == "function" then return f end
    f = _G[name]
    if type(f) == "function" then return f end
    if type(getgenv) == "function" then
        local g = getgenv()
        if g and type(g[name]) == "function" then return g[name] end
    end
    return nil
end

local f_hookmeta   = envfn("hookmetamethod")
local f_getrawmt   = envfn("getrawmetatable")
local f_setro      = envfn("setreadonly")
local f_newc       = envfn("newcclosure")
local f_mouse1     = envfn("mouse1click")
local f_mouse1down = envfn("mouse1press")
local f_mouse1up   = envfn("mouse1release")

local f_mouserel   = envfn("mousemoverel")
local f_mouseabs   = envfn("mousemoveabs")

local MOUSE_MODE = "camera"
if f_mouserel then
    MOUSE_MODE = "rel"
elseif f_mouseabs then
    MOUSE_MODE = "abs"
end

local VIM = nil
pcall(function() VIM = game:GetService("VirtualInputManager") end)

local CONFIG = {

    AimLockEnabled  = true,
    AimKey          = Enum.KeyCode.E,
    AimMouseButton  = nil,
    AimHoldMode     = true,
    AimBone         = "Head",
    AimSmoothLock   = true,
    AimMaxDist      = 900,
    AimHeightOffset = 0.0,





    AimMode         = "robot",
    LegitSpeed      = 90,
    LegitJitter     = 0.55,
    LegitError      = 1.8,
    LegitReaction   = 0.18,
    LegitOvershoot  = true,
    LegitLostKeep   = 0.4,


    CutSubject      = false,


    MouseLock       = false,

    HookCamera      = true,
    PreservePos     = true,


    AutoFire        = false,
    FireCone        = 2.5,
    FireDelay       = 0.10,
    FireOnlyLocked  = false,

    FireOnSight     = true,

    WallCheck       = true,


    ShowFOVCircle   = true,
    ESPEnabled      = true,
    ESPColorEnemy   = Color3.fromRGB(255, 72, 72),
    ESPColorAlly    = Color3.fromRGB(72, 196, 255),
    ESPMaxDistance  = 500,
    ESPShowName     = true,
    ESPShowHealth   = true,
    ESPShowDist     = true,



    SpeedEnabled    = false,
    SpeedValue      = 28,
    FlyEnabled      = false,
    FlySpeed        = 55,


    MatchOnly       = true,
}

local AIM_TUNE = {
    FOVdeg       = 100,
    FOVdrop      = 140,
    Prediction   = 0.08,
    DistWeight   = 0.25,
}

local FS = {
    write   = envfn("writefile"),
    read    = envfn("readfile"),
    isfile  = envfn("isfile"),
    delfile = envfn("delfile"),
    mkdir   = envfn("makefolder"),
    isdir   = envfn("isfolder"),


    pasta   = "LowHub",
}

local function hub_path(arquivo)
    return FS.pasta .. "/" .. arquivo
end

local function garantir_pasta()
    if type(FS.mkdir) ~= "function" then return false end
    if type(FS.isdir) == "function" then
        local ok, existe = pcall(FS.isdir, FS.pasta)
        if ok and existe then return true end
    end
    pcall(FS.mkdir, FS.pasta)
    return true
end

local function salvar_arquivo(nome, conteudo)
    if type(FS.write) ~= "function" then return false end
    if garantir_pasta() then
        local ok = pcall(FS.write, hub_path(nome), conteudo)
        if ok then return true end
    end
    local ok2 = pcall(FS.write, nome, conteudo)
    return ok2
end

local function ler_arquivo(nome)
    if type(FS.read) ~= "function" then return nil end
    local ok, dado = pcall(FS.read, hub_path(nome))
    if ok and type(dado) == "string" and #dado > 0 then return dado end
    local ok2, dado2 = pcall(FS.read, nome)
    if ok2 and type(dado2) == "string" and #dado2 > 0 then return dado2 end
    return nil
end

local function apagar_arquivo(nome)
    if type(FS.delfile) ~= "function" then return false end
    local ok = pcall(FS.delfile, hub_path(nome))
    if ok then return true end
    local ok2 = pcall(FS.delfile, nome)
    return ok2
end

FS.tem = (type(FS.write) == "function" and type(FS.read) == "function")

local AUTOLOAD_FILE = "autoload.txt"

local autoload_nome = nil
local autoload_ativo = false

local function ler_autoload()
    local txt = ler_arquivo(AUTOLOAD_FILE)
    if type(txt) ~= "string" then
        autoload_nome, autoload_ativo = nil, false
        return
    end
    txt = txt:gsub("^%s+", ""):gsub("%s+$", "")
    if #txt == 0 or txt == "off" then
        autoload_nome, autoload_ativo = nil, false
    else
        autoload_nome, autoload_ativo = txt, true
    end
end

local function gravar_autoload(nome)
    if nome then
        autoload_nome, autoload_ativo = nome, true
        salvar_arquivo(AUTOLOAD_FILE, nome)
    else
        autoload_nome, autoload_ativo = nil, false


        salvar_arquivo(AUTOLOAD_FILE, "off")
    end
end

local f_queue = envfn("queue_on_teleport") or envfn("queueonteleport")

local HUB_URL = "https://raw.githubusercontent.com/LowZadasDev/LowHubs/refs/heads/main/lowhub_tribes.lua"

local hub_url = nil

local function texto_autoexec(url)
    return 'loadstring(game:HttpGet("' .. tostring(url) .. '", true))()'
end

local function tem_queue()
    return type(f_queue) == "function"
end

local function ativar_auto_exec(url)
    if not tem_queue() then return false, "executor has no queue_on_teleport" end
    if type(url) ~= "string" or #url < 12 then
        return false, "invalid URL"
    end
    local ok = pcall(f_queue, texto_autoexec(url))
    if ok then
        hub_url = url
        salvar_arquivo("autoexec_url.txt", url)
        return true
    end
    return false, "the executor refused the queue"
end

local function desativar_auto_exec()
    hub_url = nil
    apagar_arquivo("autoexec_url.txt")
end

local Keybind = {
    capturing = false,
    which     = nil,
    painters  = {},
}

local MOUSE_NAMES = {
    [Enum.UserInputType.MouseButton1] = "Left Mouse",
    [Enum.UserInputType.MouseButton2] = "Right Mouse",
    [Enum.UserInputType.MouseButton3] = "Middle Mouse",
}

local function key_name(k)
    if not k then return "none" end
    local s = tostring(k)
    return (s:gsub("Enum.KeyCode.", ""))
end

local function bind_label()
    if CONFIG.AimMouseButton then
        return MOUSE_NAMES[CONFIG.AimMouseButton] or "mouse"
    end
    return key_name(CONFIG.AimKey)
end

local aim_held    = false
local aim_toggled = false
local aim_active  = false

local mira_modo   = "camera"

local function recompute_aim_active()
    if CONFIG.AimHoldMode then
        aim_active = aim_held
    else
        aim_active = aim_toggled
    end
end

local function repaint_keybinds()
    for _, fn in ipairs(Keybind.painters) do pcall(fn) end
end

local esp_cache         = {}
local orig_walk         = nil
local speed_state       = "desligado"
local aim_execs         = 0

local locked_target     = nil
local locked_plr        = nil
local last_aim_time     = 0
local swap_count        = 0

local shots_fired       = 0
local last_shot_time    = 0
local fire_state        = "pronto"
local attack_mode       = "?"

local fire_sight_plr    = nil

local fov_gui           = nil
local fov_circle        = nil
local window            = nil
local orig_mouse        = UserInputService.MouseBehavior
local delta_killer_on   = false
local subject_cutter_on = false
local saved_subject     = nil
local running           = true

local hook_on           = false
local desired_look      = nil
local orig_newindex     = nil

local function resolve_parent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui, "gethui" end
    end
    if type(get_hidden_gui) == "function" then
        local ok, hui = pcall(get_hidden_gui)
        if ok and hui then return hui, "get_hidden_gui" end
    end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then
        for _ = 1, 50 do
            task.wait(0.1)
            pg = LP:FindFirstChild("PlayerGui")
            if pg then break end
        end
    end
    if pg then return pg, "PlayerGui" end
    return game:GetService("CoreGui"), "CoreGui"
end

local PARENT, PARENT_KIND = resolve_parent()

local function parent_ok(p)
    if not p then return false end
    return (pcall(function() return p.Parent end))
end

local aviso_texto, aviso_ate = nil, 0

local function avisar(msg)
    aviso_texto = msg
    aviso_ate   = os.clock() + 4
end

local function my_team()  return LP:GetAttribute("Team") or 0 end
local function my_state() return LP:GetAttribute("State") or "Lobby" end
local function in_match() return my_state() == "Match" end
local function should_act()
    if not CONFIG.MatchOnly then return true end
    return in_match()
end

local function is_alive(plr)
    local a = plr:GetAttribute("Alive")
    if a ~= nil then return a == true end
    local char = plr.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function team_of(plr) return plr:GetAttribute("Team") or 0 end

local function is_enemy(plr)
    if plr == LP then return false end
    local mine, his = my_team(), team_of(plr)
    if mine == 0 or his == 0 then return false end
    return mine ~= his
end

local function is_ally(plr)
    if plr == LP then return false end
    local mine, his = my_team(), team_of(plr)
    if mine == 0 or his == 0 then return false end
    return mine == his
end

local function get_root(plr)
    local char = plr.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
end

local function get_hull(plr)
    local root = get_root(plr)
    if not root then return nil end
    return root:FindFirstChild("TribesHull") or root
end

local function get_aim_part(plr)
    local char = plr.Character
    if not char then return nil end

    local bone = CONFIG.AimBone
    if bone == "TribesHull" then return get_hull(plr) end

    local part = char:FindFirstChild(bone)
    if part and part:IsA("BasePart") then return part end

    if bone == "Head" then
        local ut = char:FindFirstChild("UpperTorso")
        if ut and ut:IsA("BasePart") then return ut end
    end
    if bone == "UpperTorso" then
        local t = char:FindFirstChild("Torso")
        if t and t:IsA("BasePart") then return t end
    end
    return get_hull(plr)
end

local function get_humanoid(plr)
    local char = plr.Character
    return char and char:FindFirstChildOfClass("Humanoid") or nil
end

local function plr_from_part(part)
    if not part then return nil end
    local node = part
    local hops = 0
    while node and node ~= Workspace and node ~= game and hops < 12 do
        if node:IsA("Model") then
            local p = Players:GetPlayerFromCharacter(node)
            if p then return p end
        end
        node = node.Parent
        hops = hops + 1
    end
    return nil
end

local function install_hook()
    if hook_on then return true end
    if not f_hookmeta or not f_getrawmt then return false end

    local ok, err = pcall(function()
        local mt = f_getrawmt(game)
        if not mt then error("sem metatable") end
        orig_newindex = mt.__newindex
        if not orig_newindex then error("sem __newindex") end
        if f_setro then f_setro(mt, false) end

        local function handler(self, key, value)

            if self ~= Camera or key ~= "CFrame" or not desired_look then
                return orig_newindex(self, key, value)
            end
            local pos = CONFIG.PreservePos and value.Position
                                         or Camera.CFrame.Position
            return orig_newindex(self, key, CFrame.lookAt(pos, pos + desired_look))
        end

        if f_newc then mt.__newindex = f_newc(handler)
        else mt.__newindex = handler end
        if f_setro then f_setro(mt, true) end
    end)

    if ok then hook_on = true
    else warn("[LowHub] hook: " .. tostring(err)) end
    return hook_on
end

local function remove_hook()
    if not hook_on then return end
    pcall(function()
        local mt = f_getrawmt(game)
        if f_setro then f_setro(mt, false) end
        if orig_newindex then mt.__newindex = orig_newindex end
        if f_setro then f_setro(mt, true) end
    end)
    hook_on = false
    desired_look = nil
end

local function collect_targets()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if is_enemy(plr) and is_alive(plr) then
            local part = get_aim_part(plr)
            if part then
                list[#list + 1] = { plr = plr, part = part }
            end
        end
    end
    return list
end

local function score_of(part, cam_pos, look)
    local delta = part.Position - cam_pos
    local dist  = delta.Magnitude
    if dist < 0.1 or dist > CONFIG.AimMaxDist then return nil end
    local dot = delta.Unit:Dot(look)
    if dot < math.cos(math.rad(AIM_TUNE.FOVdeg)) then return nil end
    local angle = math.deg(math.acos(math.clamp(dot, -1, 1)))
    return angle + (dist * AIM_TUNE.DistWeight)
end

local function target_valid(part)
    if not part or not part.Parent then return false end
    local plr = plr_from_part(part)
    if not plr then return false end
    return is_enemy(plr) and is_alive(plr)
end

local function acquire()
    local cam_pos = Camera.CFrame.Position
    local look    = Camera.CFrame.LookVector
    local best, best_plr, best_score = nil, nil, math.huge
    for _, t in ipairs(collect_targets()) do
        local sc = score_of(t.part, cam_pos, look)
        if sc and sc < best_score then
            best, best_plr, best_score = t.part, t.plr, sc
        end
    end
    return best, best_plr
end

local wall_params = nil
do
    local ok, rp = pcall(function()
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        p.IgnoreWater = true
        return p
    end)
    if ok and rp then wall_params = rp end
end

local function tem_parede(from_pos, target_part)
    if not CONFIG.WallCheck then return false end
    if not wall_params then return false end
    if not target_part or not target_part.Parent then return false end

    local dir = target_part.Position - from_pos
    local dist = dir.Magnitude
    if dist < 1 then return false end


    local ignorar = {}
    local meu = LP and LP.Character
    if meu then ignorar[#ignorar + 1] = meu end
    if target_part.Parent then ignorar[#ignorar + 1] = target_part.Parent end
    wall_params.FilterDescendantsInstances = ignorar

    local ok, hit = pcall(function()
        return Workspace:Raycast(from_pos,
            dir.Unit * (dist - 0.5), wall_params)
    end)



    if not ok then return false end
    return hit ~= nil
end

local function alvo_na_mira()
    if not Camera then return nil end
    local cam  = Camera.CFrame
    local pos  = cam.Position
    local look = cam.LookVector
    local melhor, melhor_pos, melhor_plr = nil, nil, nil
    local melhor_ang = CONFIG.FireCone

    for _, t in ipairs(collect_targets()) do
        local p = t.part
        if p and p.Parent then
            local d = p.Position - pos
            local dist = d.Magnitude
            if dist > 0.5 and dist <= CONFIG.AimMaxDist then
                local dot = math.clamp(d.Unit:Dot(look), -1, 1)
                local ang = math.deg(math.acos(dot))
                if ang <= melhor_ang then
                    if not tem_parede(pos, p) then
                        melhor_ang = ang
                        melhor     = p
                        melhor_pos = p.Position
                                   + Vector3.new(0, CONFIG.AimHeightOffset, 0)
                        melhor_plr = t.plr
                    end
                end
            end
        end
    end
    return melhor, melhor_pos, melhor_plr
end

local function get_equipped_tool()
    local char = LP.Character
    if not char then return nil end
    for _, v in ipairs(char:GetChildren()) do
        if v:IsA("Tool") then return v end
    end
    return nil
end

local function weapon_ready()
    local tool = get_equipped_tool()
    if not tool then return false, "sem arma", nil end
    if tool:GetAttribute("Reloading") == true then
        return false, "recarregando", tool
    end
    local cd = tool:GetAttribute("Cooldown")
    if type(cd) == "number" and cd > 0.01 then
        return false, string.format("cooldown %.2f", cd), tool
    end
    local ammo = tool:GetAttribute("Ammo")
    if type(ammo) == "number" and ammo <= 0 then
        return false, "sem municao", tool
    end
    local charges = tool:GetAttribute("Charges")
    if type(charges) == "number" and charges <= 0 then
        return false, "no charge", tool
    end
    return true, tool:GetAttribute("Category") or "?", tool
end

local function resolve_attack_mode()
    if VIM then
        local ok = pcall(function() return VIM.SendMouseButtonEvent end)
        if ok then attack_mode = "engine" return end
    end
    if f_mouse1 then attack_mode = "mouse1click" return end
    if f_mouse1down and f_mouse1up then attack_mode = "press/release" return end
    attack_mode = "Activate"
end

local function native_attack(tool)
    local now = os.clock()
    if now - last_shot_time < CONFIG.FireDelay then
        fire_state = "delay"
        return false
    end

    local ok = false

    if attack_mode == "engine" and VIM then
        ok = pcall(function()
            VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        end)
        if ok then
            task.wait(0.012)
            pcall(function()
                VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            end)
        end
    end

    if not ok and attack_mode == "mouse1click" and f_mouse1 then
        ok = pcall(function() f_mouse1() end)
    end

    if not ok and attack_mode == "press/release"
       and f_mouse1down and f_mouse1up then
        ok = pcall(function()
            f_mouse1down()
            task.wait(0.015)
            f_mouse1up()
        end)
    end

    if not ok then
        ok = pcall(function() tool:Activate() end)
    end

    if ok then
        last_shot_time = os.clock()
        shots_fired = shots_fired + 1
        fire_state = "atacou"
        return true
    else
        fire_state = "falhou"
        return false
    end
end

local function auto_fire_step(aim_pos, locked_part)
    if not CONFIG.AutoFire then
        fire_state = "desligado"
        return
    end



    if not should_act() then
        fire_state = "fora de partida"
        return
    end

    if CONFIG.FireOnlyLocked and not aim_active then
        fire_state = "sem trava"
        return
    end

    if not Camera then
        fire_state = "sem camera"
        return
    end


    local part, pos = locked_part, aim_pos



    if not part and CONFIG.FireOnSight then
        local p2, pos2, plr2 = alvo_na_mira()
        if p2 then
            part, pos = p2, pos2
            fire_sight_plr = plr2
        end
    end

    if not part or not pos then
        fire_sight_plr = nil
        fire_state = "sem alvo"
        return
    end

    local delta = pos - Camera.CFrame.Position
    if delta.Magnitude > CONFIG.AimMaxDist then
        fire_state = "longe"
        return
    end

    local dot = delta.Unit:Dot(Camera.CFrame.LookVector)
    local ang = math.deg(math.acos(math.clamp(dot, -1, 1)))
    if ang > CONFIG.FireCone then
        fire_state = string.format("%.1f° fora", ang)
        return
    end


    if tem_parede(Camera.CFrame.Position, part) then
        fire_state = "parede na frente"
        return
    end

    local ready, info, tool = weapon_ready()
    if not ready then
        fire_state = tostring(info)
        return
    end

    native_attack(tool)
end

local legit_phase   = 0
local legit_offset  = Vector3.zero
local legit_next_err = 0
local legit_hold    = 0
local legit_last    = nil
local legit_react   = 0
local legit_dead    = 0

local function legit_reset()
    legit_phase, legit_offset = 0, Vector3.zero
    legit_next_err, legit_hold = 0, 0
    legit_last, legit_react, legit_dead = nil, 0, 0
end

local function girar_limitado(from, to, max_rad)
    local dot = math.clamp(from:Dot(to), -1, 1)
    local ang = math.acos(dot)
    if ang <= max_rad then return to end

    local t = max_rad / ang
    local axis = from:Cross(to)
    if axis.Magnitude < 1e-6 then return to end
    axis = axis.Unit

    local a = t * ang
    local c, s = math.cos(a), math.sin(a)
    return (from * c + axis:Cross(from) * s + axis * (axis:Dot(from)) * (1 - c)).Unit
end

local function legit_aim(cam_look, goal_look, dt, now)

    legit_react = legit_react + dt
    if legit_react < CONFIG.LegitReaction then
        return cam_look
    end



    legit_phase = legit_phase + dt
    local jr = math.rad(CONFIG.LegitJitter)
    local jx = math.sin(legit_phase * 7.3) * jr
    local jy = math.cos(legit_phase * 5.1) * jr * 0.7


    if now >= legit_next_err then
        legit_next_err = now + 0.35 + math.random() * 0.4
        local er = math.rad(CONFIG.LegitError)
        legit_offset = Vector3.new(
            (math.random() * 2 - 1) * er,
            (math.random() * 2 - 1) * er * 0.8,
            (math.random() * 2 - 1) * er
        )
    end


    local right = cam_look:Cross(Vector3.new(0, 1, 0))
    if right.Magnitude < 1e-4 then right = Vector3.new(1, 0, 0) end
    right = right.Unit
    local up = right:Cross(cam_look).Unit

    local goal = (goal_look
                  + right * (jx + legit_offset.X)
                  + up    * (jy + legit_offset.Y)
                  + cam_look * legit_offset.Z).Unit


    if CONFIG.LegitOvershoot then
        local dot = math.clamp(cam_look:Dot(goal), -1, 1)
        local ang = math.deg(math.acos(dot))
        if ang > 0.6 then
            legit_dead = 0
        end
        if legit_dead < 0.18 then
            goal = girar_limitado(cam_look, goal, math.rad(3.0))
            local novo = math.deg(math.acos(math.clamp(cam_look:Dot(goal), -1, 1)))
            if novo < 0.35 then legit_dead = legit_dead + dt end
        end
    end


    local max_rad = math.rad(CONFIG.LegitSpeed) * dt
    return girar_limitado(cam_look, goal, max_rad)
end

local function centro_da_tela()
    local cam = Camera
    if not cam then return nil, nil end
    local vs = cam.ViewportSize
    if not vs then return nil, nil end
    local ok, inset = pcall(function()
        return game:GetService("GuiService"):GetGuiInset()
    end)
    local off = (ok and inset and inset.Y) or 0
    return vs.X / 2, (vs.Y / 2) + off
end

local function mirar_com_mouse(goal_look)
    if MOUSE_MODE == "camera" then return false end

    local cam = Camera
    if not cam then return false end


    local pos = cam.CFrame.Position
    local alvo3d = pos + goal_look * 100
    local ok, sp = pcall(function()
        return cam:WorldToViewportPoint(alvo3d)
    end)
    if not ok or not sp then return false end

    local cx, cy = centro_da_tela()
    if not cx then return false end


    local dx = sp.X - cx
    local dy = sp.Y - cy



    if math.abs(dx) < 1 and math.abs(dy) < 1 then return true end



    local mx = (dx >= 0) and math.floor(dx + 0.5) or math.ceil(dx - 0.5)
    local my = (dy >= 0) and math.floor(dy + 0.5) or math.ceil(dy - 0.5)

    if mx == 0 and my == 0 then return true end

    pcall(function()
        if MOUSE_MODE == "rel" then
            f_mouserel(mx, my)
        else

            f_mouseabs(cx + mx, cy + my)
        end
    end)
    return true
end

local function aim_step()
    aim_execs = aim_execs + 1
    desired_look = nil

    if not CONFIG.AimLockEnabled or not aim_active then
        locked_target = nil
        locked_plr    = nil
        legit_reset()
        return
    end

    if not should_act() then
        locked_target = nil
        locked_plr = nil
        fire_state = "fora de partida"
        legit_reset()
        return
    end

    local now = os.clock()
    local dt  = math.clamp(now - last_aim_time, 1/240, 0.10)
    last_aim_time = now

    if locked_target and not target_valid(locked_target) then
        locked_target = nil
        locked_plr    = nil
    end

    if not locked_target then
        local new, newplr = acquire()
        if new then
            locked_target = new
            locked_plr    = newplr
            swap_count    = swap_count + 1
            legit_react   = 0
        else


            if CONFIG.AimMode == "legit" and legit_last
               and legit_hold > 0 then
                legit_hold = legit_hold - dt
                local cam = Camera.CFrame
                local alvo = legit_aim(cam.LookVector, legit_last, dt, now)
                if CONFIG.HookCamera and hook_on then
                    desired_look = alvo
                    mira_modo = "hook"
                elseif mirar_com_mouse(alvo) then
                    mira_modo = MOUSE_MODE == "rel" and "mouse" or "mouse-abs"
                else
                    Camera.CFrame = CFrame.lookAt(cam.Position, cam.Position + alvo)
                    mira_modo = "camera"
                end
                fire_state = "seguindo ultimo"
                return
            end
            fire_state = "sem alvo"
            return
        end
    end

    if not locked_target or not locked_target.Parent then return end

    local aim_pos = locked_target.Position + Vector3.new(0, CONFIG.AimHeightOffset, 0)

    local okv, vel = pcall(function() return locked_target.AssemblyLinearVelocity end)
    if okv and vel and AIM_TUNE.Prediction > 0 then
        aim_pos = aim_pos + vel * AIM_TUNE.Prediction
    end

    local cam  = Camera.CFrame
    local from = cam.Position
    local to_target = aim_pos - from
    if to_target.Magnitude < 0.1 then return end

    local goal_look = to_target.Unit
    legit_last = goal_look
    legit_hold = CONFIG.LegitLostKeep

    if CONFIG.AimMode == "legit" then

        goal_look = legit_aim(cam.LookVector, goal_look, dt, now)
    else

        if CONFIG.AimSmoothLock then
            local rate = 1 - math.exp(-24 * dt)
            rate = math.clamp(rate, 0.35, 0.95)
            goal_look = cam.LookVector:Lerp(goal_look, rate).Unit
        end
    end


    if CONFIG.HookCamera and hook_on then
        desired_look = goal_look
        mira_modo = "hook"
    elseif mirar_com_mouse(goal_look) then
        mira_modo = MOUSE_MODE == "rel" and "mouse" or "mouse-abs"
    else
        Camera.CFrame = CFrame.lookAt(from, from + goal_look)
        mira_modo = "camera"
    end

    if CONFIG.AutoFire then
        auto_fire_step(aim_pos, locked_target)
    else
        fire_state = "desligado"
    end
end

local function start_subject_cutter()
    if subject_cutter_on then return end
    subject_cutter_on = true

    pcall(function()
        if Camera.CameraSubject then saved_subject = Camera.CameraSubject end
        Camera.CameraSubject = nil
        Camera.CameraType = Enum.CameraType.Scriptable
    end)

    task.spawn(function()
        while running and subject_cutter_on do
            if CONFIG.CutSubject then
                pcall(function()
                    if Camera.CameraSubject ~= nil then
                        if not saved_subject then
                            saved_subject = Camera.CameraSubject
                        end
                        Camera.CameraSubject = nil
                    end
                    if Camera.CameraType ~= Enum.CameraType.Scriptable then
                        Camera.CameraType = Enum.CameraType.Scriptable
                    end
                end)
            end
            task.wait()
        end
    end)
end

local function stop_subject_cutter()
    subject_cutter_on = false
    pcall(function()
        local hum = get_humanoid(LP)
        if hum then Camera.CameraSubject = hum
        elseif saved_subject then Camera.CameraSubject = saved_subject end
    end)
end

local function start_delta_killer()
    if delta_killer_on then return end
    delta_killer_on = true
    task.spawn(function()
        while running and delta_killer_on do
            if CONFIG.MouseLock and should_act() then
                pcall(function()
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                end)
            end
            task.wait()
        end
    end)
end

local function apply_mouse_lock()
    if not CONFIG.MouseLock then return end
    pcall(function()
        UserInputService.MouseBehavior = should_act()
            and Enum.MouseBehavior.LockCenter
            or  orig_mouse
    end)
end

local function start_aim()
    pcall(function() RunService:UnbindFromRenderStep("z_aim") end)
    pcall(function()
        RunService:BindToRenderStep("z_aim", 2000, aim_step)
    end)
    if CONFIG.HookCamera then install_hook() end
    start_delta_killer()
    if CONFIG.CutSubject then start_subject_cutter() end
end

local function stop_aim()
    pcall(function() RunService:UnbindFromRenderStep("z_aim") end)
    remove_hook()
    stop_subject_cutter()
    locked_target = nil
    locked_plr = nil
end

local function build_fov_circle()
    if not parent_ok(PARENT) then PARENT, PARENT_KIND = resolve_parent() end
    local old = PARENT:FindFirstChild("Z_fov")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "Z_fov"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483000
    gui.Parent = PARENT

    local circle = Instance.new("Frame")
    circle.BackgroundTransparency = 1
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.Size = UDim2.new(0, 200, 0, 200)
    circle.Parent = gui
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0); c.Parent = circle
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(218, 105, 157)
    st.Thickness = 1.5
    st.Transparency = 0.35
    st.Parent = circle

    local cross = Instance.new("Frame")
    cross.Size = UDim2.new(0, 10, 0, 1)
    cross.Position = UDim2.new(0.5, -5, 0.5, 0)
    cross.BackgroundColor3 = Color3.fromRGB(218, 105, 157)
    cross.BackgroundTransparency = 0.3
    cross.BorderSizePixel = 0
    cross.Parent = gui

    local cross2 = Instance.new("Frame")
    cross2.Size = UDim2.new(0, 1, 0, 10)
    cross2.Position = UDim2.new(0.5, 0, 0.5, -5)
    cross2.BackgroundColor3 = Color3.fromRGB(218, 105, 157)
    cross2.BackgroundTransparency = 0.3
    cross2.BorderSizePixel = 0
    cross2.Parent = gui

    fov_gui = gui
    fov_circle = circle
end

local function update_fov_circle()
    if not fov_circle or not fov_circle.Parent then return end
    if not CONFIG.ShowFOVCircle or not CONFIG.AimLockEnabled or not should_act() then
        fov_gui.Enabled = false
        return
    end
    fov_gui.Enabled = true

    local vp = Camera.ViewportSize
    local focal = (vp.Y * 0.5) / math.tan(math.rad(Camera.FieldOfView * 0.5))
    local radius = math.tan(math.rad(AIM_TUNE.FOVdeg)) * focal
    radius = math.clamp(radius, 20, math.min(vp.X, vp.Y) * 0.48)
    fov_circle.Size = UDim2.new(0, radius * 2, 0, radius * 2)

    local st = fov_circle:FindFirstChildOfClass("UIStroke")
    if st then
        local locked = locked_target ~= nil
        st.Color = locked and Color3.fromRGB(255, 80, 80)
                            or Color3.fromRGB(218, 105, 157)
        st.Transparency = locked and 0.1 or 0.45
    end
end

local function make_esp(plr, color)
    local char = plr.Character
    if not char then return end
    local root = get_root(plr)
    if not root then return end

    local hl = Instance.new("Highlight")
    hl.Name = "Z_hl"; hl.Adornee = char
    hl.FillColor = color; hl.FillTransparency = 0.6
    hl.OutlineColor = color; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char

    local bb = Instance.new("BillboardGui")
    bb.Name = "Z_bb"; bb.Adornee = root
    bb.Size = UDim2.new(0, 220, 0, 44)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = CONFIG.ESPMaxDistance

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.TextColor3 = color
    txt.TextStrokeTransparency = 0
    txt.TextStrokeColor3 = Color3.new(0, 0, 0)
    txt.Font = Enum.Font.GothamSemibold
    txt.TextSize = 14
    txt.Text = plr.Name
    txt.Parent = bb
    bb.Parent = char

    esp_cache[plr] = { highlight = hl, billboard = bb, label = txt, adornee = char }
end

local function remove_esp(plr)
    local e = esp_cache[plr]
    if e then
        pcall(function() e.highlight:Destroy() end)
        pcall(function() e.billboard:Destroy() end)
        esp_cache[plr] = nil
    end
end

local function refresh_esp()
    if not CONFIG.ESPEnabled or not should_act() then
        for plr in pairs(esp_cache) do remove_esp(plr) end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local enemy = is_enemy(plr)
            local ally  = is_ally(plr)
            if (enemy or ally) and is_alive(plr) and plr.Character then
                local e = esp_cache[plr]
                if not e or e.adornee ~= plr.Character then
                    remove_esp(plr)
                    make_esp(plr, enemy and CONFIG.ESPColorEnemy or CONFIG.ESPColorAlly)
                end
            else
                remove_esp(plr)
            end
        end
    end
end

local function update_esp_labels()
    local my_root = get_root(LP)
    if not my_root then return end
    for plr, e in pairs(esp_cache) do
        local root = get_root(plr)
        if root and e.label and e.billboard then
            local bits = {}
            if CONFIG.ESPShowName then bits[#bits+1] = plr.Name end
            if CONFIG.ESPShowHealth then
                local hum = get_humanoid(plr)
                bits[#bits+1] = tostring(hum and math.floor(hum.Health) or 0) .. "hp"
            end
            if CONFIG.ESPShowDist then
                bits[#bits+1] = math.floor((root.Position - my_root.Position).Magnitude) .. "m"
            end
            e.label.Text = table.concat(bits, "  ·  ")
            e.billboard.MaxDistance = CONFIG.ESPMaxDistance
        end
    end
end

local orig_walk_captured = false

local orig_walk_hum      = nil

local function apply_speed()
    local hum = get_humanoid(LP)
    if not hum then
        speed_state = "sem personagem"
        orig_walk_captured = false
        return
    end





    if hum ~= orig_walk_hum then
        orig_walk_hum      = hum
        orig_walk_captured = false
    end

    if not orig_walk_captured then
        orig_walk = hum.WalkSpeed
        orig_walk_captured = true
    end

    if not CONFIG.SpeedEnabled then
        speed_state = "desligado"
        if hum.WalkSpeed ~= orig_walk then
            pcall(function() hum.WalkSpeed = orig_walk end)
        end
        return
    end






    local want = CONFIG.SpeedValue
    pcall(function()
        if hum.WalkSpeed ~= want then hum.WalkSpeed = want end
    end)
    speed_state = "ativo (" .. string.format("%.0f", want) .. ")"
end

local fly_hum    = nil
local fly_att    = nil
local fly_vel    = nil
local fly_gyro   = nil
local fly_state  = "desligado"

local function stop_fly()
    local root = get_root(LP)
    if root then
        for _, n in ipairs({ "Z_flyVel", "Z_flyOrient", "Z_flyAtt" }) do
            local o = root:FindFirstChild(n)
            if o then pcall(function() o:Destroy() end) end
        end
    end
    if fly_hum then
        pcall(function()
            fly_hum.PlatformStand = false
            fly_hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    fly_hum, fly_att, fly_vel, fly_gyro = nil, nil, nil, nil
    fly_state = "desligado"
end

local function start_fly()
    local root = get_root(LP)
    if not root then fly_state = "sem root"; return end
    if fly_vel then return end


    for _, n in ipairs({ "Z_flyVel", "Z_flyOrient", "Z_flyAtt" }) do
        local o = root:FindFirstChild(n)
        if o then pcall(function() o:Destroy() end) end
    end

    local att = Instance.new("Attachment")
    att.Name = "Z_flyAtt"
    att.Parent = root



    local lv = Instance.new("LinearVelocity")
    lv.Name = "Z_flyVel"
    lv.Attachment0 = att
    lv.MaxForce = 1e5
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.VectorVelocity = Vector3.zero
    lv.Parent = root


    local ao = Instance.new("AlignOrientation")
    ao.Name = "Z_flyOrient"
    ao.Attachment0 = att
    ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
    ao.MaxTorque = 1e5
    ao.Responsiveness = 40
    ao.CFrame = root.CFrame
    ao.Parent = root

    fly_att, fly_vel, fly_gyro = att, lv, ao
    fly_state = "ligado"

    local hum = get_humanoid(LP)
    if hum then
        fly_hum = hum
        pcall(function() hum.PlatformStand = true end)
    end
end

local function update_fly()
    if not CONFIG.FlyEnabled then
        if fly_vel or fly_hum then stop_fly() end
        return
    end

    local root = get_root(LP)
    if not root then
        fly_state = "sem root"
        return
    end


    if not fly_vel or not fly_vel.Parent or not fly_att or not fly_att.Parent then
        fly_vel, fly_att, fly_gyro, fly_hum = nil, nil, nil, nil
        start_fly()
        if not fly_vel then return end
    end



    local hum = get_humanoid(LP)
    if hum then
        fly_hum = hum
        if not hum.PlatformStand then
            pcall(function() hum.PlatformStand = true end)
        end
    end

    local cam = Camera.CFrame
    local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end

    local spd = CONFIG.FlySpeed
    if dir.Magnitude > 0 then
        fly_vel.VectorVelocity = dir.Unit * spd
        fly_state = "voando"
    else
        fly_vel.VectorVelocity = Vector3.zero
        fly_state = "parado"
    end


    if fly_gyro then
        fly_gyro.CFrame = CFrame.new(root.Position, root.Position + cam.LookVector)
    end
end

local T = {



    bg      = Color3.fromRGB(11, 10, 14),
    header  = Color3.fromRGB(17, 15, 21),
    sidebar = Color3.fromRGB(13, 12, 17),
    card    = Color3.fromRGB(24, 21, 30),
    card2   = Color3.fromRGB(33, 29, 41),
    card3   = Color3.fromRGB(44, 38, 54),
    line    = Color3.fromRGB(58, 50, 70),
    text    = Color3.fromRGB(246, 243, 249),
    dim     = Color3.fromRGB(163, 155, 176),
    faint   = Color3.fromRGB(112, 104, 126),
    accent  = Color3.fromRGB(226, 88, 148),
    accentD = Color3.fromRGB(88, 30, 60),
    accent2 = Color3.fromRGB(255, 128, 178),
    accent2D= Color3.fromRGB(96, 40, 68),
    off     = Color3.fromRGB(30, 26, 37),
    warn    = Color3.fromRGB(240, 180, 120),
    bad     = Color3.fromRGB(240, 96, 126),
    good    = Color3.fromRGB(110, 214, 158),
}

local FB = Enum.Font.GothamBold
local F  = Enum.Font.Gotham
local FM = Enum.Font.Code

local function avatar_url(user_id, size)
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. tostring(user_id) .. "&width=" .. tostring(size)
        .. "&height=" .. tostring(size) .. "&format=png"
end

local function baixar_avatar()
    local uid = LP and LP.UserId
    if not uid or uid <= 0 then return nil end
    if type(game.HttpGet) ~= "function" then return nil end

    local tentativas = {
        avatar_url(uid, 150),
        "https://www.roblox.com/headshot-thumbnail/image?userId="
            .. tostring(uid) .. "&width=150&height=150&format=png",
    }
    for _, url in ipairs(tentativas) do
        local ok, data = pcall(function() return game:HttpGet(url, true) end)
        if ok and type(data) == "string" and #data > 64 then
            return data
        end
    end
    return nil
end

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8); c.Parent = p
    return c
end

local function stroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or T.line
    s.Thickness = th or 1
    s.Transparency = tr or 0.4
    s.Parent = p
    return s
end

local PRESETS_FILE = "presets.txt"
local presets      = {}
local preset_names = {}
local presetDrop   = nil
local disco_ok     = true

local function valor_para_texto(v)
    local t = type(v)
    if t == "boolean" then return v and "true" or "false" end
    if t == "number"  then return string.format("%.6g", v) end
    if t == "string"  then return v end

    if t == "userdata" or t == "table" then
        local ok, r = pcall(function() return v.R end)
        local ok2, g = pcall(function() return v.G end)
        local ok3, b = pcall(function() return v.B end)
        if ok and ok2 and ok3 and type(r) == "number" then
            return "cor:" .. math.floor(r * 255 + 0.5) .. ","
                          .. math.floor(g * 255 + 0.5) .. ","
                          .. math.floor(b * 255 + 0.5)
        end
    end
    return nil
end

local function texto_para_valor(txt, modelo)
    local t = type(modelo)
    if t == "boolean" then return txt == "true" end
    if t == "number"  then return tonumber(txt) end
    if t == "string"  then return txt end
    if t == "userdata" or t == "table" then
        local r, g, b = txt:match("^cor:(%d+),(%d+),(%d+)$")
        if r then
            local ok, c = pcall(function()
                return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b))
            end)
            if ok then return c end
        end
    end
    return nil
end

local function capturar_config()
    local out = {}
    for k, v in pairs(CONFIG) do
        local txt = valor_para_texto(v)
        if txt ~= nil then out[k] = txt end
    end
    for k, v in pairs(AIM_TUNE) do
        local txt = valor_para_texto(v)
        if txt ~= nil then out["AIM_" .. k] = txt end
    end
    return out
end

local function aplicar_config(tabela)
    local n = 0
    for k, txt in pairs(tabela) do
        local alvo, chave = CONFIG, k
        if string.sub(k, 1, 4) == "AIM_" then
            alvo, chave = AIM_TUNE, string.sub(k, 5)
        end
        local atual = alvo[chave]
        if atual ~= nil then
            local v = texto_para_valor(txt, atual)
            if v ~= nil then
                alvo[chave] = v
                n = n + 1
            end
        end
    end

    pcall(function()
        if CONFIG.HookCamera then install_hook() else remove_hook() end
    end)
    pcall(function()
        if CONFIG.FlyEnabled then start_fly() else stop_fly() end
    end)
    orig_walk_captured = false
    pcall(legit_reset)
    return n
end

local function salvar_presets_em_disco()
    local out = {}
    for _, nome in ipairs(preset_names) do
        local p = presets[nome]
        if p then
            local linhas = { "[preset]" .. nome }
            for k, v in pairs(p) do
                linhas[#linhas + 1] = k .. "=" .. tostring(v)
            end
            out[#out + 1] = table.concat(linhas, "\n")
        end
    end
    local txt = table.concat(out, "\n\n")
    if not salvar_arquivo(PRESETS_FILE, txt) then
        disco_ok = false
    end
end

local function carregar_presets_do_disco()
    local txt = ler_arquivo(PRESETS_FILE)
    if type(txt) ~= "string" or #txt == 0 then return end

    local atual = nil
    for linha in string.gmatch(txt .. "\n", "([^\n]*)\n") do
        local nome = linha:match("^%[preset%](.+)$")
        if nome then
            nome = nome:gsub("^%s+", ""):gsub("%s+$", "")
            if #nome > 0 and #nome <= 20 and not presets[nome] then
                atual = {}
                presets[nome] = atual
                preset_names[#preset_names + 1] = nome
            else
                atual = nil
            end
        elseif atual then
            local k, v = linha:match("^([%w_]+)=(.*)$")
            if k then atual[k] = v end
        end
    end
end

local function apagar_preset(nome)
    if not presets[nome] then return false end
    presets[nome] = nil
    for i, n in ipairs(preset_names) do
        if n == nome then table.remove(preset_names, i) break end
    end
    salvar_presets_em_disco()
    return true
end

local function build_gui()
    if not parent_ok(PARENT) then PARENT, PARENT_KIND = resolve_parent() end
    local old = PARENT:FindFirstChild("LowHub")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "LowHub"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PARENT

    local W, H = 660, 500









    local function centro_tela(larg, alt)
        local vx, vy = 1280, 720
        pcall(function()
            local cam = Workspace.CurrentCamera
            if cam then
                local vp = cam.ViewportSize
                if vp and vp.X > 100 and vp.Y > 100 then
                    vx, vy = vp.X, vp.Y
                end
            end
        end)
        local x = math.floor((vx - larg) / 2)
        local y = math.floor((vy - alt) / 2)
        if x < 0 then x = 0 end
        if y < 0 then y = 0 end
        return UDim2.new(0, x, 0, y)
    end

    local root = Instance.new("Frame")
    root.Name = "Root"
    root.Size = UDim2.new(0, W, 0, H)
    root.Position = centro_tela(W, H)
    root.BackgroundColor3 = T.bg
    root.BorderSizePixel = 0
    root.Active = true
    root.Draggable = true
    root.ClipsDescendants = true
    root.Parent = gui
    corner(root, 14)
    stroke(root, T.line, 1, 0.18)
    local rootGradient = Instance.new("UIGradient")
    rootGradient.Rotation = 28
    rootGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 13, 23)),
        ColorSequenceKeypoint.new(1, T.bg),
    })
    rootGradient.Parent = root



    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 64)
    header.BackgroundColor3 = T.header
    header.BorderSizePixel = 0
    header.Parent = root


    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 0, 0, 2)
    glow.BackgroundColor3 = T.accent
    glow.BorderSizePixel = 0
    glow.BackgroundTransparency = 0.35
    glow.Parent = header

    local hl = Instance.new("Frame")
    hl.Size = UDim2.new(1, 0, 0, 1)
    hl.Position = UDim2.new(0, 0, 1, -1)
    hl.BackgroundColor3 = T.line
    hl.BorderSizePixel = 0
    hl.Parent = header




    local aSize = 44
    local avFrame = Instance.new("Frame")
    avFrame.Name = "Avatar"
    avFrame.Size = UDim2.new(0, aSize, 0, aSize)
    avFrame.Position = UDim2.new(0, 16, 0.5, -aSize/2)
    avFrame.BackgroundColor3 = T.card2
    avFrame.BorderSizePixel = 0
    avFrame.Parent = header
    corner(avFrame, aSize/2)
    local avStroke = stroke(avFrame, T.accent, 1.5, 0.25)

    local avImg = Instance.new("ImageLabel")
    avImg.Name = "AvatarImg"
    avImg.Size = UDim2.new(1, -4, 1, -4)
    avImg.Position = UDim2.new(0, 2, 0, 2)
    avImg.BackgroundTransparency = 1
    avImg.Image = ""
    avImg.Parent = avFrame
    corner(avImg, (aSize - 4)/2)

    local avLetter = Instance.new("TextLabel")
    avLetter.Size = UDim2.new(1, 0, 1, 0)
    avLetter.BackgroundTransparency = 1
    avLetter.Text = string.upper(string.sub(LP.Name, 1, 1))
    avLetter.TextColor3 = T.accent
    avLetter.Font = FB
    avLetter.TextSize = 18
    avLetter.Parent = avFrame

    task.spawn(function()
        local data = baixar_avatar()
        if data then

            local ok = pcall(function()
                local id = "rbxassetid://0"
                if type(getcustomasset) == "function" then
                    id = getcustomasset(data)
                elseif type(getsynasset) == "function" then
                    id = getsynasset(data)
                end
                avImg.Image = id
                avLetter.Visible = false
            end)
            if not ok then


                pcall(function()
                    avImg.Image = avatar_url(LP.UserId, 150)
                    avLetter.Visible = false
                end)
            end
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -220, 0, 20)
    title.Position = UDim2.new(0, 72, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "LOWHUB"
    title.TextColor3 = T.text
    title.Font = FB
    title.TextSize = 17
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header


    local vpill = Instance.new("TextLabel")
    vpill.Size = UDim2.new(0, 44, 0, 16)
    vpill.Position = UDim2.new(0, 146, 0, 14)
    vpill.BackgroundColor3 = T.accentD
    vpill.BorderSizePixel = 0
    vpill.Text = VERSION
    vpill.TextColor3 = T.accent
    vpill.Font = FB
    vpill.TextSize = 10
    vpill.Parent = header
    corner(vpill, 8)

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -220, 0, 16)
    sub.Position = UDim2.new(0, 72, 0, 33)
    sub.BackgroundTransparency = 1
    sub.Text = LP.Name .. "   ·   " .. PARENT_KIND
    sub.TextColor3 = T.dim
    sub.Font = F
    sub.TextSize = 11
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    sub.Parent = header

    local mini = Instance.new("TextButton")
    mini.Name = "Minimize"
    mini.Size = UDim2.new(0, 30, 0, 30)
    mini.Position = UDim2.new(1, -42, 0.5, -15)
    mini.BackgroundColor3 = T.off
    mini.BorderSizePixel = 0
    mini.Text = "–"
    mini.TextColor3 = T.dim
    mini.Font = FB
    mini.TextSize = 16
    mini.AutoButtonColor = false
    mini.Parent = header
    corner(mini, 9)

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -78, 0.5, -15)
    close.BackgroundColor3 = T.off
    close.BorderSizePixel = 0
    close.Text = "×"
    close.TextColor3 = T.dim
    close.Font = FB
    close.TextSize = 17
    close.AutoButtonColor = false
    close.Parent = header
    corner(close, 9)


    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 164, 1, -88)
    sidebar.Position = UDim2.new(0, 0, 0, 64)
    sidebar.BackgroundColor3 = T.sidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = root

    local sl = Instance.new("Frame")
    sl.Size = UDim2.new(0, 1, 1, 0)
    sl.Position = UDim2.new(1, -1, 0, 0)
    sl.BackgroundColor3 = T.line
    sl.BorderSizePixel = 0
    sl.Parent = sidebar

    local tabList = Instance.new("Frame")
    tabList.Size = UDim2.new(1, 0, 1, -34)
    tabList.Position = UDim2.new(0, 0, 0, 10)
    tabList.BackgroundTransparency = 1
    tabList.Parent = sidebar

    local tlay = Instance.new("UIListLayout")
    tlay.Padding = UDim.new(0, 4)
    tlay.SortOrder = Enum.SortOrder.LayoutOrder
    tlay.Parent = tabList

    local foot = Instance.new("TextLabel")
    foot.Size = UDim2.new(1, -20, 0, 14)
    foot.Position = UDim2.new(0, 10, 1, -24)
    foot.BackgroundTransparency = 1
    foot.Text = VERSION .. "  ·  RightShift to hide"
    foot.TextColor3 = T.dim
    foot.Font = FM
    foot.TextSize = 10
    foot.TextXAlignment = Enum.TextXAlignment.Left
    foot.Parent = sidebar


    local pages = Instance.new("Frame")
    pages.Size = UDim2.new(1, -165, 1, -88)
    pages.Position = UDim2.new(0, 165, 0, 64)
    pages.BackgroundColor3 = T.bg
    pages.BorderSizePixel = 0
    pages.Parent = root






    local status = Instance.new("Frame")
    status.Size = UDim2.new(1, 0, 0, 30)
    status.Position = UDim2.new(0, 0, 1, -30)
    status.BackgroundColor3 = T.header
    status.BorderSizePixel = 0
    status.Parent = root

    local stl = Instance.new("Frame")
    stl.Size = UDim2.new(1, 0, 0, 1)
    stl.BackgroundColor3 = T.line
    stl.BorderSizePixel = 0
    stl.Parent = status


    local function chip(w, x)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(0, w, 0, 18)
        f.Position = UDim2.new(0, x, 0.5, -9)
        f.BackgroundColor3 = T.off
        f.BorderSizePixel = 0
        f.Parent = status
        corner(f, 9)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Position = UDim2.new(0, 7, 0.5, -3)
        dot.BackgroundColor3 = T.dim
        dot.BorderSizePixel = 0
        dot.Parent = f
        corner(dot, 3)

        local tx = Instance.new("TextLabel")
        tx.Size = UDim2.new(1, -18, 1, 0)
        tx.Position = UDim2.new(0, 16, 0, 0)
        tx.BackgroundTransparency = 1
        tx.Text = ""
        tx.TextColor3 = T.dim
        tx.Font = F
        tx.TextSize = 10
        tx.TextXAlignment = Enum.TextXAlignment.Left
        tx.TextTruncate = Enum.TextTruncate.AtEnd
        tx.Parent = f
        return tx, dot
    end


    local chipState, chipStateDot = chip(150, 12)
    local chipAim,   chipAimDot   = chip(250, 170)
    local chipCount               = chip(190, 428)




    local TabStore, TabOrder, ActiveTab = {}, {}, nil

    local function select_tab(name)
        for n, t in pairs(TabStore) do
            local on = (n == name)
            t.page.Visible = on
            t.label.TextColor3 = on and T.text or T.dim
            t.label.Font = on and FB or F
            t.marker.Visible = on
            t.btn.BackgroundTransparency = on and 0.55 or 1
            t.btn.BackgroundColor3 = on and T.card or T.sidebar
        end
        ActiveTab = name
    end

    local function new_tab(name)
        if TabStore[name] then return TabStore[name] end
        local idx = #TabOrder + 1
        TabOrder[idx] = name

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundTransparency = 1
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.LayoutOrder = idx
        btn.Parent = tabList

        local marker = Instance.new("Frame")
        marker.Size = UDim2.new(0, 3, 0, 18)
        marker.Position = UDim2.new(0, 0, 0.5, -9)
        marker.BackgroundColor3 = T.accent
        marker.BorderSizePixel = 0
        marker.Visible = false
        marker.Parent = btn
        corner(marker, 2)

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 1, 0)
        label.Position = UDim2.new(0, 20, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = name
        label.TextColor3 = T.dim
        label.Font = F
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = btn

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = T.line
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = pages

        local pl = Instance.new("UIListLayout")
        pl.Padding = UDim.new(0, 8)
        pl.SortOrder = Enum.SortOrder.LayoutOrder
        pl.Parent = page

        local pp = Instance.new("UIPadding")
        pp.PaddingLeft = UDim.new(0, 12)
        pp.PaddingRight = UDim.new(0, 12)
        pp.PaddingTop = UDim.new(0, 12)
        pp.PaddingBottom = UDim.new(0, 12)
        pp.Parent = page

        btn.MouseEnter:Connect(function()
            if ActiveTab ~= name then
                btn.BackgroundTransparency = 0.7
                btn.BackgroundColor3 = T.card
            end
        end)
        btn.MouseLeave:Connect(function()
            if ActiveTab ~= name then
                btn.BackgroundTransparency = 1
            end
        end)
        btn.MouseButton1Click:Connect(function() select_tab(name) end)

        local tab = { name = name, page = page, label = label,
                      btn = btn, marker = marker, _o = 0 }
        TabStore[name] = tab
        if not ActiveTab then select_tab(name) end
        return tab
    end




    local function new_section(tab, title)
        local wrap = Instance.new("Frame")
        wrap.Size = UDim2.new(1, 0, 0, 34)
        wrap.AutomaticSize = Enum.AutomaticSize.Y
        wrap.BackgroundColor3 = T.card
        wrap.BorderSizePixel = 0
        wrap.LayoutOrder = tab._o + 1
        tab._o = tab._o + 1
        wrap.Parent = tab.page
        corner(wrap, 10)
        local wStroke = stroke(wrap, T.line, 1, 0.6)


        local head = Instance.new("TextButton")
        head.Name = "Head"
        head.Size = UDim2.new(1, 0, 0, 34)
        head.BackgroundTransparency = 1
        head.Text = ""
        head.AutoButtonColor = false
        head.Parent = wrap


        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 0, 14)
        bar.Position = UDim2.new(0, 13, 0.5, -7)
        bar.BackgroundColor3 = T.accent2
        bar.BorderSizePixel = 0
        bar.Parent = head
        corner(bar, 2)

        local tl = Instance.new("TextLabel")
        tl.Size = UDim2.new(1, -60, 1, 0)
        tl.Position = UDim2.new(0, 24, 0, 0)
        tl.BackgroundTransparency = 1
        tl.Text = string.upper(title or "")
        tl.TextColor3 = T.text
        tl.Font = FB
        tl.TextSize = 10
        tl.TextXAlignment = Enum.TextXAlignment.Left
        tl.Parent = head


        local chev = Instance.new("TextLabel")
        chev.Size = UDim2.new(0, 20, 0, 20)
        chev.Position = UDim2.new(1, -30, 0.5, -10)
        chev.BackgroundTransparency = 1
        chev.Text = "v"
        chev.TextColor3 = T.dim
        chev.Font = FB
        chev.TextSize = 11
        chev.Parent = head


        local sep = Instance.new("Frame")
        sep.Size = UDim2.new(1, -24, 0, 1)
        sep.Position = UDim2.new(0, 12, 0, 33)
        sep.BackgroundColor3 = T.line
        sep.BorderSizePixel = 0
        sep.BackgroundTransparency = 0.4
        sep.Parent = wrap

        local inner = Instance.new("Frame")
        inner.Name = "Body"
        inner.Size = UDim2.new(1, 0, 0, 0)
        inner.Position = UDim2.new(0, 0, 0, 34)
        inner.BackgroundTransparency = 1
        inner.AutomaticSize = Enum.AutomaticSize.Y
        inner.Parent = wrap

        local il = Instance.new("UIListLayout")
        il.Padding = UDim.new(0, 1)
        il.SortOrder = Enum.SortOrder.LayoutOrder
        il.Parent = inner


        local tail = Instance.new("Frame")
        tail.Size = UDim2.new(1, 0, 0, 6)
        tail.BackgroundTransparency = 1
        tail.LayoutOrder = 9999
        tail.Parent = inner

        local s = { inner = inner, _o = 0, wrap = wrap, head = head,
                    open = true, chev = chev, bar = bar, stroke = wStroke,
                    sep = sep }


        function s:SetOpen(v)
            self.open = v
            inner.Visible = v
            tail.Visible = v
            sep.Visible = v
            chev.Text = v and "v" or ">"
            chev.TextColor3 = v and T.dim or T.accent
            bar.BackgroundColor3 = v and T.accent2 or T.line
            tl.TextColor3 = v and T.text or T.dim
            wStroke.Transparency = v and 0.6 or 0.85
        end

        head.MouseEnter:Connect(function()
            head.BackgroundTransparency = 0.85
            head.BackgroundColor3 = T.card2
            tl.TextColor3 = s.open and T.text or T.accent
        end)
        head.MouseLeave:Connect(function()
            head.BackgroundTransparency = 1
            tl.TextColor3 = T.text
        end)
        head.MouseButton1Click:Connect(function()
            s:SetOpen(not s.open)
        end)

        function s:row(label, h)
            self._o = self._o + 1
            local r = Instance.new("Frame")
            r.Size = UDim2.new(1, 0, 0, h or 34)
            r.BackgroundTransparency = 1
            r.LayoutOrder = self._o
            r.Parent = self.inner
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -136, 1, 0)
            t.Position = UDim2.new(0, 14, 0, 0)
            t.BackgroundTransparency = 1
            t.Text = label or ""
            t.TextColor3 = T.text
            t.Font = F
            t.TextSize = 13
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.Parent = r
            return r, t
        end
        function s:Toggle(props)
            local row = self:row(props.Label)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 38, 0, 20)
            b.Position = UDim2.new(1, -60, 0.5, -10)
            b.BackgroundColor3 = T.off
            b.BorderSizePixel = 0
            b.Text = ""
            b.AutoButtonColor = false
            b.Parent = row
            corner(b, 6)
            stroke(b, T.line, 1, 0.25)
            local k = Instance.new("Frame")
            k.Size = UDim2.new(0, 12, 0, 12)
            k.Position = UDim2.new(0, 4, 0.5, -6)
            k.BackgroundColor3 = T.dim
            k.BorderSizePixel = 0
            k.Parent = b
            corner(k, 4)
            local state = props.Default and true or false
            local function paint()
                b.BackgroundColor3 = state and T.accentD or T.off
                k.BackgroundColor3 = state and T.accent or T.dim
                k.Position = state and UDim2.new(1, -16, 0.5, -6)
                                   or UDim2.new(0, 4, 0.5, -6)
            end
            paint()
            local api = {}
            function api:Get() return state end
            function api:Set(v, silent)
                state = v and true or false
                paint()
                if not silent and props.Callback then props.Callback(state) end
            end
            b.MouseButton1Click:Connect(function()
                local novo = not state





                if props.Callback then
                    local r = props.Callback(novo)
                    if r == false then
                        paint()
                        return
                    end
                end
                state = novo
                paint()
            end)
            return api
        end


        function s:Slider(props)
            self._o = self._o + 1
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 44)
            holder.BackgroundTransparency = 1
            holder.LayoutOrder = self._o
            holder.Parent = self.inner

            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, -110, 0, 18)
            name.Position = UDim2.new(0, 14, 0, 2)
            name.BackgroundTransparency = 1
            name.Text = props.Label or ""
            name.TextColor3 = T.text
            name.Font = F
            name.TextSize = 13
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.Parent = holder

            local readout = Instance.new("TextLabel")
            readout.Size = UDim2.new(0, 96, 0, 18)
            readout.Position = UDim2.new(1, -110, 0, 2)
            readout.BackgroundTransparency = 1
            readout.TextColor3 = T.accent
            readout.Font = FM
            readout.TextSize = 12
            readout.TextXAlignment = Enum.TextXAlignment.Right
            readout.Parent = holder


            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -28, 0, 6)
            track.Position = UDim2.new(0, 14, 0, 26)
            track.BackgroundColor3 = T.off
            track.BorderSizePixel = 0
            track.Parent = holder
            corner(track, 3)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(0, 0, 1, 0)
            fill.BackgroundColor3 = T.accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            corner(fill, 3)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 12, 0, 12)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new(0, 0, 0.5, 0)
            knob.BackgroundColor3 = T.text
            knob.BorderSizePixel = 0
            knob.Parent = track
            corner(knob, 6)
            local knobStroke = stroke(knob, T.accent, 2, 0)


            local hit = Instance.new("TextButton")
            hit.Size = UDim2.new(1, -28, 0, 22)
            hit.Position = UDim2.new(0, 14, 0, 18)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Parent = holder

            local value = props.Default or props.Min or 0
            local mn, mx, stp = props.Min or 0, props.Max or 100, props.Step or 1
            local fmt = props.Format


            local steps = math.max(1, math.floor((mx - mn) / stp + 0.5))

            local function valueToScale(v)
                if mx == mn then return 0 end
                return (v - mn) / (mx - mn)
            end

            local function paint()
                local a = valueToScale(value)
                fill.Size = UDim2.new(a, 0, 1, 0)
                knob.Position = UDim2.new(a, 0, 0.5, 0)
                readout.Text = fmt and fmt(value)
                                    or string.format("%.2f", value)
            end
            paint()


            local function setFromX(mouseX)
                local abs = track.AbsolutePosition.X
                local width = track.AbsoluteSize.X
                if width <= 0 then return end
                local a = math.clamp((mouseX - abs) / width, 0, 1)
                local raw = mn + a * (mx - mn)
                local snapped = mn + math.floor((raw - mn) / stp + 0.5) * stp
                snapped = math.clamp(snapped, mn, mx)
                if math.abs(snapped - value) < 1e-9 then return end
                value = snapped
                paint()
                if props.Callback then props.Callback(value) end
            end

            local dragging = false

            hit.MouseButton1Down:Connect(function()
                dragging = true
                setFromX(UserInputService:GetMouseLocation().X)
            end)


            UserInputService.InputChanged:Connect(function(input)
                if not dragging then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    setFromX(input.Position.X)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)


            hit.MouseEnter:Connect(function()
                fill.BackgroundColor3 = T.accent2
                knobStroke.Color = T.accent2
            end)
            hit.MouseLeave:Connect(function()
                fill.BackgroundColor3 = T.accent
                knobStroke.Color = T.accent
            end)

            local api = {}
            function api:Get() return value end
            function api:Set(nv)
                value = math.clamp(nv, mn, mx)
                paint()
            end
            function api:SetStep(newStep)
                stp = newStep
            end
            return api
        end




        local pickStamp = 0
        function s:AceitaClique()
            local now = os.clock()
            if now - pickStamp < 0.08 then return false end
            pickStamp = now
            return true
        end

        function s:Button(props)
            self._o = self._o + 1
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -24, 0, 30)
            b.Position = UDim2.new(0, 12, 0, 0)
            b.BackgroundColor3 = T.card2
            b.BorderSizePixel = 0
            b.Text = props.Label or "Button"
            b.TextColor3 = props.Color or T.accent2
            b.Font = F
            b.TextSize = 13
            b.AutoButtonColor = false
            b.LayoutOrder = self._o
            b.Parent = self.inner
            corner(b, 5)
            stroke(b, T.line, 1, 0.25)
            b.MouseEnter:Connect(function() b.BackgroundColor3 = T.card3 end)
            b.MouseLeave:Connect(function() b.BackgroundColor3 = T.card2 end)
            b.MouseButton1Click:Connect(function()
                if props.Callback then props.Callback() end
            end)
            return b
        end






        function s:Input(props)
            local row = self:row(props.Label, 38)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(0, 190, 0, 26)
            box.Position = UDim2.new(1, -202, 0.5, -13)
            box.BackgroundColor3 = T.card2
            box.BorderSizePixel = 0
            box.Text = props.Default or ""
            box.PlaceholderText = props.Placeholder or "nome do preset"
            box.TextColor3 = T.text
            box.Font = F
            box.TextSize = 12
            box.ClearTextOnFocus = false
            box.Parent = row
            corner(box, 5)
            local bs = stroke(box, T.line, 1, 0.25)
            box.Focused:Connect(function()
                bs.Color = T.accent2
                bs.Transparency = 0
            end)
            box.FocusLost:Connect(function()
                bs.Color = T.line
                bs.Transparency = 0.25
                if props.Callback then props.Callback(box.Text) end
            end)
            if props.OnChange then
                box:GetPropertyChangedSignal("Text"):Connect(function()
                    props.OnChange(box.Text)
                end)
            end
            return box
        end


        function s:Dual(props)
            self._o = self._o + 1
            local order = self._o
            local larg = props.Width or 150
            local feitos = {}
            for i = 1, 2 do
                local cfg = props[i]
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(0, larg, 0, 30)
                b.Position = UDim2.new(0, 12 + (i - 1) * (larg + 8), 0, 0)
                b.BackgroundColor3 = T.card2
                b.BorderSizePixel = 0
                b.Text = cfg.Label or "?"
                b.TextColor3 = cfg.Color or T.accent2
                b.Font = F
                b.TextSize = 12
                b.AutoButtonColor = false
                b.LayoutOrder = order
                b.Parent = self.inner
                corner(b, 5)
                stroke(b, T.line, 1, 0.25)
                b.MouseEnter:Connect(function()
                    b.BackgroundColor3 = T.card3
                end)
                b.MouseLeave:Connect(function()
                    b.BackgroundColor3 = T.card2
                end)
                b.MouseButton1Click:Connect(function()
                    if cfg.Callback then cfg.Callback() end
                end)
                feitos[i] = b
            end
            return feitos[1], feitos[2]
        end



        function s:Segmented(props)
            local row = self:row(props.Label, 44)
            local opts = props.Options or {}
            local n = #opts
            local value = props.Default or opts[1]



            local function aceita() return s:AceitaClique() end


            local PAD    = 3
            local GAP    = 3
            local each   = props.SegWidth or 62
            local WID    = PAD * 2 + each * n + GAP * (n - 1)
            local HEI    = 28

            local holder = Instance.new("Frame")
            holder.Name = "SegHolder"
            holder.Size = UDim2.new(0, WID, 0, HEI)
            holder.Position = UDim2.new(1, -(WID + 14), 0.5, -HEI / 2)
            holder.BackgroundColor3 = T.off
            holder.BorderSizePixel = 0
            holder.Parent = row
            corner(holder, 7)
            stroke(holder, T.line, 1, 0.25)

            local segs = {}
            local function paint()
                for _, sg in ipairs(segs) do
                    local on = (sg.val == value)
                    sg.btn.BackgroundColor3 = on and T.accentD or T.off
                    sg.btn.TextColor3 = on and T.accent2 or T.dim
                    sg.btn.Font = on and FB or F
                    sg.btn.TextTransparency = on and 0 or 0.15
                end
            end

            local function pick(o, idx)
                if value == o then return end
                value = o
                paint()
                if props.Callback then props.Callback(o, idx) end
            end

            for idx, o in ipairs(opts) do
                local seg = Instance.new("TextButton")
                seg.Name = "Seg"
                seg.Size = UDim2.new(0, each, 1, -(PAD * 2))
                seg.Position = UDim2.new(0, PAD + (idx - 1) * (each + GAP), 0, PAD)
                seg.BackgroundColor3 = T.card2
                seg.BorderSizePixel = 0
                seg.Text = tostring(o)
                seg.TextColor3 = T.dim
                seg.Font = F
                seg.TextSize = 11
                seg.AutoButtonColor = false
                seg.TextTruncate = Enum.TextTruncate.AtEnd
                seg.ZIndex = 2
                seg.Parent = holder
                corner(seg, 4)

                segs[#segs + 1] = { btn = seg, val = o }

                seg.MouseEnter:Connect(function()
                    if value ~= o then
                        seg.BackgroundColor3 = T.card3
                        seg.TextColor3 = T.text
                        seg.TextTransparency = 0
                    end
                end)
                seg.MouseLeave:Connect(function()
                    if value ~= o then
                        seg.BackgroundColor3 = T.off
                        seg.TextColor3 = T.dim
                        seg.TextTransparency = 0.15
                    end
                end)
                seg.MouseButton1Click:Connect(function()
                    if not aceita() then return end
                    pick(o, idx)
                end)




                UserInputService.InputBegan:Connect(function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
                        return
                    end
                    if not seg.Visible or not holder.Visible then return end
                    local m  = input.Position
                    local ap = seg.AbsolutePosition
                    local as = seg.AbsoluteSize
                    if m.X >= ap.X and m.X <= ap.X + as.X
                   and m.Y >= ap.Y and m.Y <= ap.Y + as.Y then
                        if not aceita() then return end
                        pick(o, idx)
                    end
                end)
            end
            paint()

            local api = {}
            function api:Get() return value end
            function api:Set(v)
                for _, sg in ipairs(segs) do
                    if sg.val == v then value = v end
                end
                paint()
            end
            function api:Buttons() return segs end
            function api:Holder() return holder end
            return api
        end

        function s:Dropdown(props)
            local row = self:row(props.Label)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 120, 0, 26)
            b.Position = UDim2.new(1, -132, 0.5, -13)
            b.BackgroundColor3 = T.card2
            b.BorderSizePixel = 0
            b.Text = tostring(props.Default or (props.Options and props.Options[1]) or "")
            b.TextColor3 = T.accent2
            b.Font = FB
            b.TextSize = 12
            b.AutoButtonColor = false
            b.Parent = row
            corner(b, 5)
            stroke(b, T.line, 1, 0.25)
            local opts = props.Options or {}
            local i = 1
            for n, o in ipairs(opts) do if o == props.Default then i = n end end
            b.MouseEnter:Connect(function() b.BackgroundColor3 = T.card3 end)
            b.MouseLeave:Connect(function() b.BackgroundColor3 = T.card2 end)
            b.MouseButton1Click:Connect(function()
                i = i + 1
                if i > #opts then i = 1 end
                b.Text = tostring(opts[i])
                if props.Callback then props.Callback(opts[i]) end
            end)
            local api = {}
            function api:Get() return opts[i] end
            function api:Set(val)
                for n, o in ipairs(opts) do
                    if o == val then i = n; b.Text = tostring(o) end
                end
            end



            function api:Reload(novaLista)
                opts = novaLista or {}
                i = 1
                b.Text = tostring(opts[1] or "none")
            end

            function api:Options() return opts end
            return api
        end
        function s:Keybind(props)
            local row = self:row(props.Label)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 120, 0, 26)
            b.Position = UDim2.new(1, -132, 0.5, -13)
            b.BackgroundColor3 = T.card2
            b.BorderSizePixel = 0
            b.Text = props.Get and props.Get() or "none"
            b.TextColor3 = T.accent
            b.Font = FB
            b.TextSize = 12
            b.AutoButtonColor = false
            b.Parent = row
            corner(b, 5)
            local ks = stroke(b, T.line, 1, 0.25)
            local function paint()
                if Keybind.capturing and Keybind.which == props.Which then
                    b.Text = "press a key"
                    b.TextColor3 = T.warn
                    ks.Color = T.warn
                    ks.Transparency = 0
                else
                    b.Text = props.Get and props.Get() or "none"
                    b.TextColor3 = T.accent
                    ks.Color = T.line
                    ks.Transparency = 0.25
                end
            end
            paint()
            Keybind.painters[#Keybind.painters + 1] = paint
            b.MouseEnter:Connect(function() b.BackgroundColor3 = T.line end)
            b.MouseLeave:Connect(function() b.BackgroundColor3 = T.card2 end)
            b.MouseButton1Click:Connect(function()
                if props.OnStart then props.OnStart() end
                Keybind.capturing = true
                Keybind.which = props.Which
                repaint_keybinds()
            end)
            return { Paint = paint }
        end
        function s:Label(props)
            props = props or {}
            self._o = self._o + 1
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -28, 0, props.Height or 32)
            l.Position = UDim2.new(0, 14, 0, 0)
            l.BackgroundTransparency = 1
            l.Text = props.Text or ""
            l.TextColor3 = props.Color or T.dim
            l.Font = props.Mono and FM or F
            l.TextSize = props.Size or 12
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextYAlignment = Enum.TextYAlignment.Top
            l.TextWrapped = true
            l.LayoutOrder = self._o
            l.Parent = self.inner
            return l
        end
        function s:Divider()
            self._o = self._o + 1
            local d = Instance.new("Frame")
            d.Size = UDim2.new(1, -24, 0, 1)
            d.Position = UDim2.new(0, 12, 0, 0)
            d.BackgroundColor3 = T.line
            d.BorderSizePixel = 0
            d.LayoutOrder = self._o
            d.Parent = self.inner
            return d
        end
        return s
    end




    local tAim = new_tab("AIM")

    local sLock = new_section(tAim, "Aimlock")
    sLock:Toggle{ Label = "Aimlock enabled", Default = CONFIG.AimLockEnabled,
        Callback = function(v) CONFIG.AimLockEnabled = v end }




    sLock:Segmented{ Label = "Activate with",
        Options = { "KEY", "MOUSE" },
        SegWidth = 62,
        Default = CONFIG.AimMouseButton and "MOUSE" or "KEY",
        Callback = function(v)
            if v == "MOUSE" then

                CONFIG.AimMouseButton = CONFIG.AimMouseButton
                                     or Enum.UserInputType.MouseButton1
            else
                CONFIG.AimMouseButton = nil
            end
            repaint_keybinds()
        end }

    sLock:Keybind{ Label = "Aimlock key", Which = "key",
        Get = function()
            if CONFIG.AimMouseButton then return "mouse" end
            return key_name(CONFIG.AimKey)
        end,
        OnStart = function()
            CONFIG.AimMouseButton = nil
            repaint_keybinds()
        end }

    sLock:Segmented{ Label = "Mouse button",
        Options = { "LEFT", "RIGHT", "MIDDLE" },
        SegWidth = 48,
        Default = (CONFIG.AimMouseButton == Enum.UserInputType.MouseButton2 and "RIGHT")
               or (CONFIG.AimMouseButton == Enum.UserInputType.MouseButton3 and "MIDDLE")
               or (CONFIG.AimMouseButton == Enum.UserInputType.MouseButton1 and "LEFT")
               or "LEFT",
        Callback = function(v)
            if v == "LEFT" then
                CONFIG.AimMouseButton = Enum.UserInputType.MouseButton1
            elseif v == "RIGHT" then
                CONFIG.AimMouseButton = Enum.UserInputType.MouseButton2
            else
                CONFIG.AimMouseButton = Enum.UserInputType.MouseButton3
            end
            repaint_keybinds()
        end }



    sLock:Segmented{ Label = "Activation mode",
        Options = { "HOLD", "TOGGLE" },
        Default = CONFIG.AimHoldMode and "HOLD" or "TOGGLE",
        Callback = function(v)
            CONFIG.AimHoldMode = (v == "HOLD")
            aim_toggled = false
            recompute_aim_active()
        end }


    sLock:Segmented{ Label = "Target bone",
        Options = { "HEAD", "CHEST", "ROOT" },
        Default = (CONFIG.AimBone == "Head" and "HEAD")
               or (CONFIG.AimBone == "UpperTorso" and "CHEST")
               or (CONFIG.AimBone == "HumanoidRootPart" and "ROOT")
               or (CONFIG.AimBone == "TribesHull" and "ROOT")
               or "HEAD",
        Callback = function(v)
            CONFIG.AimBone = (v == "HEAD" and "Head")
                          or (v == "CHEST" and "UpperTorso")
                          or "HumanoidRootPart"
        end }

    sLock:Toggle{ Label = "Smooth entry", Default = CONFIG.AimSmoothLock,
        Callback = function(v) CONFIG.AimSmoothLock = v end }






    local sFire = new_section(tAim, "Auto-fire")
    sFire:Toggle{ Label = "Auto-fire enabled", Default = CONFIG.AutoFire,
        Callback = function(v) CONFIG.AutoFire = v end }
    sFire:Toggle{ Label = "Fire on sight",
        Default = CONFIG.FireOnSight,
        Callback = function(v) CONFIG.FireOnSight = v end }
    sFire:Toggle{ Label = "Wall check before firing",
        Default = CONFIG.WallCheck,
        Callback = function(v) CONFIG.WallCheck = v end }
    sFire:Toggle{ Label = "Only when locked", Default = CONFIG.FireOnlyLocked,
        Callback = function(v) CONFIG.FireOnlyLocked = v end }
    sFire:Slider{ Label = "Fire cone", Default = CONFIG.FireCone,
        Min = 0.5, Max = 20, Step = 0.5,
        Format = function(v) return string.format("%.1f°", v) end,
        Callback = function(v) CONFIG.FireCone = v end }
    sFire:Slider{ Label = "Fire interval", Default = CONFIG.FireDelay,
        Min = 0.02, Max = 0.6, Step = 0.02,
        Format = function(v) return string.format("%.2fs", v) end,
        Callback = function(v) CONFIG.FireDelay = v end }
    sFire:Label{ Text = "  Without a locked target it fires at anyone\n" ..
                       "  inside the cone with no wall in between.",
                 Color = T.dim, Size = 11 }






    local sMode = new_section(tAim, "Aim")
    sMode:Segmented{ Label = "Behaviour",
        Options = { "HUMAN", "ROBOT" },
        SegWidth = 66,
        Default = (CONFIG.AimMode == "robot") and "ROBOT" or "HUMAN",
        Callback = function(v)
            CONFIG.AimMode = (v == "ROBOT") and "robot" or "legit"
            legit_reset()
        end }

    sMode:Slider{ Label = "Aim speed", Default = CONFIG.LegitSpeed,
        Min = 15, Max = 900, Step = 5,
        Format = function(v) return string.format("%.0f°/s", v) end,
        Callback = function(v) CONFIG.LegitSpeed = v end }
    sMode:Slider{ Label = "Hand shake", Default = CONFIG.LegitJitter,
        Min = 0, Max = 2, Step = 0.05,
        Format = function(v) return string.format("%.2f°", v) end,
        Callback = function(v) CONFIG.LegitJitter = v end }
    sMode:Slider{ Label = "Aim error", Default = CONFIG.LegitError,
        Min = 0, Max = 6, Step = 0.1,
        Format = function(v) return string.format("%.1f°", v) end,
        Callback = function(v) CONFIG.LegitError = v end }
    sMode:Slider{ Label = "Reaction time", Default = CONFIG.LegitReaction,
        Min = 0, Max = 0.6, Step = 0.02,
        Format = function(v) return string.format("%.2fs", v) end,
        Callback = function(v) CONFIG.LegitReaction = v end }
    sMode:Toggle{ Label = "Overshoot and come back",
        Default = CONFIG.LegitOvershoot,
        Callback = function(v) CONFIG.LegitOvershoot = v end }
    sMode:Slider{ Label = "Keep tracking after loss", Default = CONFIG.LegitLostKeep,
        Min = 0, Max = 1.5, Step = 0.05,
        Format = function(v) return string.format("%.2fs", v) end,
        Callback = function(v) CONFIG.LegitLostKeep = v end }


    sMode:Divider()
    sMode:Slider{ Label = "Field of view", Default = AIM_TUNE.FOVdeg,
        Min = 30, Max = 180, Step = 15,
        Format = function(v) return string.format("%d°", v) end,
        Callback = function(v) AIM_TUNE.FOVdeg = v; AIM_TUNE.FOVdrop = v + 40 end }
    sMode:Slider{ Label = "Aim height", Default = CONFIG.AimHeightOffset,
        Min = -2, Max = 4, Step = 0.25,
        Callback = function(v) CONFIG.AimHeightOffset = v end }
    sMode:Slider{ Label = "Prediction", Default = AIM_TUNE.Prediction,
        Min = 0, Max = 0.30, Step = 0.02,
        Format = function(v) return string.format("%.2fs", v) end,
        Callback = function(v) AIM_TUNE.Prediction = v end }
    sMode:Slider{ Label = "Max range", Default = CONFIG.AimMaxDist,
        Min = 100, Max = 3000, Step = 100,
        Format = function(v) return string.format("%dm", v) end,
        Callback = function(v) CONFIG.AimMaxDist = v end }
    sMode:Slider{ Label = "Distance weight", Default = AIM_TUNE.DistWeight,
        Min = 0, Max = 0.75, Step = 0.05,
        Callback = function(v) AIM_TUNE.DistWeight = v end }
    sMode:Toggle{ Label = "FOV circle", Default = CONFIG.ShowFOVCircle,
        Callback = function(v) CONFIG.ShowFOVCircle = v end }




    local tVis = new_tab("VISUAL")







    local sEsp = new_section(tVis, "ESP")
    sEsp:Toggle{ Label = "ESP enabled", Default = CONFIG.ESPEnabled,
        Callback = function(v) CONFIG.ESPEnabled = v end }
    sEsp:Toggle{ Label = "Show name", Default = CONFIG.ESPShowName,
        Callback = function(v) CONFIG.ESPShowName = v end }
    sEsp:Toggle{ Label = "Show health", Default = CONFIG.ESPShowHealth,
        Callback = function(v) CONFIG.ESPShowHealth = v end }
    sEsp:Toggle{ Label = "Show distance", Default = CONFIG.ESPShowDist,
        Callback = function(v) CONFIG.ESPShowDist = v end }
    sEsp:Slider{ Label = "ESP range", Default = CONFIG.ESPMaxDistance,
        Min = 50, Max = 2000, Step = 50,
        Format = function(v) return string.format("%dm", v) end,
        Callback = function(v) CONFIG.ESPMaxDistance = v end }

    sEsp:Divider()

    local enemyColor = CONFIG.ESPColorEnemy
    local allyColor  = CONFIG.ESPColorAlly
    local PALETTE = {
        {name="Red",     c=Color3.fromRGB(255,72,72)},
        {name="Orange",  c=Color3.fromRGB(255,150,60)},
        {name="Yellow",  c=Color3.fromRGB(255,220,70)},
        {name="Green",   c=Color3.fromRGB(90,220,120)},
        {name="Cyan",    c=Color3.fromRGB(72,196,255)},
        {name="Purple",  c=Color3.fromRGB(170,110,255)},
        {name="Pink",    c=Color3.fromRGB(255,110,190)},
        {name="White",   c=Color3.fromRGB(240,240,240)},
    }
    local function palette_names()
        local o = {}
        for i, p in ipairs(PALETTE) do o[i] = p.name end
        return o
    end
    local enemyIdx, allyIdx = 1, 5

    sEsp:Dropdown{ Label = "Enemy colour",
        Options = palette_names(),
        Default = "Red",
        Callback = function(nome)
            for i, p in ipairs(PALETTE) do
                if p.name == nome then enemyIdx = i; enemyColor = p.c end
            end
            CONFIG.ESPColorEnemy = enemyColor
        end }
    sEsp:Dropdown{ Label = "Ally colour",
        Options = palette_names(),
        Default = "Cyan",
        Callback = function(nome)
            for i, p in ipairs(PALETTE) do
                if p.name == nome then allyIdx = i; allyColor = p.c end
            end
            CONFIG.ESPColorAlly = allyColor
        end }




    local tMov = new_tab("MOVEMENT")

    local sFly = new_section(tMov, "Fly")
    sFly:Toggle{ Label = "Fly enabled", Default = CONFIG.FlyEnabled,
        Callback = function(v)
            CONFIG.FlyEnabled = v
            if v then start_fly() else stop_fly() end
        end }
    sFly:Slider{ Label = "Fly speed", Default = CONFIG.FlySpeed,
        Min = 10, Max = 200, Step = 5,
        Format = function(v) return string.format("%d", v) end,
        Callback = function(v)
            CONFIG.FlySpeed = v
            if fly_vel then fly_vel.Velocity = Vector3.zero end
        end }
    sFly:Divider()
    sFly:Label{ Text = "  WASD to move  ·  Space up  ·  Ctrl down",
                Color = T.dim, Size = 11 }










    local tPerf = new_tab("FPS")

    local perf_orig = {}
    local fps_on    = false


    local function guardar(chave, valor)
        if perf_orig[chave] == nil then perf_orig[chave] = valor end
    end

    local POST_FX = {
        BloomEffect = true, BlurEffect = true, SunRaysEffect = true,
        ColorCorrectionEffect = true, DepthOfFieldEffect = true,
        Atmosphere = true,
    }

    local function ligar_fps()
        pcall(function()
            local L = game:GetService("Lighting")
            guardar("GlobalShadows", L.GlobalShadows)
            L.GlobalShadows = false
            guardar("Quality", L.QualityLevel)
            L.QualityLevel = 1
            guardar("FogEnd", L.FogEnd)
            L.FogEnd = 100000
            for _, c in ipairs(L:GetChildren()) do
                if POST_FX[c.ClassName] and c:IsA("PostEffect") then
                    guardar("fx_" .. c.Name, c.Enabled)
                    c.Enabled = false
                end
            end
        end)
        pcall(function()
            local T2 = Workspace:FindFirstChildOfClass("Terrain")
            if T2 then
                guardar("Terrain", T2.Transparency)
                T2.Transparency = 1
            end
        end)
        pcall(function()
            for _, d in ipairs(Workspace:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Trail")
                   or d:IsA("Smoke") or d:IsA("Fire")
                   or d:IsA("Sparkles") then
                    d.Enabled = false
                end
            end
        end)
        fps_on = true
    end

    local function desligar_fps()
        pcall(function()
            local L = game:GetService("Lighting")
            if perf_orig.GlobalShadows ~= nil then
                L.GlobalShadows = perf_orig.GlobalShadows
            end
            if perf_orig.Quality ~= nil then
                L.QualityLevel = perf_orig.Quality
            end
            if perf_orig.FogEnd ~= nil then L.FogEnd = perf_orig.FogEnd end
            for _, c in ipairs(L:GetChildren()) do
                local o = perf_orig["fx_" .. c.Name]
                if o ~= nil then c.Enabled = o end
            end
        end)
        pcall(function()
            local T2 = Workspace:FindFirstChildOfClass("Terrain")
            if T2 and perf_orig.Terrain ~= nil then
                T2.Transparency = perf_orig.Terrain
            end
        end)
        fps_on = false
    end



    local sFps = new_section(tPerf, "Performance")

    local btnFps = Instance.new("TextButton")
    btnFps.Name = "PerformanceToggle"
    btnFps.Size = UDim2.new(1, -24, 0, 52)
    btnFps.Position = UDim2.new(0, 12, 0, 0)
    btnFps.BackgroundColor3 = T.off
    btnFps.BorderSizePixel = 0
    btnFps.Text = ""
    btnFps.AutoButtonColor = false
    btnFps.LayoutOrder = 1
    btnFps.Parent = sFps.inner
    corner(btnFps, 10)


    local dotFps = Instance.new("Frame")
    dotFps.Name = "Dot"
    dotFps.Size = UDim2.new(0, 8, 0, 8)
    dotFps.Position = UDim2.new(0, 18, 0.5, -4)
    dotFps.BackgroundColor3 = T.dim
    dotFps.BorderSizePixel = 0
    dotFps.Parent = btnFps
    corner(dotFps, 4)

    local lblFps = Instance.new("TextLabel")
    lblFps.Name = "Title"
    lblFps.Size = UDim2.new(1, -70, 1, 0)
    lblFps.Position = UDim2.new(0, 36, 0, 0)
    lblFps.BackgroundTransparency = 1
    lblFps.Text = "PERFORMANCE MODE"
    lblFps.TextColor3 = T.text
    lblFps.Font = FB
    lblFps.TextSize = 12
    lblFps.TextXAlignment = Enum.TextXAlignment.Left
    lblFps.Parent = btnFps


    local chevFps = Instance.new("TextLabel")
    chevFps.Name = "Chevron"
    chevFps.Size = UDim2.new(0, 24, 1, 0)
    chevFps.Position = UDim2.new(1, -34, 0, 0)
    chevFps.BackgroundTransparency = 1
    chevFps.Text = "ON"
    chevFps.TextColor3 = T.faint
    chevFps.Font = FB
    chevFps.TextSize = 10
    chevFps.Parent = btnFps



    local strokeFps = stroke(btnFps, T.line, 1, 0.5)

    local function pintar_fps()
        if fps_on then
            btnFps.BackgroundColor3 = T.accentD
            dotFps.BackgroundColor3 = T.good
            lblFps.TextColor3     = T.accent2
            chevFps.Text          = "ON"
            chevFps.TextColor3    = T.good
            strokeFps.Color        = T.accent
            strokeFps.Transparency = 0.35
        else
            btnFps.BackgroundColor3 = T.off
            dotFps.BackgroundColor3 = T.dim
            lblFps.TextColor3       = T.text
            chevFps.Text            = "OFF"
            chevFps.TextColor3      = T.faint
            strokeFps.Color        = T.line
            strokeFps.Transparency = 0.5
        end
    end
    pintar_fps()

    btnFps.MouseButton1Click:Connect(function()
        if fps_on then
            desligar_fps()
        else
            ligar_fps()
        end
        pintar_fps()
    end)











    local tCfg = new_tab("CONFIG")

    carregar_presets_do_disco()



    local pintar_auto

    local presetAtual  = nil
    local nomeDigitado = ""



    local auto_load_on = (autoload_nome ~= nil)




    local sPre = new_section(tCfg, "Preset")

    local listaFrame = Instance.new("Frame")
    listaFrame.Name = "PresetList"
    listaFrame.Size = UDim2.new(1, -24, 0, 0)
    listaFrame.Position = UDim2.new(0, 12, 0, 0)
    listaFrame.BackgroundTransparency = 1
    listaFrame.AutomaticSize = Enum.AutomaticSize.Y
    listaFrame.LayoutOrder = 1
    listaFrame.Parent = sPre.inner

    local listaLayout = Instance.new("UIListLayout")
    listaLayout.Padding = UDim.new(0, 6)
    listaLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listaLayout.Parent = listaFrame



    local function montar_linha(nome, indice)
        local ehAuto = (autoload_nome == nome)
        local sel    = (presetAtual == nome)

        local card = Instance.new("Frame")
        card.Name = "P_" .. nome
        card.Size = UDim2.new(1, 0, 0, 38)
        card.BackgroundColor3 = sel and T.card3 or T.card2
        card.BorderSizePixel = 0
        card.LayoutOrder = indice
        card.Parent = listaFrame
        corner(card, 8)



        local rail = Instance.new("Frame")
        rail.Name = "Rail"
        rail.Size = UDim2.new(0, 3, 1, -14)
        rail.Position = UDim2.new(0, 0, 0, 7)
        rail.BackgroundColor3 = ehAuto and T.accent or T.line
        rail.BorderSizePixel = 0
        rail.Parent = card
        corner(rail, 2)

        local nomeLbl = Instance.new("TextLabel")
        nomeLbl.Name = "Name"
        nomeLbl.Size = UDim2.new(1, -142, 1, 0)
        nomeLbl.Position = UDim2.new(0, 16, 0, 0)
        nomeLbl.BackgroundTransparency = 1
        nomeLbl.Text = nome
        nomeLbl.TextColor3 = sel and T.accent2 or T.text
        nomeLbl.Font = FB
        nomeLbl.TextSize = 12
        nomeLbl.TextXAlignment = Enum.TextXAlignment.Left
        nomeLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nomeLbl.Parent = card


        if ehAuto then
            local pill = Instance.new("Frame")
            pill.Name = "Pill"
            pill.Size = UDim2.new(0, 34, 0, 14)
            pill.Position = UDim2.new(1, -142, 0.5, -7)
            pill.BackgroundColor3 = T.accentD
            pill.BorderSizePixel = 0
            pill.Parent = card
            corner(pill, 7)
            local pt = Instance.new("TextLabel")
            pt.Size = UDim2.new(1, 0, 1, 0)
            pt.BackgroundTransparency = 1
            pt.Text = "AUTO"
            pt.TextColor3 = T.accent2
            pt.Font = FB
            pt.TextSize = 8
            pt.Parent = pill
        end

        local function acao(texto, x, cor, ligado, fn)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(0, 30, 0, 24)
            b.Position = UDim2.new(1, x, 0.5, -12)
            b.BackgroundColor3 = ligado and T.accentD or T.off
            b.BorderSizePixel = 0
            b.Text = texto
            b.TextColor3 = ligado and T.accent2 or T.dim
            b.Font = FB
            b.TextSize = 13
            b.AutoButtonColor = false
            b.Parent = card
            corner(b, 6)
            if ligado then stroke(b, T.accent, 1, 0.4) end
            b.MouseButton1Click:Connect(fn)
            return b
        end


        acao(">", -72, T.accent2, false, function()
            local n = aplicar_config(presets[nome])
            presetAtual = nome
            redesenhar_lista()
            avisar("'" .. nome .. "' loaded (" .. n .. ")")
        end)


        local pin = acao("*", -38, T.good, ehAuto, function()
            if autoload_nome == nome then
                gravar_autoload(nil)
                auto_load_on = false
                avisar("Auto-load off")
            else
                gravar_autoload(nome)
                auto_load_on = true
                avisar("'" .. nome .. "' loads on inject")
            end
            redesenhar_lista()
            if pintar_auto then pintar_auto() end
        end)
        pin.Name = "Pin"
    end


    local redesenhar_lista = nil
    redesenhar_lista = function()
        for _, c in ipairs(listaFrame:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end

        if #preset_names == 0 then
            local vazio = Instance.new("Frame")
            vazio.Name = "Empty"
            vazio.Size = UDim2.new(1, 0, 0, 46)
            vazio.BackgroundColor3 = T.off
            vazio.BorderSizePixel = 0
            vazio.LayoutOrder = 1
            vazio.Parent = listaFrame
            corner(vazio, 8)

            local t1 = Instance.new("TextLabel")
            t1.Size = UDim2.new(1, -24, 0, 18)
            t1.Position = UDim2.new(0, 14, 0, 8)
            t1.BackgroundTransparency = 1
            t1.Text = "No presets saved"
            t1.TextColor3 = T.dim
            t1.Font = FB
            t1.TextSize = 12
            t1.TextXAlignment = Enum.TextXAlignment.Left
            t1.Parent = vazio

            local t2 = Instance.new("TextLabel")
            t2.Size = UDim2.new(1, -24, 0, 16)
            t2.Position = UDim2.new(0, 14, 0, 25)
            t2.BackgroundTransparency = 1
            t2.Text = "Create one below."
            t2.TextColor3 = T.faint
            t2.Font = F
            t2.TextSize = 11
            t2.TextXAlignment = Enum.TextXAlignment.Left
            t2.Parent = vazio
            return
        end

        for i, nome in ipairs(preset_names) do
            montar_linha(nome, i)
        end
    end


    sPre:Divider()
    sPre:Input{ Label = "Name", Placeholder = "e.g. strong aimbot",
        OnChange = function(txt) nomeDigitado = txt end }

    local function nome_limpo()
        return tostring(nomeDigitado or ""):gsub("^%s+", ""):gsub("%s+$", "")
    end

    sPre:Dual{ Width = 190,
        { Label = "SAVE", Color = T.good, Callback = function()
            local nome = nome_limpo()
            if #nome == 0 then
                avisar("Type a name first")
                return
            end
            if #nome > 20 then
                avisar("Name too long (max 20)")
                return
            end
            local jaTinha = presets[nome] ~= nil
            presets[nome] = capturar_config()
            if not jaTinha then
                preset_names[#preset_names + 1] = nome
            end
            salvar_presets_em_disco()
            presetAtual = nome
            redesenhar_lista()
            avisar(jaTinha and ("'" .. nome .. "' updated")
                           or ("'" .. nome .. "' saved"))
        end },
        { Label = "OVERWRITE", Color = T.accent, Callback = function()
            local nome = presetAtual or preset_names[1]
            if not nome or not presets[nome] then
                avisar("No preset selected")
                return
            end
            presets[nome] = capturar_config()
            salvar_presets_em_disco()
            redesenhar_lista()
            avisar("'" .. nome .. "' overwritten")
        end },
    }

    sPre:Dual{ Width = 190,
        { Label = "DELETE", Color = T.bad, Callback = function()
            local nome = nome_limpo()
            if #nome == 0 then nome = presetAtual or "" end
            if #nome == 0 or not presets[nome] then
                avisar("No preset named '" .. nome .. "'")
                return
            end
            apagar_preset(nome)
            if autoload_nome == nome then
                gravar_autoload(nil)
                auto_load_on = false
            end
            if presetAtual == nome then presetAtual = preset_names[1] end
            redesenhar_lista()
            avisar("'" .. nome .. "' deleted")
        end },
        { Label = "RESET ALL", Color = T.warn, Callback = function()
            local base = {
                AimMode = "robot", LegitSpeed = 90, LegitJitter = 0.55,
                LegitError = 1.8, LegitReaction = 0.18,
                LegitOvershoot = true, LegitLostKeep = 0.4,
                FireOnlyLocked = false, FireOnSight = true, WallCheck = true,
                AutoFire = false, FireCone = 2.5, FireDelay = 0.10,
                ESPEnabled = true, ESPMaxDistance = 500,
                ESPShowName = true, ESPShowHealth = true, ESPShowDist = true,
                FlyEnabled = false, FlySpeed = 55, MatchOnly = true,
                HookCamera = true, ShowFOVCircle = true,
                AIM_FOVdeg = 100, AIM_Prediction = 0.08,
                AIM_DistWeight = 0.25,
            }
            local txt = {}
            for k, v in pairs(base) do txt[k] = valor_para_texto(v) end
            aplicar_config(txt)


            gravar_autoload(nil)
            auto_load_on = false
            desativar_auto_exec()
            redesenhar_lista()
            avisar("Defaults restored")
        end },
    }






    sPre:Divider()



    local autoLbl = Instance.new("TextLabel")
    autoLbl.Name = "AutoStatus"
    autoLbl.Size = UDim2.new(1, -24, 0, 16)
    autoLbl.Position = UDim2.new(0, 12, 0, 0)
    autoLbl.BackgroundTransparency = 1
    autoLbl.TextColor3 = T.dim
    autoLbl.Font = FM
    autoLbl.TextSize = 11
    autoLbl.TextXAlignment = Enum.TextXAlignment.Left
    autoLbl.LayoutOrder = 4
    autoLbl.Parent = sPre.inner

    function pintar_auto()
        if not FS.tem then
            autoLbl.Text = "unavailable - no writefile"
            autoLbl.TextColor3 = T.bad
        elseif autoload_nome then
            autoLbl.Text = "on inject  ->  " .. autoload_nome
            autoLbl.TextColor3 = T.good
        else
            autoLbl.Text = "nothing loads on inject"
            autoLbl.TextColor3 = T.faint
        end
    end

    sPre:Toggle{ Label = "Load a preset on inject",
        Default = auto_load_on,
        Callback = function(v)
            if v then
                local alvo = presetAtual or preset_names[1]
                if not alvo then
                    avisar("Save a preset first")

                    return false
                end
                gravar_autoload(alvo)
                avisar("'" .. alvo .. "' loads on inject")
            else
                gravar_autoload(nil)
                avisar("Auto-load off")
            end
            redesenhar_lista()
            pintar_auto()
        end }
    pintar_auto()



    sPre:Toggle{ Label = "Reopen hub on next load",
        Default = (hub_url ~= nil),
        Callback = function(v)
            if v then
                local ok2, motivo = ativar_auto_exec(HUB_URL)
                if ok2 then
                    avisar("Hub will reopen on next load")
                else
                    avisar(tostring(motivo))
                    return false
                end
            else
                desativar_auto_exec()
                avisar("Auto-exec off")
            end
        end }




    local open = true

    root.Active = false
    root.Draggable = false








    root.Active = false
    root.Draggable = false

    local dragging, dragStart, dragOrigin = false, nil, nil
    local dragGoal = nil
    local dragNow  = nil





    local function in_drag_zone(pos)
        local rp = root.AbsolutePosition
        local rs = root.AbsoluteSize
        local x = pos.X - rp.X
        local y = pos.Y - rp.Y
        if x < 0 or x > rs.X then return false end
        if y < 0 or y > rs.Y then return false end

        if open then
            if y > 64 then return false end
            if x > rs.X - 104 then return false end
            return true
        end



        if y > 40 and y < 64 and x > 10 and x < 54 then return false end
        return true
    end

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if not in_drag_zone(input.Position) then return end
        dragging   = true
        dragStart  = input.Position
        dragOrigin = root.Position
        dragGoal   = root.Position
        dragNow    = root.Position
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local dx = input.Position.X - dragStart.X
        local dy = input.Position.Y - dragStart.Y

        dragGoal = UDim2.new(
            dragOrigin.X.Scale, dragOrigin.X.Offset + dx,
            dragOrigin.Y.Scale, dragOrigin.Y.Offset + dy)
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)







    RunService.RenderStepped:Connect(function(dt)
        if not dragging or not dragGoal or not dragNow then return end
        local a = 1 - math.exp(-28 * math.clamp(dt, 1/240, 0.1))
        local nx = dragNow.X.Offset + (dragGoal.X.Offset - dragNow.X.Offset) * a
        local ny = dragNow.Y.Offset + (dragGoal.Y.Offset - dragNow.Y.Offset) * a
        dragNow = UDim2.new(dragNow.X.Scale, nx, dragNow.Y.Scale, ny)
        root.Position = dragNow
    end)



    local savedSize = UDim2.new(0, W, 0, H)
    local miniBar = nil

    local function set_open(v)
        open = v






        for _, c in ipairs(root:GetChildren()) do
            if c ~= header and c:IsA("GuiObject") then
                c.Visible = v
            end
        end

        if v then

            root.Size = savedSize
            if vpill then vpill.Visible = true end
            if sub   then sub.Visible   = true end
            title.Visible = true
            title.Position = UDim2.new(0, 72, 0, 12)
            title.Size = UDim2.new(1, -220, 0, 20)
            title.Text = "LOWHUB"
            title.TextSize = 17
            title.TextXAlignment = Enum.TextXAlignment.Left

            avFrame.Size = UDim2.new(0, 44, 0, 44)
            avFrame.Position = UDim2.new(0, 16, 0.5, -22)
            if avLetter then avLetter.TextSize = 18 end
            pcall(function() avStroke.Transparency = 0.25 end)

            mini.Position  = UDim2.new(1, -42, 0.5, -15)
            close.Position = UDim2.new(1, -78, 0.5, -15)
            close.Visible  = true
            if miniBar then miniBar:Destroy(); miniBar = nil end
        else

            root.Size = UDim2.new(0, 64, 0, 64)

            if vpill then vpill.Visible = false end
            if sub   then sub.Visible   = false end

            title.Text = "LH"
            title.TextSize = 9
            title.TextXAlignment = Enum.TextXAlignment.Center
            title.Position = UDim2.new(0, 0, 1, -14)
            title.Size = UDim2.new(1, 0, 0, 11)


            avFrame.Size = UDim2.new(0, 40, 0, 40)
            avFrame.Position = UDim2.new(0.5, -20, 0, 6)
            if avLetter then avLetter.TextSize = 16 end
            pcall(function() avStroke.Transparency = 0 end)


            mini.Position = UDim2.new(0.5, -11, 1, -22)
            mini.Size = UDim2.new(0, 22, 0, 18)
            close.Visible = false
        end

        mini.Text = v and "–" or "+"
        if v then
            mini.Size = UDim2.new(0, 30, 0, 30)
        end
        dragging = false
        dragGoal = nil
        dragNow  = nil
    end

    mini.MouseEnter:Connect(function()
        mini.BackgroundColor3 = T.card2; mini.TextColor3 = T.text
    end)
    mini.MouseLeave:Connect(function()
        mini.BackgroundColor3 = T.off; mini.TextColor3 = T.dim
    end)
    close.MouseEnter:Connect(function()
        close.BackgroundColor3 = T.bad; close.TextColor3 = Color3.new(1,1,1)
    end)
    close.MouseLeave:Connect(function()
        close.BackgroundColor3 = T.off; close.TextColor3 = T.dim
    end)




    limpar_tudo = function()
        running = false
        pcall(function() UserInputService.MouseBehavior = orig_mouse end)
        pcall(stop_aim)
        pcall(stop_fly)
        pcall(function()
            for plr in pairs(esp_cache) do remove_esp(plr) end
        end)
        if gui then pcall(function() gui:Destroy() end) end
        if fov_gui then pcall(function() fov_gui:Destroy() end) end
        gui, fov_gui, window = nil, nil, nil
    end

    close.MouseButton1Click:Connect(limpar_tudo)




    task.spawn(function()
        local lastExecs = aim_execs
        while running and gui and gui.Parent do
            local n = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if is_enemy(plr) and is_alive(plr) then n = n + 1 end
            end

            local de = aim_execs - lastExecs
            lastExecs = aim_execs


            local emPartida = (my_state() ~= "Lobby")
            chipState.Text = emPartida and ("match  ·  team " .. my_team())
                                    or "lobby  ·  not in a match"
            chipStateDot.BackgroundColor3 = emPartida and T.good or T.dim
            chipState.TextColor3 = emPartida and T.text or T.dim






            local st, col
            if aviso_texto and os.clock() < aviso_ate then
                st, col = aviso_texto, T.warn
            elseif not CONFIG.AimLockEnabled then
                st, col = "aimlock off", T.dim
            elseif locked_plr then
                st, col = "locked on " .. locked_plr.Name, T.accent
            elseif aim_active and fire_sight_plr then
                st, col = "on sight: " .. fire_sight_plr.Name, T.warn
            elseif aim_active then
                st, col = "searching for target", T.warn
            else
                st, col = bind_label() .. " to lock", T.faint
            end
            chipAim.Text = st
            chipAim.TextColor3 = col
            chipAimDot.BackgroundColor3 = col

            chipCount.Text = string.format("%d enemies  ·  %d shots",
                                           n, shots_fired)
            chipCount.TextColor3 = n > 0 and T.text or T.dim

            task.wait(0.1)
        end
    end)

    window = { Root = root, SetOpen = set_open, IsOpen = function() return open end }







    local posAntesDeMinimizar = nil
    local lastToggle = 0

    local function toggle_open()
        local now = os.clock()
        if now - lastToggle < 0.25 then return end
        lastToggle = now

        if open then

            posAntesDeMinimizar = root.Position
            local vx, vy = 1280, 720
            pcall(function()
                local cam = Workspace.CurrentCamera
                if cam and cam.ViewportSize then
                    local vp = cam.ViewportSize
                    if vp.X > 100 and vp.Y > 100 then vx, vy = vp.X, vp.Y end
                end
            end)
            local x = root.AbsolutePosition.X
            local y = root.AbsolutePosition.Y

            if x < 0 then x = 0 end
            if y < 0 then y = 0 end
            if x > vx - 64 then x = vx - 64 end
            if y > vy - 64 then y = vy - 64 end
            set_open(false)
            root.Position = UDim2.new(0, math.floor(x), 0, math.floor(y))
        else
            set_open(true)
            if posAntesDeMinimizar then
                root.Position = posAntesDeMinimizar
            else
                root.Position = centro_tela(W, H)
            end
        end
    end

    mini.MouseButton1Click:Connect(toggle_open)





    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local m  = input.Position
        local bp = mini.AbsolutePosition
        local bs = mini.AbsoluteSize
        local pad = 6
        if m.X >= bp.X - pad and m.X <= bp.X + bs.X + pad
       and m.Y >= bp.Y - pad and m.Y <= bp.Y + bs.Y + pad then
            toggle_open()
        end
    end)




    UserInputService.InputBegan:Connect(function(input, gpe)

        if Keybind.capturing then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    Keybind.capturing = false
                    repaint_keybinds()
                    return
                end
                if Keybind.which == "mouse" then
                    CONFIG.AimMouseButton = nil
                else
                    CONFIG.AimKey = input.KeyCode
                    CONFIG.AimMouseButton = nil
                end
                Keybind.capturing = false
                repaint_keybinds()
                return
            elseif input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.MouseButton2
                or input.UserInputType == Enum.UserInputType.MouseButton3 then
                if Keybind.which == "mouse" then
                    CONFIG.AimMouseButton = input.UserInputType
                    Keybind.capturing = false
                    repaint_keybinds()
                end
                return
            end
            return
        end





        if input.UserInputType == Enum.UserInputType.Keyboard
           and input.KeyCode == Enum.KeyCode.RightShift then
            toggle_open()
            return
        end




        if CONFIG.AimMouseButton
           and input.UserInputType == CONFIG.AimMouseButton then


            if not gpe then
                aim_held = true
                if not CONFIG.AimHoldMode then
                    aim_toggled = not aim_toggled
                end
                recompute_aim_active()
            end
            return
        end

        if gpe then return end


        if input.UserInputType == Enum.UserInputType.Keyboard then
            if not CONFIG.AimMouseButton and input.KeyCode == CONFIG.AimKey then
                aim_held = true
                if not CONFIG.AimHoldMode then
                    aim_toggled = not aim_toggled
                end
                recompute_aim_active()
                return
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if Keybind.capturing then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if not CONFIG.AimMouseButton and input.KeyCode == CONFIG.AimKey then
                aim_held = false
                recompute_aim_active()
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.MouseButton3 then
            if CONFIG.AimMouseButton == input.UserInputType then
                aim_held = false
                recompute_aim_active()
            end
        end
    end)
end

if not game:IsLoaded() then
    local t0 = os.clock()
    while not game:IsLoaded() and os.clock() - t0 < 10 do
        task.wait(0.1)
    end
end

task.wait(0.35)

resolve_attack_mode()

local preset_autoload_aplicado = nil
if FS.tem then
    pcall(function()
        carregar_presets_do_disco()
        ler_autoload()
        if autoload_ativo and autoload_nome and presets[autoload_nome] then
            aplicar_config(presets[autoload_nome])
            preset_autoload_aplicado = autoload_nome
        end
    end)
end

local ok, err = pcall(function()
    build_gui()
    build_fov_circle()
    start_aim()

    task.spawn(function()
        while running and PARENT and PARENT.Parent do
            refresh_esp()
            apply_speed()
            update_fly()
            update_esp_labels()
            apply_mouse_lock()
            task.wait(0.05)
        end
    end)


    if MOUSE_MODE == "camera" and not hook_on then
        task.wait(1)
        G.__LOWHUB_AVISO = true
        local aviso = Instance.new("TextLabel")
        aviso.Name = "AvisoMira"
        aviso.Size = UDim2.new(0, 420, 0, 54)
        aviso.Position = UDim2.new(0.5, -210, 0, 20)
        aviso.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
        aviso.BackgroundTransparency = 0.1
        aviso.BorderSizePixel = 0
        aviso.TextColor3 = Color3.fromRGB(255, 190, 120)
        aviso.Font = Enum.Font.GothamMedium
        aviso.TextSize = 12
        aviso.TextWrapped = true
        aviso.Text = "AIMLOCK NOT SUPPORTED ON THIS EXECUTOR\n" ..
                      "mousemoverel and hookmetamethod are missing. " ..
                      "Use Real, or the aimlock will not lock."
        aviso.ZIndex = 500
        aviso.Parent = PARENT

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 10)
        c.Parent = aviso

        task.delay(12, function()
            pcall(function() aviso:Destroy() end)
        end)
    end

    task.spawn(function()
        while running and PARENT and PARENT.Parent do
            update_fov_circle()
            task.wait()
        end
    end)

    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.4)
            refresh_esp()
        end)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        remove_esp(plr)
    end)

    LP.CharacterAdded:Connect(function()
        task.wait(0.8)
        if CONFIG.FlyEnabled then start_fly() end
    end)
end)

if ok then



    G.__LOWHUB_ATIVO = { limpar = limpar_tudo }
else


    warn("[LowHub] " .. tostring(err))
end

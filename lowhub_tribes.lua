local VERSION = "LowHub"
local limpar_tudo = nil

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

--[[ MARCADOR DE VIDA

     O usuario relatou "nao executou" - sem menu, sem console. Isso
     significa que a morte acontece antes de qualquer coisa visivel.
     Este print sai ASSIM QUE o guard do jogo passa, pra separar:

       - se ESTA linha nao aparecer -> o script morreu no guard ou
         antes dele (nem chegou aqui)
       - se aparecer e nada mais -> morreu entre aqui e o menu
     ============================================================ ]]
pcall(function()
    if type(print) == "function" then
        print("[LowHub] passou o guard do jogo - carregando...")
    end
end)

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

--[[ ============================================================
     MOUSE DESLIGADO - A CAUSA DO BUG EM TERCEIRA PESSOA

     Aqui o codigo fazia:

         local MOUSE_MODE = "camera"
         if f_mouserel then MOUSE_MODE = "rel"
         elseif f_mouseabs then MOUSE_MODE = "abs" end

     Ou seja: bastava o executor EXPOR `mousemoverel` pra o hub
     passar a mirar por mouse em vez de por camera. O Xeno expoe -
     entao o modo mouse ligava sozinho.

     COMPARACAO QUE PROVA O PROBLEMA

     As versoes que funcionavam (lowhub_v1.8, LowHub_v2.1,
     lowhub_v2.3, tribos_3v3_v19) foram conferidas uma por uma:

         lowhub_v2.3.lua      -> 0 ocorrencias de mouse
         LowHub_v2.1.lua      -> 0 ocorrencias de mouse
         lowhub_v1.8.lua      -> 0 ocorrencias de mouse
         tribos_3v3_v19.lua   -> 0 ocorrencias de mouse

     NENHUMA delas usava mouse. Todas so' escreviam Camera.CFrame,
     e a mira funcionava nos dois modos de camera.

     Esta versao tem 18 ocorrencias de mouse - um subsistema inteiro
     (MOUSE_MODE, mirar_com_mouse, centro_da_tela, mousemoverel) que
     as antigas nao tinham. Foi codigo novo que quebrou o que
     funcionava.

     POR QUE O MOUSE NAO SERVE AQUI

     `WorldToViewportPoint` + `mousemoverel` dependem de PROJECAO na
     tela. Isso funciona em primeira pessoa, onde girar a camera nao
     muda a posicao dela. Em terceira pessoa a camera orbita o
     personagem: cada delta de mouse desloca a camera no mundo, o
     aim_step reenvia delta ~60x por segundo, e o movimento do mouse
     do proprio usuario entra no mesmo frame. A tela fica instavel.

     O `Camera.CFrame` nao tem nada disso: e' ABSOLUTO, escreve a
     direcao direto, nao acumula e nao depende de onde o cursor esta'.

     CORRECAO: MOUSE_MODE fica sempre "camera". O subsistema de mouse
     continua no arquivo (nao removido) mas nunca liga sozinho.
     ============================================================ ]]
local MOUSE_MODE = "camera"

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

-- (aqui ficava a memoria do suavizador paralelo - suave_look,
--  suave_look_t, suave_look_ant - e o contador alvo_falhas da
--  tolerancia de lock. Tudo removido: o suavizador voltou a ser
--  o da v2.3, que le a camera VIVA a cada frame e nao guarda
--  estado nenhum, entao nao tem como dessincronizar dela.)
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

--[[ ============================================================
     MIRA EM YAW/PITCH - TECNICA DO RIVALS

     Ver o bloco no aim_step pra explicacao completa. Resumo:

     Girar direcao com `Lerp` de VETOR nao funciona - o resultado
     nao fica unitario e a direcao chega torta (1.12 graus de erro
     por frame, medido no Rivals).

     O certo e' quebrar a direcao em dois ANGULOS:
         yaw   = giro horizontal (esquerda/direita)
         pitch = giro vertical   (cima/baixo)

     e andar um teto fixo de graus por frame em cada um, nunca
     passando do alvo. Sem overshoot, sem tremor, e o erro vai a
     zero mesmo com alvo correndo.
     ============================================================ ]]

-- teto de velocidade da mira, em GRAUS POR FRAME.
-- 14 a 60fps = 840 graus/s - acompanha qualquer alvo mais lento
-- que isso. Quanto menor, mais "legit" (e mais lento).
local AIM_GRAUS_MAX    = 14

-- direcao (vetor unitario) -> yaw, pitch em radianos
local function direcao_para_yaw_pitch(v)
    local horiz = math.sqrt(v.X * v.X + v.Z * v.Z)
    local yaw   = math.atan2(-v.X, -v.Z)
    local pitch = math.atan2(v.Y, horiz)
    return yaw, pitch
end

-- yaw, pitch em radianos -> direcao (vetor unitario)
local function yaw_pitch_para_direcao(yaw, pitch)
    local cp = math.cos(pitch)
    return Vector3.new(-math.sin(yaw) * cp,
                        math.sin(pitch),
                       -math.cos(yaw) * cp)
end

-- diferenca angular pelo CAMINHO CURTO.
-- Sem isso, ir de 179 graus pra -179 daria a volta inteira (358)
-- em vez de andar 2 graus pelo lado de ca'.
local function menor_angulo(de, para)
    local d = para - de
    while d >  math.pi do d = d - math.pi * 2 end
    while d < -math.pi do d = d + math.pi * 2 end
    return d
end

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

local AVISO_UI = nil

local function avisar(msg)
    aviso_texto = msg
    aviso_ate   = os.clock() + 4
    if AVISO_UI then
        pcall(function()
            AVISO_UI.Text = msg
            AVISO_UI.Visible = true
        end)
    end
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

--[[ ============================================================
     tem_parede - DE ONDE O RAIO DEVE SAIR

     Relato: "wallcheck do autofire ta atirando em pessoas pela
     parede".

     O raio sempre saiu da CAMERA:

         tem_parede(Camera.CFrame.Position, part)

     Em PRIMEIRA pessoa isso e' perfeito - a camera esta' na cabeca,
     o raio sai do mesmo lugar que o tiro.

     Em TERCEIRA pessoa a camera fica ~11 studs atras. E o Roblox
     tem colisao de camera: quando algo entra entre a camera e o
     personagem, ele EMPURRA a camera pra frente. Se ela acabar do
     outro lado de uma parede, o raio comeca DEPOIS do obstaculo,
     nao bate em nada, e o autofire conclui "caminho livre" - atira
     na parede.

     Aqui tambem havia um descuido: o raio ia de `from_pos` ate'
     `target_part.Position` com distancia `dist - 0.5`. Os 0.5 studs
     de folga evitavam o auto-hit no alvo, mas quando o alvo estava
     COLADO numa parede a folga curta escondia a parede.

     CORRECAO: raycast sai do PERSONAGEM (o HumanoidRootPart, ou a
     cabeca se nao houver root) - e' de la' que o tiro realmente sai.
     A folga do fim virou proporcional, com minimo maior, pra nao
     esconder parede em alvo encostado nela.
     ============================================================ ]]
local function origem_do_tiro()
    local meu = LP and LP.Character
    if not meu then return nil end
    local raiz = meu:FindFirstChild("HumanoidRootPart")
    if raiz then return raiz.Position end
    local cabeca = meu:FindFirstChild("Head")
    if cabeca then return cabeca.Position end
    return nil
end

local function tem_parede(from_pos, target_part)
    if not CONFIG.WallCheck then return false end
    if not wall_params then return false end
    if not target_part or not target_part.Parent then return false end

    --[[ SAI DO PERSONAGEM, NAO DA CAMERA

         Se por algum motivo nao der pra achar o personagem (respawn
         em andamento, por exemplo), cai de volta na posicao recebida.
         Melhor um wallcheck imperfeito do que nenhum.
         ============================================================ ]]
    local origem = origem_do_tiro() or from_pos

    local dir = target_part.Position - origem
    local dist = dir.Magnitude
    if dist < 1 then return false end

    local ignorar = {}
    local meu = LP and LP.Character
    if meu then ignorar[#ignorar + 1] = meu end
    if target_part.Parent then ignorar[#ignorar + 1] = target_part.Parent end
    wall_params.FilterDescendantsInstances = ignorar

    -- folga no fim: nao deixa o raio encostar no alvo (senao ele
    -- mesmo conta como parede). Proporcional, com piso de 1.5 studs,
    -- pra alvo colado em parede nao esconder o obstaculo.
    local folga = math.max(1.5, dist * 0.05)
    local alcance = dist - folga
    if alcance <= 0 then return false end

    local ok, hit = pcall(function()
        return Workspace:Raycast(origem, dir.Unit * alcance, wall_params)
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

--[[ MEMORIA DO MODO MOUSE

     O mousemoverel do Xeno FUNCIONA (medido: mexeu 2.5x mais que a
     deriva natural do jogo). Mas nem todo executor que expoe a funcao
     faz ela funcionar de verdade.

     Em vez de testar a cada frame (caro e instavel), damos ate' 8
     chances. Se nenhuma mexer a camera, desistimos e usamos sempre o
     Camera.CFrame. Se mexer uma vez, confiamos pelo resto da sessao.
     ============================================================ ]]
local mouse_ok          = false
local mouse_desistiu    = false
local mouse_tentativas  = 0

--[[ DISTANCIA ATE' O ALVO

     Usada em mirar_com_mouse pra projetar o alvo na tela no lugar
     certo. O aim_step atualiza isso a cada tick com a distancia real
     ate' o inimigo travado. Se ficar nil (sem alvo), a funcao usa
     100 studs como valor neutro.
     ============================================================ ]]
local ALVO_DIST         = nil

--[[ ============================================================
     centro_da_tela - O BUG DA MIRA ALTA

     O codigo antigo era:

         local ok, inset = pcall(function()
             return game:GetService("GuiService"):GetGuiInset()
         end)
         local off = (ok and inset and inset.Y) or 0
         return vs.X / 2, (vs.Y / 2) + off

     Ou seja: somava o GuiInset.Y (36 pixels, medido no Xeno) no
     centro vertical.

     POR QUE ISSO ERRA: o `Camera:WorldToViewportPoint()` - que e'
     quem produz o `sp` comparado aqui - JA' devolve a coordenada no
     espaco do VIEWPORT, que e' a area 3D pura, sem a barra de topo.
     O inset nao entra nessa conta.

     Entao o centro ficava 36 pixels ABAIXO do centro real:

         ViewportSize.Y = 1009
         centro certo   =  504.5
         centro usado   =  540.5     <- 36 px abaixo

     Efeito: o codigo calculava

         dy = sp.Y - cy

     Com `cy` maior, o `dy` saia sempre deslocado. O mouse era movido
     para cima demais e a mira parava ACIMA da cabeca do inimigo -
     exatamente o defeito relatado ("puxa mas fica bem acima deles").

     O erro e' constante (nao depende da distancia ate' o alvo),
     entao o desvio parece o mesmo em qualquer inimigo.

     CORRECAO: centro = metade do viewport, sem somar inset.
     ============================================================ ]]
local function centro_da_tela()
    local cam = Camera
    if not cam then return nil, nil end
    local vs = cam.ViewportSize
    if not vs then return nil, nil end
    return vs.X / 2, vs.Y / 2
end

local function mirar_com_mouse(goal_look)
    --[[ DESLIGADO DE PROPOSITO

         MOUSE_MODE agora e' sempre "camera" (ver o bloco la' em cima,
         onde ficava a decisao automatica). Entao esta funcao sai aqui
         na primeira linha e o aim_step usa sempre:

             Camera.CFrame = CFrame.lookAt(from, from + goal_look)

         que e' exatamente o que as versoes antigas faziam - as que
         funcionavam nos dois modos de camera.

         O corpo da funcao ficou guardado porque `MOUSE_MODE` ainda
         pode ser trocado pra "rel"/"abs" na mao (debug futuro). Se
         isso acontecer, ele volta a funcionar. Nao removi pra nao
         perder o codigo, mas ele NAO roda no fluxo normal.
         ============================================================ ]]
    if MOUSE_MODE == "camera" then return false end

    -- ja' provamos que o mouse nao faz nada aqui: nao perde tempo
    if mouse_desistiu then return false end

    local cam = Camera
    if not cam then return false end

    local pos = cam.CFrame.Position
    --[[ PONTO DE PROJECAO

         Antes era sempre `pos + goal_look * 100` - um ponto fixo a
         100 studs. Isso nao leva em conta onde o alvo realmente esta'.

         Agora usamos a distancia REAL ate' o alvo quando ela e'
         conhecida, com limites pra nao ficar perto demais (a projecao
         fica instavel) nem longe demais (perde precisao).
         ============================================================ ]]
    local dist_alvo = ALVO_DIST or 100
    dist_alvo = math.clamp(dist_alvo, 20, 2000)
    local alvo3d = pos + goal_look * dist_alvo
    local ok, sp = pcall(function()
        return cam:WorldToViewportPoint(alvo3d)
    end)
    if not ok or not sp then return false end

    --[[ O ALVO ESTA' ATRAS DA CAMERA?

         `WorldToViewportPoint` devolve Z NEGATIVO quando o ponto esta'
         atras da camera. Nesse caso X e Y vem INVERTIDOS - nao e' uma
         projecao valida, e usar dx/dy dali manda a mira pro lado errado.

         Isso acontece muito em TERCEIRA PESSOA, porque o proprio
         personagem fica entre a camera e a mira. Era uma das causas
         da mira "solta" nesse modo.

         Se estiver atras, nao da' pra corrigir por pixel: devolvemos
         `false` e o aim_step cai no Camera.CFrame, que resolve por
         direcao e nao depende de projecao.
         ============================================================ ]]
    if sp.Z <= 0 then return false end

    -- alvo quase colado na camera (menos de 1 stud): a projecao
    -- dispara pra qualquer lado e o mouse da' um solavanco gigante.
    -- Melhor deixar o Camera.CFrame resolver por direcao.
    if sp.Z < 1 then return false end

    local cx, cy = centro_da_tela()
    if not cx then return false end

    local dx = sp.X - cx
    local dy = sp.Y - cy

    if math.abs(dx) < 1 and math.abs(dy) < 1 then return true end

    --[[ LIMITE DE MOVIMENTO POR FRAME

         Sem limite, quando o alvo entra de repente pela lateral (troca
         de alvo, respawn, alguem passando correndo) o `dx` pode passar
         de 900 pixels e a camera da' um GIRO BRUSCO - a tela "chicoteia".

         Isso aparece mais em terceira pessoa, porque a camera tem mais
         espaco pra se mover.

         Limitamos a 220 pixels por frame. A mira chega no alvo em
         poucos frames e o movimento fica suave. O valor e' folgado o
         bastante pra nao atrasar a captura de alvos proximos.
         ============================================================ ]]
    local LIMITE = 220
    dx = math.clamp(dx, -LIMITE, LIMITE)
    dy = math.clamp(dy, -LIMITE, LIMITE)

    local mx = (dx >= 0) and math.floor(dx + 0.5) or math.ceil(dx - 0.5)
    local my = (dy >= 0) and math.floor(dy + 0.5) or math.ceil(dy - 0.5)

    if mx == 0 and my == 0 then return true end

    --[[ ============================================================
         O CODIGO QUE MENTIA

         Antes era:

             pcall(function()
                 if MOUSE_MODE == "rel" then f_mouserel(mx, my)
                 else f_mouseabs(cx + mx, cy + my) end
             end)
             return true          <-- MENTIA

         O `pcall` engolia qualquer erro e o `return true` acontecia
         SEMPRE, mesmo quando a funcao de mouse nao fazia nada. Como
         quem chama usa o retorno pra decidir se tenta o proximo
         caminho, um `true` falso bloqueava o plano B:

             else
                 Camera.CFrame = CFrame.lookAt(from, from + goal_look)
             end

         Correcao: so' devolve `true` se o vetor de olhar da camera
         REALMENTE mudou depois da chamada.

         MEDIDO NO XENO (teste de camera): o `mousemoverel` FUNCIONA
         la' - mexeu 2.5x mais que a deriva natural do jogo. Entao
         este caminho costuma dar `true` de verdade.
         ============================================================ ]]
    local olhar_antes = cam.CFrame.LookVector

    local okmove = pcall(function()
        if MOUSE_MODE == "rel" then
            f_mouserel(mx, my)
        else
            f_mouseabs(cx + mx, cy + my)
        end
    end)

    if not okmove then return false end

    --[[ ============================================================
         NAO ESPERAR FRAME AQUI - ISSO TRAVAVA O AIMLOCK

         O codigo tinha:

             pcall(function() RunService.RenderStepped:Wait() end)

         Mas o aim_step roda em BindToRenderStep("z_aim", ...) - ou
         seja, DENTRO do proprio RenderStepped. Esperar por ele ali
         nunca retorna: o script fica pendurado e o resto do aim_step
         (inclusive o Camera.CFrame) nunca executa.

         Foi exatamente esse padrao que travou o teste de camera no
         meio. Aqui dentro e' ainda pior, porque e' chamado TODO FRAME.

         Em vez de esperar, medimos na hora mesmo. O mousemoverel do
         Roblox aplica o movimento na camera imediatamente quando
         chamado, entao da' pra comparar sem esperar.
         ============================================================ ]]
    --[[ JA' SABEMOS QUE FUNCIONA

         Depois da primeira vez que o mouse mexeu a camera de verdade,
         nao precisa mais medir: so' chama e devolve `true`. Medir toda
         hora custaria leitura de CFrame por frame sem ganho nenhum.
         ============================================================ ]]
    if mouse_ok then return true end

    local olhar_depois = cam.CFrame.LookVector
    local mudou = (olhar_depois - olhar_antes).Magnitude

    if mudou > 0.0005 then
        mouse_ok = true
        return true
    end

    --[[ A FUNCAO NAO MEXEU A CAMERA AGORA.

         Pode ser dois casos:

           1) o executor tem a funcao mas ela nao controla o cursor
              (foi o caso do Xeno ANTES do teste: existia e nao fazia
              nada) -> nunca vai funcionar, desiste de vez

           2) o executor aplica o movimento de forma ASSINCRONA - o
              efeito aparece no proximo frame, nao na hora. Medir no
              mesmo instante da' zero, mas a funcao serve.

         Como separar sem esperar frame (esperar trava, ver acima):
         damos algumas chances. Se em N chamadas seguidas nunca mexer
         nada, e' o caso 1 e desistimos de vez. Se mexer, marcamos e
         paramos de medir - a partir daí confiamos direto.
         ============================================================ ]]
    mouse_tentativas = mouse_tentativas + 1

    if mouse_tentativas >= 8 then
        -- 8 chamadas sem nenhum efeito: a funcao e' inutil aqui
        mouse_desistiu = true
        return false
    end

    -- ainda na duvida: deixa o aim_step tentar o Camera.CFrame
    -- tambem, mas continue testando nos proximos frames
    return false
end

local function aim_step()
    aim_execs = aim_execs + 1
    desired_look = nil
    --[[ ============================================================
         VOLTAMOS AO aim_step DA v2.3

         O usuario foi direto: "o aimlock ta ficando pior a cada
         tentativa sua, olha versoes anteriores e tenta resolver".

         Ele esta' certo. Comparei o aim_step da v2.3 (a versao em que
         o lock funcionava) com o meu:

             v2.3 : 46 linhas
             meu  : 376 linhas

         Eu acumulei, ao longo da sessao, uma pilha de remendos em
         cima de um codigo que JA' funcionava:

             suave_look / suave_look_ant / suave_look_t  (suavizador paralelo)
             travada / olhar_cam / parada / base         (heuristica de "o jogo travou a camera")
             cam_viva                                    (recaptura de camera)
             alvo_falhas                                 (tolerancia de lock)
             mira_modo / ALVO_DIST                       (subsistema de mouse)

         Cada um desses remendos resolvia um sintoma e criava outro.
         O suavizador paralelo, em especial, brigava com o suavizador
         original - era ele que causava a camera "desgrudando" em
         terceira pessoa, e foi pra consertar ISSO que eu adicionei a
         heuristica `travada`, que por sua vez me obrigou a mexer na
         posicao da camera, e assim por diante.

         O suavizador da v2.3 e' UMA linha:

             goal_look = cam.LookVector:Lerp(goal_look, rate).Unit

         Ele le a camera VIVA a cada frame e mistura com o alvo. Nao
         guarda estado nenhum, entao nao tem como dessincronizar da
         camera - nem em primeira, nem em terceira pessoa.

         Aqui nao recapturamos mais a camera a cada tick. O
         `Camera` e' reatribuido no respawn (ver o handler de
         CharacterAdded), que e' onde isso realmente importa.         ============================================================ ]]

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

    --[[ ============================================================
         BLOCO DO LOCK - IDENTICO A v2.3

         Por que o lock "soltava" e por que o original esta' certo:

         O `target_valid` checa SO' duas coisas - se continua sendo
         inimigo e se esta' vivo. Ele nao olha FOV, nao olha distancia.

         Quem filtra por FOV e' o `acquire`, e o `acquire` SO' roda
         quando `locked_target` ja' e' nil. Ou seja: puxar a mira NAO
         derruba o lock - o alvo continua travado mesmo fora do campo
         de visao, exatamente como deve ser.
         ============================================================ ]]
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
            legit_react   = 0        -- atraso vale a cada alvo novo
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

    -- distancia real ate' o alvo: o mirar_com_mouse usa isso pra
    -- projetar o ponto certo na tela (em vez dos 100 studs fixos)
    ALVO_DIST = to_target.Magnitude

    local goal_look = to_target.Unit
    legit_last = goal_look
    legit_hold = CONFIG.LegitLostKeep

    if CONFIG.AimMode == "legit" then

        goal_look = legit_aim(cam.LookVector, goal_look, dt, now)
    else

        --[[ ============================================================
             SUAVIZADOR - DE VOLTA AO DA v2.3 (UMA LINHA)

             Aqui empilhei, ao longo da sessao, um suavizador paralelo
             inteiro: memoria propria (`suave_look`), deteccao de
             camera travada (`travada`), base hibrida, reset por
             tempo. Tudo pra resolver um sintoma que eu mesmo tinha
             criado na tentativa anterior.

             O suavizador da v2.3 e' isto:

                 goal_look = cam.LookVector:Lerp(goal_look, rate).Unit

             Ele le a CAMERA VIVA a cada frame e mistura com o alvo.
             Nao guarda estado nenhum - nao existe como dessincronizar
             da camera, porque nao ha' memoria pra ficar velha.

             Em primeira pessoa: a camera esta' na cabeca e o Lerp
             converge pro alvo. Funciona.

             Em terceira pessoa: a camera ORBITA o personagem. Como
             lemos a posicao e a direcao DELA a cada frame, a orbita
             e' acompanhada naturalmente. Funciona tambem.

             Era isso que faltava entender: eu tratei o "preso em
             primeira pessoa" como se o Lerp a partir da camera fosse
             o problema, e troquei por memoria propria - que e'
             justamente o que quebra a terceira pessoa. O problema
             real nunca foi a base do Lerp.
             ============================================================ ]]
        --[[ ============================================================
             APLICANDO A MIRA DO RIVALS AQUI

             O usuario lembrou: "nao da pra aplicar o mesmo de rivals
             nesse jogo?". Deu, e o Rivals ja' tinha resolvido os DOIS
             problemas que eu estava apanhando - ele documentou:

             ERRO 1 - Lerp de VETOR nao serve pra girar direcao
                 `a:Lerp(b, f)` interpola componente por componente e o
                 resultado NAO fica unitario. O meio de dois pontos de
                 uma esfera fica DENTRO dela, e a linha do centro ate
                 esse ponto nao passa pelo alvo. Medido no Rivals:
                 1.12 graus de erro por frame.

                 Era o que eu fazia:
                     mira_mem:Lerp(goal_look, rate).Unit

                 O `.Unit` esconde o erro de magnitude, mas a DIRECAO
                 continua chegando torta. Somando com a reescrita da
                 camera pelo jogo, virava o tremor.

             ERRO 2 - fracao do resto nunca fecha com alvo ANDANDO
                 erro_novo = erro * (1 - ganho)

                 Com o alvo parado converge em 3 frames e parece
                 otimo. Com o alvo ANDANDO, cada frame soma de volta o
                 movimento:
                     erro_novo = erro * (1 - ganho) + movimento
                 Quando o alvo anda mais rapido que a fracao que eu
                 recupero, o erro ESTABILIZA alto e NUNCA fecha.

                 E' o nosso "nao locka em ninguem": a mira fica colada
                 num angulo atras, sempre puxando e nunca chegando.

             A SOLUCAO DO RIVALS (adotada aqui)

             Trabalhar em YAW/PITCH - dois angulos, um por eixo - e
             andar um TETO FIXO de graus por frame, nunca passando do
             alvo:

                 passo = clamp(erro_em_graus, -teto, teto)
                 yaw   = yaw_atual   + passo
                 pitch = pitch_atual + passo

             Duas vantagens que importam MUITO aqui:

             1. NAO usa Lerp de vetor -> nao tem o erro de 1.12 graus.

             2. A posicao de partida (y0, p0) vem da camera VIVA, mas
                o ALVO (y1, p1) e' absoluto. Entao, se o jogo reescrever
                a camera, no frame seguinte lemos a camera reescrita e
                continuamos de la' - sem acumular erro, sem oscilar.
                O clamp garante que nunca passamos do alvo: sem
                overshoot, sem tremor.

             E como o teto controla a VELOCIDADE (nao a fracao), o
             erro vai a zero de verdade mesmo com alvo correndo -
             desde que ele ande menos que o teto.
             ============================================================ ]]
        if CONFIG.AimSmoothLock then
            local y0, p0 = direcao_para_yaw_pitch(cam.LookVector)
            local y1, p1 = direcao_para_yaw_pitch(goal_look)

            -- erro em GRAUS, por eixo (menor caminho no yaw)
            local dy_g = math.deg(menor_angulo(y0, y1))
            local dp_g = math.deg(p1 - p0)

            -- teto fixo de graus por frame (ver comentario la em cima)
            local teto = AIM_GRAUS_MAX

            -- anda ate o teto, mas NUNCA passa do alvo
            local passo_y = math.clamp(dy_g, -teto, teto)
            local passo_p = math.clamp(dp_g, -teto, teto)

            local yaw   = y0 + math.rad(passo_y)
            local pitch = p0 + math.rad(passo_p)

            goal_look = yaw_pitch_para_direcao(yaw, pitch)
        end
    end

    if CONFIG.HookCamera and hook_on then
        desired_look = goal_look
        mira_modo = "hook"
    elseif mirar_com_mouse(goal_look) then
        mira_modo = MOUSE_MODE == "rel" and "mouse" or "mouse-abs"
    else
        --[[ ============================================================
             A CAMERA DESGRUDANDO EM TERCEIRA PESSOA

             Eu tentei "preservar a posicao" assim:

                 local base = viva.CFrame
                 viva.CFrame = CFrame.lookAt(base.Position,
                                             base.Position + goal_look)

             Parecia seguro, mas em TERCEIRA PESSOA ele quebra tudo.
             Relato do usuario: "a camera desgruda do personagem e vai
             pra longe", so' enquanto segura a tecla.

             Por que: em terceira pessoa a camera ORBITA o personagem.
             A posicao dela e' derivada - o Roblox recalcula a cada
             frame a partir do zoom e do angulo. Ao ESCREVER a posicao
             explicitamente, nos congelamos um valor que o Roblox ia
             recalcular, e o sistema de camera do jogo entende aquilo
             como um zoom novo. No frame seguinte ele parte daquele
             valor e recalcula de novo - e a distancia cresce sem
             parar. A camera vai embora.

             Em primeira pessoa nao aparece: a camera esta' presa na
             cabeca, o Roblox nao tem zoom pra recalcular.

             CORRECAO: nao escrever posicao nenhuma. Usar o `from` lido
             da camera e deixar o Roblox cuidar da orbita e do zoom -
             nos so' apontamos a direcao. E' o comportamento original,
             que funcionava em terceira pessoa.
             ============================================================ ]]
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

--[[ ============================================================
     aim_tick_seguro - A PROTECAO QUE FALTAVA NO AIMLOCK

     O start_aim fazia:

         RunService:BindToRenderStep("z_aim", 2000, aim_step)

     Passando aim_step DIRETO. O problema: se aim_step der QUALQUER
     erro (um nil, um atributo que nao existe, uma propriedade que o
     jogo mudou), o BindToRenderStep DESCONECTA sozinho e o aimlock
     para de rodar no meio do jogo - sem erro na tela, sem aviso.

     E' exatamente o sintoma relatado: liga, funciona um pouco, e
     depois a mira simplesmente nao responde mais.

     Agora todo tick passa por pcall. Se der erro, avisa UMA vez no
     console (pra nao inundar) e continua tentando nos proximos
     frames - assim um erro passageiro nao mata a mira pra sempre.
     ============================================================ ]]
local aim_erro_avisado = false

-- conexao da mira com o RenderStepped (ver o bloco em start_aim)
local aim_conn         = nil

local function aim_tick_seguro()
    local ok, err = pcall(aim_step)
    if not ok and not aim_erro_avisado then
        aim_erro_avisado = true
        if type(warn) == "function" then
            warn("[LowHub] erro no aimlock: " .. tostring(err))
        end
    end
    return ok
end

--[[ ============================================================
     ONDE A MIRA RODA - A CAUSA DOS DOIS BUGS

     Relato do usuario, e ele esta' certo:
         "literalmente a mesma coisa da ultima vez: voce faz esse
          bug, resolve, e faz o outro bug de a mira solta facil
          mexendo o mouse"

     Eu estava trocando UM bug pelo outro porque mexia no CONTEUDO
     da mira (suavizador, posicao, memoria). O problema nunca foi o
     conteudo - era ONDE a mira roda.

     COMO EU DESCOBRI: o usuario pediu pra testar o hub do Rivals.
     Ele nao rodou la' (o Rivals tem trava de jogo), mas lendo o
     codigo dele apareceu a diferenca que eu nao tinha visto:

         RIVALS: loop_conn = RunService.RenderStepped:Connect(passo)
         MEU   : RunService:BindToRenderStep("z_aim", 2000, ...)

     BindToRenderStep NAO e' "RenderStepped com prioridade". E' uma
     FILA ordenada, e o Roblox roda a fila assim:

         Input(100) -> Camera(200) -> Character(300) -> ... -> 2000 (eu)

     Depois da fila ainda rodam os passos do PROPRIO JOGO, e o
     RenderStepped por ultimo. Quem escreve depois, vence.

     POR QUE ISSO EXPLICA OS DOIS BUGS

     1) "a mira solta facil mexendo o mouse"
        O input do mouse entra na fila ANTES de nos (prioridade 100)
        e a camera do jogo logo depois (200). Quando o jogador mexe o
        mouse, ele escreve a camera, a gente escreve por cima, e o
        que vier DEPOIS de nos no frame tambem passa por cima. Quanto
        mais movimento de mouse, mais sobrescrita - a mira "solta".

     2) "a camera desgruda em terceira pessoa"
        Em 3a pessoa a posicao da camera e' DERIVADA da orbita. Nos
        escrevemos no meio do frame; o sistema de camera do jogo roda
        depois, parte da posicao que deixamos e recalcula. O ponto
        nao fecha com a orbita e a distancia cresce.

     POR QUE O RenderStepped RESOLVE

     Ele roda DEPOIS de tudo: da fila inteira, do input, da camera
     do jogo e dos passos proprios do jogo. E' o ultimo momento antes
     do desenho. Escrevendo ali, ninguem sobrescreve no mesmo frame -
     nem o input do mouse, nem a camera do jogo.

     E' por isso que o Rivals nunca teve nenhum dos dois bugs.
     ============================================================ ]]
local function aim_loop()
    aim_tick_seguro()
end

local function start_aim()
    -- desliga qualquer conexao anterior (dos dois tipos, porque
    -- versoes antigas usavam BindToRenderStep com o nome "z_aim")
    pcall(function() RunService:UnbindFromRenderStep("z_aim") end)
    pcall(function() if aim_conn then aim_conn:Disconnect() end end)

    aim_conn = RunService.RenderStepped:Connect(aim_loop)

    if CONFIG.HookCamera then install_hook() end
    start_delta_killer()
    if CONFIG.CutSubject then start_subject_cutter() end
end

local function stop_aim()
    pcall(function() RunService:UnbindFromRenderStep("z_aim") end)
    pcall(function() if aim_conn then aim_conn:Disconnect() aim_conn = nil end end)
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

--[[ ============================================================
     ESP - O BUG DO "AS VEZES APARECE, AS VEZES NAO"

     Relato: "as vezes aparece, as vezes nao" - e antes funcionava
     perfeitamente.

     A CAUSA: o ESP era pendurado DENTRO do personagem do inimigo.

         hl.Parent = char        -- Highlight dentro do Character
         bb.Parent = char        -- BillboardGui tambem

     Isso funciona enquanto o personagem vive. Mas o Roblox DESTROI
     o Character quando o dono morre - e leva o nosso ESP junto, sem
     avisar ninguem. O `esp_cache` continua com uma referencia morta,
     e o `refresh_esp` so' percebe quando compara

         e.adornee ~= plr.Character

     ...mas so' quando aquele jogador JA' esta' vivo de novo E passa
     no `is_alive`. Enquanto o personagem esta' no meio do respawn,
     o `is_alive` da' false e o ESP nao e' recriado. Resultado: some
     por um tempo e volta depois, de forma irregular - exatamente o
     que o usuario descreve.

     CORRECAO: pendurar o ESP numa pasta nossa, que nao morre junto
     com ninguem. O `Adornee` continua apontando pro personagem, que
     e' o que faz o Highlight e o Billboard seguirem o alvo.

     Bonus: se a pasta for destruida (o hub desligar), tudo vai junto.
     ============================================================ ]]
local esp_folder = nil

local function pasta_esp()
    -- reaproveita se existir, recria se alguem apagou
    if esp_folder and esp_folder.Parent then return esp_folder end
    local ok, p = pcall(function()
        local f = Instance.new("Folder")
        f.Name = "Z_esp"
        f.Parent = game:GetService("CoreGui")
        return f
    end)
    if ok and p then esp_folder = p; return p end

    -- CoreGui pode estar bloqueado em alguns executores: tenta a
    -- pasta raiz do Workspace, que sempre existe
    pcall(function()
        local f = Instance.new("Folder")
        f.Name = "Z_esp"
        f.Parent = Workspace
        esp_folder = f
    end)
    return esp_folder
end

local function make_esp(plr, color)
    local char = plr.Character
    if not char then return end
    local root = get_root(plr)
    if not root then return end

    local pasta = pasta_esp()

    local hl = Instance.new("Highlight")
    hl.Name = "Z_hl"; hl.Adornee = char
    hl.FillColor = color; hl.FillTransparency = 0.6
    hl.OutlineColor = color; hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    -- dentro da NOSSA pasta, nao do personagem do inimigo: assim o
    -- ESP nao morre junto quando ele morre
    hl.Parent = pasta or char

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
    bb.Parent = pasta or char

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

--[[ ============================================================
     refresh_esp - NAO DEIXAR O CACHE FICAR SUJO

     Duas coisas faziam o ESP piscar:

     1) Quando o ESP era filho do Character, a morte do inimigo
        destruia ele - mas o `esp_cache` seguia com a entrada. O
        `e.adornee ~= plr.Character` detectava, porem so' quando o
        jogador JA' passava no `is_alive`. No meio do respawn o ESP
        ficava invisivel.

     2) Se alguem apagasse o ESP por fora (o jogo limpando o
        personagem, por exemplo), o cache continuava achando que ele
        existia e nunca recriava.

     Agora: antes de decidir, conferimos se o ESP AINDA EXISTE no
     mundo. Se sumiu, jogamos fora a entrada e criamos de novo no
     mesmo frame - sem janela cega.
     ============================================================ ]]
local function esp_vivo(e)
    if not e then return false end
    local ok, hl = pcall(function() return e.highlight and e.highlight.Parent end)
    local ok2, bb = pcall(function() return e.billboard and e.billboard.Parent end)
    return (ok and hl ~= nil) and (ok2 and bb ~= nil)
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
                -- recria se: nunca existiu, trocou de personagem,
                -- ou o objeto foi destruido por fora
                if not e or e.adornee ~= plr.Character or not esp_vivo(e) then
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
    bg      = Color3.fromRGB(14, 12, 20),
    header  = Color3.fromRGB(20, 17, 28),
    sidebar = Color3.fromRGB(20, 17, 28),
    card    = Color3.fromRGB(26, 22, 36),
    card2   = Color3.fromRGB(32, 27, 44),
    card3   = Color3.fromRGB(38, 32, 52),
    line    = Color3.fromRGB(44, 38, 60),
    text    = Color3.fromRGB(238, 234, 248),
    dim     = Color3.fromRGB(150, 142, 172),
    faint   = Color3.fromRGB(112, 106, 130),
    accent  = Color3.fromRGB(150, 92, 245),
    accentD = Color3.fromRGB(56, 34, 92),
    accent2 = Color3.fromRGB(190, 140, 255),
    accent2D= Color3.fromRGB(72, 44, 120),
    off     = Color3.fromRGB(32, 27, 44),
    warn    = Color3.fromRGB(255, 196, 100),
    bad     = Color3.fromRGB(240, 85, 105),
    good    = Color3.fromRGB(90, 220, 140),
}

local FB = Enum.Font.GothamBold
local F  = Enum.Font.Gotham
local FM = Enum.Font.Code

local UIX = {}

function UIX.avatar_url(user_id, size)
    return "https://www.roblox.com/headshot-thumbnail/image?userId="
        .. tostring(user_id) .. "&width=" .. tostring(size)
        .. "&height=" .. tostring(size) .. "&format=png"
end

function UIX.baixar_avatar()
    local uid = LP and LP.UserId
    if not uid or uid <= 0 then return nil end
    if type(game.HttpGet) ~= "function" then return nil end

    local tentativas = {
        UIX.avatar_url(uid, 150),
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

function UIX.corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8); c.Parent = p
    return c
end

function UIX.stroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or T.line
    s.Thickness = th or 1
    s.Transparency = tr or 0.4
    s.Parent = p
    return s
end

function UIX.novo(classe, props)
    local o = Instance.new(classe)
    for k, v in pairs(props or {}) do
        pcall(function() o[k] = v end)
    end
    return o
end

function UIX.canto(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = o
    return c
end

function UIX.borda(o, cor, t)
    local s = Instance.new("UIStroke")
    s.Color = cor or T.line
    s.Thickness = t or 1
    s.Parent = o
    return s
end

function UIX.hover(botao, quanto)
    quanto = quanto or 0.18
    botao.AutoButtonColor = false
    local cor_original = nil

    botao.MouseEnter:Connect(function()
        cor_original = botao.BackgroundColor3
        local c = botao.BackgroundColor3
        botao.BackgroundColor3 = Color3.new(
            math.min(c.R + quanto, 1),
            math.min(c.G + quanto, 1),
            math.min(c.B + quanto, 1)
        )
    end)

    botao.MouseLeave:Connect(function()
        if cor_original then
            botao.BackgroundColor3 = cor_original
            cor_original = nil
        end
    end)
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

local PRESETS = {
    {
        nome = "Legit",
        sub  = "subtle, hard to notice",
        cor  = Color3.fromRGB(90, 160, 240),
        cfg  = {
            AimLockEnabled = true,
            AimMode        = "legit",
            LegitSpeed     = 45,
            LegitJitter    = 0.35,
            LegitError     = 2.5,
            LegitReaction  = 0.28,
            LegitOvershoot = false,
            LegitLostKeep  = 0.25,
            AimBone        = "Head",
            AimSmoothLock  = true,
            AimMaxDist     = 500,
            AutoFire       = false,
            FireOnSight    = false,
            WallCheck      = true,
            FireOnlyLocked = true,
            FireCone       = 1.5,
            FireDelay      = 0.14,
            ESPEnabled     = true,
            ESPShowName    = true,
            ESPShowHealth  = true,
            ESPShowDist    = false,
            ESPMaxDistance = 300,
            ShowFOVCircle  = false,
            FlyEnabled     = false,
            AIM_FOVdeg     = 60,
            AIM_FOVdrop    = 100,
            AIM_Prediction = 0.05,
            AIM_DistWeight = 0.15,
        },
    },
    {
        nome = "Balanced",
        sub  = "the middle ground, good to play with",
        cor  = Color3.fromRGB(150, 92, 245),
        cfg  = {
            AimLockEnabled = true,
            AimMode        = "legit",
            LegitSpeed     = 140,
            LegitJitter    = 0.55,
            LegitError     = 1.8,
            LegitReaction  = 0.16,
            LegitOvershoot = true,
            LegitLostKeep  = 0.4,
            AimBone        = "Head",
            AimSmoothLock  = true,
            AimMaxDist     = 900,
            AutoFire       = false,
            FireOnSight    = true,
            WallCheck      = true,
            FireOnlyLocked = false,
            FireCone       = 2.5,
            FireDelay      = 0.10,
            ESPEnabled     = true,
            ESPShowName    = true,
            ESPShowHealth  = true,
            ESPShowDist    = true,
            ESPMaxDistance = 500,
            ShowFOVCircle  = true,
            FlyEnabled     = false,
            AIM_FOVdeg     = 100,
            AIM_FOVdrop    = 140,
            AIM_Prediction = 0.08,
            AIM_DistWeight = 0.25,
        },
    },
    {
        nome = "Aggressive",
        sub  = "fast aim and automatic fire",
        cor  = Color3.fromRGB(240, 150, 60),
        cfg  = {
            AimLockEnabled = true,
            AimMode        = "robot",
            LegitSpeed     = 420,
            LegitJitter    = 0.75,
            LegitError     = 0.9,
            LegitReaction  = 0.06,
            LegitOvershoot = true,
            LegitLostKeep  = 0.7,
            AimBone        = "UpperTorso",
            AimSmoothLock  = true,
            AimMaxDist     = 1800,
            AutoFire       = true,
            FireOnSight    = true,
            WallCheck      = false,
            FireOnlyLocked = false,
            FireCone       = 6,
            FireDelay      = 0.06,
            ESPEnabled     = true,
            ESPShowName    = true,
            ESPShowHealth  = true,
            ESPShowDist    = true,
            ESPMaxDistance = 1200,
            ShowFOVCircle  = true,
            FlyEnabled     = false,
            AIM_FOVdeg     = 150,
            AIM_FOVdrop    = 190,
            AIM_Prediction = 0.14,
            AIM_DistWeight = 0.5,
        },
    },
    {
        nome = "Rage",
        sub  = "everything on, no disguise",
        cor  = Color3.fromRGB(240, 85, 105),
        cfg  = {
            AimLockEnabled = true,
            AimMode        = "robot",
            LegitSpeed     = 900,
            LegitJitter    = 0.9,
            LegitError     = 0.2,
            LegitReaction  = 0,
            LegitOvershoot = true,
            LegitLostKeep  = 1.5,
            AimBone        = "Head",
            AimSmoothLock  = false,
            AimMaxDist     = 3000,
            AutoFire       = true,
            FireOnSight    = true,
            WallCheck      = false,
            FireOnlyLocked = false,
            FireCone       = 20,
            FireDelay      = 0.02,
            ESPEnabled     = true,
            ESPShowName    = true,
            ESPShowHealth  = true,
            ESPShowDist    = true,
            ESPMaxDistance = 2000,
            ShowFOVCircle  = true,
            FlyEnabled     = false,
            AIM_FOVdeg     = 180,
            AIM_FOVdrop    = 220,
            AIM_Prediction = 0.20,
            AIM_DistWeight = 0.75,
        },
    },
}

local function aplicar_preset(p)
    if not p or not p.cfg then return 0 end
    local txt = {}
    for k, v in pairs(p.cfg) do txt[k] = valor_para_texto(v) end
    local n = aplicar_config(txt)
    if pintar_tudo_ui then pcall(pintar_tudo_ui) end
    return n
end

local refs = {
    toggles = {},
    abas    = {},
    paginas = {},
}

local pintar_tudo_ui = nil

do

function UIX.criar_toggle(pai, ordem, texto, chave, aoMudar, sub)
    local linha = UIX.novo("Frame", {
        Name = "tg_" .. tostring(chave),
        Size = UDim2.new(1, 0, 0, sub and 46 or 38),
        BackgroundColor3 = T.card,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    UIX.canto(linha, 8)

    local rot = UIX.novo("TextLabel", {
        Size = UDim2.new(1, -70, 0, sub and 18 or 38),
        Position = UDim2.new(0, 12, 0, sub and 5 or 0),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = T.text,
        Font = F,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    if sub then
        local sl = UIX.novo("TextLabel", {
            Size = UDim2.new(1, -70, 0, 14),
            Position = UDim2.new(0, 12, 0, 24),
            BackgroundTransparency = 1,
            Text = sub,
            TextColor3 = T.dim,
            Font = F,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        sl.Parent = linha
    end

    local pil = UIX.novo("Frame", {
        Name = "Pilula",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
    })
    pil.Parent = linha
    UIX.canto(pil, 10)

    local bol = UIX.novo("Frame", {
        Name = "Bola",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = T.dim,
        BorderSizePixel = 0,
    })
    bol.Parent = pil
    UIX.canto(bol, 7)

    local clicavel = UIX.novo("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    })
    clicavel.Parent = linha

    local function pinta()
        local on = CONFIG[chave] and true or false
        pil.BackgroundColor3 = on and T.accent or T.card2
        bol.Position = on and UDim2.new(1, -17, 0.5, -7)
                            or UDim2.new(0, 3, 0.5, -7)
        bol.BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or T.dim
    end
    pinta()
    refs.toggles[chave] = pinta

    clicavel.MouseButton1Click:Connect(function()
        local novo_valor = not CONFIG[chave]
        CONFIG[chave] = novo_valor
        if aoMudar then
            local ok, r = pcall(aoMudar, novo_valor)
            if ok and r == false then
                CONFIG[chave] = not novo_valor
                pinta()
                return
            end
        end
        pinta()
    end)

    local cor_linha = linha.BackgroundColor3
    clicavel.MouseEnter:Connect(function()
        linha.BackgroundColor3 = Color3.new(
            math.min(cor_linha.R + 0.07, 1),
            math.min(cor_linha.G + 0.07, 1),
            math.min(cor_linha.B + 0.07, 1))
    end)
    clicavel.MouseLeave:Connect(function()
        linha.BackgroundColor3 = cor_linha
    end)

    return linha
end

function UIX.criar_slider(pai, ordem, texto, chave, min, max, passo, fmt)
    local linha = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = T.card,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    UIX.canto(linha, 8)

    local rot = UIX.novo("TextLabel", {
        Size = UDim2.new(1, -90, 0, 18),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = T.text,
        Font = F,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    local valor = UIX.novo("TextLabel", {
        Size = UDim2.new(0, 70, 0, 18),
        Position = UDim2.new(1, -82, 0, 6),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = T.accent2,
        Font = FM,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    valor.Parent = linha

    local trilha = UIX.novo("Frame", {
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 0, 34),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
    })
    trilha.Parent = linha
    UIX.canto(trilha, 3)

    local cheio = UIX.novo("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = T.accent,
        BorderSizePixel = 0,
    })
    cheio.Parent = trilha
    UIX.canto(cheio, 3)

    local function pinta()
        local v = tonumber(CONFIG[chave]) or min
        local frac = 0
        if max ~= min then frac = (v - min) / (max - min) end
        frac = math.clamp(frac, 0, 1)
        cheio.Size = UDim2.new(frac, 0, 1, 0)
        if fmt then
            valor.Text = fmt(v)
        else
            valor.Text = string.format("%.2f", v)
        end
    end
    pinta()
    refs.toggles[chave] = pinta

    local arrastando = false
    local toque = UIX.novo("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    })
    toque.Parent = linha

    local function definir(px)
        local larg = trilha.AbsoluteSize.X
        if not larg or larg <= 0 then return end
        local rel = (px - trilha.AbsolutePosition.X) / larg
        rel = math.clamp(rel, 0, 1)
        local v = min + (max - min) * rel
        if passo and passo > 0 then
            v = math.floor(v / passo + 0.5) * passo
        end
        v = math.clamp(v, min, max)
        CONFIG[chave] = v
        pinta()
    end

    toque.MouseButton1Down:Connect(function()
        arrastando = true
        definir(UserInputService:GetMouseLocation().X)
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not arrastando then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement then
            definir(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = false
        end
    end)

    return linha
end

function UIX.criar_opcoes(pai, ordem, texto, chave, opcoes)
    local linha = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = T.card,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    UIX.canto(linha, 8)

    local rot = UIX.novo("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = T.text,
        Font = F,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    local caixa = UIX.novo("Frame", {
        Size = UDim2.new(1, -24, 0, 26),
        Position = UDim2.new(0, 12, 0, 28),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
    })
    caixa.Parent = linha
    UIX.canto(caixa, 6)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 4)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = caixa

    local botoes = {}
    local function pinta()
        for val, b in pairs(botoes) do
            local on = (CONFIG[chave] == val)
            b.BackgroundColor3 = on and T.accent or T.card
            b.TextColor3 = on and Color3.fromRGB(255, 255, 255) or T.dim
            b.Font = on and FB or F
        end
    end

    for _, op in ipairs(opcoes or {}) do
        local b = UIX.novo("TextButton", {
            Size = UDim2.new(0, 78, 0, 20),
            BackgroundColor3 = T.card,
            BorderSizePixel = 0,
            Text = op.rotulo,
            TextColor3 = T.dim,
            Font = F,
            TextSize = 11,
            AutoButtonColor = false,
        })
        b.Parent = caixa
        UIX.canto(b, 5)
        UIX.hover(b, 0.10)
        botoes[op.valor] = b
        b.MouseButton1Click:Connect(function()
            CONFIG[chave] = op.valor
            pinta()
            if op.aoEscolher then pcall(op.aoEscolher, op.valor) end
        end)
    end
    pinta()
    refs.toggles[chave] = pinta

    return linha
end

function UIX.criar_opcoes_campo(pai, ordem, texto, getter, setter, rotulos)
    local linha = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = T.card,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    UIX.canto(linha, 8)

    local rot = UIX.novo("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = T.text,
        Font = F,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    local caixa = UIX.novo("Frame", {
        Size = UDim2.new(1, -24, 0, 26),
        Position = UDim2.new(0, 12, 0, 28),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
    })
    caixa.Parent = linha
    UIX.canto(caixa, 6)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 4)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = caixa

    local botoes = {}
    local function pinta()
        local atual = getter and getter() or nil
        for val, b in pairs(botoes) do
            local on = (atual == val)
            b.BackgroundColor3 = on and T.accent or T.card
            b.TextColor3 = on and Color3.fromRGB(255, 255, 255) or T.dim
            b.Font = on and FB or F
        end
    end

    for _, par in ipairs(rotulos or {}) do
        local b = UIX.novo("TextButton", {
            Size = UDim2.new(0, 78, 0, 20),
            BackgroundColor3 = T.card,
            BorderSizePixel = 0,
            Text = par.rotulo,
            TextColor3 = T.dim,
            Font = F,
            TextSize = 11,
            AutoButtonColor = false,
        })
        b.Parent = caixa
        UIX.canto(b, 5)
        UIX.hover(b, 0.10)
        botoes[par.valor] = b
        b.MouseButton1Click:Connect(function()
            if setter then setter(par.valor) end
            pinta()
        end)
    end
    pinta()
    refs.toggles[ordem] = pinta

    refs.livres = refs.livres or {}
    refs.livres[#refs.livres + 1] = pinta

    return linha
end

function UIX.criar_titulo(pai, ordem, texto)
    local t = UIX.novo("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = string.upper(texto or ""),
        TextColor3 = T.accent2,
        Font = FB,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = ordem,
    })
    t.Parent = pai
    return t
end

function UIX.criar_keybind(pai, ordem, texto, sub, qual, getter, aoIniciar)
    local linha = UIX.novo("Frame", {
        Name = "kb_" .. tostring(qual),
        Size = UDim2.new(1, 0, 0, sub and 46 or 38),
        BackgroundColor3 = T.card,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    UIX.canto(linha, 8)

    local rot = UIX.novo("TextLabel", {
        Size = UDim2.new(1, -130, 0, sub and 18 or 38),
        Position = UDim2.new(0, 12, 0, sub and 5 or 0),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = T.text,
        Font = F,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    if sub then
        local sl = UIX.novo("TextLabel", {
            Size = UDim2.new(1, -130, 0, 14),
            Position = UDim2.new(0, 12, 0, 24),
            BackgroundTransparency = 1,
            Text = sub,
            TextColor3 = T.dim,
            Font = F,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        sl.Parent = linha
    end

    local b = UIX.novo("TextButton", {
        Name = "Tecla",
        Size = UDim2.new(0, 108, 0, 26),
        Position = UDim2.new(1, -120, 0.5, -13),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = T.accent2,
        Font = F,
        TextSize = 12,
        AutoButtonColor = false,
    })
    b.Parent = linha
    UIX.canto(b, 6)
    local bs = UIX.borda(b, T.line, 1)

    local function valor_atual()
        if qual == "key" then
            if CONFIG.AimMouseButton then return "mouse in use" end
            return key_name(CONFIG.AimKey)
        end
        if CONFIG.AimMouseButton then
            return MOUSE_NAMES[CONFIG.AimMouseButton] or "mouse"
        end
        return "not set"
    end

    local function paint()
        if Keybind.capturing and Keybind.which == qual then
            b.Text = "press a key"
            b.TextColor3 = T.warn
            bs.Color = T.warn
            bs.Transparency = 0
        else
            b.Text = getter and getter() or valor_atual()
            b.TextColor3 = T.accent2
            bs.Color = T.line
            bs.Transparency = 0.25
        end
    end
    paint()
    Keybind.painters[#Keybind.painters + 1] = paint

    b.MouseEnter:Connect(function() b.BackgroundColor3 = T.line end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = T.card2 end)
    b.MouseButton1Click:Connect(function()
        if aoIniciar then pcall(aoIniciar) end
        Keybind.capturing = true
        Keybind.which = qual
        repaint_keybinds()
    end)

    return linha
end

function UIX.criar_input(pai, ordem, texto, padrao, dica, aoMudar)
    local linha = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = T.card,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    UIX.canto(linha, 8)

    local rot = UIX.novo("TextLabel", {
        Size = UDim2.new(0, 70, 0, 18),
        Position = UDim2.new(0, 12, 0.5, -9),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = T.text,
        Font = F,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    local box = UIX.novo("TextBox", {
        Size = UDim2.new(1, -94, 0, 26),
        Position = UDim2.new(0, 82, 0.5, -13),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
        Text = padrao or "",
        PlaceholderText = dica or "",
        PlaceholderColor3 = T.dim,
        TextColor3 = T.text,
        Font = F,
        TextSize = 12,
        ClearTextOnFocus = false,
    })
    box.Parent = linha
    UIX.canto(box, 6)
    local bs = UIX.borda(box, T.line, 1)

    box.Focused:Connect(function()
        bs.Color = T.accent
        bs.Transparency = 0
    end)
    box.FocusLost:Connect(function()
        bs.Color = T.line
        bs.Transparency = 0.25
    end)
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if aoMudar then pcall(aoMudar, box.Text) end
    end)

    return linha, box
end

function UIX.criar_botao(pai, ordem, texto, cor, acao)
    local b = UIX.novo("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
        Text = texto,
        TextColor3 = cor or T.accent2,
        Font = FB,
        TextSize = 12,
        AutoButtonColor = false,
        LayoutOrder = ordem,
    })
    b.Parent = pai
    UIX.canto(b, 8)
    UIX.borda(b, T.line, 1)
    UIX.hover(b, 0.10)
    b.MouseButton1Click:Connect(function()
        if acao then pcall(acao) end
    end)
    return b
end

function UIX.criar_dupla(pai, ordem, defs)
    local linha = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        LayoutOrder = ordem,
    })
    linha.Parent = pai

    local feitos = {}
    for i = 1, 2 do
        local cfg = defs[i]
        local x = (i == 1) and 0 or 0.5
        local b = UIX.novo("TextButton", {
            Size = UDim2.new(0.5, -3, 1, 0),
            Position = UDim2.new(x, (i == 1) and 0 or 3, 0, 0),
            BackgroundColor3 = T.card2,
            BorderSizePixel = 0,
            Text = cfg and cfg.rotulo or "?",
            TextColor3 = (cfg and cfg.cor) or T.accent2,
            Font = FB,
            TextSize = 11,
            AutoButtonColor = false,
        })
        b.Parent = linha
        UIX.canto(b, 8)
        UIX.borda(b, T.line, 1)
        UIX.hover(b, 0.10)
        if cfg and cfg.acao then
            b.MouseButton1Click:Connect(function() pcall(cfg.acao) end)
        end
        feitos[i] = b
    end
    return feitos[1], feitos[2], linha
end

function UIX.criar_secao(pai, ordem, titulo)
    local wrap = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = T.card,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    wrap.Parent = pai
    UIX.canto(wrap, 8)

    local bd = UIX.borda(wrap, T.line, 1)
    bd.Transparency = 0.55

    local head = UIX.novo("TextButton", {
        Name = "Head",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    })
    head.Parent = wrap

    local barra = UIX.novo("Frame", {
        Size = UDim2.new(0, 3, 0, 14),
        Position = UDim2.new(0, 12, 0.5, -7),
        BackgroundColor3 = T.accent,
        BorderSizePixel = 0,
    })
    barra.Parent = head
    local cb = Instance.new("UICorner")
    cb.CornerRadius = UDim.new(1, 0)
    cb.Parent = barra

    local rotulo = UIX.novo("TextLabel", {
        Size = UDim2.new(1, -58, 1, 0),
        Position = UDim2.new(0, 22, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(titulo or ""),
        TextColor3 = T.text,
        Font = FB,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rotulo.Parent = head

    local seta = UIX.novo("TextLabel", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -28, 0.5, -9),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = T.dim,
        Font = FB,
        TextSize = 11,
    })
    seta.Parent = head

    local inner = UIX.novo("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    })
    inner.Parent = wrap

    local il = Instance.new("UIListLayout")
    il.Padding = UDim.new(0, 1)
    il.SortOrder = Enum.SortOrder.LayoutOrder
    il.Parent = inner

    local rabo = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 5),
        BackgroundTransparency = 1,
        LayoutOrder = 9999,
    })
    rabo.Parent = inner

    local s = {
        inner  = inner,
        _o     = 0,
        wrap   = wrap,
        head   = head,
        open   = true,
        seta   = seta,
        barra  = barra,
        rotulo = rotulo,
        borda  = bd,
    }

    function s:SetOpen(v)
        self.open = v
        inner.Visible = v
        rabo.Visible = v
        seta.Text = v and "v" or ">"
        seta.TextColor3 = v and T.dim or T.accent
        barra.BackgroundColor3 = v and T.accent or T.line
        rotulo.TextColor3 = v and T.text or T.dim
        bd.Transparency = v and 0.55 or 0.85
    end

    head.MouseEnter:Connect(function()
        head.BackgroundTransparency = 0.9
        head.BackgroundColor3 = T.card2
        rotulo.TextColor3 = s.open and T.text or T.accent2
    end)
    head.MouseLeave:Connect(function()
        head.BackgroundTransparency = 1
        rotulo.TextColor3 = s.open and T.text or T.dim
    end)
    head.MouseButton1Click:Connect(function()
        s:SetOpen(not s.open)
    end)

    function s:prox()
        self._o = self._o + 1
        return self._o
    end

    function s:AddToggle(texto, chave, aoMudar, sub)
        return UIX.criar_toggle(self.inner, self:prox(), texto, chave, aoMudar, sub)
    end

    function s:AddSlider(texto, chave, min, max, passo, fmt)
        return UIX.criar_slider(self.inner, self:prox(),
                            texto, chave, min, max, passo, fmt)
    end

    function s:AddOpcoes(texto, chave, opcoes)
        return UIX.criar_opcoes(self.inner, self:prox(), texto, chave, opcoes)
    end

    function s:AddOpcoesCampo(texto, getter, setter, rotulos)
        return UIX.criar_opcoes_campo(self.inner, self:prox(),
                                  texto, getter, setter, rotulos)
    end

    function s:AddKeybind(texto, sub, qual, getter, aoIniciar)
        return UIX.criar_keybind(self.inner, self:prox(),
                             texto, sub, qual, getter, aoIniciar)
    end

    function s:AddInput(texto, padrao, dica, aoMudar)
        return UIX.criar_input(self.inner, self:prox(),
                           texto, padrao, dica, aoMudar)
    end

    function s:AddBotao(texto, cor, acao)
        return UIX.criar_botao(self.inner, self:prox(), texto, cor, acao)
    end

    function s:AddDupla(defs)
        return UIX.criar_dupla(self.inner, self:prox(), defs)
    end

    function s:AddTitulo(texto)
        return UIX.criar_titulo(self.inner, self:prox(), texto)
    end

    function s:AddLabel(texto, cor, tamanho)
        local l = UIX.novo("TextLabel", {
            Size = UDim2.new(1, -24, 0, 32),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = texto,
            TextColor3 = cor or T.dim,
            Font = F,
            TextSize = tamanho or 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            LayoutOrder = self:prox(),
        })
        l.Parent = self.inner
        return l
    end

    function s:AddDivisor()
        local d = UIX.novo("Frame", {
            Size = UDim2.new(1, -24, 0, 1),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundColor3 = T.line,
            BorderSizePixel = 0,
            LayoutOrder = self:prox(),
        })
        d.Parent = self.inner
        return d
    end

    return s
end

function UIX.nova_pagina(holder, nome)
    local scroll = UIX.novo("ScrollingFrame", {
        Name = "pg_" .. tostring(nome),
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = T.accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    })
    scroll.Parent = holder

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    return scroll
end

local function pintar_tudo()
    for _, p in pairs(refs.toggles) do pcall(p) end
    for _, p in ipairs(refs.livres or {}) do pcall(p) end
end
pintar_tudo_ui = pintar_tudo

function UIX.montar_preset_pronto(pai, i, p, aoUsar)
    local c = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
        LayoutOrder = i,
    })
    c.Parent = pai
    UIX.canto(c, 9)

    local faixa = UIX.novo("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.new(0, 0, 0, 8),
        BackgroundColor3 = p.cor,
        BorderSizePixel = 0,
    })
    faixa.Parent = c
    UIX.canto(faixa, 2)

    local n = UIX.novo("TextLabel", {
        Size = UDim2.new(1, -110, 0, 18),
        Position = UDim2.new(0, 14, 0, 8),
        BackgroundTransparency = 1,
        Text = p.nome,
        TextColor3 = T.text,
        Font = FB,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    n.Parent = c

    local sb = UIX.novo("TextLabel", {
        Size = UDim2.new(1, -110, 0, 14),
        Position = UDim2.new(0, 14, 0, 26),
        BackgroundTransparency = 1,
        Text = p.sub,
        TextColor3 = T.dim,
        Font = F,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    sb.Parent = c

    local usar = UIX.novo("TextButton", {
        Size = UDim2.new(0, 78, 0, 26),
        Position = UDim2.new(1, -90, 0.5, -13),
        BackgroundColor3 = p.cor,
        BorderSizePixel = 0,
        Text = "USE",
        TextColor3 = Color3.fromRGB(12, 10, 18),
        Font = FB,
        TextSize = 11,
        AutoButtonColor = false,
    })
    usar.Parent = c
    UIX.canto(usar, 7)
    UIX.hover(usar, 0.10)
    usar.MouseButton1Click:Connect(function() aoUsar(p) end)

    return c, usar
end

end

local function build_gui()
    if not parent_ok(PARENT) then PARENT, PARENT_KIND = resolve_parent() end
    local old = PARENT:FindFirstChild("LowHub")
    if old then old:Destroy() end

    local W, H = 660, 500
    local HEADER_H = 64

    local gui = Instance.new("ScreenGui")
    gui.Name = "LowHub"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = PARENT

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

    local root = UIX.novo("Frame", {
        Name = "Root",
        Size = UDim2.new(0, W, 0, H),
        Position = centro_tela(W, H),
        BackgroundColor3 = T.bg,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
        ClipsDescendants = true,
    })
    root.Parent = gui
    UIX.canto(root, 12)
    UIX.borda(root, T.line, 1)

    local escala = Instance.new("UIScale")
    escala.Scale = 1
    escala.Parent = root

    local function ajustar_escala()
        local cam = Workspace.CurrentCamera
        local vs = cam and cam.ViewportSize
        if not vs or vs.X <= 0 or vs.Y <= 0 then return false end
        local fx = (vs.X * 0.92) / W
        local fy = (vs.Y * 0.92) / H
        local f = math.min(fx, fy, 1)
        f = math.max(f, 0.6)
        escala.Scale = f
        return true
    end
    if not ajustar_escala() then
        task.spawn(function()
            for _ = 1, 60 do
                task.wait(0.1)
                if ajustar_escala() then break end
            end
        end)
    end
    task.spawn(function()
        while root.Parent do
            local cam = Workspace.CurrentCamera
            if cam then
                local conn
                conn = cam:GetPropertyChangedSignal("ViewportSize")
                          :Connect(ajustar_escala)
                while root.Parent and cam == Workspace.CurrentCamera do
                    task.wait(0.5)
                end
                pcall(function() conn:Disconnect() end)
            end
            task.wait(0.5)
        end
    end)

    local sombra = Instance.new("ImageLabel")
    sombra.Name = "Shadow"
    sombra.Size = UDim2.new(1, 60, 1, 60)
    sombra.Position = UDim2.new(0, -30, 0, -30)
    sombra.BackgroundTransparency = 1
    sombra.Image = "rbxassetid://6014261993"
    sombra.ImageColor3 = Color3.fromRGB(0, 0, 0)
    sombra.ImageTransparency = 0.5
    sombra.ZIndex = -1
    sombra.Parent = root

    local header = UIX.novo("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, HEADER_H),
        BackgroundColor3 = T.header,
        BorderSizePixel = 0,
    })
    header.Parent = root
    UIX.canto(header, 12)

    local tampa = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = T.header,
        BorderSizePixel = 0,
    })
    tampa.Parent = header

    local hl = UIX.novo("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.line,
        BorderSizePixel = 0,
    })
    hl.Parent = header

    local aSize = 44
    local avFrame = UIX.novo("Frame", {
        Name = "Avatar",
        Size = UDim2.new(0, aSize, 0, aSize),
        Position = UDim2.new(0, 14, 0.5, -aSize / 2),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
    })
    avFrame.Parent = header
    UIX.canto(avFrame, aSize / 2)
    local avStroke = UIX.borda(avFrame, T.accent, 1.5)
    avStroke.Transparency = 0.25

    local avImg = UIX.novo("ImageLabel", {
        Name = "AvatarImg",
        Size = UDim2.new(1, -4, 1, -4),
        Position = UDim2.new(0, 2, 0, 2),
        BackgroundTransparency = 1,
        Image = "",
    })
    avImg.Parent = avFrame
    UIX.canto(avImg, (aSize - 4) / 2)

    local avLetter = UIX.novo("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = string.upper(string.sub(LP.Name, 1, 1)),
        TextColor3 = T.accent,
        Font = FB,
        TextSize = 18,
    })
    avLetter.Parent = avFrame

    task.spawn(function()
        local data = UIX.baixar_avatar()
        if not data then return end
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
                avImg.Image = UIX.avatar_url(LP.UserId, 150)
                avLetter.Visible = false
            end)
        end
    end)

    local tit = UIX.novo("TextLabel", {
        Name = "Titulo",
        Size = UDim2.new(0, 260, 0, 22),
        Position = UDim2.new(0, 70, 0, 13),
        BackgroundTransparency = 1,
        Text = "LOWHUB",
        TextColor3 = T.text,
        Font = FB,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    tit.Parent = header

    local vpill = UIX.novo("TextLabel", {
        Name = "Versao",
        Size = UDim2.new(0, 46, 0, 15),
        Position = UDim2.new(0, 142, 0, 17),
        BackgroundColor3 = T.accentD,
        BorderSizePixel = 0,
        Text = VERSION,
        TextColor3 = T.accent2,
        Font = FB,
        TextSize = 9,
    })
    vpill.Parent = header
    UIX.canto(vpill, 7)

    local sub = UIX.novo("TextLabel", {
        Name = "Subtitulo",
        Size = UDim2.new(0, 300, 0, 16),
        Position = UDim2.new(0, 70, 0, 34),
        BackgroundTransparency = 1,
        Text = "Tribes  \195\151  RightShift to hide",
        TextColor3 = T.dim,
        Font = F,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    sub.Parent = header

    local estado = UIX.novo("TextLabel", {
        Name = "Estado",
        Size = UDim2.new(0, 190, 0, 18),
        Position = UDim2.new(1, -206, 0, 14),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = T.dim,
        Font = FM,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    estado.Parent = header

    local metodo = UIX.novo("TextLabel", {
        Name = "Metodo",
        Size = UDim2.new(0, 190, 0, 16),
        Position = UDim2.new(1, -206, 0, 34),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = T.faint,
        Font = F,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    metodo.Parent = header

    local close = UIX.novo("TextButton", {
        Name = "Close",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -32, 0, 14),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
        Text = "\195\151",
        TextColor3 = T.dim,
        Font = FB,
        TextSize = 15,
        AutoButtonColor = false,
    })
    close.Parent = header
    UIX.canto(close, 6)
    UIX.hover(close, 0.10)

    local mini = UIX.novo("TextButton", {
        Name = "Minimize",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -60, 0, 14),
        BackgroundColor3 = T.card2,
        BorderSizePixel = 0,
        Text = "-",
        TextColor3 = T.dim,
        Font = FB,
        TextSize = 15,
        AutoButtonColor = false,
    })
    mini.Parent = header
    UIX.canto(mini, 6)
    UIX.hover(mini, 0.10)

    local barra = UIX.novo("Frame", {
        Name = "Abas",
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.new(0, 12, 0, HEADER_H + 8),
        BackgroundTransparency = 1,
    })
    barra.Parent = root
    local bl = Instance.new("UIListLayout")
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding = UDim.new(0, 6)
    bl.Parent = barra

    local holder = UIX.novo("Frame", {
        Name = "Paginas",
        Size = UDim2.new(1, -24, 1, -(HEADER_H + 8 + 30 + 34)),
        Position = UDim2.new(0, 12, 0, HEADER_H + 38 + 8),
        BackgroundTransparency = 1,
    })
    holder.Parent = root

    local rodape = UIX.novo("TextLabel", {
        Name = "Rodape",
        Size = UDim2.new(1, -24, 0, 16),
        Position = UDim2.new(0, 12, 1, -22),
        BackgroundTransparency = 1,
        Text = VERSION .. "  \195\151  RightShift to hide",
        TextColor3 = T.faint,
        Font = F,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rodape.Parent = root

    local avisoLbl = UIX.novo("TextLabel", {
        Name = "Aviso",
        Size = UDim2.new(1, -220, 0, 16),
        Position = UDim2.new(0, 200, 1, -22),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = T.warn,
        Font = F,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Visible = false,
    })
    avisoLbl.Parent = root
    AVISO_UI = avisoLbl

    local NOMES = { "AIM", "VISUAL", "MOVEMENT", "FPS", "CONFIG" }
    local botoes = {}

    local function trocar(nome)
        for n, b in pairs(botoes) do
            local on = (n == nome)
            b.BackgroundColor3 = on and T.accent or T.card
            b.TextColor3 = on and Color3.fromRGB(255, 255, 255) or T.dim
        end
        for n, p in pairs(refs.paginas) do
            p.Visible = (n == nome)
        end
        refs.abas.atual = nome
    end
    refs.abas.trocar = trocar

    for _, nome in ipairs(NOMES) do
        local b = UIX.novo("TextButton", {
            Name = "Aba_" .. nome,
            Size = UDim2.new(0, 92, 1, 0),
            BackgroundColor3 = T.card,
            BorderSizePixel = 0,
            Text = nome,
            TextColor3 = T.dim,
            Font = FB,
            TextSize = 11,
            AutoButtonColor = false,
        })
        b.Parent = barra
        UIX.canto(b, 7)
        UIX.hover(b, 0.09)
        botoes[nome] = b
        b.MouseButton1Click:Connect(function() trocar(nome) end)
    end

    for _, nome in ipairs(NOMES) do
        refs.paginas[nome] = UIX.nova_pagina(holder, nome)
    end

    do
        local pg = refs.paginas.AIM

        local sLock = UIX.criar_secao(pg, 1, "Aimlock")
        sLock:AddToggle("Aimlock enabled", "AimLockEnabled", nil,
            "locks your aim onto the closest enemy")

        sLock:AddOpcoesCampo("Activate with",
            function()
                return CONFIG.AimMouseButton and "MOUSE" or "KEY"
            end,
            function(v)
                if v == "MOUSE" then
                    CONFIG.AimMouseButton = CONFIG.AimMouseButton
                                         or Enum.UserInputType.MouseButton1
                else
                    CONFIG.AimMouseButton = nil
                end
                repaint_keybinds()
            end,
            {
                { rotulo = "KEY",   valor = "KEY"   },
                { rotulo = "MOUSE", valor = "MOUSE" },
            })

        sLock:AddKeybind("Aimlock key", "click and press any key", "key",
            function()
                if CONFIG.AimMouseButton then return "mouse in use" end
                return key_name(CONFIG.AimKey)
            end,
            function()
                CONFIG.AimMouseButton = nil
                repaint_keybinds()
            end)

        sLock:AddOpcoesCampo("Mouse button",
            function()
                local mb = CONFIG.AimMouseButton
                if mb == Enum.UserInputType.MouseButton2 then return "RIGHT" end
                if mb == Enum.UserInputType.MouseButton3 then return "MIDDLE" end
                if mb == Enum.UserInputType.MouseButton1 then return "LEFT" end
                return nil
            end,
            function(v)
                if v == "LEFT" then
                    CONFIG.AimMouseButton = Enum.UserInputType.MouseButton1
                elseif v == "RIGHT" then
                    CONFIG.AimMouseButton = Enum.UserInputType.MouseButton2
                else
                    CONFIG.AimMouseButton = Enum.UserInputType.MouseButton3
                end
                repaint_keybinds()
            end,
            {
                { rotulo = "LEFT",   valor = "LEFT"   },
                { rotulo = "RIGHT",  valor = "RIGHT"  },
                { rotulo = "MIDDLE", valor = "MIDDLE" },
            })

        sLock:AddOpcoes("Activation mode", "AimHoldMode", {
            { rotulo = "HOLD",   valor = true  },
            { rotulo = "TOGGLE", valor = false },
        })
        refs.toggles.AimHoldMode = function()
            local b = refs.abas and nil
            for _, p in pairs(refs.toggles) do end
        end

        sLock:AddOpcoesCampo("Target bone",
            function()
                local b = CONFIG.AimBone
                if b == "Head" then return "HEAD" end
                if b == "UpperTorso" then return "CHEST" end
                if b == "HumanoidRootPart" or b == "TribesHull" then
                    return "ROOT"
                end
                return "HEAD"
            end,
            function(v)
                if v == "HEAD" then
                    CONFIG.AimBone = "Head"
                elseif v == "CHEST" then
                    CONFIG.AimBone = "UpperTorso"
                else
                    CONFIG.AimBone = "HumanoidRootPart"
                end
            end,
            {
                { rotulo = "HEAD",  valor = "HEAD"  },
                { rotulo = "CHEST", valor = "CHEST" },
                { rotulo = "ROOT",  valor = "ROOT"  },
            })

        sLock:AddToggle("Smooth entry", "AimSmoothLock", nil,
            "eases the crosshair in instead of snapping")

        local sMode = UIX.criar_secao(pg, 2, "Aim behaviour")

        sMode:AddOpcoesCampo("Behaviour",
            function()
                return (CONFIG.AimMode == "robot") and "ROBOT" or "HUMAN"
            end,
            function(v)
                CONFIG.AimMode = (v == "ROBOT") and "robot" or "legit"
                pcall(legit_reset)
            end,
            {
                { rotulo = "HUMAN", valor = "HUMAN" },
                { rotulo = "ROBOT", valor = "ROBOT" },
            })

        sMode:AddSlider("Aim speed", "LegitSpeed", 15, 900, 5,
            function(v) return string.format("%.0f deg/s", v) end)
        sMode:AddSlider("Hand shake", "LegitJitter", 0, 2, 0.05,
            function(v) return string.format("%.2f deg", v) end)
        sMode:AddSlider("Aim error", "LegitError", 0, 6, 0.1,
            function(v) return string.format("%.1f deg", v) end)
        sMode:AddSlider("Reaction time", "LegitReaction", 0, 0.6, 0.02,
            function(v) return string.format("%.2fs", v) end)
        sMode:AddToggle("Overshoot and come back", "LegitOvershoot")
        sMode:AddSlider("Keep tracking after loss", "LegitLostKeep",
            0, 1.5, 0.05,
            function(v) return string.format("%.2fs", v) end)

        local sTune = UIX.criar_secao(pg, 3, "Aim tuning")
        sTune:AddSlider("Field of view", "AIM_FOVdeg", 30, 180, 15,
            function(v) return string.format("%d deg", v) end)
        sTune:AddSlider("Aim height", "AimHeightOffset", -2, 4, 0.25,
            function(v) return string.format("%.2f", v) end)
        sTune:AddSlider("Prediction", "AIM_Prediction", 0, 0.30, 0.02,
            function(v) return string.format("%.2fs", v) end)
        sTune:AddSlider("Max range", "AimMaxDist", 100, 3000, 100,
            function(v) return string.format("%dm", v) end)
        sTune:AddSlider("Distance weight", "AIM_DistWeight", 0, 0.75, 0.05,
            function(v) return string.format("%.2f", v) end)
        sTune:AddToggle("FOV circle", "ShowFOVCircle", nil,
            "shows the aim range on screen")

        local sFire = UIX.criar_secao(pg, 4, "Auto-fire")
        sFire:AddToggle("Auto-fire enabled", "AutoFire", nil,
            "fires by itself once a target is locked")
        sFire:AddToggle("Fire on sight", "FireOnSight", nil,
            "also fires when a target walks into the cone")
        sFire:AddToggle("Wall check before firing", "WallCheck", nil,
            "wont fire at enemies behind walls")
        sFire:AddToggle("Only when locked", "FireOnlyLocked", nil)
        sFire:AddSlider("Fire cone", "FireCone", 0.5, 20, 0.5,
            function(v) return string.format("%.1f deg", v) end)
        sFire:AddSlider("Fire interval", "FireDelay", 0.02, 0.6, 0.02,
            function(v) return string.format("%.2fs", v) end)
        sFire:AddLabel(
            "  Without a locked target it fires at anyone inside " ..
            "the cone with no wall in between.")

        refs.secoes_aim = { sLock, sMode, sTune, sFire }
    end

    do
        local pg = refs.paginas.VISUAL

        local PALETTE = {
            { name = "Red",    c = Color3.fromRGB(255, 72, 72)   },
            { name = "Orange", c = Color3.fromRGB(255, 150, 60)  },
            { name = "Yellow", c = Color3.fromRGB(255, 220, 70)  },
            { name = "Green",  c = Color3.fromRGB(90, 220, 120)  },
            { name = "Cyan",   c = Color3.fromRGB(72, 196, 255)  },
            { name = "Purple", c = Color3.fromRGB(170, 110, 255) },
            { name = "Pink",   c = Color3.fromRGB(255, 110, 190) },
            { name = "White",  c = Color3.fromRGB(240, 240, 240) },
        }

        local function nome_da_cor(c)
            for _, p in ipairs(PALETTE) do
                if p.c == c then return p.name end
            end
            return "Red"
        end
        local function cor_do_nome(nome)
            for _, p in ipairs(PALETTE) do
                if p.name == nome then return p.c end
            end
            return nil
        end

        local sEsp = UIX.criar_secao(pg, 1, "ESP")
        sEsp:AddToggle("ESP enabled", "ESPEnabled", nil,
            "shows enemies through walls")
        sEsp:AddToggle("Show name", "ESPShowName")
        sEsp:AddToggle("Show health", "ESPShowHealth")
        sEsp:AddToggle("Show distance", "ESPShowDist")
        sEsp:AddSlider("ESP range", "ESPMaxDistance", 50, 2000, 50,
            function(v) return string.format("%dm", v) end)

        local sCor = UIX.criar_secao(pg, 2, "Colours")
        local optsCor = {}
        for _, p in ipairs(PALETTE) do
            optsCor[#optsCor + 1] = { rotulo = p.name, valor = p.name }
        end

        sCor:AddOpcoesCampo("Enemy colour",
            function() return nome_da_cor(CONFIG.ESPColorEnemy) end,
            function(v)
                local c = cor_do_nome(v)
                if c then CONFIG.ESPColorEnemy = c end
            end,
            optsCor)

        sCor:AddOpcoesCampo("Ally colour",
            function() return nome_da_cor(CONFIG.ESPColorAlly) end,
            function(v)
                local c = cor_do_nome(v)
                if c then CONFIG.ESPColorAlly = c end
            end,
            optsCor)

        sCor:AddLabel(
            "  Enemy and ally colours only apply to teammates " ..
            "and opponents - the ESP still only draws players.")
    end

    do
        local pg = refs.paginas.MOVEMENT

        local sFly = UIX.criar_secao(pg, 1, "Flight")
        sFly:AddToggle("Fly enabled", "FlyEnabled",
            function(on)
                if on then pcall(start_fly) else pcall(stop_fly) end
            end,
            "WASD to move, Space up, Ctrl down")
        sFly:AddSlider("Fly speed", "FlySpeed", 10, 200, 5,
            function(v)
                if fly_vel then fly_vel.VectorVelocity = Vector3.zero end
                return string.format("%d", v)
            end)

        local sSpeed = UIX.criar_secao(pg, 2, "Speed")
        sSpeed:AddToggle("Speed enabled", "SpeedEnabled", nil,
            "changes your walk speed")
        sSpeed:AddSlider("Walk speed", "SpeedValue", 16, 200, 1,
            function(v)
                pcall(apply_speed)
                return string.format("%d", v)
            end)
        sSpeed:AddLabel(
            "  Restores your normal walk speed the moment you " ..
            "turn this off.")
    end

    do
        local pg = refs.paginas.FPS

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
                local ter = Workspace:FindFirstChildOfClass("Terrain")
                if ter then
                    guardar("Terrain", ter.Transparency)
                    ter.Transparency = 1
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
                local ter = Workspace:FindFirstChildOfClass("Terrain")
                if ter and perf_orig.Terrain ~= nil then
                    ter.Transparency = perf_orig.Terrain
                end
            end)
            fps_on = false
        end

        local sFps = UIX.criar_secao(pg, 1, "Performance mode")

        sFps:AddToggle("Performance mode", "FpsMode",
            function(on)
                if on then ligar_fps() else desligar_fps() end
            end,
            "turns off shadows, effects and fog")

        sFps:AddLabel(
            "  Restores your original lighting the moment you " ..
            "turn it off - nothing is left changed.")

        refs.fps = { ligar = ligar_fps, desligar = desligar_fps,
                     ativo = function() return fps_on end }
    end

    do
        local pg = refs.paginas.CONFIG

        carregar_presets_do_disco()

        local pintar_auto
        local presetAtual  = nil
        local nomeDigitado = ""
        local listaFrame, redesenhar_lista

        local sPre = UIX.criar_secao(pg, 1, "Presets")

        for i, p in ipairs(PRESETS) do
            UIX.montar_preset_pronto(sPre.inner, i + 1, p, function(pr)
                local n = aplicar_preset(pr)
                presetAtual = nil
                if redesenhar_lista then redesenhar_lista() end
                avisar(pr.nome .. " loaded (" .. tostring(n) .. ")")
            end)
        end

        sPre:AddLabel(
            "  A ready preset overwrites your settings. Nothing " ..
            "is written to disk until you save it below.")

        local sMeu = UIX.criar_secao(pg, 2, "My presets")

        listaFrame = UIX.novo("Frame", {
            Name = "PresetList",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = sMeu:prox(),
        })
        listaFrame.Parent = sMeu.inner

        local listaLayout = Instance.new("UIListLayout")
        listaLayout.Padding = UDim.new(0, 6)
        listaLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listaLayout.Parent = listaFrame

        local function montar_linha(nome, indice)
            local ehAuto = (autoload_nome == nome)
            local sel    = (presetAtual == nome)

            local card = UIX.novo("Frame", {
                Name = "P_" .. nome,
                Size = UDim2.new(1, 0, 0, 38),
                BackgroundColor3 = sel and T.card3 or T.card,
                BorderSizePixel = 0,
                LayoutOrder = indice,
            })
            card.Parent = listaFrame
            UIX.canto(card, 8)

            local rail = UIX.novo("Frame", {
                Name = "Rail",
                Size = UDim2.new(0, 3, 1, -14),
                Position = UDim2.new(0, 0, 0, 7),
                BackgroundColor3 = ehAuto and T.good or T.line,
                BorderSizePixel = 0,
            })
            rail.Parent = card
            UIX.canto(rail, 2)

            local nomeLbl = UIX.novo("TextLabel", {
                Name = "Name",
                Size = UDim2.new(1, -142, 1, 0),
                Position = UDim2.new(0, 16, 0, 0),
                BackgroundTransparency = 1,
                Text = nome,
                TextColor3 = sel and T.accent2 or T.text,
                Font = FB,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            })
            nomeLbl.Parent = card

            if ehAuto then
                local pill = UIX.novo("Frame", {
                    Name = "Pill",
                    Size = UDim2.new(0, 34, 0, 14),
                    Position = UDim2.new(1, -142, 0.5, -7),
                    BackgroundColor3 = T.accentD,
                    BorderSizePixel = 0,
                })
                pill.Parent = card
                UIX.canto(pill, 7)
                local pt = UIX.novo("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "AUTO",
                    TextColor3 = T.accent2,
                    Font = FB,
                    TextSize = 8,
                })
                pt.Parent = pill
            end

            local function acao(texto, x, ligado, fn)
                local b = UIX.novo("TextButton", {
                    Size = UDim2.new(0, 30, 0, 24),
                    Position = UDim2.new(1, x, 0.5, -12),
                    BackgroundColor3 = ligado and T.accentD or T.card2,
                    BorderSizePixel = 0,
                    Text = texto,
                    TextColor3 = ligado and T.accent2 or T.dim,
                    Font = FB,
                    TextSize = 13,
                    AutoButtonColor = false,
                })
                b.Parent = card
                UIX.canto(b, 6)
                if ligado then UIX.borda(b, T.accent, 1) end
                UIX.hover(b, 0.10)
                b.MouseButton1Click:Connect(function() pcall(fn) end)
                return b
            end

            acao(">", -72, false, function()
                local n = aplicar_config(presets[nome])
                presetAtual = nome
                redesenhar_lista()
                avisar("'" .. nome .. "' loaded (" .. tostring(n) .. ")")
            end)

            local pin = acao("*", -38, ehAuto, function()
                if autoload_nome == nome then
                    gravar_autoload(nil)
                    avisar("Auto-load off")
                else
                    gravar_autoload(nome)
                    avisar("'" .. nome .. "' loads on inject")
                end
                redesenhar_lista()
                if pintar_auto then pintar_auto() end
            end)
            pin.Name = "Pin"

            acao("\195\151", -106, false, function()
                apagar_preset(nome)
                if autoload_nome == nome then gravar_autoload(nil) end
                if presetAtual == nome then presetAtual = preset_names[1] end
                redesenhar_lista()
                if pintar_auto then pintar_auto() end
                avisar("'" .. nome .. "' deleted")
            end)
        end

        redesenhar_lista = function()
            for _, c in ipairs(listaFrame:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end

            if #preset_names == 0 then
                local vazio = UIX.novo("Frame", {
                    Name = "Empty",
                    Size = UDim2.new(1, 0, 0, 46),
                    BackgroundColor3 = T.card2,
                    BorderSizePixel = 0,
                    LayoutOrder = 1,
                })
                vazio.Parent = listaFrame
                UIX.canto(vazio, 8)

                local t1 = UIX.novo("TextLabel", {
                    Size = UDim2.new(1, -24, 0, 18),
                    Position = UDim2.new(0, 14, 0, 8),
                    BackgroundTransparency = 1,
                    Text = "No presets saved",
                    TextColor3 = T.dim,
                    Font = FB,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                t1.Parent = vazio

                local t2 = UIX.novo("TextLabel", {
                    Size = UDim2.new(1, -24, 0, 16),
                    Position = UDim2.new(0, 14, 0, 25),
                    BackgroundTransparency = 1,
                    Text = "Type a name below and hit SAVE.",
                    TextColor3 = T.faint,
                    Font = F,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                t2.Parent = vazio
                return
            end

            for i, nome in ipairs(preset_names) do
                montar_linha(nome, i)
            end
        end
        redesenhar_lista()

        sMeu:AddInput("Name", "", "e.g. strong aimbot",
            function(txt) nomeDigitado = txt end)

        local function nome_limpo()
            return tostring(nomeDigitado or ""):gsub("^%s+", "")
                                          :gsub("%s+$", "")
        end

        sMeu:AddDupla({
            { rotulo = "SAVE", cor = T.good, acao = function()
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
            { rotulo = "OVERWRITE", cor = T.accent2, acao = function()
                local nome = nome_limpo()
                if #nome == 0 then nome = presetAtual or "" end
                if #nome == 0 or not presets[nome] then
                    avisar("No preset selected")
                    return
                end
                presets[nome] = capturar_config()
                salvar_presets_em_disco()
                presetAtual = nome
                redesenhar_lista()
                avisar("'" .. nome .. "' overwritten")
            end },
        })

        sMeu:AddDupla({
            { rotulo = "DELETE", cor = T.bad, acao = function()
                local nome = nome_limpo()
                if #nome == 0 then nome = presetAtual or "" end
                if #nome == 0 or not presets[nome] then
                    avisar("No preset named '" .. nome .. "'")
                    return
                end
                apagar_preset(nome)
                if autoload_nome == nome then gravar_autoload(nil) end
                if presetAtual == nome then presetAtual = preset_names[1] end
                redesenhar_lista()
                if pintar_auto then pintar_auto() end
                avisar("'" .. nome .. "' deleted")
            end },
            { rotulo = "RESET ALL", cor = T.warn, acao = function()
                local base = {
                    AimMode = "robot", LegitSpeed = 90, LegitJitter = 0.55,
                    LegitError = 1.8, LegitReaction = 0.18,
                    LegitOvershoot = true, LegitLostKeep = 0.4,
                    FireOnlyLocked = false, FireOnSight = true,
                    WallCheck = true,
                    AutoFire = false, FireCone = 2.5, FireDelay = 0.10,
                    ESPEnabled = true, ESPMaxDistance = 500,
                    ESPShowName = true, ESPShowHealth = true,
                    ESPShowDist = true,
                    FlyEnabled = false, FlySpeed = 55, MatchOnly = true,
                    HookCamera = true, ShowFOVCircle = true,
                    AIM_FOVdeg = 100, AIM_FOVdrop = 140,
                    AIM_Prediction = 0.08, AIM_DistWeight = 0.25,
                }
                local txt = {}
                for k, v in pairs(base) do txt[k] = valor_para_texto(v) end
                aplicar_config(txt)
                gravar_autoload(nil)
                desativar_auto_exec()
                redesenhar_lista()
                if pintar_auto then pintar_auto() end
                avisar("Defaults restored")
            end },
        })

        local autoLbl = UIX.novo("TextLabel", {
            Name = "AutoStatus",
            Size = UDim2.new(1, -24, 0, 16),
            Position = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = T.dim,
            Font = FM,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = sMeu:prox(),
        })
        autoLbl.Parent = sMeu.inner

        pintar_auto = function()
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

        sMeu:AddToggle("Load a preset on inject", "AutoLoadOnInject",
            function(v)
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
            end,
            "picks up where you left off when the hub loads")

        CONFIG.AutoLoadOnInject = (autoload_nome ~= nil)
        if refs.toggles.AutoLoadOnInject then
            pcall(refs.toggles.AutoLoadOnInject)
        end
        pintar_auto()

        sMeu:AddToggle("Reopen hub on next load", "AutoExecHub",
            function(v)
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
            end,
            "queues the hub again after a teleport")
        CONFIG.AutoExecHub = (hub_url ~= nil)
        if refs.toggles.AutoExecHub then
            pcall(refs.toggles.AutoExecHub)
        end

        refs.config = {
            redesenhar = redesenhar_lista,
            pintar_auto = pintar_auto,
        }
    end

    trocar("AIM")

    local open = true
    root.Active = false
    root.Draggable = false

    local dragging, dragStart, dragOrigin = false, nil, nil
    local dragGoal = nil
    local dragNow  = nil

    local savedSize = UDim2.new(0, W, 0, H)
    local miniBar = nil

    local function set_open(v)
        open = v

        local esconder = { barra, holder, rodape, avisoLbl }
        for _, o in ipairs(esconder) do
            if o then o.Visible = v end
        end

        if v then
            root.Size = savedSize
            vpill.Visible = true
            sub.Visible   = true
            estado.Visible = true
            metodo.Visible = true
            avFrame.Visible = true
            tit.Visible = true
            close.Visible = true
            miniBar = miniBar
            if miniBar then miniBar:Destroy(); miniBar = nil end
        else
            root.Size = UDim2.new(0, 64, 0, 64)
            vpill.Visible = false
            sub.Visible   = false
            estado.Visible = false
            metodo.Visible = false

            avFrame.Visible = true
            tit.Visible = false
            close.Visible = false
        end

        mini.Visible = true
        mini.Text = v and "-" or "+"
        dragging = false
        dragGoal = nil
        dragNow  = nil
    end

    local function in_drag_zone(pos)
        local rp = root.AbsolutePosition
        local rs = root.AbsoluteSize
        local x = pos.X - rp.X
        local y = pos.Y - rp.Y
        if x < 0 or x > rs.X then return false end
        if y < 0 or y > rs.Y then return false end
        if open then
            if y > HEADER_H then return false end
            if x > rs.X - 90 then return false end
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

    close.MouseButton1Click:Connect(function()
        if limpar_tudo then limpar_tudo() end
    end)

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

        if input.KeyCode == Enum.KeyCode.RightShift then
            toggle_open()
            return
        end

        if Keybind.capturing then
            if Keybind.which == "key" then
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    CONFIG.AimKey = input.KeyCode
                    Keybind.capturing = false
                    Keybind.which = nil
                    recompute_aim_active()
                    repaint_keybinds()
                end
            elseif Keybind.which == "mouse" then
                if input.UserInputType == Enum.UserInputType.MouseButton1
                   or input.UserInputType == Enum.UserInputType.MouseButton2
                   or input.UserInputType == Enum.UserInputType.MouseButton3 then
                    CONFIG.AimMouseButton = input.UserInputType
                    Keybind.capturing = false
                    Keybind.which = nil
                    recompute_aim_active()
                    repaint_keybinds()
                end
            end
            return
        end

        if gpe then return end
        if not CONFIG.AimLockEnabled then return end

        if CONFIG.AimMouseButton then
            if input.UserInputType == CONFIG.AimMouseButton then
                if CONFIG.AimHoldMode then
                    aim_held = true
                else
                    aim_toggled = not aim_toggled
                end
                recompute_aim_active()
            end
        elseif input.KeyCode ~= Enum.KeyCode.Unknown then
            if input.KeyCode == CONFIG.AimKey then
                if CONFIG.AimHoldMode then
                    aim_held = true
                else
                    aim_toggled = not aim_toggled
                end
                recompute_aim_active()
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not CONFIG.AimHoldMode then return end
        if CONFIG.AimMouseButton then
            if input.UserInputType == CONFIG.AimMouseButton then
                aim_held = false
                recompute_aim_active()
            end
        elseif input.KeyCode == CONFIG.AimKey then
            aim_held = false
            recompute_aim_active()
        end
    end)

    limpar_tudo = function()
        running = false
        pcall(function() UserInputService.MouseBehavior = orig_mouse end)
        pcall(stop_aim)
        pcall(stop_fly)
        pcall(function()
            for plr in pairs(esp_cache) do remove_esp(plr) end
        end)
        if refs.fps then pcall(refs.fps.desligar) end
        if gui then pcall(function() gui:Destroy() end) end
        if fov_gui then pcall(function() fov_gui:Destroy() end) end
        gui, fov_gui, window = nil, nil, nil
    end

    task.spawn(function()
        while running and gui and gui.Parent do
            local emPartida = (my_state() ~= "Lobby")
            local n = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if is_enemy(plr) and is_alive(plr) then n = n + 1 end
            end

            local st, col
            if aviso_texto and os.clock() < aviso_ate then
                st, col = aviso_texto, T.warn
            elseif not CONFIG.AimLockEnabled then
                st, col = "aimlock off", T.dim
            elseif locked_plr then
                st, col = "locked on " .. locked_plr.Name, T.accent2
            elseif aim_active and fire_sight_plr then
                st, col = "on sight: " .. fire_sight_plr.Name, T.warn
            elseif aim_active then
                st, col = "searching for target", T.warn
            else
                st, col = bind_label() .. " to lock", T.faint
            end

            pcall(function()
                estado.Text = st
                estado.TextColor3 = col

                local m = attack_mode
                if m == "engine" then m = "native" end
                --[[ DIAGNOSTICO NA TELA (temporario)

                     O usuario relata "aimlock bugado, nao esta
                     lockando" mas a leitura do codigo diz que ele e'
                     identico ao da v2.3, que funcionava. Entao o
                     problema esta' em algum ESTADO de execucao que so'
                     da' pra ver rodando.

                     Estes numeros contam a historia:
                       aim_execs  - ticks do aim (se congela, morreu)
                       swap_count - quantas vezes trocou de alvo
                       fb         - o que o auto_fire esta' pensando
                     ============================================================ ]]
                metodo.Text = m .. " / " .. mira_modo
                              .. "  \195\151  " .. tostring(aim_execs) .. "ticks"
                              .. "  \195\151  " .. tostring(swap_count) .. "swap"
                              .. "  \195\151  " .. tostring(n) .. "en"
                              .. "  \195\151  " .. tostring(fire_state)
                metodo.TextColor3 = emPartida and T.dim or T.faint
            end)

            if avisoLbl then
                avisoLbl.Visible = (aviso_texto ~= nil
                                    and os.clock() < aviso_ate)
            end

            task.wait(0.1)
        end
    end)

    window = { Root = root, SetOpen = set_open, IsOpen = function() return open end }

    return gui
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

--[[ ============================================================
     INICIALIZACAO POR ETAPAS NOMEADAS (temporario)

     Antes isto era um `pcall` unico em volta de tudo:

         local ok, err = pcall(function()
             build_gui()
             build_fov_circle()
             start_aim()
             ... mais 40 linhas ...
         end)

     Quando alguma coisa falhava no meio, o erro era engolido e o
     usuario so' via "abriu o menu e nada funciona" - sem pista
     nenhuma de QUAL etapa morreu.

     Agora cada etapa tem nome e o erro sai identificado. Assim que
     o problema for localizado, isto volta a ser um pcall so'.
     ============================================================ ]]
pcall(function()
    if type(print) == "function" then
        print("[LowHub] definicoes carregadas - construindo interface...")
    end
end)

local ETAPAS = {}
local function etapa(nome, fn)
    local ok, err = pcall(fn)
    if not ok then
        ETAPAS[#ETAPAS + 1] = "FALHOU: " .. nome .. " -> " .. tostring(err)
    else
        ETAPAS[#ETAPAS + 1] = "ok: " .. nome
    end
    return ok
end

etapa("build_gui",        function() build_gui() end)
etapa("build_fov_circle", function() build_fov_circle() end)
etapa("start_aim",        function() start_aim() end)

etapa("loop_principal", function()
    task.spawn(function()
        while running and PARENT and PARENT.Parent do
            pcall(refresh_esp)
            pcall(apply_speed)
            pcall(update_fly)
            pcall(update_esp_labels)
            pcall(apply_mouse_lock)
            task.wait(0.05)
        end
    end)
end)

--[[ O AVISO DE "NAO SUPORTADO" SAIU

     Aqui tinha:

         if MOUSE_MODE == "camera" and not hook_on then
             -- mostra "AIMLOCK NOT SUPPORTED ON THIS EXECUTOR"

     Esse aviso existia porque o hub antigo so' sabia mirar por
     mouse ou por hook de metatable. Como o Xeno nao tem
     hookmetamethod, sobrava o mouse - e se o mouse faltasse
     tambem, nao havia caminho nenhum.

     Isso nao e' mais verdade. O caminho por `Camera.CFrame`
     funciona sozinho e foi o que sempre funcionou nas versoes
     antigas (lowhub_v1.8 / v2.1 / v2.3 / tribos_3v3_v19 - todas
     com ZERO codigo de mouse).

     Com MOUSE_MODE agora fixo em "camera", a condicao antiga daria
     SEMPRE verdadeiro e o aviso apareceria toda vez, dizendo que a
     mira nao funciona - quando ela funciona. Aviso removido pra
     nao assustar sem motivo.
     ============================================================ ]]

etapa("loop_fov", function()
    task.spawn(function()
        while running and PARENT and PARENT.Parent do
            pcall(update_fov_circle)
            task.wait()
        end
    end)
end)

etapa("eventos", function()
    Players.PlayerAdded:Connect(function(plr)
        plr.CharacterAdded:Connect(function()
            task.wait(0.4)
            pcall(refresh_esp)
        end)
    end)

    Players.PlayerRemoving:Connect(function(plr)
        pcall(remove_esp, plr)
    end)

    LP.CharacterAdded:Connect(function()
        task.wait(0.8)
        if CONFIG.FlyEnabled then pcall(start_fly) end
    end)
end)

local ok = true
for _, linha in ipairs(ETAPAS) do
    -- "FALHOU" tem 6 letras. Estava sub(1, 7), que pega "FALHOU:"
    -- e nunca bate com "FALHOU" - ou seja, o relatorio dizia
    -- "inicializacao completa" mesmo com etapa falhando.
    if linha:sub(1, 6) == "FALHOU" then ok = false end
end
local err = table.concat(ETAPAS, "\n         ")

--[[ RELATORIO SEMPRE, ANTES DE QUALQUER COISA

     O usuario relatou "nao executou" - nem o console saiu. Sinal de
     que a morte acontece ANTES do print do relatorio, ou que o
     proprio relatorio derruba (ex: G nil, limpar_tudo nil).

     Entao: imprimimos PRIMEIRO, e cada passo vai em pcall proprio.
     Assim, mesmo que algo abaixo exploda, o diagnostico ja' saiu na
     tela e da' pra saber onde parou.
     ============================================================ ]]
pcall(function()
    if type(print) == "function" then
        print("[LowHub] ==== relatorio de inicializacao ====")
        for _, linha in ipairs(ETAPAS) do print("         " .. linha) end
        print("[LowHub] ==== fim do relatorio ====")
    end
end)

if ok then
    pcall(function()
        G.__LOWHUB_ATIVO = { limpar = limpar_tudo }
    end)
else
    pcall(function()
        warn("[LowHub] " .. tostring(err))
    end)
end

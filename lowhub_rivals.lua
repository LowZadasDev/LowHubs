local VERSION = "LowHub Rivals"
local limpar_tudo = nil

--[[
    TRAVA DE JOGO

    O hub so roda no jogo pra que foi feito. Se alguem pegar o
    arquivo e executar em outro lugar, ele nao faz NADA - so
    mostra um aviso e morre.

    Isto roda ANTES de tudo: nada de servico, nada de interface,
    nada de loop. Se o jogo estiver errado, o script termina na
    primeira linha util.

    ------------------------------------------------------------------
    OS IDs ESTAVAM ERRADOS  (corrigido em 22/10)

    O que estava guardado aqui:

        place   = 117398147513099   <- isso e' PlaceId, mas de um
                                       mapa SECUNDARIO
        criador = 6035872082        <- isso NAO e' CreatorId.
                                       e' o UNIVERSE ID do Rivals.

    Conferido na API da Roblox:

        UniverseId 6035872082
          rootPlaceId = 17625359962      <- o mapa principal
          creator     = 3461453          <- Nosniy Games (grupo)
          nome        = "[RIVALS]"

    Ou seja: o campo `criador` guardava o Universe ID. Como
    game.CreatorId nunca devolve isso, a comparacao dava falso
    SEMPRE - a trava nunca ia reconhecer o Rivals.

    ------------------------------------------------------------------
    OS IDs CERTOS

        game.PlaceId    = 17625359962   (root place do Rivals)
        game.CreatorId  = 3461453       (grupo "Nosniy Games")

    Aceito os DOIS PlaceIds conhecidos porque o Rivals tem mais de
    um lugar no mesmo universo - os dois apontam pro mesmo jogo:

        17625359962     -> universe 6035872082
        117398147513099 -> universe 6035872082   (secundario)

    Se o Rivals abrir um mapa novo com PlaceId diferente, o
    CreatorId cobre - e' a rede de seguranca.

    Se os dois campos estiverem preenchidos, vale QUALQUER UM.
--]]
local JOGO_ESPERADO = {
    -- root place + o place secundario que a gente ja conhecia
    places  = { 17625359962, 117398147513099 },
    criador = 3461453,
    nome    = "Rivals",
}

do
    local place_ok = false
    for _, id in ipairs(JOGO_ESPERADO.places) do
        if game.PlaceId == id then place_ok = true break end
    end
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
            t.Text = "LOWHUB  ·  WRONG GAME"
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

        -- termina aqui. Nada de hub.
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

local ENV = (type(getfenv) == "function" and getfenv()) or _G

local function envfn(name)
    local f = ENV[name]
    if type(f) == "function" then return f end
    f = _G[name]
    if type(f) == "function" then return f end
    if type(getgenv) == "function" then
        local ok, g = pcall(getgenv)
        if ok and type(g) == "table" and type(g[name]) == "function" then
            return g[name]
        end
    end
    return nil
end

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local StarterGui        = game:GetService("StarterGui")
local GuiService        = game:GetService("GuiService")
local CoreGui           = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local VIM = nil
do
    local ok, svc = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    if ok and svc then VIM = svc end
    if not VIM then
        local f = envfn("VirtualInputManager")
        if f then VIM = f end
    end
end
local f_mouse1     = envfn("mouse1click")

local f_mouse1down = envfn("mouse1press")
local f_mouse1up   = envfn("mouse1release")
local f_mousemove  = envfn("mousemoverel")

if not game:IsLoaded() then
    local t0 = os.clock()
    while not game:IsLoaded() and os.clock() - t0 < 10 do
        task.wait(0.1)
    end
end
task.wait(0.35)
Camera = Workspace.CurrentCamera

local function resolve_parent()
    local hui = envfn("gethui")
    if hui then
        local ok, r = pcall(hui)
        if ok and r then return r, "gethui" end
    end
    local ghg = envfn("get_hidden_gui")
    if ghg then
        local ok, r = pcall(ghg)
        if ok and r then return r, "hidden" end
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

local FS = {
    write   = envfn("writefile"),
    read    = envfn("readfile"),
    isfile  = envfn("isfile"),
    delfile = envfn("delfile"),
    mkdir   = envfn("makefolder"),
    isdir   = envfn("isfolder"),
    pasta   = "LowHub",
}
FS.tem = (type(FS.write) == "function" and type(FS.read) == "function")

local function hub_path(arquivo) return FS.pasta .. "/" .. arquivo end

local function garantir_pasta()
    if type(FS.mkdir) ~= "function" then return false end
    if type(FS.isdir) == "function" then
        local ok, existe = pcall(FS.isdir, FS.pasta)
        if ok and existe then return true end
    end
    pcall(FS.mkdir, FS.pasta)
    return true
end

local function salvar_arquivo(nome, texto)
    if not FS.tem then return false end
    garantir_pasta()
    if pcall(FS.write, hub_path(nome), texto) then return true end
    return pcall(FS.write, nome, texto)
end

local function ler_arquivo(nome)
    if not FS.tem then return nil end
    local ok, txt = pcall(FS.read, hub_path(nome))
    if ok and txt then return txt end
    ok, txt = pcall(FS.read, nome)
    if ok and txt then return txt end
    return nil
end

local function apagar_arquivo(nome)
    if type(FS.delfile) ~= "function" then return end
    pcall(FS.delfile, hub_path(nome))
    pcall(FS.delfile, nome)
end

local CONFIG = {

    AimEnabled      = false,
    -- o aimlock pode ser acionado por tecla OU por botao do mouse.
    -- Se AimMouseButton estiver setado, ele manda e a tecla fica
    -- ignorada. E' assim no Tribos tambem.
    AimKey          = Enum.KeyCode.E,
    AimMouseButton  = nil,

    AimMode         = "hold",
    -- Agora e VELOCIDADE, nao fracao: 0 = teto cheio (14
    -- graus/frame), 0.85 = devagar. 0.35 acompanha qualquer
    -- jogador sem parecer teleporte.
    AimSmooth       = 0.35,
    AimFOV          = 120,
    AimTarget       = "HEAD",
    WallCheck       = true,


    TriggerBot      = false,
    FireDelay       = 0.09,
    FireOnlyLocked  = true,


    FireTolerance   = 14,


    ESPEnabled      = true,
    ESPMaxDistance  = 600,
    ESPShowName     = true,
    ESPShowHealth   = true,
    ESPShowDist     = true,
    ESPBox          = true,

    ESPmax          = 900,


    FlyEnabled      = false,
    FlySpeed         = 55,
    SpeedEnabled    = false,
    SpeedValue      = 22,


    FpsMode         = false,


    ShowFOVCircle   = true,
}

local COR = {
    inimigo   = Color3.fromRGB(255, 70, 90),
    aliado    = Color3.fromRGB(90, 220, 130),
    texto     = Color3.fromRGB(240, 236, 250),
    esqueleto = Color3.fromRGB(255, 255, 255),
    perigo    = Color3.fromRGB(255, 170, 40),
    travado   = Color3.fromRGB(140, 255, 170),
}

local function gui_no_mouse(lista, mx, my)
    if not lista then return false end
    local ok, objetos = pcall(function()
        return lista:GetGuiObjectsAtPosition(mx, my)
    end)
    if not ok or type(objetos) ~= "table" then return false end
    for _, v in ipairs(objetos) do
        local ativo = false
        local visivel = false
        pcall(function() ativo = v.Active end)
        pcall(function() visivel = v.Visible end)
        if ativo and visivel then


            local ok2, sg = pcall(function() return v:FindFirstAncestorOfClass("ScreenGui") end)
            if ok2 and sg then
                local ligado = true
                pcall(function() ligado = sg.Enabled end)
                if ligado then return true end
            end
        end
    end
    return false
end

local function can_click()

    local ok, focado = pcall(function()
        return UserInputService:GetFocusedTextBox()
    end)
    if ok and focado then return false end

    local ok3, pos = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if not ok3 or not pos then return true end



    local y = pos.Y
    pcall(function() y = pos.Y - GuiService:GetGuiInset().Y end)

    if gui_no_mouse(LP:FindFirstChild("PlayerGui"), pos.X, y) then
        return false
    end
    if gui_no_mouse(CoreGui, pos.X, y) then
        return false
    end
    return true
end

local rc_params = nil
local function preparar_raycast()
    if rc_params then return rc_params end
    local ok, p = pcall(function()
        return RaycastParams.new()
    end)
    if not ok or not p then return nil end
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.IgnoreWater = true
    rc_params = p
    return rc_params
end

local wall_cache = {}
local WALL_TTL = 0.12

local function tem_visao(plr, parte, ch)
    if not CONFIG.WallCheck then return true end
    if not Camera or not parte then return true end

    -- Aceita Player OU personagem. Em partida o Rivals esconde o
    -- Player, entao o alvo chega aqui como Model puro - e sem isso
    -- a linha abaixo (plr.Character) quebrava e derrubava a mira.
    local alvo_char = ch
    if not alvo_char and plr then alvo_char = plr.Character end

    -- a chave do cache precisa de algo unico. Se nao tem Player,
    -- uso o proprio personagem.
    local chave = plr or alvo_char
    if not chave then return true end

    local agora = os.clock()
    local c = wall_cache[chave]
    if c and agora - c.t < WALL_TTL then return c.ok end

    local p = preparar_raycast()
    if not p then return true end


    local ignorar = {}
    local meu = LP.Character
    if meu then ignorar[#ignorar + 1] = meu end
    if alvo_char then ignorar[#ignorar + 1] = alvo_char end
    local cam = Workspace.CurrentCamera
    if cam then ignorar[#ignorar + 1] = cam end
    p.FilterDescendantsInstances = ignorar

    local origem = cam.CFrame.Position
    local destino = parte.Position
    local dir = destino - origem

    local ok, res = pcall(function()
        return Workspace:Raycast(origem, dir, p)
    end)


    local limpo = true
    if ok and res and res.Instance then

        if res.Distance < dir.Magnitude - 0.6 then
            limpo = false
        end
    end

    wall_cache[chave] = { t = agora, ok = limpo }
    return limpo
end

local HITBOX_HEAD = { "PhysicalHitboxHead", "HitboxHead", "Head" }
local HITBOX_BODY = { "HitboxBody", "UpperTorso", "HumanoidRootPart" }

local function parte_do_alvo(char, tipo)
    if not char then return nil end
    local lista = (tipo == "BODY") and HITBOX_BODY or HITBOX_HEAD
    for _, nome in ipairs(lista) do
        local p = char:FindFirstChild(nome)
        if p and p:IsA("BasePart") then return p end
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function arena_entities()
    local arena = Workspace:FindFirstChild("Arena")
    if not arena then return nil end
    return arena:FindFirstChild("Entities")
end

local function esta_na_arena(char)
    local ent = arena_entities()
    if not ent then return true end
    if not char then return false end
    return char.Parent == ent or char:IsDescendantOf(ent)
end

--[[
    ONDE ESTAO OS ADVERSARIOS  (descoberto no recon de 21/10)

    Eu tinha escrito que os corpos ficam em Workspace.Arena.Entities.
    ERADO. O dump da arvore do Workspace mostra eles SOLTOS na raiz:

        Workspace
          Lobby                  [Folder]   <- lobby
          ShootingRangeEntities  [Folder]   <- treino
          ViewModels             [Model]    <- arma em 1a pessoa
          Arena                  [Model]    <- so o MAPA
          EUXITOXITOXITOMEMOX    [Model]    <- eu
          Justjustice3paige      [Model]    <- adversario
          Brandon786496          [Model]    <- adversario
          progamer_67682         [Model]    <- aliado

    Arena.Entities so tem estrutura (MapVersion_Arena, Winners,
    Spawns, Barriers) - nenhum corpo. Foi por isso que continuou
    sem achar alvo depois da primeira correcao.

    E o TeamID FUNCIONA. O mesmo recon mediu:

        EU                 TeamID = 2
        Justjustice3paige  TeamID = 1   INIMIGO
        progamer_67682     TeamID = 2   ALIADO

    Entao da pra separar aliado de inimigo com precisao - nao
    preciso mais tratar "todo mundo que nao sou eu" como inimigo.
--]]

-- Le o TeamID de um Player. Devolve nil se nao tiver.
local function team_id(plr)
    if not plr then return nil end
    local ok, t = pcall(function() return plr.TeamID end)
    if ok and type(t) == "number" and t ~= 0 then return t end
    local tm = plr.Team
    if tm then
        local ok2, t2 = pcall(function() return tm.TeamId end)
        if ok2 and t2 then return t2 end
    end
    return nil
end

local MEU_TIME = nil

--[[
    DE QUEM E' ESTE CORPO?

    O dump provou que no Rivals o Model tem o NOME DO DONO:

        Workspace.ProDark_GamerBr   [Model]  <- eu
        Workspace.luismill93        [Model]  <- outro jogador

    E o Players:GetPlayerFromCharacter devolve nil pra eles - o
    Rivals corta o vinculo Model->Player. Entao o nome e' a
    ligacao mais confiavel que sobra.
--]]
local function dono_do_model(m)
    local plr = Players:GetPlayerFromCharacter(m)
    if plr then return plr end

    for _, campo in ipairs({ "Player", "Owner", "UserId" }) do
        local ok, v = pcall(function() return m:GetAttribute(campo) end)
        if ok and v ~= nil then
            if typeof(v) == "Instance" and v:IsA("Player") then return v end
            if type(v) == "number" then
                local p = Players:GetPlayerByUserId(v)
                if p then return p end
            end
        end
    end

    -- pelo nome do Model (o caminho que o dump mostrou funcionar)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == m.Name then return p end
    end

    return nil
end

--[[
    ISTO E' UM CORPO DE JOGADOR OU UM BONECO DE TREINO?

    Descoberto no dump de 22/10. O Workspace tem MUITO Model com
    Humanoid, e a maioria NAO e' gente:

        Workspace
          ShootingRangeEntities [Folder] 207 filhos, ~40 DUMMIES
          Construction          [Model]   cenario
          energy_bundle         [Model]   cenario
          Panel / Part          [Part]    cenario
          Weapons / Market      [Folder]  loja do lobby

    Se eu aceitar tudo que tem Humanoid, a mira gruda em boneco de
    treino e em cenario. Foi o que o dump mostrou: 40 "alvos" que
    nao sao ninguem.

    A diferenca que separa os dois:

      JOGADOR         nome do dono, 29-30 filhos (corpo R15 completo
                      + as hitboxes PhysicalHitboxHead, HitboxHead,
                      HitboxBody...)
      DUMMY/CENARIO   nome generico ("Dummy", "DPS Dummy"), e as
                      vezes sem hitbox nenhuma

    Entao eu exijo as HITBOXES. Elas so existem em corpo jogavel -
    e' justamente nelas que o dano do Rivals bate.
--]]
local HITBOXES = {
    "PhysicalHitboxHead", "HitboxHead", "HitboxHeadSmall",
    "HitboxBody", "HitboxBodySmall",
}

local function tem_hitbox(m)
    for _, n in ipairs(HITBOXES) do
        if m:FindFirstChild(n) then return true end
    end
    return false
end

-- nomes que denunciam boneco/cenario
local function nome_de_boneco(nome)
    local n = string.lower(nome)
    return n == "dummy"
        or string.find(n, "dps dummy", 1, true) ~= nil
        or string.find(n, "dummy", 1, true) ~= nil
        or string.find(n, "target", 1, true) ~= nil
        or string.find(n, "bot", 1, true) ~= nil
end

local function e_corpo(m)
    if not m or not m:IsA("Model") then return false end
    if m == LP.Character then return false end

    -- boneco de treino e cenario: fora
    if nome_de_boneco(m.Name) then return false end

    -- precisa ter Humanoid vivo
    local hum = m:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    -- e precisa ter as hitboxes: e' o que separa gente de cenario
    if not tem_hitbox(m) then return false end

    -- nao pode ser descendente de cenario/loja
    local pai = m.Parent
    while pai and pai ~= Workspace do
        local n = string.lower(pai.Name)
        if n == "shootingrangeentities"
           or n == "construction"
           or n == "market"
           or n == "weapons" then
            return false
        end
        pai = pai.Parent
    end

    return true
end

--[[
    LISTA DE ALVOS  (reescrito com o dump de 22/10 EM PARTIDA)

    O que o dump provou, rodando numa partida de verdade:

        === ARENA ===
        There is no Arena in Workspace.      <- nem existe!

        === WORKSPACE ===
        ProDark_GamerBr   Model  29 children  <- EU
        luismill93        Model  30 children  <- ADVERSARIO
        ShootingRangeEntities Folder 207      <- treino (ignorar)

        === EU ===
        Players: 1 player(s)                  <- so eu!
        ProDark_GamerBr

    Entao:
      - Arena.Entities NAO EXISTE em partida. Minha fonte 3 era
        fantasia - eu inventei com base num dump do LOBBY.
      - Players:GetPlayers() traz SO O PROPRIO JOGADOR.
      - Os adversarios sao Models SOLTOS na raiz do Workspace,
        com o nome do dono.

    A busca agora e' simples e direta: varre a raiz do Workspace
    procurando Model com Humanoid + hitboxes, e descarta o meu.
--]]
local function listar_alvos()
    local vistos = {}
    local lista  = {}

    local function adicionar(plr, char)
        if not char then
            if plr then char = plr.Character end
            if not char then return end
        end
        if char == LP.Character then return end
        if plr and plr == LP then return end
        if vistos[char] then return end
        vistos[char] = true
        lista[#lista + 1] = { plr = plr, char = char }
    end

    -- FONTE 1: corpos soltos na raiz do Workspace.
    -- E' aqui que os adversarios ficam em partida.
    pcall(function()
        for _, obj in ipairs(Workspace:GetChildren()) do
            if e_corpo(obj) then
                adicionar(dono_do_model(obj), obj)
            end
        end
    end)

    -- FONTE 2: Players com Character.
    -- Em partida so traz o proprio jogador (que ja e' filtrado),
    -- mas no lobby e' a fonte boa.
    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            local ch = plr.Character
            if ch and e_corpo(ch) then
                adicionar(plr, ch)
            end
        end
    end)

    -- FONTE 3: se a raiz do Workspace nao bastou, procura um
    -- nivel mais fundo. Cobre o caso do Rivals agrupar os corpos
    -- numa pasta qualquer que eu nao conheco.
    if #lista == 0 then
        pcall(function()
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Folder") or obj:IsA("Model") then
                    for _, sub in ipairs(obj:GetChildren()) do
                        if e_corpo(sub) then
                            adicionar(dono_do_model(sub), sub)
                        end
                    end
                end
            end
        end)
    end

    return lista
end

-- Atualiza MEU_TIME. Chamado no boot e quando o time muda.
local function ler_meu_time()
    local t = team_id(LP)
    if t then MEU_TIME = t end
    return MEU_TIME
end

-- (bloco antigo removido: procurava em Arena.Entities, lugar errado)

local function is_alive(plr)
    if not plr or plr == LP then return false end
    local ch = plr.Character
    if not ch then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    return true
end

local function is_enemy(plr)
    return is_alive(plr)
end

local function get_root(plr)
    local ch = plr and plr.Character
    if not ch then return nil end
    return ch:FindFirstChild("HumanoidRootPart")
end

--[[
    SISTEMA DE KEYBIND  (mesmo do Tribos)

    O usuario pediu pra poder escolher a tecla do aimlock, igual
    no LowHub do Tribos. O sistema e' este:

      1. Clica no botao do menu -> entra em modo captura
      2. O botao fica laranja escrito "press a key"
      3. Aperta qualquer tecla OU clica qualquer botao do mouse
      4. Esc cancela e mantem o que estava
      5. Todos os botoes de keybind se repintam juntos

    O Tribos suporta teclado E mouse (o que e' util: muita gente
    prefere botao lateral do mouse pro aimlock).
--]]
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

local function repaint_keybinds()
    for _, fn in ipairs(Keybind.painters) do pcall(fn) end
end

local aim_held    = false
--[[
    aim_toggled saiu junto com o modo "toggle".

    Ele guardava o estado de ligado/desligado da mira por tecla.
    Como agora so existem HOLD (segura) e ALWAYS (sempre), nao
    tem mais estado pra guardar - `aim_held` ja cobre tudo.
--]]
local aim_active  = false
local aim_target  = nil
local locked      = nil
local locked_char = nil
local fire_state  = "idle"

local aim_erro    = 999

local function recompute_aim()
    if not CONFIG.AimEnabled then aim_active = false return end

    --[[
        SO HOLD E ALWAYS

        O modo "toggle" saiu do menu - ele e o HOLD faziam a
        mesma coisa, so com nomes diferentes. Se algum preset
        velho ainda trouxer "toggle", eu trato como HOLD, que
        e' o comportamento mais parecido (precisa da tecla).
    --]]
    local m = CONFIG.AimMode
    if m == "always" then
        aim_active = true
    else
        -- hold (e qualquer valor antigo, tipo "toggle")
        aim_active = aim_held
    end
end

--[[
    ESCOLHA DE ALVO COM MEMORIA

    Bug do "puxa e solta" (relatado em 22/10):

      Eu escolhia o alvo mais perto do centro dentro do FOV. Quando
      a mira comecava a puxar, o alvo saia do centro -> a distancia
      CRESCIA -> estourava o FOV -> o codigo perdia o alvo. Aí
      escolhia outro, puxava, perdia. Puxa-e-solta.

    A correcao e' ter MEMORIA: uma vez travado, continuo no mesmo
    alvo enquanto ele estiver vivo, visivel e dentro de um limite
    maior (o "FOV de soltura"). So troco quando ele morre, some ou
    fica absurdamente longe.

      FOV normal    = 120  (pra ACHAR um alvo novo)
      FOV de soltura = 2.5x (pra LARGAR o que ja esta travado)

    Assim a mira gruda e nao fica piscando entre dois caras.
--]]
local FOV_SOLTA = 2.5

--[[
    POR QUE A MIRA SE PERDIA  (relato de 22/10)

    "as vezes a mira se perde caso eu nao mexa ela ou ate quando
     eu mexo"

    Duas causas, as duas no alvo_ainda_vale:

    1) `if not na_tela then return false end`

       O WorldToViewportPoint devolve na_tela = false quando o
       alvo passa da borda da tela OU quando esta muito perto da
       camera (o Rivals e' primeira pessoa e o alvo colado no
       peito faz isso). Nesses instantes eu largava o alvo na
       hora - mesmo com ele vivo e na minha frente.

    2) `d <= CONFIG.AimFOV * FOV_SOLTA`

       A distancia e' medida em PIXELS ate o centro. Com o alvo
       de lado e a mira ja puxando, ele saia do circulo e eu
       soltava.

    Agora eu nao largo mais por posicao na tela. So largo por
    motivo de verdade:

        - o corpo sumiu do jogo (morreu, saiu, teleportou)
        - o Humanoid morreu
        - ficou MUITO longe em 3D (> 900 studs)

    Posicao na tela nao e' mais motivo pra soltar. Se o alvo
    sair de tras de uma parede e voltar, eu continuo nele.
--]]
local DIST_SOLTA = 900

local function alvo_ainda_vale(ch, parte)
    if not ch then return false end
    if not ch.Parent then return false end

    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    -- a parte alvo pode sumir por um frame (morte/teleporte).
    -- Isso NAO e' motivo pra soltar: o corpo continua ali.
    if not parte then return true end

    -- longe demais em 3D: aí sim solta
    local meu = LP.Character
    local minha = meu and meu:FindFirstChild("HumanoidRootPart")
    local raiz = ch:FindFirstChild("HumanoidRootPart")
    if minha and raiz then
        if (raiz.Position - minha.Position).Magnitude > DIST_SOLTA then
            return false
        end
    end

    return true
end

--[[
    TOLERANCIA DE PERDA  (parte 2 do bug "a mira se perde")

    Mesmo com o alvo_ainda_vale corrigido, a mira ainda largava
    por UM frame ruim:

      - o Rivals recria o corpo (respawn, troca de arma) e o
        Model fica sem hitbox por 1-2 frames
      - o alvo passa por tras de uma parede por 1 frame no
        wallcheck
      - o Humanoid reporta Health = 0 no instante da morte

    Largar na hora nesses casos fazia a mira piscar entre dois
    caras. Agora eu conto os frames ruins: so solto depois de
    12 frames seguidos (0.2s) sem conseguir mirar. Um tropeco
    de 1 frame nao derruba mais nada.
--]]
local PERDA_MAX = 12
local perda_frames = 0

local function escolher_alvo()
    if not Camera then return nil end
    local vs = Camera.ViewportSize
    local centro = Vector2.new(vs.X / 2, vs.Y / 2)
    local meu = get_root(LP)

    -- 1) o alvo travado continua valendo?
    if locked_char then
        local parte = parte_do_alvo(locked_char, CONFIG.AimTarget)
        if alvo_ainda_vale(locked_char, parte) then
            perda_frames = 0
            return locked, locked_char
        end

        -- nao larga no primeiro tropeco
        perda_frames = perda_frames + 1
        if perda_frames <= PERDA_MAX then
            -- mantem o alvo, so nao mexe a mira neste frame
            return locked, locked_char
        end

        perda_frames = 0
        locked = nil
        locked_char = nil
    end

    -- 2) escolhe um novo
    local melhor, melhor_char = nil, nil
    local melhor_d = CONFIG.AimFOV
    local melhor_dist3d = math.huge

    for _, it in ipairs(listar_alvos()) do
        local ch = it.char
        if ch ~= locked_char then
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local parte = parte_do_alvo(ch, CONFIG.AimTarget)
                if parte then
                    local sp, na_tela = Camera:WorldToViewportPoint(parte.Position)
                    if na_tela then
                        local d = (Vector2.new(sp.X, sp.Y) - centro).Magnitude
                        if d < melhor_d and tem_visao(it.plr, parte, ch) then
                            local d3 = 0
                            local raiz = ch:FindFirstChild("HumanoidRootPart")
                            if meu and raiz then
                                d3 = (raiz.Position - meu.Position).Magnitude
                            end
                            -- so troca de alvo se for bem mais perto
                            -- (30px), senao fica oscilando entre dois
                            if d < melhor_d - 30 or d3 < melhor_dist3d then
                                melhor_d = d
                                melhor_dist3d = d3
                                melhor = it.plr
                                melhor_char = ch
                            end
                        end
                    end
                end
            end
        end
    end

    -- se nao achou ninguem novo, mantem o antigo mesmo fora do FOV
    -- (evita soltar quando o cara sai da tela por um instante)
    if not melhor_char and locked_char then
        local parte = parte_do_alvo(locked_char, CONFIG.AimTarget)
        if parte then return locked, locked_char end
    end

    return melhor, melhor_char
end

local function mover_mouse(dx, dy)
    if not f_mousemove then return false end
    local ok = pcall(f_mousemove, dx, dy)
    return ok
end

local MIRA_MODO = "mouse"

local function detectar_mira()
    if not f_mousemove then
        MIRA_MODO = "camera"
        return
    end

    local uis = game:GetService("UserInputService")
    local ok, antes = pcall(function() return uis:GetMouseLocation() end)
    if not ok or not antes then
        MIRA_MODO = "camera"
        return
    end

    pcall(f_mousemove, 8, 0)
    task.wait(0.05)
    local ok2, depois = pcall(function() return uis:GetMouseLocation() end)

    if ok2 and depois and math.abs(depois.X - antes.X) > 0.5 then
        MIRA_MODO = "mouse"
    else
        MIRA_MODO = "camera"
    end
end

--[[
    MIRA PELA CAMERA  (corrigido duas vezes em 22/10)

    POR QUE MIRAR PELA CAMERA:

    Quando o jogo trava o cursor (MouseBehavior = LockCenter), o
    mousemoverel nao faz nada - o jogo reescreve a posicao do
    cursor a cada frame. O diagnostico mostrou isso no Xeno: a
    funcao existe, mas o mouse nao anda.

    Nesse caso o jeito e' apontar a camera direto. O Rivals e
    primeira pessoa, entao a camera fica na cabeca: eu preservo a
    POSICAO e troco so a direcao.

    ERRO 1 (corrigido): interpolacao de vetor

        Camera.CFrame.LookVector:Lerp(goal, f)

    Lerp de VETOR nao serve pra girar direcao. Ele interpola
    componente por componente e o resultado NAO fica unitario:
    o meio de dois pontos numa esfera esta DENTRO dela, e a
    linha do centro ate esse ponto nao passa pelo alvo. Medi:
    1.12 graus de erro por frame com f = 0.78.

    O certo e' interpolar (yaw, pitch). Isso eu faco abaixo.

    ERRO 2 (o grave, e a causa do "puxa mas fraco"):

    Eu mirava com uma FRACAO do resto a cada frame:

        erro_novo = erro * (1 - ganho)

    Com o alvo parado converge em 3 frames e parece otimo. Mas
    com o alvo ANDANDO, cada frame soma de volta o movimento:

        erro_novo = erro * (1 - ganho) + movimento

    Quando o alvo anda mais rapido do que a fracao que eu
    recupero, o erro ESTABILIZA num valor alto e NUNCA fecha. A
    mira fica colada num angulo atras, sempre puxando e nunca
    chegando. Simulei: com ganho 0.78 e alvo a 8 graus por
    frame, 200 frames e ainda nao alcancou.

    O certo e' VELOCIDADE: cada frame ando ate um teto fixo de
    graus. Assim acompanho qualquer alvo que ande menos que o
    teto e o erro vai a zero de verdade.

      AimSmooth = 0   -> vai no teto (14 graus/frame = 840/s)
      AimSmooth = 0.5 -> metade do teto
      AimSmooth = 0.95 -> bem devagar, legit
--]]
local AIM_GRAUS_MAX = 14

local function direcao_para_yaw_pitch(v)
    local horiz = math.sqrt(v.X * v.X + v.Z * v.Z)
    local yaw   = math.atan2(-v.X, -v.Z)
    local pitch = math.atan2(v.Y, horiz)
    return yaw, pitch
end

local function yaw_pitch_para_direcao(yaw, pitch)
    local cp = math.cos(pitch)
    return Vector3.new(-math.sin(yaw) * cp, math.sin(pitch), -math.cos(yaw) * cp)
end

-- encurta o caminho: se a diferenca passar de 180 graus, vai pelo
-- lado curto em vez de dar a volta inteira
local function menor_angulo(de, para)
    local d = para - de
    while d > math.pi do d = d - math.pi * 2 end
    while d < -math.pi do d = d + math.pi * 2 end
    return d
end

local function mirar_camera(goal_look)
    if not Camera then return false end

    local atual = Camera.CFrame
    local pos = atual.Position
    if not goal_look or goal_look.Magnitude < 0.001 then return false end

    local y0, p0 = direcao_para_yaw_pitch(atual.LookVector)
    local y1, p1 = direcao_para_yaw_pitch(goal_look.Unit)

    -- erro em graus, por eixo
    local dy_g = math.deg(menor_angulo(y0, y1))
    local dp_g = math.deg(p1 - p0)

    -- teto de velocidade em graus por frame.
    -- 0.05 = bem devagar (legit)   1.0 = teto cheio (rage)
    local teto = AIM_GRAUS_MAX * math.clamp(1 - CONFIG.AimSmooth, 0.05, 1)

    -- anda ate o teto, mas NUNCA passa do alvo
    local passo_y = math.clamp(dy_g, -teto, teto)
    local passo_p = math.clamp(dp_g, -teto, teto)

    local yaw   = y0 + math.rad(passo_y)
    local pitch = p0 + math.rad(passo_p)

    local novo = yaw_pitch_para_direcao(yaw, pitch)

    local ok = pcall(function()
        Camera.CFrame = CFrame.lookAt(pos, pos + novo)
    end)
    return ok
end

local function centro_da_tela()
    if not Camera then return nil end
    local vs = Camera.ViewportSize
    return Vector2.new(vs.X / 2, vs.Y / 2)
end

local function mirar(dt)
    if not aim_active then
        locked = nil locked_char = nil aim_erro = 999 perda_frames = 0
        return
    end
    local alvo, ch = escolher_alvo()
    if not ch then
        locked = nil locked_char = nil aim_erro = 999
        return
    end
    -- o alvo pode vir sem Player (quando o Rivals esconde o
    -- adversario em partida). O personagem e' o que importa pra
    -- mirar - o Player so serve pra saber o nome.
    locked = alvo
    locked_char = ch

    local parte = parte_do_alvo(ch, CONFIG.AimTarget)
    if not parte or not Camera then return end

    local sp, na_tela = Camera:WorldToViewportPoint(parte.Position)

    --[[
        TERCEIRO MOTIVO DE PERDER A MIRA

        Aqui tinha `if not na_tela then return end`. Quando o alvo
        saia da tela, o mirar desistia NAQUELE frame - e como a
        mira nao mexia, o alvo nunca voltava pra tela. Travava
        num ciclo: nao esta na tela, nao mexo, continua fora.

        Agora, se esta fora da tela, eu APONTO PRA ELE mesmo
        assim - uso a posicao 3D direto. E' o que traz de volta.
    --]]
    if not na_tela then
        local de = Camera.CFrame.Position
        local para = parte.Position - de
        if para.Magnitude > 0.1 then
            aim_erro = 999
            if MIRA_MODO == "camera" then
                mirar_camera(para.Unit)
            end
        end
        return
    end

    local base = centro_da_tela()
    if not base then return end
    local dx = sp.X - base.X
    local dy = sp.Y - base.Y

    aim_erro = math.sqrt(dx * dx + dy * dy)

    local f = math.clamp(1 - CONFIG.AimSmooth, 0.05, 1)

    if MIRA_MODO == "camera" then
        local de = Camera.CFrame.Position
        local para = parte.Position - de
        if para.Magnitude > 0.1 then
            mirar_camera(para.Unit)
        end
    else
        --[[
            BUG DO "FRACO" NO MODO MOUSE

            Eu mandava f * distancia. Com AimSmooth 0.22, f = 0.78:
            o cursor andava 78% do caminho e nunca chegava. No
            frame seguinte a distancia era 22% da original, e ele
            andava 78% DISSO - uma serie geometrica que converge
            devagar e, com o alvo se mexendo, nunca fecha.

            Pior: o piso de 1px cortava os passos finais (abaixo
            de 1px o codigo ignorava), entao sobrava um erro
            permanente que o jogo nunca corrigia.

            Agora eu aplico um GANHO, nao uma fracao do resto.
            Cada frame anda pelo menos 35% e no maximo 100% da
            distancia - chega rapido sem tremer.
        --]]
        local ganho = math.clamp(1 - CONFIG.AimSmooth * 0.6, 0.35, 1)

        local mx = dx * ganho
        local my = dy * ganho

        if mx > 0 then mx = math.floor(mx + 0.5)
        elseif mx < 0 then mx = math.ceil(mx - 0.5) end
        if my > 0 then my = math.floor(my + 0.5)
        elseif my < 0 then my = math.ceil(my - 0.5) end

        -- se o alvo esta a 2px ou menos, dou o passo final de
        -- qualquer jeito: sem isso fica um erro de 1px pra sempre
        if aim_erro > 0 and aim_erro <= 2.5 then
            if mx == 0 and math.abs(dx) > 0.5 then
                mx = dx > 0 and 1 or -1
            end
            if my == 0 and math.abs(dy) > 0.5 then
                my = dy > 0 and 1 or -1
            end
        end

        if mx ~= 0 or my ~= 0 then
            mover_mouse(mx, my)
        end
    end
end

local attack_mode = "none"
local last_shot  = 0
local shots      = 0

local function resolve_attack()
    if VIM then
        local ok = pcall(function()
            return VIM.SendMouseButtonEvent
        end)
        if ok then
            attack_mode = "engine"
            return
        end
    end
    if f_mouse1 then
        attack_mode = "mouse1click"
        return
    end
    if f_mouse1down and f_mouse1up then
        attack_mode = "press/release"
        return
    end
    attack_mode = "none"
end

local function atacar()
    local agora = os.clock()
    if agora - last_shot < CONFIG.FireDelay then
        fire_state = "cooling"
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
        ok = pcall(f_mouse1)
    end

    if not ok and attack_mode == "press/release"
       and f_mouse1down and f_mouse1up then
        ok = pcall(function()
            f_mouse1down()
            task.wait(0.015)
            f_mouse1up()
        end)
    end

    if ok then
        last_shot = os.clock()
        shots = shots + 1
        fire_state = "fired"
        return true
    end

    fire_state = "no method"
    return false
end

local function alvo_na_mira()
    if not Camera then return nil end
    local alcance = CONFIG.ESPmax or 900

    local p = preparar_raycast()
    if not p then return nil end

    local ignorar = {}
    local meu = LP.Character
    if meu then ignorar[#ignorar + 1] = meu end
    ignorar[#ignorar + 1] = Camera


    local vm = Workspace:FindFirstChild("ViewModels")
    if vm then ignorar[#ignorar + 1] = vm end
    p.FilterDescendantsInstances = ignorar

    local origem = Camera.CFrame.Position
    local ok, res = pcall(function()
        return Workspace:Raycast(origem, Camera.CFrame.LookVector * alcance, p)
    end)
    if not ok or not res or not res.Instance then return nil end

    local atingido = res.Instance

    local modelo = atingido:FindFirstAncestorOfClass("Model")
    if not modelo then return nil end

    local plr = Players:GetPlayerFromCharacter(modelo)
    if not plr or plr == LP then return nil end
    if not is_enemy(plr) then return nil end
    return plr, atingido
end

local ESP_COMUM = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local esp_cache = {}

local function remove_esp(plr)
    local e = esp_cache[plr]
    if not e then return end
    for _, obj in pairs(e) do
        if type(obj) == "table" then
            for _, o in pairs(obj) do
                if typeof(o) == "Instance" then
                    pcall(function() o:Destroy() end)
                end
            end
        elseif typeof(obj) == "Instance" then
            pcall(function() obj:Destroy() end)
        end
    end
    esp_cache[plr] = nil
end

--[[
    O ESP NAO APARECIA

    O make_esp pendurava os Frames direto no PARENT. Se o PARENT
    for o PlayerGui (que e' o caso no Xeno, que nao tem gethui),
    um Frame SOLTO nao renderiza - o Roblox so desenha GuiObject
    que esteja dentro de um ScreenGui.

    Entao eu crio um ScreenGui so pro ESP. Isso tambem resolve o
    gethui: quando existe, o ScreenGui vai pra la e fica escondido
    do jogo (anti-deteccao); quando nao existe, vai pro PlayerGui
    e funciona igual.
--]]
local SG_ESP = nil

local function garantir_sg_esp()
    if SG_ESP and SG_ESP.Parent then return SG_ESP end
    if not PARENT then return nil end

    local sg = Instance.new("ScreenGui")
    sg.Name = "LowHubESP"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = PARENT

    SG_ESP = sg
    return sg
end

local function make_esp(plr)
    local pai = garantir_sg_esp()
    if not pai then return nil end
    local e = { linhas = {}, dono = plr }


    local caixa = Instance.new("Frame")
    caixa.Name = "Caixa"
    caixa.BackgroundTransparency = 1
    caixa.Visible = false
    caixa.Parent = pai

    local function lado(nome)
        local f = Instance.new("Frame")
        f.Name = nome
        f.BackgroundColor3 = COR.inimigo
        f.BorderSizePixel = 0
        f.Parent = caixa
        return f
    end
    e.caixa     = caixa
    e.cima      = lado("Cima")
    e.baixo     = lado("Baixo")
    e.esquerda  = lado("Esquerda")
    e.direita   = lado("Direita")


    local nome = Instance.new("TextLabel")
    nome.Name = "Nome"
    nome.BackgroundTransparency = 1
    nome.TextColor3 = COR.inimigo
    nome.Font = Enum.Font.GothamBold
    nome.TextSize = 12
    nome.TextStrokeTransparency = 0.35
    nome.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nome.Visible = false
    nome.Parent = pai
    e.nome = nome


    local info = Instance.new("TextLabel")
    info.Name = "Info"
    info.BackgroundTransparency = 1
    info.TextColor3 = COR.texto
    info.Font = Enum.Font.Code
    info.TextSize = 10
    info.TextStrokeTransparency = 0.5
    info.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    info.Visible = false
    info.Parent = pai
    e.info = info


    local bar = Instance.new("Frame")
    bar.Name = "Barra"
    bar.BackgroundColor3 = Color3.fromRGB(25, 22, 32)
    bar.BorderSizePixel = 0
    bar.Visible = false
    bar.Parent = pai
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(90, 220, 130)
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(1, 0); fc.Parent = fill

    e.bar = bar
    e.fill = fill

    return e
end

local function esconder_esp(e)
    e.caixa.Visible = false
    e.nome.Visible = false
    e.info.Visible = false
    e.bar.Visible = false
end

local function refresh_esp()

    --[[
        BUG DO ESP QUE NAO APARECIA

        A chave do cache era "it.plr or ch". Em partida o Rivals
        esconde o Player, entao it.plr e' nil e a chave vira o
        Model. Mas se o Player aparece DEPOIS (ou no lobby), a
        chave vira o Player - e o mesmo cara passa a ter DUAS
        entradas no cache, uma delas nunca mais atualizada.

        Pior: a primeira entrada fica orfa, com Visible=false, e
        o codigo cria um ESP novo a cada troca.

        Agora a chave e' SEMPRE o Model. Um corpo = um ESP.
    --]]
    for chave in pairs(esp_cache) do
        local vivo = false
        if typeof(chave) == "Instance" and chave:IsA("Model") then
            local hum = chave:FindFirstChildOfClass("Humanoid")
            vivo = chave.Parent ~= nil and hum ~= nil and hum.Health > 0
        end
        if not vivo then remove_esp(chave) end
    end
    if not CONFIG.ESPEnabled or not Camera then return end

    for _, it in ipairs(listar_alvos()) do
        local ch = it.char
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if ch and hum and hum.Health > 0 then
            local e = esp_cache[ch]
            if not e then
                e = make_esp(ch)
                esp_cache[ch] = e
            end

            if e then
                local raiz = ch:FindFirstChild("HumanoidRootPart")

                --[[
                    LIMITE DE ALCANCE DO ESP  (bug: nao existia)

                    O slider "Range" (ESPMaxDistance, padrao 600)
                    estava no menu, salvava no preset, e NAO ERA
                    LIDO EM LUGAR NENHUM. O ESP desenhava todo
                    mundo que existisse no Workspace - inclusive
                    os ~40 bonecos de treino do ShootingRange e
                    qualquer coisa do outro lado do mapa.

                    A distancia so era calculada MAIS ABAIXO, e
                    so pra MOSTRAR o numero. Nunca pra decidir se
                    desenhava.

                    Agora calculo aqui, ANTES de desenhar, e saio
                    fora se passar do limite. Um calculo so serve
                    pros dois usos (filtrar e mostrar).
                --]]
                local minha = get_root(LP)
                local dist = (minha and raiz)
                             and (raiz.Position - minha.Position).Magnitude
                             or nil

                if not hum or not raiz then
                    esconder_esp(e)
                elseif dist and dist > CONFIG.ESPMaxDistance then
                    esconder_esp(e)
                else






                    local cabeca = ch:FindFirstChild("Head")
                    local topo = cabeca and cabeca.Position
                                 or (raiz.Position + Vector3.new(0, 1.5, 0))
                    local pe = raiz.Position - Vector3.new(0, 3, 0)

                    local st, vt = Camera:WorldToViewportPoint(topo)
                    local sb, vb = Camera:WorldToViewportPoint(pe)

                    if not vt or not vb then
                        esconder_esp(e)
                    else
                        local altura = math.abs(sb.Y - st.Y)
                        local largura = altura * 0.55
                        local cx = (st.X + sb.X) / 2
                        local x1, y1 = cx - largura / 2, math.min(st.Y, sb.Y)
                        local x2, y2 = cx + largura / 2, math.max(st.Y, sb.Y)


                        local hp = hum.Health
                        local maxhp = hum.MaxHealth
                        if maxhp <= 0 then maxhp = 150 end
                        local frac = math.clamp(hp / maxhp, 0, 1)
                        local cor = COR.inimigo
                        if frac < 0.34 then
                            cor = COR.perigo
                        elseif locked_char == ch then
                            cor = COR.travado
                        end

                        if CONFIG.ESPBox then
                            e.caixa.Visible = true
                            e.cima.Position = UDim2.new(0, x1, 0, y1)
                            e.cima.Size = UDim2.new(0, x2 - x1, 0, 1)
                            e.baixo.Position = UDim2.new(0, x1, 0, y2)
                            e.baixo.Size = UDim2.new(0, x2 - x1, 0, 1)
                            e.esquerda.Position = UDim2.new(0, x1, 0, y1)
                            e.esquerda.Size = UDim2.new(0, 1, 0, y2 - y1)
                            e.direita.Position = UDim2.new(0, x2, 0, y1)
                            e.direita.Size = UDim2.new(0, 1, 0, y2 - y1)
                            for _, l in ipairs({ e.cima, e.baixo, e.esquerda, e.direita }) do
                                l.BackgroundColor3 = cor
                            end
                        else
                            e.caixa.Visible = false
                        end




                        e.nome.Visible = CONFIG.ESPShowName
                        if CONFIG.ESPShowName then
                            -- sem Player (partida) eu mostro o nome do
                            -- Model, que no Rivals costuma ser o do dono
                            e.nome.Text = it.plr and it.plr.Name or ch.Name
                            e.nome.TextColor3 = cor
                            e.nome.Position = UDim2.new(0, cx - 90, 0, y1 - 16)
                            e.nome.Size = UDim2.new(0, 180, 0, 14)
                        end

                        local bits = {}
                        if CONFIG.ESPShowDist and dist then
                            -- reaproveita o calculo do filtro de
                            -- alcance, feito la em cima. Antes isto
                            -- recalculava a mesma coisa.
                            bits[#bits + 1] = math.floor(dist) .. "m"
                        end
                        if CONFIG.ESPShowHealth then
                            bits[#bits + 1] = math.floor(hp) .. "/" .. math.floor(maxhp)
                        end

                        e.info.Visible = CONFIG.ESPShowHealth and #bits > 0
                        if e.info.Visible then
                            e.info.Text = table.concat(bits, "   ")
                            e.info.Position = UDim2.new(0, cx - 60, 0, y2 + 3)
                            e.info.Size = UDim2.new(0, 120, 0, 12)
                        end

                        e.bar.Visible = CONFIG.ESPShowHealth
                        if CONFIG.ESPShowHealth then
                            e.bar.Position = UDim2.new(0, x1, 0, y2 + 17)
                            e.bar.Size = UDim2.new(0, x2 - x1, 0, 4)
                            e.fill.Size = UDim2.new(frac, 0, 1, 0)
                            if frac > 0.6 then
                                e.fill.BackgroundColor3 = Color3.fromRGB(90, 220, 130)
                            elseif frac > 0.3 then
                                e.fill.BackgroundColor3 = Color3.fromRGB(240, 200, 80)
                            else
                                e.fill.BackgroundColor3 = Color3.fromRGB(240, 90, 90)
                            end
                        end
                    end
                end
            end
        end
    end
end

local fly_bv, fly_conn = nil, nil
local speed_conn = nil

local function stop_fly()
    if fly_bv then pcall(function() fly_bv:Destroy() end) fly_bv = nil end
    if fly_conn then pcall(function() fly_conn:Disconnect() end) fly_conn = nil end
end

local function start_fly()
    stop_fly()
    local ch = LP.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    fly_bv = Instance.new("BodyVelocity")
    fly_bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    fly_bv.Velocity = Vector3.new()
    fly_bv.Parent = hrp

    fly_conn = RunService.RenderStepped:Connect(function()
        if not fly_bv or not fly_bv.Parent or not Camera then return end
        local dir = Vector3.new()
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        if dir.Magnitude > 0 then dir = dir.Unit end
        fly_bv.Velocity = dir * CONFIG.FlySpeed
    end)
end

local function apply_speed()
    local ch = LP.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if CONFIG.SpeedEnabled then
        hum.WalkSpeed = CONFIG.SpeedValue
    end
end

local fps_guardado = nil
local POST_FX = {}

local function guardar(nome)
    local ok, v = pcall(function() return Lighting[nome] end)
    if ok then return v end
    return nil
end

local function ligar_fps()
    if CONFIG.FpsMode then return end
    fps_guardado = {
        GlobalShadows = guardar("GlobalShadows"),
        QualityLevel  = guardar("QualityLevel"),
        FogEnd        = guardar("FogEnd"),
        Brightness    = guardar("Brightness"),
    }
    POST_FX = {}
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("PostEffect") then
            POST_FX[#POST_FX + 1] = { obj = c, on = c.Enabled }
            pcall(function() c.Enabled = false end)
        end
    end
    pcall(function() Lighting.GlobalShadows = false end)
    pcall(function() Lighting.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function() Lighting.FogEnd = 100000 end)
    local terra = Workspace:FindFirstChildOfClass("Terrain")
    if terra then
        pcall(function() terra.Transparency = 0.55 end)
    end
    CONFIG.FpsMode = true
end

local function desligar_fps()
    if not CONFIG.FpsMode then return end
    if fps_guardado then
        for k, v in pairs(fps_guardado) do
            if v ~= nil then pcall(function() Lighting[k] = v end) end
        end
    end
    for _, e in ipairs(POST_FX) do
        pcall(function() e.obj.Enabled = e.on end)
    end
    local terra = Workspace:FindFirstChildOfClass("Terrain")
    if terra then pcall(function() terra.Transparency = 0 end) end
    POST_FX = {}
    CONFIG.FpsMode = false
end

local function build_fov()
    if not PARENT then return nil end
    local sg = Instance.new("ScreenGui")
    sg.Name = "Z_fov"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 2147483000
    sg.Parent = PARENT

    local c = Instance.new("Frame")
    c.Name = "Circle"
    c.BackgroundTransparency = 1
    c.AnchorPoint = Vector2.new(0.5, 0.5)
    c.Size = UDim2.new(0, CONFIG.AimFOV * 2, 0, CONFIG.AimFOV * 2)
    c.Position = UDim2.new(0.5, 0, 0.5, 0)
    c.Parent = sg

    local s = Instance.new("UIStroke")
    s.Color = COR.inimigo
    s.Thickness = 1
    s.Transparency = 0.5
    s.Parent = c
    local co = Instance.new("UICorner")
    co.CornerRadius = UDim.new(1, 0)
    co.Parent = c

    return { sg = sg, circle = c, stroke = s }
end

--[[
    ACIONAMENTO DO AIMLOCK

    Antes so aceitava tecla, e a tecla era fixa no CONFIG (E).
    Agora aceita botao do mouse tambem, e os dois sao escolhidos
    pelo usuario no menu - igual no LowHub do Tribos.

    Regra: se AimMouseButton estiver setado, ELE manda. Senao
    vale a tecla.
--]]
local function key_pressed(input)
    if CONFIG.AimMouseButton then
        return input.UserInputType == CONFIG.AimMouseButton
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return input.KeyCode == CONFIG.AimKey
    end
    return false
end

local input_conn = UserInputService.InputBegan:Connect(function(input, gp)
    -- captura de keybind tem prioridade sobre tudo
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

    if gp then return end
    if key_pressed(input) then
        --[[
            A tecla so LEVANTA a bandeira do "segurando".

            Tinha aqui um `if AimMode == "toggle"` que invertia
            uma flag a cada aperto. Com o modo toggle fora do
            menu, isso virou codigo morto - e ainda confundiria,
            porque no HOLD o InputEnded ja baixa a bandeira.

            Agora e' so isso: apertou, mira. Soltou (InputEnded
            logo abaixo), para.
        --]]
        aim_held = true
        recompute_aim()
    end
end)

local input_end = UserInputService.InputEnded:Connect(function(input)
    if Keybind.capturing then return end
    if key_pressed(input) then
        aim_held = false
        recompute_aim()
    end
end)

local toggle_conn = UserInputService.InputBegan:Connect(function(input, gp)
    -- durante a captura de keybind, o RightShift e' uma tecla
    -- valida pra escolher - nao pode abrir/fechar o menu junto
    if Keybind.capturing then return end
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if _G.__LOWHUB_TOGGLE then pcall(_G.__LOWHUB_TOGGLE) end
    end
end)

local loop_conn = nil
local esp_tick = 0

--[[
    CIRCULO DO FOV  (bug: nunca aparecia)

    O build_fov estava DEFINIDO mas nunca era CHAMADO - o circulo
    simplesmente nao existia. E nunca era atualizado: se voce
    mudasse o AimFOV no menu, o desenho continuava no tamanho
    antigo.

    Agora eu crio no boot e atualizo a cada frame, lendo o
    CONFIG.AimFOV vivo. Assim mexer no slider muda o circulo
    na hora.
--]]
local FOV_UI = nil

local function atualizar_fov()
    if not FOV_UI or not FOV_UI.sg or not FOV_UI.sg.Parent then return end
    if not CONFIG.ShowFOVCircle or not CONFIG.AimEnabled then
        FOV_UI.circle.Visible = false
        return
    end
    FOV_UI.circle.Visible = true

    local tam = CONFIG.AimFOV * 2
    FOV_UI.circle.Size = UDim2.new(0, tam, 0, tam)
    FOV_UI.circle.Position = UDim2.new(0.5, 0, 0.5, 0)

    -- fica verde quando tem alvo travado, vermelho quando nao
    if locked_char then
        FOV_UI.stroke.Color = COR.travado
        FOV_UI.stroke.Transparency = 0.25
    else
        FOV_UI.stroke.Color = COR.inimigo
        FOV_UI.stroke.Transparency = 0.55
    end
end

local function passo(dt)
    Camera = Workspace.CurrentCamera
    recompute_aim()
    mirar(dt)

    local pode = can_click()

    if CONFIG.TriggerBot and pode then
        local na_mira = alvo_na_mira()
        if na_mira then
            atacar()
        else
            fire_state = "off target"
        end
    elseif not pode then
        fire_state = "menu open"
    else
        fire_state = "ready"
    end

    pcall(atualizar_fov)

    esp_tick = esp_tick + dt
    if esp_tick >= 0.066 then
        esp_tick = 0
        local ok = pcall(refresh_esp)
        if not ok then end
    end

    if CONFIG.SpeedEnabled then
        pcall(apply_speed)
    end
end

loop_conn = RunService.RenderStepped:Connect(passo)

resolve_attack()

pcall(function()
    FOV_UI = build_fov()
end)

task.spawn(function()
    detectar_mira()
end)

local UI = {
    cor = {
        fundo     = Color3.fromRGB(14, 12, 20),
        painel    = Color3.fromRGB(20, 17, 28),
        cartao    = Color3.fromRGB(26, 22, 36),
        cartao2   = Color3.fromRGB(32, 27, 44),
        borda     = Color3.fromRGB(44, 38, 60),
        texto     = Color3.fromRGB(238, 234, 248),
        fraco     = Color3.fromRGB(150, 142, 172),
        roxo      = Color3.fromRGB(150, 92, 245),
        roxo2     = Color3.fromRGB(190, 140, 255),
        verde     = Color3.fromRGB(90, 220, 140),
        vermelho  = Color3.fromRGB(240, 85, 105),
        amarelo   = Color3.fromRGB(255, 196, 100),
    },
    fonte  = Enum.Font.Gotham,
    fonteB = Enum.Font.GothamBold,
    fonteM = Enum.Font.GothamMedium,
    fonteC = Enum.Font.Code,
}

local function novo(classe, props)
    local o = Instance.new(classe)
    for k, v in pairs(props or {}) do
        pcall(function() o[k] = v end)
    end
    return o
end

local function canto(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = o
    return c
end

local function borda(o, cor, t)
    local s = Instance.new("UIStroke")
    s.Color = cor or UI.cor.borda
    s.Thickness = t or 1
    s.Parent = o
    return s
end

local function hover(botao, quanto)
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

local JANELA_W, JANELA_H = 660, 500
local HEADER_H = 64

local refs = {
    toggles = {},
    abas    = {},
    paginas = {},
}

local function criar_toggle(pai, ordem, texto, chave, aoMudar, sub)
    local linha = novo("Frame", {
        Name = "tg_" .. chave,
        Size = UDim2.new(1, 0, 0, sub and 46 or 38),
        BackgroundColor3 = UI.cor.cartao,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    canto(linha, 8)

    local rot = novo("TextLabel", {
        Size = UDim2.new(1, -70, 0, sub and 18 or 38),
        Position = UDim2.new(0, 12, 0, sub and 5 or 0),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = UI.cor.texto,
        Font = UI.fonteM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    if sub then
        local s = novo("TextLabel", {
            Size = UDim2.new(1, -70, 0, 14),
            Position = UDim2.new(0, 12, 0, 24),
            BackgroundTransparency = 1,
            Text = sub,
            TextColor3 = UI.cor.fraco,
            Font = UI.fonte,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        s.Parent = linha
    end

    local pil = novo("Frame", {
        Name = "Pilula",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = UI.cor.cartao2,
        BorderSizePixel = 0,
    })
    pil.Parent = linha
    canto(pil, 10)

    local bol = novo("Frame", {
        Name = "Bola",
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = UI.cor.fraco,
        BorderSizePixel = 0,
    })
    bol.Parent = pil
    canto(bol, 7)

    local clicavel = novo("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    })
    clicavel.Parent = linha

    local function pinta()
        local on = CONFIG[chave] and true or false
        pil.BackgroundColor3 = on and UI.cor.roxo or UI.cor.cartao2
        bol.Position = on and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        bol.BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or UI.cor.fraco
    end
    pinta()
    refs.toggles[chave] = pinta

    clicavel.MouseButton1Click:Connect(function()
        CONFIG[chave] = not CONFIG[chave]
        pinta()
        if aoMudar then pcall(aoMudar, CONFIG[chave]) end
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

--[[
    CONTROLE DE KEYBIND

    Igual ao do LowHub do Tribos: um botao que mostra a tecla atual
    e, quando clicado, entra em modo captura. Aperta o que quiser
    e ele assume. Esc cancela.

    Aqui eu uso DOIS botoes: um pra tecla e um pro mouse. E' mais
    claro que um botao so, porque o usuario ve na hora as duas
    opcoes e qual esta ativa.
--]]
local function criar_keybind(pai, ordem, texto, sub, qual)
    local linha = novo("Frame", {
        Name = "kb_" .. qual,
        Size = UDim2.new(1, 0, 0, sub and 46 or 38),
        BackgroundColor3 = UI.cor.cartao,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    canto(linha, 8)

    local rot = novo("TextLabel", {
        Size = UDim2.new(1, -130, 0, sub and 18 or 38),
        Position = UDim2.new(0, 12, 0, sub and 5 or 0),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = UI.cor.texto,
        Font = UI.fonteM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    if sub then
        local s = novo("TextLabel", {
            Size = UDim2.new(1, -130, 0, 14),
            Position = UDim2.new(0, 12, 0, 24),
            BackgroundTransparency = 1,
            Text = sub,
            TextColor3 = UI.cor.fraco,
            Font = UI.fonte,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        s.Parent = linha
    end

    local botao = novo("TextButton", {
        Name = "Tecla",
        Size = UDim2.new(0, 108, 0, 26),
        Position = UDim2.new(1, -120, 0.5, -13),
        BackgroundColor3 = UI.cor.cartao2,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = UI.cor.roxo2,
        Font = UI.fonteM,
        TextSize = 12,
        AutoButtonColor = false,
    })
    botao.Parent = linha
    canto(botao, 6)
    local borda_kb = borda(botao, UI.cor.borda, 1)

    local function valor_atual()
        if qual == "key" then
            if CONFIG.AimMouseButton then return "mouse in use" end
            return key_name(CONFIG.AimKey)
        else
            if CONFIG.AimMouseButton then
                return MOUSE_NAMES[CONFIG.AimMouseButton] or "mouse"
            end
            return "not set"
        end
    end

    local function paint()
        if Keybind.capturing and Keybind.which == qual then
            botao.Text = "press a key"
            botao.TextColor3 = UI.cor.amarelo
            borda_kb.Color = UI.cor.amarelo
            borda_kb.Transparency = 0
        else
            botao.Text = valor_atual()
            botao.TextColor3 = UI.cor.roxo2
            borda_kb.Color = UI.cor.borda
            borda_kb.Transparency = 0.2
        end
    end
    paint()
    Keybind.painters[#Keybind.painters + 1] = paint

    local cor_orig = botao.BackgroundColor3
    botao.MouseEnter:Connect(function()
        botao.BackgroundColor3 = UI.cor.borda
    end)
    botao.MouseLeave:Connect(function()
        botao.BackgroundColor3 = cor_orig
    end)
    botao.MouseButton1Click:Connect(function()
        Keybind.capturing = true
        Keybind.which = qual
        repaint_keybinds()
    end)

    return linha
end

local function criar_slider(pai, ordem, texto, chave, min, max, passo, fmt)
    local linha = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = UI.cor.cartao,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    canto(linha, 8)

    local rot = novo("TextLabel", {
        Size = UDim2.new(1, -90, 0, 18),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = UI.cor.texto,
        Font = UI.fonteM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    local valor = novo("TextLabel", {
        Size = UDim2.new(0, 70, 0, 18),
        Position = UDim2.new(1, -82, 0, 6),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = UI.cor.roxo2,
        Font = UI.fonteC,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    valor.Parent = linha

    local trilha = novo("Frame", {
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 0, 34),
        BackgroundColor3 = UI.cor.cartao2,
        BorderSizePixel = 0,
    })
    trilha.Parent = linha
    canto(trilha, 3)

    local cheio = novo("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = UI.cor.roxo,
        BorderSizePixel = 0,
    })
    cheio.Parent = trilha
    canto(cheio, 3)

    local function pinta()
        local v = CONFIG[chave]
        local frac = (v - min) / (max - min)
        frac = math.clamp(frac, 0, 1)
        cheio.Size = UDim2.new(frac, 0, 1, 0)
        if fmt then
            valor.Text = fmt(v)
        else
            valor.Text = tostring(v)
        end
    end
    pinta()

    local arrastando = false
    local toque = novo("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    })
    toque.Parent = linha

    local function definir(px)
        local rel = math.clamp((px - trilha.AbsolutePosition.X) / trilha.AbsoluteSize.X, 0, 1)
        local v = min + (max - min) * rel
        v = math.floor(v / passo + 0.5) * passo
        v = math.clamp(v, min, max)
        CONFIG[chave] = v
        pinta()
    end

    toque.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = true
            definir(inp.Position.X)
        end
    end)
    toque.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            arrastando = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if arrastando and inp.UserInputType == Enum.UserInputType.MouseMovement then
            definir(inp.Position.X)
        end
    end)

    return linha
end

local function criar_opcoes(pai, ordem, texto, chave, opcoes)
    local linha = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = UI.cor.cartao,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    linha.Parent = pai
    canto(linha, 8)

    local rot = novo("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = texto,
        TextColor3 = UI.cor.texto,
        Font = UI.fonteM,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rot.Parent = linha

    local caixa = novo("Frame", {
        Size = UDim2.new(1, -24, 0, 26),
        Position = UDim2.new(0, 12, 0, 28),
        BackgroundColor3 = UI.cor.cartao2,
        BorderSizePixel = 0,
    })
    caixa.Parent = linha
    canto(caixa, 6)

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 4)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Parent = caixa

    local botoes = {}
    local function pinta()
        for val, b in pairs(botoes) do
            local on = (CONFIG[chave] == val)
            b.BackgroundColor3 = on and UI.cor.roxo or UI.cor.cartao
            b.TextColor3 = on and Color3.fromRGB(255,255,255) or UI.cor.fraco
        end
    end

    for _, op in ipairs(opcoes) do
        local b = novo("TextButton", {
            Size = UDim2.new(0, 78, 0, 20),
            BackgroundColor3 = UI.cor.cartao,
            BorderSizePixel = 0,
            Text = op.rotulo,
            TextColor3 = UI.cor.fraco,
            Font = UI.fonteM,
            TextSize = 11,
            AutoButtonColor = false,
        })
        b.Parent = caixa
        canto(b, 5)
        hover(b, 0.10)
        botoes[op.valor] = b
        b.MouseButton1Click:Connect(function()
            CONFIG[chave] = op.valor
            pinta()
        end)
    end
    pinta()
    refs.toggles[chave] = pinta

    return linha
end

local function criar_titulo(pai, ordem, texto)
    local t = novo("TextLabel", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = texto:upper(),
        TextColor3 = UI.cor.roxo2,
        Font = UI.fonteB,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = ordem,
    })
    t.Parent = pai
    return t
end

--[[
    SECAO DOBRavel  (as "abinhas" do Tribes)

    O Tribes tem isso e o Rivals nao tinha: cada bloco de opcoes
    e' um cartao com titulo clicavel que abre e fecha. Em vez de
    um monte de titulo solto empilhado, fica uma lista organizada
    onde voce esconde o que nao usa.

    Portado do lowhub_tribes.lua (new_section) pra ficar com a
    MESMA cara nos dois hubs - era o pedido.

    Devolve um objeto `s` com:

        s.inner          -> Frame onde as linhas vao
        s._o             -> contador de ordem (some sozinho)
        s:AddToggle(...) -> atalho que ja posiciona dentro
        s:AddSlider(...) -> idem
        s:AddOpcoes(...) -> idem
        s:AddKeybind(..) -> idem

    Os opcoes continuam sendo as mesmas funcoes (criar_toggle,
    criar_slider...), so que apontando pra dentro do cartao em
    vez de pra pagina. Assim nao duplico codigo de controle.
--]]
local function criar_secao(pai, ordem, titulo)
    local wrap = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = UI.cor.cartao,
        BorderSizePixel = 0,
        LayoutOrder = ordem,
    })
    wrap.Parent = pai

    local canto = Instance.new("UICorner")
    canto.CornerRadius = UDim.new(0, 8)
    canto.Parent = wrap

    local borda = Instance.new("UIStroke")
    borda.Color = UI.cor.borda
    borda.Thickness = 1
    borda.Transparency = 0.55
    borda.Parent = wrap

    -- cabecalho: clicavel, com barrinha de destaque a esquerda
    local head = novo("TextButton", {
        Name = "Head",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    })
    head.Parent = wrap

    local barra = novo("Frame", {
        Size = UDim2.new(0, 3, 0, 14),
        Position = UDim2.new(0, 12, 0.5, -7),
        BackgroundColor3 = UI.cor.roxo,
        BorderSizePixel = 0,
    })
    barra.Parent = head

    local cantoBarra = Instance.new("UICorner")
    cantoBarra.CornerRadius = UDim.new(1, 0)
    cantoBarra.Parent = barra

    local rotulo = novo("TextLabel", {
        Size = UDim2.new(1, -58, 1, 0),
        Position = UDim2.new(0, 22, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(titulo or ""),
        TextColor3 = UI.cor.texto,
        Font = UI.fonteB,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rotulo.Parent = head

    local seta = novo("TextLabel", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -28, 0.5, -9),
        BackgroundTransparency = 1,
        Text = "v",
        TextColor3 = UI.cor.fraco,
        Font = UI.fonteB,
        TextSize = 11,
    })
    seta.Parent = head

    -- corpo onde as opcoes entram
    local inner = novo("Frame", {
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

    -- respiro no fim, pra ultima linha nao colar na borda
    local rabo = novo("Frame", {
        Size = UDim2.new(1, 0, 0, 5),
        BackgroundTransparency = 1,
        LayoutOrder = 9999,
    })
    rabo.Parent = inner

    local s = {
        inner = inner,
        _o    = 0,
        wrap  = wrap,
        head  = head,
        open  = true,
        seta  = seta,
        barra = barra,
        rotulo = rotulo,
        borda = borda,
    }

    function s:SetOpen(v)
        self.open = v
        inner.Visible = v
        rabo.Visible = v
        seta.Text = v and "v" or ">"
        seta.TextColor3 = v and UI.cor.fraco or UI.cor.roxo
        barra.BackgroundColor3 = v and UI.cor.roxo or UI.cor.borda
        rotulo.TextColor3 = v and UI.cor.texto or UI.cor.fraco
        borda.Transparency = v and 0.55 or 0.85
    end

    head.MouseEnter:Connect(function()
        head.BackgroundTransparency = 0.9
        head.BackgroundColor3 = UI.cor.cartao2
        rotulo.TextColor3 = s.open and UI.cor.texto or UI.cor.roxo2
    end)
    head.MouseLeave:Connect(function()
        head.BackgroundTransparency = 1
        rotulo.TextColor3 = s.open and UI.cor.texto or UI.cor.fraco
    end)
    head.MouseButton1Click:Connect(function()
        s:SetOpen(not s.open)
    end)

    -- atalhos: entram dentro do cartao, com ordem automatica
    function s:prox()
        self._o = self._o + 1
        return self._o
    end

    function s:AddToggle(texto, chave, aoMudar, sub)
        return criar_toggle(self.inner, self:prox(), texto, chave, aoMudar, sub)
    end

    function s:AddSlider(texto, chave, min, max, passo, fmt)
        return criar_slider(self.inner, self:prox(),
                            texto, chave, min, max, passo, fmt)
    end

    function s:AddOpcoes(texto, chave, opcoes)
        return criar_opcoes(self.inner, self:prox(), texto, chave, opcoes)
    end

    function s:AddKeybind(texto, sub, qual)
        return criar_keybind(self.inner, self:prox(), texto, sub, qual)
    end

    return s
end

local function nova_pagina(holder, nome)
    local scroll = novo("ScrollingFrame", {
        Name = "pg_" .. nome,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = UI.cor.roxo,
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

local PRESETS = {
    {
        nome = "Legit",
        sub  = "subtle, hard to notice",
        cor  = Color3.fromRGB(90, 160, 240),
        cfg  = {
            AimEnabled = true, AimSmooth = 0.75, AimFOV = 55,
            AimTarget = "HEAD", WallCheck = true,
            AimMode = "hold",
            TriggerBot = false,
            ESPEnabled = true, ESPBox = true,
            ESPShowHealth = true, ESPShowDist = false,
            ShowFOVCircle = false,
        },
    },
    {
        nome = "Balanced",
        sub  = "the middle ground, good to play with",
        cor  = Color3.fromRGB(150, 92, 245),
        cfg  = {
            AimEnabled = true, AimSmooth = 0.40, AimFOV = 110,
            AimTarget = "HEAD", WallCheck = true,
            AimMode = "hold",
            TriggerBot = true, FireDelay = 0.10,
            ESPEnabled = true, ESPBox = true,
            ESPShowHealth = true, ESPShowDist = true,
            ShowFOVCircle = true,
        },
    },
    {
        nome = "Aggressive",
        sub  = "fast aim and automatic fire",
        cor  = Color3.fromRGB(240, 150, 60),
        cfg  = {
            AimEnabled = true, AimSmooth = 0.12, AimFOV = 200,
            AimTarget = "HEAD", WallCheck = false,
            AimMode = "always",
            TriggerBot = false, FireDelay = 0.06,
            ESPEnabled = true, ESPBox = true,
            ESPShowHealth = true, ESPShowDist = true,
            ShowFOVCircle = true,
        },
    },
    {
        nome = "Rage",
        sub = "everything on, no disguise",
        cor  = Color3.fromRGB(240, 85, 105),
        cfg  = {
            AimEnabled = true, AimSmooth = 0, AimFOV = 400,
            AimTarget = "HEAD", WallCheck = false,
            AimMode = "always",
            TriggerBot = true, FireDelay = 0.04,
            ESPEnabled = true, ESPBox = true,
            ESPShowHealth = true, ESPShowDist = true,
            SpeedEnabled = true, SpeedValue = 30,
            ShowFOVCircle = true,
        },
    },
}

local function pintar_tudo()
    for _, p in pairs(refs.toggles) do
        pcall(p)
    end
end

local function aplicar_preset(p)
    for k, v in pairs(p.cfg) do
        CONFIG[k] = v
    end
    if CONFIG.FlyEnabled then start_fly() else stop_fly() end
    if CONFIG.FpsMode then ligar_fps() else desligar_fps() end
    pintar_tudo()
end

local function coletar_preset()
    local t = {}
    for _, k in ipairs({
        "AimEnabled","AimMode","AimSmooth","AimFOV","AimTarget","WallCheck",
        -- a tecla escolhida pelo usuario tambem vai pro arquivo
        "AimKey","AimMouseButton",
        "TriggerBot","FireDelay",
        "ESPEnabled","ESPBox","ESPShowName","ESPShowHealth","ESPShowDist","ESPMaxDistance",
        "SpeedEnabled","SpeedValue","FlySpeed",
        "ShowFOVCircle",
    }) do
        t[k] = CONFIG[k]
    end
    return t
end

local function salvar_preset_custom()
    if not FS.tem then return false end
    local partes = {}
    for k, v in pairs(coletar_preset()) do
        local val
        if type(v) == "string" then val = '"' .. v .. '"'
        elseif type(v) == "boolean" then val = tostring(v)
        else val = tostring(v) end
        partes[#partes + 1] = k .. "=" .. val
    end
    return salvar_arquivo("presets_rivals.txt", table.concat(partes, "\n"))
end

local function carregar_preset_custom()
    local txt = ler_arquivo("presets_rivals.txt")
    if not txt then return false end
    local n = 0
    for linha in txt:gmatch("[^\n]+") do
        local k, v = linha:match("^([%w_]+)=(.*)$")
        if k and CONFIG[k] ~= nil then
            local num = tonumber(v)
            if v == "true" then CONFIG[k] = true n = n + 1
            elseif v == "false" then CONFIG[k] = false n = n + 1
            elseif num then CONFIG[k] = num n = n + 1
            elseif v:sub(1,1) == '"' then
                CONFIG[k] = v:sub(2, -2) n = n + 1
            end
        end
    end
    pintar_tudo()
    return n > 0
end

local janela, toggle_painel

local function build()
    local sg = novo("ScreenGui", {
        Name = "LowHubRivals",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    sg.Parent = PARENT

    local painel = novo("Frame", {
        Name = "Painel",
        Size = UDim2.new(0, JANELA_W, 0, JANELA_H),
        Position = UDim2.new(0.5, -JANELA_W / 2, 0.5, -JANELA_H / 2),
        BackgroundColor3 = UI.cor.fundo,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
    })
    painel.Parent = sg
    canto(painel, 12)
    borda(painel, UI.cor.borda, 1)


    local escala = Instance.new("UIScale")
    escala.Scale = 1
    escala.Parent = painel

    local function ajustar_escala()
        local cam = Workspace.CurrentCamera
        local vs = cam and cam.ViewportSize
        if not vs or vs.X <= 0 or vs.Y <= 0 then return false end



        local fx = (vs.X * 0.92) / JANELA_W
        local fy = (vs.Y * 0.92) / JANELA_H
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
        while painel.Parent do
            local cam = Workspace.CurrentCamera
            if cam then
                local conn
                conn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(ajustar_escala)

                while painel.Parent and cam == Workspace.CurrentCamera do
                    task.wait(0.5)
                end
                pcall(function() conn:Disconnect() end)
            end
            task.wait(0.5)
        end
    end)


    local sombra = Instance.new("ImageLabel")
    sombra.Size = UDim2.new(1, 60, 1, 60)
    sombra.Position = UDim2.new(0, -30, 0, -30)
    sombra.BackgroundTransparency = 1
    sombra.Image = "rbxassetid://6014261993"
    sombra.ImageColor3 = Color3.fromRGB(0, 0, 0)
    sombra.ImageTransparency = 0.5
    sombra.ZIndex = -1
    sombra.Parent = painel




    local cab = novo("Frame", {
        Name = "Cabecalho",
        Size = UDim2.new(1, 0, 0, HEADER_H),
        BackgroundColor3 = UI.cor.painel,
        BorderSizePixel = 0,
    })
    cab.Parent = painel
    local cc = canto(cab, 12)

    local cob = Instance.new("Frame")
    cob.Size = UDim2.new(1, 0, 0, 14)
    cob.Position = UDim2.new(0, 0, 1, -14)
    cob.BackgroundColor3 = UI.cor.painel
    cob.BorderSizePixel = 0
    cob.Parent = cab

    local av = Instance.new("ImageLabel")
    av.Size = UDim2.new(0, 44, 0, 44)
    av.Position = UDim2.new(0, 14, 0.5, -22)
    av.BackgroundColor3 = UI.cor.cartao2
    av.BorderSizePixel = 0
    av.Image = "rbxthumb://type=AvatarHeadShot&w=150&h=150&id=" .. tostring(LP.UserId)
    av.Parent = cab
    canto(av, 22)

    local tit = novo("TextLabel", {
        Size = UDim2.new(0, 260, 0, 22),
        Position = UDim2.new(0, 70, 0, 13),
        BackgroundTransparency = 1,
        Text = VERSION,
        TextColor3 = UI.cor.texto,
        Font = UI.fonteB,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    tit.Parent = cab

    local sub = novo("TextLabel", {
        Size = UDim2.new(0, 300, 0, 16),
        Position = UDim2.new(0, 70, 0, 34),
        BackgroundTransparency = 1,
        Text = "Rivals  ·  RightShift",
        TextColor3 = UI.cor.fraco,
        Font = UI.fonte,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    sub.Parent = cab


    local estado = novo("TextLabel", {
        Size = UDim2.new(0, 150, 0, 18),
        Position = UDim2.new(1, -166, 0, 14),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = UI.cor.fraco,
        Font = UI.fonteC,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    estado.Parent = cab

    local metodo = novo("TextLabel", {
        Size = UDim2.new(0, 150, 0, 16),
        Position = UDim2.new(1, -166, 0, 34),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = UI.cor.fraco,
        Font = UI.fonte,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
    })
    metodo.Parent = cab


    local fechar = novo("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -32, 0, 14),
        BackgroundColor3 = UI.cor.cartao2,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = UI.cor.fraco,
        Font = UI.fonteB,
        TextSize = 15,
        AutoButtonColor = false,
    })
    fechar.Parent = cab
    canto(fechar, 6)
    hover(fechar, 0.10)
    fechar.MouseButton1Click:Connect(function()
        painel.Visible = false
    end)




    local barra = novo("Frame", {
        Name = "Abas",
        Size = UDim2.new(1, -24, 0, 30),
        Position = UDim2.new(0, 12, 0, HEADER_H + 8),
        BackgroundTransparency = 1,
    })
    barra.Parent = painel
    local bl = Instance.new("UIListLayout")
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding = UDim.new(0, 6)
    bl.Parent = barra

    local holder = novo("Frame", {
        Name = "Paginas",
        Size = UDim2.new(1, -24, 1, -(HEADER_H + 8 + 30 + 34)),
        Position = UDim2.new(0, 12, 0, HEADER_H + 38 + 8),
        BackgroundTransparency = 1,
    })
    holder.Parent = painel

    local NOMES = { "AIM", "VISUAL", "MOVEMENT", "FPS", "CONFIG" }
    local botoes = {}

    local function trocar(nome)
        for n, b in pairs(botoes) do
            local on = (n == nome)
            b.BackgroundColor3 = on and UI.cor.roxo or UI.cor.cartao
            b.TextColor3 = on and Color3.fromRGB(255,255,255) or UI.cor.fraco
        end
        for n, p in pairs(refs.paginas) do
            p.Visible = (n == nome)
        end
    end

    for _, nome in ipairs(NOMES) do
        local b = novo("TextButton", {
            Size = UDim2.new(0, 92, 1, 0),
            BackgroundColor3 = UI.cor.cartao,
            BorderSizePixel = 0,
            Text = nome,
            TextColor3 = UI.cor.fraco,
            Font = UI.fonteB,
            TextSize = 11,
            AutoButtonColor = false,
        })
        b.Parent = barra
        canto(b, 7)
        hover(b, 0.09)
        botoes[nome] = b
        b.MouseButton1Click:Connect(function() trocar(nome) end)
    end




    for _, nome in ipairs(NOMES) do
        refs.paginas[nome] = nova_pagina(holder, nome)
    end


    do
        local pg = refs.paginas.AIM

        -- ==================================================
        -- ABINHAS DA ABA AIM
        --
        -- Tudo agora vive dentro de cartoes dobráveis, igual ao
        -- Tribes. A "Aimlock key" virou secao propria dentro da
        -- aba de aimlock - era onde ela devia estar desde o
        -- comeco, ja que so existe por causa do modo HOLD.
        -- ==================================================

        local sMain = criar_secao(pg, 1, "Aimlock")
        sMain:AddToggle("Enabled", "AimEnabled",
            function() recompute_aim() end,
            "locks your aim onto the closest enemy")

        --[[
            ACTIVATION: so HOLD e ALWAYS.

            Tinha tres (KEY / HOLD / ALWAYS). O "KEY" e o "HOLD"
            faziam exatamente a mesma coisa - o nome era diferente
            e mais nada. Ter os dois lado a lado so confundia.

              HOLD   -> mira enquanto voce segura a tecla
              ALWAYS -> mira o tempo todo, sem apertar nada
        --]]
        sMain:AddOpcoes("Activation", "AimMode", {
            { rotulo = "HOLD",   valor = "hold"   },
            { rotulo = "ALWAYS", valor = "always" },
        })

        --[[
            A tecla do aimlock, na propria aba do aimlock.

            So faz diferenca no modo HOLD - no ALWAYS nao tem o
            que segurar. Deixo sempre a vista mesmo assim, pra
            voce configurar antes de trocar o modo.
        --]]
        local sKey = criar_secao(pg, 2, "Aimlock key")
        sKey:AddKeybind("Keyboard", "click and press any key", "key")
        sKey:AddKeybind("Mouse", "click and press a mouse button", "mouse")

        local sAlvo = criar_secao(pg, 3, "Target")
        sAlvo:AddOpcoes("Hitbox", "AimTarget", {
            { rotulo = "HEAD", valor = "HEAD" },
            { rotulo = "BODY", valor = "BODY" },
            { rotulo = "ROOT", valor = "HRP"  },
        })
        sAlvo:AddSlider("Smoothness", "AimSmooth", 0, 0.8, 0.05,
            function(v) return string.format("%.2f", v) end)
        sAlvo:AddSlider("FOV (pixels)", "AimFOV", 20, 400, 10,
            function(v) return tostring(math.floor(v)) .. "px" end)

        local sTiro = criar_secao(pg, 4, "Fire")
        sTiro:AddToggle("Triggerbot", "TriggerBot", nil,
            "fires when your crosshair is ON the target")
        sTiro:AddSlider("Fire interval", "FireDelay", 0.02, 0.4, 0.01,
            function(v) return string.format("%.2fs", v) end)

        local sFiltro = criar_secao(pg, 5, "Filters")
        sFiltro:AddToggle("Wall check", "WallCheck", nil,
            "wont aim at enemies behind walls")
        sFiltro:AddToggle("FOV circle", "ShowFOVCircle", nil,
            "shows the aim range on screen")

        -- deixa a lista de secoes a mao, pra fechar/abrir tudo
        refs.secoes_aim = {
            sMain, sKey, sAlvo, sTiro, sFiltro,
        }
    end


    do
        local pg = refs.paginas.VISUAL

        local sEsp = criar_secao(pg, 1, "ESP")
        sEsp:AddToggle("ESP enabled", "ESPEnabled", nil,
            "shows enemies through walls")

        local sCaixa = criar_secao(pg, 2, "Box")
        sCaixa:AddToggle("Box", "ESPBox", nil,
            "box around the body")

        local sInfo = criar_secao(pg, 3, "Info")
        sInfo:AddToggle("Name", "ESPShowName", nil)
        sInfo:AddToggle("Health and distance", "ESPShowHealth", nil,
            "bar and number, scaled to the 150 this game uses")
        sInfo:AddToggle("Show distance", "ESPShowDist", nil)

        --[[
            O Range ficou sozinho numa secao porque e' o ajuste
            que mais mexe no que voce ve na tela - e foi o que
            estava sem funcionar (o ESP ignorava ele).
        --]]
        local sAlcance = criar_secao(pg, 4, "Range")
        sAlcance:AddSlider("Range", "ESPMaxDistance", 50, 2000, 50,
            function(v) return tostring(math.floor(v)) .. "m" end)
    end


    do
        local pg = refs.paginas.MOVEMENT

        local sVoo = criar_secao(pg, 1, "Flight")
        sVoo:AddToggle("Fly", "FlyEnabled",
            function(on) if on then start_fly() else stop_fly() end end,
            "WASD to move, Space up, Ctrl down")
        sVoo:AddSlider("Fly speed", "FlySpeed", 10, 200, 5,
            function(v) return tostring(math.floor(v)) end)

        local sVel = criar_secao(pg, 2, "Speed")
        sVel:AddToggle("Increase speed", "SpeedEnabled", nil,
            "above normal draws attention")
        sVel:AddSlider("Speed", "SpeedValue", 16, 60, 1,
            function(v) return tostring(math.floor(v)) end)
    end


    do
        local pg = refs.paginas.FPS

        --[[
            O FPS tinha um cartao feito a mao com titulo, subtitulo
            e botao. Agora que existe criar_secao, virou abinha
            igual as outras - menos codigo e a mesma cara.
        --]]
        local sFps = criar_secao(pg, 1, "FPS Mode")

        local linha = novo("Frame", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundTransparency = 1,
            LayoutOrder = sFps:prox(),
        })
        linha.Parent = sFps.inner

        local d = novo("TextLabel", {
            Size = UDim2.new(1, -118, 0, 16),
            Position = UDim2.new(0, 14, 0, 6),
            BackgroundTransparency = 1,
            Text = "turns off shadows, effects and fog",
            TextColor3 = UI.cor.fraco,
            Font = UI.fonte,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        d.Parent = linha

        local botao = novo("TextButton", {
            Size = UDim2.new(1, -28, 0, 30),
            Position = UDim2.new(0, 14, 0, 24),
            BackgroundColor3 = UI.cor.cartao2,
            BorderSizePixel = 0,
            Text = "ON",
            TextColor3 = UI.cor.texto,
            Font = UI.fonteB,
            TextSize = 12,
            AutoButtonColor = false,
        })
        botao.Parent = linha
        canto(botao, 8)
        hover(botao, 0.10)

        botao.MouseButton1Click:Connect(function()
            if CONFIG.FpsMode then
                desligar_fps()
                botao.Text = "ON"
                botao.BackgroundColor3 = UI.cor.cartao2
                botao.TextColor3 = UI.cor.texto
            else
                ligar_fps()
                botao.Text = "OFF"
                botao.BackgroundColor3 = UI.cor.verde
                botao.TextColor3 = Color3.fromRGB(10, 30, 18)
            end
        end)
    end


    do
        local pg = refs.paginas.CONFIG

        -- os presets prontos vao numa abinha
        local sPre = criar_secao(pg, 1, "Presets")

        for i, p in ipairs(PRESETS) do
            local c = novo("Frame", {
                Size = UDim2.new(1, 0, 0, 50),
                BackgroundColor3 = UI.cor.cartao,
                BorderSizePixel = 0,
                LayoutOrder = i + 1,
            })
            c.Parent = sPre.inner
            canto(c, 9)

            local faixa = novo("Frame", {
                Size = UDim2.new(0, 3, 1, -16),
                Position = UDim2.new(0, 0, 0, 8),
                BackgroundColor3 = p.cor,
                BorderSizePixel = 0,
            })
            faixa.Parent = c
            canto(faixa, 2)

            local n = novo("TextLabel", {
                Size = UDim2.new(1, -110, 0, 18),
                Position = UDim2.new(0, 14, 0, 8),
                BackgroundTransparency = 1,
                Text = p.nome,
                TextColor3 = UI.cor.texto,
                Font = UI.fonteB,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            n.Parent = c

            local s = novo("TextLabel", {
                Size = UDim2.new(1, -110, 0, 14),
                Position = UDim2.new(0, 14, 0, 26),
                BackgroundTransparency = 1,
                Text = p.sub,
                TextColor3 = UI.cor.fraco,
                Font = UI.fonte,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            s.Parent = c

            local usar = novo("TextButton", {
                Size = UDim2.new(0, 78, 0, 26),
                Position = UDim2.new(1, -90, 0.5, -13),
                BackgroundColor3 = p.cor,
                BorderSizePixel = 0,
                Text = "USE",
                TextColor3 = Color3.fromRGB(12, 10, 18),
                Font = UI.fonteB,
                TextSize = 11,
                AutoButtonColor = false,
            })
            usar.Parent = c
            canto(usar, 7)
            hover(usar, 0.10)
            usar.MouseButton1Click:Connect(function()
                aplicar_preset(p)
            end)
        end

        local sMeu = criar_secao(pg, 2, "My preset")
        sMeu:AddToggle("Save on exit", "AutoSave", nil,
            "writes your settings when the hub closes")

        local linha = novo("Frame", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundTransparency = 1,
            LayoutOrder = sMeu:prox(),
        })
        linha.Parent = sMeu.inner

        local salvar = novo("TextButton", {
            Size = UDim2.new(0.5, -4, 1, 0),
            BackgroundColor3 = UI.cor.cartao,
            BorderSizePixel = 0,
            Text = "SAVE",
            TextColor3 = UI.cor.texto,
            Font = UI.fonteB,
            TextSize = 12,
            AutoButtonColor = false,
        })
        salvar.Parent = linha
        canto(salvar, 8)
        hover(salvar, 0.10)

        local carregar = novo("TextButton", {
            Size = UDim2.new(0.5, -4, 1, 0),
            Position = UDim2.new(0.5, 4, 0, 0),
            BackgroundColor3 = UI.cor.cartao,
            BorderSizePixel = 0,
            Text = "LOAD",
            TextColor3 = UI.cor.texto,
            Font = UI.fonteB,
            TextSize = 12,
            AutoButtonColor = false,
        })
        carregar.Parent = linha
        canto(carregar, 8)
        hover(carregar, 0.10)

        salvar.MouseButton1Click:Connect(function()
            local ok = salvar_preset_custom()
            salvar.Text = ok and "SAVED" or "NO FILE"
            task.delay(1.4, function() salvar.Text = "SAVE" end)
        end)
        carregar.MouseButton1Click:Connect(function()
            local ok = carregar_preset_custom()
            carregar.Text = ok and "LOADED" or "EMPTY"
            task.delay(1.4, function() carregar.Text = "LOAD" end)
        end)
    end




    local rodape = novo("TextLabel", {
        Size = UDim2.new(1, -24, 0, 16),
        Position = UDim2.new(0, 12, 1, -22),
        BackgroundTransparency = 1,
        Text = VERSION .. "  ·  RightShift pra esconder",
        TextColor3 = UI.cor.fraco,
        Font = UI.fonte,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    rodape.Parent = painel

    trocar("AIM")




    task.spawn(function()
        while painel.Parent do
            local m = attack_mode
            if m == "engine" then m = "native"
            elseif m == "none" then m = "NO METHOD" end
            pcall(function()
                estado.Text = fire_state
                local mira = (MIRA_MODO == "camera") and "cam" or "mouse"
                metodo.Text = m .. " / " .. mira .. "  ·  "
                              .. tostring(shots) .. " shots"
            end)
            task.wait(0.25)
        end
    end)




    toggle_painel = function()
        painel.Visible = not painel.Visible
    end
    _G.__LOWHUB_TOGGLE = toggle_painel

    janela = sg
    return sg
end

do
    local ok, err = pcall(build)
    if not ok then
        warn("[LowHub] falha ao montar interface: " .. tostring(err))
    end
end

G.__LOWHUB_ATIVO = {
    limpar = function()
        if input_conn then pcall(function() input_conn:Disconnect() end) end
        if input_end then pcall(function() input_end:Disconnect() end) end
        if toggle_conn then pcall(function() toggle_conn:Disconnect() end) end
        if loop_conn then pcall(function() loop_conn:Disconnect() end) end
        stop_fly()
        for plr in pairs(esp_cache) do remove_esp(plr) end
        desligar_fps()
        if janela then pcall(function() janela:Destroy() end) end
        G.__LOWHUB_ATIVO = nil
    end,
}

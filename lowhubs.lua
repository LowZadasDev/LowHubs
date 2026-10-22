if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer

local BASE = "https://raw.githubusercontent.com/LowZadasDev/LowHubs/refs/heads/main/"

local CATALOGO = {
    {
        id     = "rivals",
        nome   = "Rivals",
        desc   = "Aimlock, triggerbot, box ESP",
        arquivo = "lowhub_rivals.lua",
    
        places  = { 17625359962, 117398147513099 },
        criador = 3461453,
        cor    = Color3.fromRGB(255, 90, 110),
    },
    {
        id     = "tribos",
        nome   = "Tribes 3v3",
        desc   = "Aim, ESP, movement and FPS",
        arquivo = "lowhub_tribes.lua",
        place  = 72169370437173,
        criador = 776581204,
        cor    = Color3.fromRGB(150, 92, 245),
    },

}

local UI = {
    cor = {
        fundo    = Color3.fromRGB(14, 12, 20),
        painel   = Color3.fromRGB(20, 17, 28),
        cartao   = Color3.fromRGB(26, 22, 36),
        cartao2  = Color3.fromRGB(32, 27, 44),
        borda    = Color3.fromRGB(44, 38, 60),
        texto    = Color3.fromRGB(238, 234, 248),
        fraco    = Color3.fromRGB(150, 142, 172),
        roxo     = Color3.fromRGB(150, 92, 245),
        roxo2    = Color3.fromRGB(190, 140, 255),
        verde    = Color3.fromRGB(90, 220, 140),
        vermelho = Color3.fromRGB(240, 85, 105),
    },
    fonteT = Enum.Font.GothamBold,
    fonte  = Enum.Font.Gotham,
    fonteM = Enum.Font.GothamMedium,
    fonteC = Enum.Font.Code,
}

local function resolve_parent()
    local tentativas = {
        function() return gethui and gethui() end,
        function() return get_hidden_gui and get_hidden_gui() end,
        function() return LP:WaitForChild("PlayerGui", 5) end,
        function() return CoreGui end,
    }
    for _, f in ipairs(tentativas) do
        local ok, r = pcall(f)
        if ok and r then return r end
    end
    return CoreGui
end

local PARENT = resolve_parent()

local function novo(classe, props)
    local o = Instance.new(classe)
    for k, v in pairs(props or {}) do o[k] = v end
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
    quanto = quanto or 0.10
    botao.AutoButtonColor = false
    local antes = nil
    botao.MouseEnter:Connect(function()
        antes = botao.BackgroundColor3
        local c = botao.BackgroundColor3
        botao.BackgroundColor3 = Color3.new(
            math.min(c.R + quanto, 1),
            math.min(c.G + quanto, 1),
            math.min(c.B + quanto, 1))
    end)
    botao.MouseLeave:Connect(function()
        if antes then botao.BackgroundColor3 = antes antes = nil end
    end)
end

local estado = {
    gui     = nil,
    painel  = nil,
    itens   = {},
    log     = {},
    baixando = false,
}


local ativar_tecla
local desativar_tecla

local function logar(texto, tipo)
    table.insert(estado.log, { texto = texto, tipo = tipo or "info" })
    if #estado.log > 5 then table.remove(estado.log, 1) end

    if not estado.painel then return end
    local caixa = estado.painel:FindFirstChild("Log", true)
    if not caixa then return end

    for _, f in ipairs(caixa:GetChildren()) do
        if f:IsA("TextLabel") then f:Destroy() end
    end

    local cores = {
        info  = UI.cor.fraco,
        ok    = UI.cor.verde,
        erro  = UI.cor.vermelho,
    }
    for i, l in ipairs(estado.log) do
        local t = novo("TextLabel", {
            Name = "L" .. i,
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, (i - 1) * 14),
            BackgroundTransparency = 1,
            Text = l.texto,
            TextColor3 = cores[l.tipo] or cores.info,
            Font = UI.fonteC,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        t.Parent = caixa
    end
end

local function baixar(url)
    local ok, corpo = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok or not corpo then
        return nil, "falha de rede"
    end
    if #corpo < 80 then
        return nil, "resposta vazia (" .. #corpo .. " bytes)"
    end



    local inicio = corpo:sub(1, 40):lower()
    if inicio:find("<!doctype") or inicio:find("<html")
       or inicio:find("404: not found") then
        return nil, "arquivo nao existe no repositorio"
    end
    return corpo
end


local function varrer_chao()
    -- desliga o atalho primeiro: sem isso, um RightShift depois
    -- da limpeza recriaria o menu do nada
    desativar_tecla()

    if estado.gui then
        pcall(function() estado.gui:Destroy() end)
        estado.gui = nil
    end

    -- procura por nome em todo canto que a gente alcanca
    local lugares = {}

    pcall(function()
        local pl = game:GetService("Players")
        if pl.LocalPlayer then
            lugares[#lugares + 1] = pl.LocalPlayer:FindFirstChild("PlayerGui")
        end
    end)

    pcall(function()
        lugares[#lugares + 1] = game:GetService("CoreGui")
    end)

    for _, onde in ipairs(lugares) do
        if onde then
            for _, f in ipairs(onde:GetChildren()) do
                if f.Name == "LowHubCarregador" then
                    pcall(function() f:Destroy() end)
                end
                -- o overlay as vezes sobrevive sozinho
                if f.Name == "LowHubCarregadorOverlay" then
                    pcall(function() f:Destroy() end)
                end
            end
        end
    end

    -- zera o registro global pra ninguem tentar reabrir um menu
    -- que nao existe mais
    pcall(function()
        local G = _G
        if type(getgenv) == "function" then
            local ok, g = pcall(getgenv)
            if ok and type(g) == "table" then G = g end
        end
        if G.__LOWHUB_CARREGADOR then
            G.__LOWHUB_CARREGADOR = nil
        end
    end)
end

local function rodar(item)
    if estado.baixando then return end
    estado.baixando = true

    logar("downloading " .. item.arquivo .. "...", "info")

    task.spawn(function()
        local url = BASE .. item.arquivo
        local corpo, erro = baixar(url)

        if not corpo then
            logar("error: " .. tostring(erro), "error")
            estado.baixando = false
            return
        end

        logar("baixado (" .. math.floor(#corpo / 1024) .. " KB)", "ok")

        local chunk, erro_sint
        if type(loadstring) == "function" then
            chunk, erro_sint = loadstring(corpo, "LowHub_" .. item.id)
        else
            chunk, erro_sint = load(corpo, "LowHub_" .. item.id)
        end

        if not chunk then
            logar("script error: " .. tostring(erro_sint), "error")
            estado.baixando = false
            return
        end



        -- limpa TUDO antes de entregar a tela pro hub
        varrer_chao()

        local ok, erro_exec = pcall(chunk)
        if not ok then
            -- o hub nao subiu: devolvo o menu pra voce escolher
            -- na mao. Antes isto reabria sozinho, e como o hub
            -- tambem abria, ficavam DOIS paineis na tela.
            warn("[LowHub] " .. tostring(erro_exec))
            ativar_tecla()
            if estado.abrir then estado.abrir() end
        else

local function bate_place(item)
    if item.place and game.PlaceId == item.place then return true end
    if item.places then
        for _, id in ipairs(item.places) do
            if game.PlaceId == id then return true end
        end
    end
    return false
end

local function detectar_atual()
    for _, item in ipairs(CATALOGO) do
        if bate_place(item) then return item end
        if item.criador and game.CreatorId == item.criador then
            return item
        end
    end
    return nil
end

local function construir()
    local larg = 420
    local alt = 130 + (#CATALOGO * 66) + 30

    local sg = novo("ScreenGui", {
        Name = "LowHubCarregador",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 2147483647,
    })
    sg.Parent = PARENT
    estado.gui = sg


    local ov = novo("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
    })
    ov.Parent = sg

    local painel = novo("Frame", {
        Name = "Painel",
        Size = UDim2.new(0, larg, 0, alt),
        Position = UDim2.new(0.5, -larg / 2, 0.5, -alt / 2),
        BackgroundColor3 = UI.cor.painel,
        BorderSizePixel = 0,
        Active = true,
        Draggable = true,
    })
    painel.Parent = sg
    canto(painel, 14)
    borda(painel, UI.cor.borda, 1)
    estado.painel = painel


    local escala = Instance.new("UIScale")
    escala.Parent = painel
    local function ajustar()
        local cam = workspace.CurrentCamera
        local vs = cam and cam.ViewportSize
        if not vs or vs.X <= 0 then return false end
        local f = math.min((vs.X * 0.92) / larg, (vs.Y * 0.92) / alt, 1)
        escala.Scale = math.max(f, 0.55)
        return true
    end
    if not ajustar() then
        task.spawn(function()
            for _ = 1, 60 do
                task.wait(0.1)
                if ajustar() then break end
            end
        end)
    end


    local cab = novo("Frame", {
        Name = "Cabecalho",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 1,
    })
    cab.Parent = painel

    local titulo = novo("TextLabel", {
        Size = UDim2.new(1, -30, 0, 22),
        Position = UDim2.new(0, 18, 0, 13),
        BackgroundTransparency = 1,
        Text = "LowHub",
        TextColor3 = UI.cor.texto,
        Font = UI.fonteT,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    titulo.Parent = cab

    local sub = novo("TextLabel", {
        Size = UDim2.new(1, -30, 0, 15),
        Position = UDim2.new(0, 18, 0, 35),
        BackgroundTransparency = 1,
        Text = "choose your game hub",
        TextColor3 = UI.cor.fraco,
        Font = UI.fonte,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    sub.Parent = cab


    local fechar = novo("TextButton", {
        Name = "Fechar",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -34, 0, 16),
        BackgroundColor3 = UI.cor.cartao,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = UI.cor.fraco,
        Font = UI.fonteT,
        TextSize = 16,
        AutoButtonColor = false,
    })
    fechar.Parent = cab
    canto(fechar, 6)
    hover(fechar, 0.10)
    fechar.MouseButton1Click:Connect(function()
        pcall(function() sg:Destroy() end)
        estado.gui = nil
    end)


    local lista = novo("Frame", {
        Name = "Lista",
        Size = UDim2.new(1, -36, 0, #CATALOGO * 66),
        Position = UDim2.new(0, 18, 0, 58),
        BackgroundTransparency = 1,
    })
    lista.Parent = painel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = lista

    local atual = detectar_atual()

    for i, item in ipairs(CATALOGO) do
        local eh_atual = (item == atual)

        local cartao = novo("TextButton", {
            Name = "Item_" .. item.id,
            Size = UDim2.new(1, 0, 0, 58),
            BackgroundColor3 = UI.cor.cartao,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
        })
        cartao.Parent = lista
        canto(cartao, 10)
        local traco = borda(cartao, eh_atual and UI.cor.verde or UI.cor.borda, 1)


        local fita = novo("Frame", {
            Size = UDim2.new(0, 4, 1, -16),
            Position = UDim2.new(0, 8, 0, 8),
            BackgroundColor3 = item.cor,
            BorderSizePixel = 0,
        })
        fita.Parent = cartao
        canto(fita, 2)

        local nome = novo("TextLabel", {
            Size = UDim2.new(1, -100, 0, 17),
            Position = UDim2.new(0, 20, 0, 10),
            BackgroundTransparency = 1,
            Text = item.nome,
            TextColor3 = UI.cor.texto,
            Font = UI.fonteT,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        nome.Parent = cartao

        local desc = novo("TextLabel", {
            Size = UDim2.new(1, -100, 0, 14),
            Position = UDim2.new(0, 20, 0, 28),
            BackgroundTransparency = 1,
            Text = item.desc,
            TextColor3 = UI.cor.fraco,
            Font = UI.fonte,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        })
        desc.Parent = cartao

        local marca = novo("TextLabel", {
            Name = "Marca",
            Size = UDim2.new(0, 90, 0, 16),
            Position = UDim2.new(1, -100, 0, 21),
            BackgroundTransparency = 1,
            Text = eh_atual and "YOU ARE HERE" or "LOAD",
            TextColor3 = eh_atual and UI.cor.verde or UI.cor.roxo2,
            Font = UI.fonteM,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Right,
        })
        marca.Parent = cartao

        cartao.MouseButton1Click:Connect(function()
            rodar(item)
        end)
        hover(cartao, 0.05)
        estado.itens[item.id] = cartao
    end


    local caixinha = novo("Frame", {
        Name = "Log",
        Size = UDim2.new(1, -36, 0, 70),
        Position = UDim2.new(0, 18, 1, -78),
        BackgroundTransparency = 1,
    })
    caixinha.Parent = painel

    logar("ready. pick a hub above.", "info")

    return sg
end

local function abrir()
    if estado.gui then return end
    pcall(construir)
end

estado.abrir = abrir


local TECLA = Enum.KeyCode.RightShift
local conn_tecla = nil

-- preenche os nomes declarados la em cima
function ativar_tecla()
    if conn_tecla then return end
    conn_tecla = UserInputService.InputBegan:Connect(function(input, processado)
        if processado then return end
        if input.KeyCode == TECLA then
            if estado.gui then
                pcall(function() estado.gui:Destroy() end)
                estado.gui = nil
            else
                abrir()
            end
        end
    end)
end

function desativar_tecla()
    if not conn_tecla then return end
    pcall(function() conn_tecla:Disconnect() end)
    conn_tecla = nil
end

ativar_tecla()

local G = _G
if type(getgenv) == "function" then
    local ok, g = pcall(getgenv)
    if ok and type(g) == "table" then G = g end
end

if G.__LOWHUB_CARREGADOR and G.__LOWHUB_CARREGADOR.limpar then
    pcall(G.__LOWHUB_CARREGADOR.limpar)
end

G.__LOWHUB_CARREGADOR = {
    limpar = function()
        desativar_tecla()
        if estado.gui then
            pcall(function() estado.gui:Destroy() end)
            estado.gui = nil
        end
    end,
    abrir = abrir,
}

task.wait(math.random() * 0.5)


local AJUSTE_MANUAL = false

local atual = detectar_atual()

if AJUSTE_MANUAL or not atual then
    if not atual then
        logar("unknown game  (PlaceId " ..
              tostring(game.PlaceId) .. ")", "error")
        logar("pick one from the list", "info")
    end
    abrir()
else
    logar("detected: " .. atual.nome, "ok")
    task.spawn(function()
        rodar(atual)
    end)
end

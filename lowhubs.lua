local T={{246,1,229,236,199,195,179},{202,229,215,185,138,167,138},{189,202,171,167,109,129,114,102,84,34,35,31,18,244,221,206},{157,175,140,123,115,71,72,68,55,25,2,243},{146,141,124,103,89,15,243,226,20,242,247,157,197,182,176,147,143,107,109,90,59,55,23,18,0,245,213,205,194,107,143,138,119,40,52,70,61,15,5,247,227,228,164,180,180,92,104,122,113,49,77,41,41,212,6,232,216,212,127,167,147,126,112,110,25,70,41,32,20,196},{125,99,95,57,51,41},{62,68,64,26,20,10},{14,37,24,6,248,219,210,130,101,168,149,123,104,87,68,64,31,27,15,182,153,202,198,190,85,105,102,82},{26,12,3,227,223,187,167,169,143,139,101,95,85,255,44,36,255},{3,240,214,190,186,173},{196,209,183,159,145,142,42,44,94,10},{146,169,156,74,45,65,62,42,245,216,20,5,251,217,208,183,175,164,63,111,107,80,251,16,9,251},{158,144,135,103,99,63,43,47,28,2,234,220,217,131,176,168,131},{99,110,82,89,52,48,244,17,244},{73,44,21,48,34,13,243,239},{42,13,6,22,3,239,218,195}
,{31,19,250,242},{227,245,220},{204,204,206,185,128,132,116,102,92},{165},{160,138,132,111,87,5,56,40,210,19,245,227,211},{141,111,108,88,70,57,41,5,179,248,210,218,184,159,77,68},{28,77,83,61,29,26,191},{25,237,31,25,252,252,240,214,186},{250,21,16,248,230},{211,190,177,166,123,184,168,156,55,108,100,89,65,38},{225,225,207,194,165,161,137,41,102,72,69,229,25,27,251,244,228,196,110,171,155,59,124,94,88,70,57,30,24,2,244,218,207},{173,191,182,118,146,110,62,75,75,58,28,13,246,232,226,212},{142,160,151,87,115,79,31,44,44,27,253,238,215,201,195,181,129,151,117,113,90,62,69},{137,135,111,83,83,55,44,26},{120,84,68,61,37},{73,67,58,32,13,255,224,210,198,186,162,74}
,{244,227,210},{12,8,247,227,213,140,97},{237,233,216,196,182},{203,185,176,174,134,120,114,18,9},{106,132,106,64},{154,133},{88,106,97,33,61,25,5},{97,68,52,45,201,253,255,219,200,201,183,161,147,48,103,79,80,236,41,15,2,252,223,203,199,100,159,145,114,100,98,82,63,37,25,1,169,230,214,200,101,160,146,115,101},{65,32,30,4,250,237,136,188,184,167,147,133,60,17},{10,234,252,243,179,207,171,149,71},{227,226,224,194,177,169,113,142,113},{183,210,176,171,146},{161,183,149,145,122,94,101},{131,131,122,110,84,74},{105,76,69,68,49,43,19},{56,69,53,39,20,1,251,230,220}
,{34,52,43,235,7,227},{26,14,4,243,230,199,113,185,158,147,127,28,82,59,54,29,199,254,250,214},{236,236,238,217,150,184,166,149,127,109},{191,205,186,174,150,150},{29,224},{135,147,140,124,88},{113,84,70,82,75,59,2,6,13,242,231,213},{70,96,64,55,24},{},{12,15,15,239,220},{249,222,211,141,157,157,127,73,96,76,72,42},{205,191,160,146},{212,182,161,147,151,59,28,91,67,44,35,199,247,165,220,216,180,97,145,129,125,115,81,9},{184,160,140,126,110,101,75,236,34,11,6,237,151,134,125,148,159,131,116,101,56,66,237},{77},{117,93,70,61,225,31,13,243,157,210,205,185,166,72,139,110,90,4,63,43,36,20}
,{74,58,56,24,5,5,229,211,152,109}}
local S={}
local C=string.char
local function D(i)
  if S[i] then return S[i] end
  local a=T[i]
  local o={}
  for b=1,#a do
    local k=((i-1)*31+(b-1)*17+90)%256
    o[b]=C((a[b]+k)%256)
  end
  local r=table.concat(o)
  S[i]=r
  return r
end
local __S=D
pcall(function()local g=getgenv and getgenv()if g then g.__S=D end end)
if not game:IsLoaded()then
game.Loaded:Wait()
end
local Players=game:GetService(__S(1))
local CoreGui=game:GetService(__S(2))
local UserInputService=game:GetService(__S(3))
local TweenService=game:GetService(__S(4))
local LP=Players.LocalPlayer
local BASE=__S(5)
local CATALOGO={{id=__S(6),nome=__S(7),desc=__S(8),arquivo=__S(9),places={17625359962,117398147513099},criador=3461453,cor=Color3.fromRGB(255,90,110),},{id=__S(10),nome=__S(11),desc=__S(12),arquivo=__S(13),place=72169370437173,criador=776581204,cor=Color3.fromRGB(150,92,245),},}
local UI={cor={fundo=Color3.fromRGB(14,12,20),painel=Color3.fromRGB(20,17,28),cartao=Color3.fromRGB(26,22,36),cartao2=Color3.fromRGB(32,27,44),borda=Color3.fromRGB(44,38,60),texto=Color3.fromRGB(238,234,248),fraco=Color3.fromRGB(150,142,172),roxo=Color3.fromRGB(150,92,245),roxo2=Color3.
fromRGB(190,140,255),verde=Color3.fromRGB(90,220,140),vermelho=Color3.fromRGB(240,85,105),},fonteT=Enum.Font.GothamBold,fonte=Enum.Font.Gotham,fonteM=Enum.Font.GothamMedium,fonteC=Enum.Font.Code,}
local
function resolve_parent()
local tentativas={
function()
return gethui and gethui()
end
,
function()
return get_hidden_gui and get_hidden_gui()
end
,
function()
return LP:WaitForChild(__S(14),5)
end
,
function()
return CoreGui
end
,}
for _,f in ipairs(tentativas)
do
local ok,r=pcall(f)
if ok and r then
return r
end
end
return CoreGui
end
local PARENT=resolve_parent()
local
function novo(classe,props)
local o=Instance.new(classe)
for k,v in pairs(props or{})
do
o[k]=v
end
return o
end
local
function canto(o,r)
local c=Instance.new(__S(15))c.CornerRadius=UDim.new(0,r or 8)c.Parent=o
return c
end
local
function borda(o,cor,t)
local s=Instance.new(__S(16))s.Color=cor or UI.cor.borda s.Thickness=t or 1 s.Parent=o
return s
end
local
function hover(botao,quanto)quanto=quanto or 0.10 botao.AutoButtonColor=false
local antes=nil botao.MouseEnter:Connect(
function()antes=botao.BackgroundColor3
local c=botao.BackgroundColor3 botao.BackgroundColor3=Color3.new(math.min(c.R+quanto,1),math.min(c.G+quanto,1),math.min(c.B+quanto,1))
end
)botao.MouseLeave:Connect(
function()
if antes then
botao.BackgroundColor3=antes antes=nil
end
end
)
end
local estado={gui=nil,painel=nil,itens={},log={},baixando=false,}
local ativar_tecla
local desativar_tecla
local
function logar(texto,tipo)table.insert(estado.log,{texto=texto,tipo=tipo or __S(17)})
if#estado.log>5 then
table.remove(estado.log,1)
end
if not estado.painel then
return
end
local caixa=estado.painel:FindFirstChild(__S(18),true)
if not caixa then
return
end
for _,f in ipairs(caixa:GetChildren())
do
if f:IsA(__S(19))then
f:Destroy()
end
end
local cores={info=UI.cor.fraco,ok=UI.cor.verde,erro=UI.cor.vermelho,}
for i,l in ipairs(estado.log)
do
local t=novo(__S(19),{Name=__S(20)..i,Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,(i-1)*14),BackgroundTransparency=1,Text=l.texto,TextColor3=cores[l.tipo]or cores.info,Font=UI.fonteC,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,})t.Parent=caixa
end
end
local
function baixar(url)
local ok,corpo=pcall(
function()
return game:HttpGet(url,true)
end
)
if not ok or not corpo then
return nil,__S(21)
end
if#corpo<80 then
return nil,__S(22)..#corpo..__S(23)
end
local inicio=corpo:sub(1,40):lower()
if inicio:find(__S(24))or inicio:find(__S(25))or inicio:find(__S(26))then
return nil,__S(27)
end
return corpo
end
local
function varrer_chao()desativar_tecla()
if estado.gui then
pcall(
function()estado.gui:Destroy()
end
)estado.gui=nil
end
local lugares={}pcall(
function()
local pl=game:GetService(__S(1))
if pl.LocalPlayer then
lugares[#lugares+1]=pl.LocalPlayer:FindFirstChild(__S(14))
end
end
)pcall(
function()lugares[#lugares+1]=game:GetService(__S(2))
end
)
for _,onde in ipairs(lugares)
do
if onde then
for _,f in ipairs(onde:GetChildren())
do
if f.Name==__S(28)then
pcall(
function()f:Destroy()
end
)
end
if f.Name==__S(29)then
pcall(
function()f:Destroy()
end
)
end
end
end
end
pcall(
function()
local G=_G
if type(getgenv)==__S(30)then
local ok,g=pcall(getgenv)
if ok and type(g)==__S(31)then
G=g
end
end
if G.__LOWHUB_CARREGADOR then
G.__LOWHUB_CARREGADOR=nil
end
end
)
end
local
function rodar(item)
if estado.baixando then
return
end
estado.baixando=true logar(__S(32)..item.arquivo..__S(33),__S(17))task.spawn(
function()
local url=BASE..item.arquivo
local corpo,erro=baixar(url)
if not corpo then
logar(__S(34)..tostring(erro),__S(35))estado.baixando=false
return
end
logar(__S(36)..math.floor(#corpo/1024)..__S(37),__S(38))
local chunk,erro_sint
if type(loadstring)==__S(30)then
chunk,erro_sint=loadstring(corpo,__S(39)..item.id)
elseif type(load)==__S(30)then
chunk,erro_sint=load(corpo,__S(39)..item.id)
if not chunk then
local ok2,c2,e2=pcall(load,
function()
return corpo
end
,__S(39)..item.id)
if ok2 and c2 then
chunk,erro_sint=c2,nil
else
erro_sint=e2 or erro_sint
end
end
else
erro_sint=__S(40)
end
if not chunk then
logar(__S(41)..tostring(erro_sint),__S(35))estado.baixando=false
return
end
varrer_chao()
local ok,erro_exec=pcall(chunk)
if not ok then
warn(__S(42)..tostring(erro_exec))ativar_tecla()
if estado.abrir then
estado.abrir()
end
else
varrer_chao()
end
estado.baixando=false
end
)
end
local
function bate_place(item)
if item.place and game.PlaceId==item.place then
return true
end
if item.places then
for _,id in ipairs(item.places)
do
if game.PlaceId==id then
return true
end
end
end
return false
end
local
function detectar_atual()
for _,item in ipairs(CATALOGO)
do
if bate_place(item)then
return item
end
if item.criador and game.CreatorId==item.criador then
return item
end
end
return nil
end
local
function construir()
local larg=420
local alt=130+(#CATALOGO*66)+30
local sg=novo(__S(43),{Name=__S(28),ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=2147483647,})sg.Parent=PARENT estado.gui=sg
local ov=novo(__S(44),{Name=__S(45),Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.45,BorderSizePixel=0,})ov.Parent=sg
local painel=novo(__S(44),{Name=__S(46),Size=UDim2.new(0,larg,0,alt),Position=UDim2.new(0.5,-larg/2,0.5,-alt/2),BackgroundColor3=UI.cor.painel,BorderSizePixel=0,Active=true,Draggable=true,})painel.Parent=sg canto(painel,14)borda(painel,UI.cor.borda,1)estado.painel=painel
local escala=Instance.new(__S(47))escala.Parent=painel
local
function ajustar()
local cam=workspace.CurrentCamera
local vs=cam and cam.ViewportSize
if not vs or vs.X<=0 then
return false
end
local f=math.min((vs.X*0.92)/larg,(vs.Y*0.92)/alt,1)escala.Scale=math.max(f,0.55)
return true
end
if not ajustar()then
task.spawn(
function()
for _=1,60
do
task.wait(0.1)
if ajustar()then
break
end
end
end
)
end
local cab=novo(__S(44),{Name=__S(48),Size=UDim2.new(1,0,0,58),BackgroundTransparency=1,})cab.Parent=painel
local titulo=novo(__S(19),{Size=UDim2.new(1,-30,0,22),Position=UDim2.new(0,18,0,13),BackgroundTransparency=1,Text=__S(49),TextColor3=UI.cor.texto,Font=UI.fonteT,TextSize=20,TextXAlignment=Enum.TextXAlignment.Left,})titulo.Parent=cab
local sub=novo(__S(19),{Size=UDim2.new(1,-30,0,15),Position=UDim2.new(0,18,0,35),BackgroundTransparency=1,Text=__S(50),TextColor3=UI.cor.fraco,Font=UI.fonte,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,})sub.Parent=cab
local fechar=novo(__S(51),{Name=__S(52),Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-34,0,16),BackgroundColor3=UI.cor.cartao,BorderSizePixel=0,Text=__S(53),TextColor3=UI.cor.fraco,Font=UI.fonteT,TextSize=16,AutoButtonColor=false,})fechar.Parent=cab canto(fechar,6)hover(fechar,0.10)fechar.
MouseButton1Click:Connect(
function()pcall(
function()sg:Destroy()
end
)estado.gui=nil
end
)
local lista=novo(__S(44),{Name=__S(54),Size=UDim2.new(1,-36,0,#CATALOGO*66),Position=UDim2.new(0,18,0,58),BackgroundTransparency=1,})lista.Parent=painel
local layout=Instance.new(__S(55))layout.Padding=UDim.new(0,8)layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=lista
local atual=detectar_atual()
for i,item in ipairs(CATALOGO)
do
local eh_atual=(item==atual)
local cartao=novo(__S(51),{Name=__S(56)..item.id,Size=UDim2.new(1,0,0,58),BackgroundColor3=UI.cor.cartao,BorderSizePixel=0,Text=__S(57),AutoButtonColor=false,LayoutOrder=i,})cartao.Parent=lista canto(cartao,10)
local traco=borda(cartao,eh_atual and UI.cor.verde or UI.cor.borda,1)
local fita=novo(__S(44),{Size=UDim2.new(0,4,1,-16),Position=UDim2.new(0,8,0,8),BackgroundColor3=item.cor,BorderSizePixel=0,})fita.Parent=cartao canto(fita,2)
local nome=novo(__S(19),{Size=UDim2.new(1,-100,0,17),Position=UDim2.new(0,20,0,10),BackgroundTransparency=1,Text=item.nome,TextColor3=UI.cor.texto,Font=UI.fonteT,TextSize=14,TextXAlignment=Enum.TextXAlignment.Left,})nome.Parent=cartao
local desc=novo(__S(19),{Size=UDim2.new(1,-100,0,14),Position=UDim2.new(0,20,0,28),BackgroundTransparency=1,Text=item.desc,TextColor3=UI.cor.fraco,Font=UI.fonte,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,})desc.Parent=cartao
local marca=novo(__S(19),{Name=__S(58),Size=UDim2.new(0,90,0,16),Position=UDim2.new(1,-100,0,21),BackgroundTransparency=1,Text=eh_atual and __S(59)or __S(60),TextColor3=eh_atual and UI.cor.verde or UI.cor.roxo2,Font=UI.fonteM,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,})marca.Parent=cartao
cartao.MouseButton1Click:Connect(
function()rodar(item)
end
)hover(cartao,0.05)estado.itens[item.id]=cartao
end
local caixinha=novo(__S(44),{Name=__S(18),Size=UDim2.new(1,-36,0,70),Position=UDim2.new(0,18,1,-78),BackgroundTransparency=1,})caixinha.Parent=painel logar(__S(61),__S(17))
return sg
end
local
function abrir()
if estado.gui then
return
end
pcall(construir)
end
estado.abrir=abrir
local TECLA=Enum.KeyCode.RightShift
local conn_tecla=nil
function ativar_tecla()
if conn_tecla then
return
end
conn_tecla=UserInputService.InputBegan:Connect(
function(input,processado)
if processado then
return
end
if input.KeyCode==TECLA then
if estado.gui then
pcall(
function()estado.gui:Destroy()
end
)estado.gui=nil
else
abrir()
end
end
end
)
end
function desativar_tecla()
if not conn_tecla then
return
end
pcall(
function()conn_tecla:Disconnect()
end
)conn_tecla=nil
end
ativar_tecla()
local G=_G
if type(getgenv)==__S(30)then
local ok,g=pcall(getgenv)
if ok and type(g)==__S(31)then
G=g
end
end
if G.__LOWHUB_CARREGADOR and G.__LOWHUB_CARREGADOR.limpar then
pcall(G.__LOWHUB_CARREGADOR.limpar)
end
G.__LOWHUB_CARREGADOR={limpar=
function()desativar_tecla()
if estado.gui then
pcall(
function()estado.gui:Destroy()
end
)estado.gui=nil
end
end
,abrir=abrir,}task.wait(math.random()*0.5)
local AJUSTE_MANUAL=false
local atual=detectar_atual()
if AJUSTE_MANUAL or not atual then
if not atual then
logar(__S(62)..tostring(game.PlaceId)..__S(63),__S(35))logar(__S(64),__S(17))
end
abrir()
else
logar(__S(65)..atual.nome,__S(38))task.spawn(
function()rodar(atual)
end
)
end

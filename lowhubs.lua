local T={{10,7,29,244,251,221,179},{58,229,233,201,250,187,182},{205,218,223,185,149,131,142,122,84,98,39,33,18,28,229,242},{227,191,188,143,149,95,120,92,73,57,2,23},{190,147,140,121,105,17,19,98,44,14,247,191,197,218,176,189,147,149,125,106,79,73,47,50,0,11,245,207,198,237,183,138,155,40,84,70,77,17,61,9,31,252,228,212,180,252,168,154,113,95,93,91,57,116,30,24,232,236,159,169,183,130,144,118,57,74,89,32,52,68},{135,111,97,73,85,57},{70,76,64,38,52,26},{114,45,56,10,24,235,242,134,155,184,175,135,152,119,68,64,33,59,17,90,167,250,198,194,235,153,190,174},{62,12,3,237,227,197,231,187,179,157,157,97,109,1,44,36,3},{5,240,250,198,218,181},{196,211,219,161,177,150,214,52,110,26},{238,169,188,206,211,65,70,118,27,104,52,5,13,233,240,203,209,164,193,147,109,112,5,112,23,11},{162,176,135,105,103,65,107,49,36,14,26,236,233,133,208,184,191},{189,146,110,89,84,48,20,17,28},{89,84,109,80,34,15,23,241},{126,117,30,42,29,239,250,199},
{35,53,10,18},{37,21,236},{220,252,210,207,128,188,140,154,124},{235},{160,182,132,145,107,59,72,88,110,45,21,229,247},{151,147,116,104,70,73,63,61,77,8,238,218,216,163,243,204},{36,119,95,67,45,42,67},{31,21,33,57,4,12,240,234,206},{126,59,16,24,234},{85,66,183,174,133,216,168,172,201,156,100,105,67,90},{225,227,211,198,173,163,137,215,102,120,69,27,41,37,7,12,228,196,146,173,187,197,132,98,104,70,73,34,40,2,12,230,207},{211,223,182,154,150,150,70,119,85,74,44,61,10,24,226,236},{242,160,151,185,119,113,103,84,52,37,13,30,235,255,195,207,129,169,149,115,126,66,77},{187,155,145,115,85,91,44,58},{136,108,124,67,37},{127,67,74,32,51,31,224,246,202,218,162,246},
{20,101,114},{60,24,9,227,239,148,159},{29,251,232,196,206},{245,201,208,178,186,136,146,46,55},{150,140,154,192},{186,141},{184,106,97,111,77,43,5},{103,76,92,53,119,13,1,239,248,217,201,161,173,208,105,115,80,20,43,51,14,12,225,255,217,156,161,177,142,100,98,86,65,45,59,1,87,230,246,216,155,160,178,143,155},{65,32,38,12,6,243,184,204,200,185,179,159,196,47},{10,46,28,243,221,211,213,149,249},{35,226,224,198,209,171,145,146,145},{201,210,208,175,182},{225,201,181,147,158,98,109},{157,191,134,110,116,78},{185,180,93,124,81,45,55},{72,125,79,91,44,1,29,234,252},
{102,84,59,21,27,29},{42,50,4,19,254,251,143,185,190,151,129,36,114,71,90,45,121,2,14,238},{60,28,242,239,238,200,186,171,159,111},{193,253,202,210,170,174},{101,32},{137,191,148,140,104},{177,188,74,126,91,77,6,58,21,18,251,235},{74,96,64,91,24},{},{12,51,17,23,228},{57,62,215,179,229,231,131,247,160,188,88,94},{51,223,224,246},{236,202,161,181,155,221,36,101,79,84,35,121,11,91,228,232,204,159,177,131,157,117,113,11},{200,160,180,158,110,101,77,20,34,55,10,29,169,186,131,236,161,191,140,101,88,70,19},{245},{139,101,126,69,31,63,15,23,163,242,215,217,170,248,157,146,110,60,65,87,60,20},
{126,78,72,40,61,27,229,245,152,147}}
local S={}
local C=string.char
local function D(i)
  if S[i] then return S[i] end
  local a=T[i]
  local o={}
  for b=1,#a do
    local k=((i-1)*31+(b-1)*17+90)%256
    o[b]=C((a[b]~k)%256)
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

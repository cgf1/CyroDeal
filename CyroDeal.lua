local Chat = Chat
local EVENT_MANAGER = EVENT_MANAGER
local GetAddOnManager = GetAddOnManager
local GetUnitDisplayName = GetUnitDisplayName
local LibChatMessage = LibChatMessage
local ReloadUI = ReloadUI
local zo_callLater = zo_callLater
local ZO_SavedVars = ZO_SavedVars

local myname = 'CyroDeal'
local defaults = {Visible = true}
local version = "1.00"

local x = {
    __index = _G,
    name = myname
}

CyroDeal = setmetatable(x, x)
local CyroDeal = CyroDeal
CyroDeal.CyroDeal = CyroDeal
setfenv(1, CyroDeal)

local chat, itsme, log, lsc, saved, options = {}
local panel
local dprint, print, printf

function split2(inputstr, sep)
    if sep == nil then
	sep = "%s"
    end
    local first
    local rest = ''
    for str in inputstr:gmatch("([^"..sep.."]+)") do
	if first == nil then
	    first = str
	else
	    rest = rest .. ' ' .. str
	end
    end
    return first, rest:sub(2)
end

function split(inputstr, sep)
    if sep == nil then
	sep = "%s"
    end
    local t = {}
    for str in inputstr:gmatch("([^"..sep.."]+)") do
	t[#t + 1] = str
    end
    return unpack(t)
end

function parse(text)
    local t = {}
    while text:len() > 0 do
	local pre, b4q, q = text:match("^(%s*[^'\"]-)([^%s'\"]*)(['\"]?)")
	if q == '' then
	    pre = pre .. b4q
	end
	for str in pre:gmatch("%S+") do
	    t[#t + 1] = str
	    -- print(1, "'" .. t[#t] .. "'")
	end
	text = text:sub(pre:len() + 1)
	if text:len() == 0 then
	    break
	end
	if q ~= '' then
	    local e
	    local atom = ''
	    while true do
		local _, e = text:find("%b" .. q .. q)

		local seg = text:sub(1, e):gsub(q, '')
		atom = atom .. seg
		text = text:sub(e + 1)
		local pre, q = text:match([[^([^'"%s]*)(['"]?)]])
		atom = atom .. pre
		text = text:sub(pre:len() + 1)

		if q == '' then
		    break
		end
	    end
	    t[#t + 1] = atom
	    text = ' ' .. text
	end
    end
    return unpack(t)
end

local seen
function tprint (tbl, indent)
  if not indent then
      seen = {}
      indent = 0
  end
  local toprint = string.rep(" ", indent) .. "{\r\n"
  indent = indent + 2
  for k, v in pairs(tbl) do
    toprint = toprint .. string.rep(" ", indent)
    if (type(k) == "number") then
      toprint = toprint .. "[" .. k .. "] = "
    elseif (type(k) == "string") then
      toprint = toprint	 .. k ..  "= "
    end
    if (type(v) == "number") then
      toprint = toprint .. v .. ",\r\n"
    elseif (type(v) == "string") then
      toprint = toprint .. "\"" .. v .. "\",\r\n"
    elseif (type(v) == "table" and not seen[v]) then
      seen[v] = true
      toprint = toprint .. tprint(v, indent + 2) .. ",\r\n"
    else
      toprint = toprint .. "\"" .. tostring(v) .. "\",\r\n"
    end
  end
  if indent == 0 then
      seen = nil
  end
  toprint = toprint .. string.rep(" ", indent-2) .. "}"
  return toprint
end

function dlater(msg)
    -- zo_callLater(function () log:Error(msg) end, 100)
    zo_callLater(function () d(msg) end, 100)
end

local modules = {}
local function cyrodeal(what)
    if what == nil then
	return '/cyr', cyrodeal, 'Perform various operations for CyroDeal addon'
    end
    local kw, rest = split2(what)
    if kw == 'clear' then
	if rest ~= '' then
	    saved[rest] = nil
	else
	    for _, m in ipairs(modules) do
		print("clearing", m)
		saved[m] = nil
	    end
	end
	ReloadUI()
    end
end

local function rrr(what)
    if what == nil then
	return '/rrr', rrr, 'Alias for /reloadui'
    end
    ReloadUI()
end

local initvars
local function init(_, name)
    if name == myname then
	dprint = CyroDeal.dprint
	print = CyroDeal.print
	printf = CyroDeal.printf
	EVENT_MANAGER:UnregisterForEvent(myname, EVENT_ADD_ON_LOADED)
	saved = ZO_SavedVars:NewCharacterIdSettings(name .. 'Saved', 1.0, nil, defaults)
	local lcm = LibChatMessage
	chat = lcm.Create("CyroDeal", "CYD")
	log = LibDebugLogger.Create('CyroDeal')
	log:SetEnabled(true)
	lsc = LibSlashCommander
	local LAM = LibAddonMenu2
	local manager = GetAddOnManager()
	local name, title, author, description
	for i = 1, manager:GetNumAddOns() do
	    name, title, author, description = manager:GetAddOnInfo(i)
	    if name == myname then
		break
	    end
	end

	local paneldata = {
	    type = "panel",
	    name = title,
	    displayName = "|c00B50F" .. title .. "|r",
	    author = author,
	    description = description,
	    version = version,
	    registerForDefaults = true,
	    registerForRefresh = true
	}
	panel = LAM:RegisterAddonPanel(myname .. 'AddonPanel', paneldata)
	local iam = {['@JamesHowser'] = true, ['@Smilier'] = true, ['@StompMan'] = true}
	itsme = not not iam[GetUnitDisplayName('player')]
	initvars = {chat = chat, itsme = itsme, log = log, lsc = lsc, options = options}
	CyroDeal.Chat(initvars)
	lsc:Register(cyrodeal())
	lsc:Register(rrr())
    end
end

local function loadsaved(module)
    saved[module] = saved[module] or {}
    local modsaved = saved[module]
    if CyroDeal[module].SaveDefaults then
	local defaults = CyroDeal[module].SaveDefaults()
	for k, v in pairs(defaults) do
	    if modsaved[k] == nil then
		modsaved[k] = v
	    end
	end
    end
    local sawit = false
    for k, v in pairs(saved) do
	if k == module then
	    print("YES", module)
	    sawit = true
	end
    end
    dprint("NEVER SAW", module, saved[module])

    return modsaved
end

local function activated()
    EVENT_MANAGER:UnregisterForEvent(myname, EVENT_PLAYER_ACTIVATED)
    local manager = GetAddOnManager()
    local n = manager:GetNumAddOns()
    for i = 1, n do
	local module, _, _, description, enabled = manager:GetAddOnInfo(i)
	if enabled then
	    local word = description:gmatch("%S+")()
	    if word == 'CyroDeal' then
		modules[#modules + 1] = module
		initvars.saved = loadsaved(module)
		CyroDeal[module].Init(initvars)
	    end
	end
    end
end
EVENT_MANAGER:RegisterForEvent(myname, EVENT_ADD_ON_LOADED, init)
EVENT_MANAGER:RegisterForEvent(myname, EVENT_PLAYER_ACTIVATED, activated)

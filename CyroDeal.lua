local EVENT_MANAGER = EVENT_MANAGER
local GetAddOnManager = GetAddOnManager
local LibChatMessage = LibChatMessage
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
setfenv(1,CyroDeal)

local chat, log, lsc, saved, options = {}
local panel

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

local initvars
local function init(_, name)
    if name == myname then
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
	initvars = {chat = chat, log = log, lsc = lsc, options = options, saved = saved}
    end
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
		CyroDeal[module].Init(initvars)
	    end
	end
    end
end
EVENT_MANAGER:RegisterForEvent(myname, EVENT_ADD_ON_LOADED, init)
EVENT_MANAGER:RegisterForEvent(myname, EVENT_PLAYER_ACTIVATED, activated)

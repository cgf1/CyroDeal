local CreateControlFromVirtual = CreateControlFromVirtual
local dlater = CyroDeal.dlater
local dprint = CyroDeal.dprint
local EQUIP_SLOT_COSTUME = EQUIP_SLOT_COSTUME
local error = CyroDeal.error
local EVENT_MANAGER = EVENT_MANAGER
local GetControl = GetControl
local GetDateElementsFromTimestamp = GetDateElementsFromTimestamp
local GetGroupSize = GetGroupSize
local GetGroupUnitTagByIndex = GetGroupUnitTagByIndex
local GetGuildDescription = GetGuildDescription
local GetGuildId = GetGuildId
local GetGuildMemberIndexFromDisplayName = GetGuildMemberIndexFromDisplayName
local GetGuildMemberInfo = GetGuildMemberInfo
local GetGuildName = GetGuildName
local GetHeight = GetHeight
local GetItemCreatorName = GetItemCreatorName
local GetNumGuilds = GetNumGuilds
local GetString = GetString
local GetTimeStamp = GetTimeStamp
local GetUnitDisplayName = GetUnitDisplayName
local GetGroupLeaderUnitTag = GetGroupLeaderUnitTag
local GetUnitZone = GetUnitZone
local GroupLeave = GroupLeave
local GUILD_SHARED_INFO = GUILD_SHARED_INFO
local IsInCyrodiil = IsInCyrodiil
local IsUnitGrouped = IsUnitGrouped
local IsUnitInGroupSupportRange = IsUnitInGroupSupportRange
local print = CyroDeal.print
local printf = CyroDeal.printf
local SetGuildMemberNote = SetGuildMemberNote
local SI_CHECK_BUTTON_ON = SI_CHECK_BUTTON_ON
local SLASH_COMMANDS = SLASH_COMMANDS
local split2 = CyroDeal.split2
local TOPLEFT = TOPLEFT
local TOPRIGHT = TOPRIGHT
local watch = CyroDeal.Watch
local zo_callLater = zo_callLater
local ZO_CheckButton_SetToggleFunction = ZO_CheckButton_SetToggleFunction
local ZO_GuildHistory = ZO_GuildHistory
local ZO_GuildRosterHideOffline = ZO_GuildRosterHideOffline
local ZO_GuildRosterSearchLabel = ZO_GuildRosterSearchLabel
local ZO_CheckButton_SetCheckState = ZO_CheckButton_SetCheckState

setfenv(1, CyroDeal)
local myname = "CyroLeader"
local x = {
    __index = _G,
    name = myname
}

CyroLeader = setmetatable(x, x)
local cl = CyroLeader
cl.CyroLeader = cl

local log, lsc, saved
local recordpvp
local iam = GetUnitDisplayName("player")

function cl.SaveDefaults()
    return {tabard = false}
end

local function isleader()
    local leadertag = GetGroupLeaderUnitTag()
    if not leadertag then
	return false
    end
    local dname = GetUnitDisplayName(leadertag)
    return dname == iam
end

local function lam()
    local a = {{
	type = "checkbox",
	name = "Update Guild when wearing tabard?",
	tooltip = "Only update guild notes with date when when wearing tabard",
	getFunc = function()
	    return saved.tabard or false
	end,
	setFunc = function(val)
	    saved.tabard = val
	end
    }}
    return a
end

local function tabard_guid()
    local guild = GetItemCreatorName(0, EQUIP_SLOT_COSTUME)
    local n = GetNumGuilds()
    for i = 1, n do
	local guid = GetGuildId(i)
	if GetGuildName(guid) == guild then
	    return guid
	end
    end
    return -1
end

local updq = {}
local group = {
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4},
{1, 2, 3, 4}
}
local queued = false
function queue()
    if #updq <= 0 then
	queued = false
	return
    end
    local guid, guix, unit, pvpdate = unpack(table.remove(updq))
    printf("unqueued %s %s %s %s", tostring(guid), tostring(guix), tostring(unit), tostring(pvpdate))
local guin = GetGuildName(guid)
    if not saved.tabard or tabard_guid() == guid then
	local name, note = GetGuildMemberInfo(guid, guix)
printf("checking %s from %s", name, guin)
	if not note or not note:find(pvpdate) then
	    if not IsUnitInGroupSupportRange(unit) then
		updq[#updq + 1] = {guid, guix}
	    else
		note = note:gsub("PVP:%d%d%d%d/%d%d/%d%d ?", "")
		if note:len() > 0 then
		    pvpdate = pvpdate .. " "
		end
printf("updated %s in %s", name, guin)
		SetGuildMemberNote(guid, guix, pvpdate .. note)
	    end
else printf("didn't update %s in %s", name, guin)
	end

    end
    if #updq <= 0 then
	printf("queue: %d", #updq)
	queued = false
    else
	printf("resecheduling: %d", #updq)
	zo_callLater(queue, 11000)
	queued = true
    end
end

local lastdate
local seen = {}
function update_guild_info(count)
    if not IsUnitGrouped('player') then
dprint("not grouped")
	return
    end

    if not IsInCyrodiil() then
dprint("not in Cyrodiil")
	return
    end
    local pvpdate = string.format("PVP:%4d/%02d/%02d", GetDateElementsFromTimestamp(GetTimeStamp()))
    if pvpdate ~= lastdate then
	lastdate = pvpdate
	seen = {}
    end
    local updqlen = #updq
printf("Group size %d, date %s", GetGroupSize(), pvpdate)
    for i = 1, GetGroupSize() do
	local unit = GetGroupUnitTagByIndex(i)
	local name = GetUnitDisplayName(unit)
	if not seen[name] then
	    seen[name] = true
	    for guid, wantit in pairs(recordpvp) do
		if wantit then
		    local guix = GetGuildMemberIndexFromDisplayName(guid, name)
		    if guix then

			printf("queuing %s %s unit %s pvpdate:%s", tostring(name), GetUnitZone(unit), unit, pvpdate)
			local g = group[i]
			g[1], g[2], g[3], g[4] = guid, guix, unit, pvpdate
			table.insert(updq, g)
		    end
		end
	    end
	end
    end
    if not queued and updqlen ~= #updq then
print("starting queue")
	zo_callLater(queue, 10000)
	queued = true
    end
end

function cyl(what)
    if what == nil then
	return '/cyl', cyl, "CyroDeal: Refresh guild notes for group members in Cyrodiil"
    end
    update_guild_info(61)
end

local function spoof_cyrodiil(what)
    if what == nil then
	return '/cylcyrodiil', spoof_cyrodiil, "CyroDeal: Assert that we are actually in Cyrodiil"
    end
    IsInCyrodiil = function() return true end
end

local function spoof_isleader(what)
    if what == nil then
	return '/cylleader', spoof_isleader, "CyroDeal: Assert that we are the group leader"
    end
    isleader = function() return true end
end

function cl.Init(init)
    log, lsc, saved = init.log, init.lsc, init.saved
    saved.recordpvp = saved.recordpvp or {}
    recordpvp = saved.recordpvp
    lsc:Register(cyl())
    lam(init.options)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_GROUP_UPDATE, function () update_guild_info() end)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_GROUP_MEMBER_JOINED, function () update_guild_info() end)
    update_guild_info()
    local ref = ZO_GuildRosterHideOffline
    -- local ref = ZO_GuildRosterSearchLabel,
    local button = CreateControlFromVirtual(nil, ref, "ZO_CheckButton")
    local text = CreateControlFromVirtual(nil, button, "ZO_CheckButtonLabel")
    text:SetText("Record PVP attendance");
    button:SetAnchor(TOPLEFT, ref, TOPLEFT, 0, -(text:GetHeight() + 2))
    text:SetAnchor(TOPLEFT, button, TOPRIGHT, 5, -2)
    -- ZO_CheckButton_SetCheckState(button, true)
    local count = GetControl(GUILD_SHARED_INFO.control, "Count")
    count:SetHandler("OnTextChanged", function(self, currentFrameTimeSeconds)
	local guid = GUILD_SHARED_INFO.guildId
	recordpvp[guid] = recordpvp[guid] or false
	ZO_CheckButton_SetCheckState(button, recordpvp[guid])
    end)
    ZO_CheckButton_SetToggleFunction(button, function(control, checked)
	saved.recordpvp[GUILD_SHARED_INFO.guildId] = checked
    end)
    lsc:Register(spoof_cyrodiil())
    lsc:Register(spoof_isleader())
    return lam()
end

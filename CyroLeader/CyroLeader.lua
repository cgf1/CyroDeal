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
    return {recordpvp = {}}
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
	name = "Update Guild when wearing tabard (currently doesn't work)?",
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

local lastdate
local running = false
local seen = {}
function update_guild_info()
    if not IsUnitGrouped('player') then
	dprint("not grouped")
	return
    end

    if not IsInCyrodiil() then
	dprint("not in Cyrodiil")
	return
    end
    if not running then
print("scanning")
	scan()
    end
end

function scan()
    local pvpdate = string.format("PVP:%4d/%02d/%02d", GetDateElementsFromTimestamp(GetTimeStamp()))
    if pvpdate ~= lastdate then
	lastdate = pvpdate
	seen = {}
    end
printf("Group size %d, date %s", GetGroupSize(), pvpdate)
    local already_updated = false
    local sawguild = false
    for i = 1, GetGroupSize() do
	local unit = GetGroupUnitTagByIndex(i)
	local name = GetUnitDisplayName(unit)
	if seen[name] then
print("seen", name)
	else
	    for guid, wantit in pairs(recordpvp) do
		if wantit then
		    sawguild = true
		    local guix = GetGuildMemberIndexFromDisplayName(guid, name)
		    if guix then
local guin = GetGuildName(guid)
printf("checking %s %s, unit %s, guild %s pvpdate:%s, seen:%s", tostring(name), GetUnitZone(unit), unit, guin, pvpdate, tostring(seen[name] or false))
			local _, note = GetGuildMemberInfo(guid, guix)
			if note and note:find(pvpdate) then
			    seen[name] = true
printf("%s already updated with %s", name, pvpdate)
			elseif not IsUnitInGroupSupportRange(unit) or already_updated then
			    zo_callLater(scan, 10000)
			    running = true
			    return
			else
			    seen[name] = true
			    note = note:gsub("PVP:%d%d%d%d/%d%d/%d%d ?", "")
			    if note:len() > 0 then
				pvpdate = pvpdate .. " "
			    end
printf("updated %s in %s", name, guin)
			    SetGuildMemberNote(guid, guix, pvpdate .. note)
			    already_updated = true
			end
		    end
		end
	    end
	end
    end
    if not sawguild then
	print("Never saw a guild to register PVP attendance")
    end
    running = false
end

function cyl(what)
    if what == nil then
	return '/cyl', cyl, "CyroDeal: Refresh guild notes for group members in Cyrodiil"
    end
    if not running then
	update_guild_info()
    end
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
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_GROUP_MEMBER_REMOVED, function () update_guild_info() end)
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

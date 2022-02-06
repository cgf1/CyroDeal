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

function cl.SaveDefaults()
    return {GuildNotes = false}
end

local function lam()
    local a = {{
	type = "checkbox",
	name = "Update Guild notes?",
	tooltip = "Update guild note with current date with all guild members in your current Leader.  Uses current guild tabard to determine guild",
	getFunc = function()
	    return saved.GuildNotes or false
	end,
	setFunc = function(val)
	    saved.GuildNotes = val
	end
    }}
    return a
end

local function guildid()
    local guild = GetItemCreatorName(0, EQUIP_SLOT_COSTUME)
    local n = GetNumGuilds()
    for i = 1, n do
	local guid = GetGuildId(i)
	if GetGuildName(guid) == guild then
	    return guid
	end
    end
    return nil
end

local updq = {}
local queued = false
function queue()
    if #updq <= 0 then
	queued = false
	return
    end
    local guid, guix, unit, pvpdate = unpack(table.remove(updq, 1))
    local _, note = GetGuildMemberInfo(guid, guix)
    if not note:find(pvpdate) then
	if not IsUnitInGroupSupportRange(unit) then
	    updq[#updq + 1] = {guid, guix}
	else
	    note = note:gsub("PVP:%d%d%d%d/%d%d/%d%d ?", "")
	    if note:len() > 0 then
		pvpdate = pvpdate .. " "
	    end
printf("updated %d", guix)
	    SetGuildMemberNote(guid, guix, pvpdate .. note)
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

    local guid = guildid()
    if not guid then
	count = count or 0
	if count <= 60 then
	    zo_callLater(function () update_guild_info(count + 1) end, 1000)
	else
	    printf("no guild tabard equipped after %d tries - guild notes not updated", count)
	end
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
printf("considering %s %s seen:%s", tostring(name), GetUnitZone(unit), tostring(seen[name] or false))
	if not seen[name] then
	    seen[name] = true
	    local guix = GetGuildMemberIndexFromDisplayName(guid, name)
	    if guix then
		updq[#updq + 1] = {guid, guix, unit, pvpdate}
	    end
	end
    end
    if not queued and updqlen ~= #updq then
print("kicking queue")
	queue()
    end
end

function cyl(what)
    if what == nil then
	return '/cyl', cyl, "CyroDeal: Refresh guild notes for group members in Cyrodiil"
    end
    update_guild_info(61)
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
	local guildid = GUILD_SHARED_INFO.guildId
	recordpvp[guildid] = recordpvp[guildid] or false
printf("HERE %s %s", tostring(guildid), tostring(recordpvp[guildid]))
	ZO_CheckButton_SetCheckState(button, recordpvp[guildid])
    end)
    ZO_CheckButton_SetToggleFunction(button, function(control, checked)
printf("GUILD ID %s", tostring(GUILD_SHARED_INFO.guildId))
	saved.recordpvp[GUILD_SHARED_INFO.guildId] = checked
    end)
    lsc:Register('/foo', function() ZO_CheckButton_SetCheckState(button, false) end, 'foo')
    return lam()
end

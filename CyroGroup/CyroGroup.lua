local dlater = CyroDeal.dlater
local split2 = CyroDeal.split2
local watch = CyroDeal.Watch
local zo_callLater = zo_callLater
local AcceptGroupInvite = AcceptGroupInvite
local CHAT_CHANNEL_PARTY = CHAT_CHANNEL_PARTY
local CHAT_SYSTEM = CHAT_SYSTEM
local GroupLeave = GroupLeave
local ZO_PreHook = ZO_PreHook

setfenv(1, CyroDeal)
local myname = "CyroGroup"
local x = {
    __index = _G,
    name = myname
}

CyroGroup = setmetatable(x, x)
local cg = CyroGroup
cg.CyroGroup = cg

local chat, log, lsc, options, saved

local JUMP1 = 'JUMP_TO_GROUP_LEADER_WORLD_PROMPT'
local JUMP2 = 'JUMP_TO_GROUP_LEADER_OCCURANCE_PROMPT'

local hooked = false
local suppress = false
local function nodialog(name, data)
    watch("nodialog", name, data)
    if (name == JUMP1 or name == JUMP2) and suppress then
	suppress = false
	return true
    end
end

local function on_invite(_, charname, displayname)
    watch("on_invite", charname, displayname)
    if saved.AutoAccept[charname] or saved.AutoAccept[displayname] then
	suppress = true
	if not hooked then
	    ZO_PreHook("ZO_Dialogs_ShowDialog", nodialog)
	    hooked = true
	end
	AcceptGroupInvite()
	chat:Printf("[CyroDeal] accepted invite from %s", charname)
    end
end

local function autoaccept(what)
    if what == nil then
	return '/cyaccept', autoaccept, 'Automatically accept requests from given person'
    end

    local kw, rest = split2(what)
    if kw == 'clear' then
	what = rest
    end
    if kw == 'clear' then
	if what == '' then
	    saved.AutoAccept = {}
	    chat:Print("[CyroDeal] clearing all auto accept group invites")
	elseif saved.AutoAccept[what] then
	    saved.AutoAccept[what] = nil
	    chat:Printf("[CyroDeal] clearing auto accept group invite for %s", what)
	else
	    chat:SetTagColor("ff0000"):Printf('[CyroDeal] "%s" was not found in auto accept list', what)
	end
    elseif what:len() > 0 then
	saved.AutoAccept[what] = true
	chat:Printf("[CyroDeal] automatically accept group invites from %s", what)
    else
	local keys = {}
	for n in pairs(saved.AutoAccept) do
	    keys[#keys + 1] = n
	end
	if #keys == 0 then
	    chat:SetTagColor("ff0000"):Print("[CyroDeal] not accepting group invites from anyone")
	else
	    chat:Print("[CyroDeal] accepting group invites from:")
	    table.sort(keys)
	    for _, n in ipairs(keys) do
		chat:Print(n)
	    end
	end
    end
end

local function leave(what)
    if what == nil then
	return '/cyleave', leave, "Leave group"
    end
    GroupLeave()
end

local function finddiscord()
end

function cg.SendText(n)
    local channel = CHAT_CHANNEL_PARTY
    local target = nil
    local message
    if n > 1 then
	message = saved.Texts[n]
    else
	message = finddiscord()
	if not message then
	    return
	end
    end
    if message then
	CHAT_SYSTEM:StartTextEntry(message, CHAT_CHANNEL_PARTY)
    else
	chat:SetTagColor("ff0000"):Print("[CyroDeal] no message assigned to that slot")
    end
end

function cg.SaveDefaults()
    return {AutoAccept = {}, Texts = {}, FindDiscord = true}
end

function cg.Init(init)
    chat, log, lsc, options, saved = init.chat, init.log, init.lsc, init.options, init.saved
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_GROUP_INVITE_RECEIVED, on_invite)
    local aa = lsc:Register(autoaccept())
    aa:AddAlias('/cya')
    local l = lsc:Register(leave())
    l:AddAlias('/leave')
end
ZO_CreateStringId("SI_BINDING_NAME_CYROGROUP_SEND_TEXT1", "Send Discord Link")
ZO_CreateStringId("SI_BINDING_NAME_CYROGROUP_SEND_TEXT2", "Send Arbitrary Text")
ZO_CreateStringId("SI_BINDING_NAME_CYROGROUP_SEND_TEXT3", "Send Arbitrary Text")

local CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING = CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING
local CAMPAIGN_QUEUE_REQUEST_STATE_WAITING = CAMPAIGN_QUEUE_REQUEST_STATE_WAITING
local ConfirmCampaignEntry = ConfirmCampaignEntry
local dlater = CyroDeal.dlater
local error = CyroDeal.error
local GetAssignedCampaignId = GetAssignedCampaignId
local GetCampaignName = GetCampaignName
local GetCampaignQueuePosition = GetCampaignQueuePosition
local GetCampaignQueueState = GetCampaignQueueState
local GetNumSelectionCampaigns = GetNumSelectionCampaigns
local GetSelectionCampaignId = GetSelectionCampaignId
local LeaveCampaignQueue = LeaveCampaignQueue
local print = CyroDeal.print
local printf = CyroDeal.printf
local QueueForCampaign = QueueForCampaign
local split2 = CyroDeal.split2
local tostring = tostring
local watch = Watch
local zo_callLater = zo_callLater

setfenv(1, CyroDeal)
local myname = "CyroCampaign"
local x = {
    __index = _G,
    name = myname
}

CyroCampaign = setmetatable(x, x)
local cc = CyroCampaign
cc.cc = cc

local log, lsc, saved

local function group(isgroup)
    if isgroup then
	return 'group '
    else
	return ''
    end
end

local function wantid(id)
    return saved.AcceptAll or id == GetAssignedCampaignId()
end

local function pos_changed(_, id, isgroup, pos)
    if saved.ShowPosChange then
	printf("%s%s queue position %d", group(isgroup), GetCampaignName(id), pos)
    end
end

local function state_changed(_, id, isgroup, state)
    if not wantid(id) then
	return
    end
    if state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING and wantid(id) then
	ConfirmCampaignEntry(id, isgroup, true)
    elseif state == CAMPAIGN_QUEUE_REQUEST_STATE_PENDING_ACCEPT then
	printf("entering campaign %s", GetCampaignName(id))
    end
end

local function joined(_, id, isgroup)
    printf("%squeued for campaign %s", group(isgroup), GetCampaignName(id))
    -- zo_callLater(function () state_changed(_, id, isgroup, CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING) end, 3000)
end

local function left(_, id, isgroup)
    printf("left %squeue for %s", group(isgroup), GetCampaignName(id))
end

local function cypvp(what)
    if what == nil then
	return '/cypvp', cypvp, "CyroDeal: Join the queue for your home campaign"
    end
    local isgroup, leave
    if what == '' then
	isgroup = false leave = false
    else
	while true do
	    local kw, rest = split2(what)
	    if kw == 'group' then
		isgroup = true
		what = rest
	    elseif kw == 'leave' then
		leave = true
		what = rest
	    else
		break
	    end
	end
    end
    local wantid
    if what == '' then
	wantid = GetAssignedCampaignId()
	if not wantid then
	    error("no home campaign set yet")
	    return
	end
    else
	what = what:lower()
	local n = GetNumSelectionCampaigns()
	for i = 1, n do
	    local id = GetSelectionCampaignId(i)
	    if id and id ~= 0 and GetCampaignName(id):lower() == what then
		wantid = id
		break
	    end
	end
	if not wantid then
	    error("campaign '%s' not found", what)
	    return
	end
    end
    if leave then
	LeaveCampaignQueue(wantid, isgroup)
	printf("%sleaving campaign: %s", group(isgroup), GetCampaignName(wantid))
    else
	QueueForCampaign(wantid, isgroup)
	printf("%squeuing for campaign %s", group(isgroup), GetCampaignName(wantid))
    end
end

local function cyq(what)
    if what == nil then
	return "/cyq", cyq, "CyroDeal: Show position in Cyrodill queue"
    end
    local n = GetNumSelectionCampaigns()
    for i = 1, n do
	local id = GetSelectionCampaignId(i)
	if id and id ~= 0 and (what == '' or GetCampaignName(id):lower() == what) then
	    for i=1, 2 do
		local pos
		local isgroup = i == 2
		local state = GetCampaignQueueState(id, isgroup)
		if state == CAMPAIGN_QUEUE_REQUEST_STATE_WAITING then
		    pos = GetCampaignQueuePosition(id, isgroup)
		elseif state == CAMPAIGN_QUEUE_REQUEST_STATE_CONFIRMING then
		    pos = 'confirming'
		end
		if pos then
		    printf("%s%s queue position: %s", group(isgroup), GetCampaignName(id), tostring(pos))
		end
	    end
	end
    end
end

function cc.SaveDefaults()
    return {AcceptAll = true}
end

function cc.Init(init)
    log, lsc, saved = init.log, init.lsc, init.saved
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_CAMPAIGN_QUEUE_JOINED, joined)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_CAMPAIGN_QUEUE_LEFT, left)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_CAMPAIGN_QUEUE_POSITION_CHANGED, pos_changed)
    EVENT_MANAGER:RegisterForEvent(myname, EVENT_CAMPAIGN_QUEUE_STATE_CHANGED, state_changed)
    lsc:Register(cypvp())
    local cyq = lsc:Register(cyq())
    cyq:AddAlias("/cyqueue")
end

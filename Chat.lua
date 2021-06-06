local lcm = LibChatMessage
local TAG_PREFIX_OFF = lcm.TAG_PREFIX_OFF
local mysplit = CyroDeal.mysplit
local parse = CyroDeal.parse
local split = CyroDeal.split

setfenv(1, CyroDeal)

-- Globals defined here

Watching = false
Watch = nil

_ = ''	-- start parsing

local watchmen

local chat, itsme, log, lsc, saved

local function emptyfunc()
end

local initwatch

local function chatobj(...)
    local n = select('#', ...)
    local args = {}
    for i=1, n do
	args[i] = select(i, ...)
    end
    local obj
    local color
    if type(args[1]) == 'string' then
	color = '75eaff'
    else
	color = string.format("%06x", args[1])
	table.remove(args, 1)
    end
    local obj
    if lcm:GetTagPrefixMode() ~= TAG_PREFIX_OFF then
	obj = chat:SetTagColor(color)
    else
	args[1] = '[CyroDeal] ' .. tostring(args[1])
	obj = chat
    end
    return args, color, obj, n
end

local function colorize(color, msg)
    return '|c' .. color .. msg .. '|r'
end
function print(...)
    local args, color, obj, n = chatobj(...)
    local msg = ''
    for i = 1, n do
	msg = msg .. ' ' .. tostring(args[i])
    end
    obj:Print(colorize(color, msg:sub(2)))
end

function printf(...)
    local args, color, obj = chatobj(...)
    args[1] = colorize(color, args[1])
    obj:Printf(unpack(args))
end

function dprint(...)
    log:Warn(...)
end

function error(...)
    local vars = {...}
    local printfunc
    if vars[1]:find('%%') then
	printfunc = printf
    else
	printfunc = print
    end
    printfunc(0xff0000, ...)
end

local function real_watch(what, ...)
    initwatch()
    local inargs = {...}
    if watchmen[what] == nil then
	return
    end
    local doit
    if type(watchmen[what]) ~= 'number' then
	doit = watchmen[what]
    elseif watchmen[what] <= 0 then
	return
    else
	watchmen[what] = watchmen[what] - 1
	doit = true
    end
    if doit then
	dprint(what .. ': ', ...)
    end
end

local function setwatch(x)
    if x == nil then
	return '/cywatch', setwatch, 'debugging'
    end
    initwatch()
    if x == "clear" then
	saved.WatchMen = {}
	watchmen = saved.WatchMen
	print("cleared all watchpoints")
	Watch = emptyfunc
	Watching = false
	return
    end
    if x:len() == 0 then
	print("Watchpoints")
	for n, v in pairs(watchmen) do
	    print(n .. ":", v)
	end
	return
    end
    local what, todo = mysplit(x)
    local n = tonumber(todo)
    if n ~= nil then
	todo = n
    elseif todo == nil then
	todo = true
    elseif todo == "on" or "todo" == "true" then
	todo = true
    elseif todo == "off" or todo == "false" then
	todo = false
    else
	error("Can't grok" .. todo)
    end
    watchmen[what] = todo
    if next(watchmen) then
	Watch = real_watch
	Watching = true
    else
	Watch = emptyfunc
	Watching = false
    end
    print("watch", what, '=', todo)
end

initwatch = function()
    if not saved.WatchMen then
	saved.WatchMen = {}
    end
    if not watchmen then
	watchmen = saved.WatchMen
    end
    initwatch = emptyfunc
    if next(watchmen) then
	Watch = real_watch
	Watching = true
    else
	Watch = emptyfunc
	Watching = false
    end
end

Watch = real_watch

function Chat(init)
    chat, itsme, log, lsc, saved = init.chat, init.itsme, init.log, init.lsc, init.saved
    lsc:Register(setwatch())
    if itsme then
	lsc:Register('/print', function (what) print(split(what)) end, 'print arguments')
	lsc:Register('/printf', function (what) printf(parse(what)) end, 'printf arguments')
    end
end

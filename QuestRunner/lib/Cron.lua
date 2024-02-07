--[[
Cron.lua
Timed Tasks Manager

Copyright (c) 2021 psiberx
]]

local Cron = {}

Cron.timers = { version = '1.0.1' }
local counter = 0

--@param timeout number
--@param recurring boolean
--@param callback function
--@param args
--@return any
local function addTimer(timeout, recurring, callback, args)
	if type(timeout) ~= 'number' then
		return
	end

	if timeout <= 0 then
		return
	end

	if type(recurring) ~= 'boolean' then
		return
	end

	if type(callback) ~= 'function' then
		if type(args) == 'function' then
			callback, args = args, callback
		else
			return
		end
	end

	if type(args) ~= 'table' then
		args = { arg = args }
	end

	counter = counter + 1

	local timer = {
		id = "timer_" .. tostring(counter),
		callback = callback,
		recurring = recurring,
		timeout = timeout,
		active = true,
		delay = timeout,
		args = args,
	}

	if args.id == nil then
		args.id = timer.id
	end

	if args.interval == nil then
		args.interval = timer.timeout
	end

	if args.Halt == nil then
		args.Halt = Cron.Halt
	end

	if args.Pause == nil then
		args.Pause = Cron.Pause
	end

	if args.Resume == nil then
		args.Resume = Cron.Resume
	end

	table.insert(Cron.timers, timer)

	return timer.id
end

--@param timeout number
--@param callback function
--@param data
--@return any
function Cron.After(timeout, callback, data)
	return addTimer(timeout, false, callback, data)
end

--@param timeout number
--@param callback function
--@param data
--@return any
function Cron.Every(timeout, callback, data)
	return addTimer(timeout, true, callback, data)
end

--@param timerId any
--@return void
function Cron.Halt(timerId)
	if type(timerId) == 'table' then
		timerId = timerId.id
	end

	for i, timer in ipairs(Cron.timers) do
		if timer.id == timerId then
			table.remove(Cron.timers, i)
			break
		end
	end
end

--@param timerId any
--@return void
function Cron.Pause(timerId)
	if type(timerId) == 'table' then
		timerId = timerId.id
	end

	for _, timer in ipairs(Cron.timers) do
		if timer.id == timerId then
			timer.active = false
			break
		end
	end
end

--@param timerId any
--@return void
function Cron.Resume(timerId)
	if type(timerId) == 'table' then
		timerId = timerId.id
	end

	for _, timer in ipairs(Cron.timers) do
		if timer.id == timerId then
			timer.active = true
			break
		end
	end
end

--@param delta number
--@return void
function Cron.Update(delta)
	if #Cron.timers > 0 then
		for i, timer in ipairs(Cron.timers) do
			-- print(timer.id, timer.delay)
			if timer.active then
				timer.delay = timer.delay - delta

				if timer.delay <= 0 then
					if timer.recurring then
						timer.delay = timer.delay + timer.timeout
					else
						table.remove(Cron.timers, i)
						i = i - 1
					end

					timer.callback(timer.args)
				end
			end
		end
	end
end

function Cron.getTimer(timerId)
	for i, timer in ipairs(Cron.timers) do
		if timer.id == timerId then
			return timer
		end
	end
	return nil
end

return Cron

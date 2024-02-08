-- (c)1dentity - part of Quest Runner custom mission framework
local Cron = require("lib/Cron")
local Lang = require("module/Lang")
local log, errorLog, trace, Logger = table.unpack(require("module/Log"))
local selector = require("lib/interactionUI")

local Manager = {}

function Manager:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	o.quests = {}
	o.available = {}
	o.current = nil
	o.refreshAvailable = 0
	return o
end

function Manager:addQuest(quest)
	quest.runner = self.runner
	table.insert(self.quests, quest)
	log("Added quest", quest.getLocalizedNameSTATIC())

	self.refreshAvailable = 10 -- force update
	self:updateQuestTriggers()
end

function Manager:getQuestOptions()
	local availableQuests = self:getAvailable()
	local options = {}
	if #availableQuests == 0 then return end

	for i, quest in ipairs(availableQuests) do
		table.insert(options, { text = quest.getLocalizedNameSTATIC(), icon = quest.icon or selector.OPEN_VENDOR_ICON })
	end
	table.insert(options, { text = Lang:get("cancel"), icon = selector.NONE_ICON })

	selector.create(Lang:get(self.runner.rootFixerId), options, function(id)
		-- the last option is to cancel, so omit in selection
		if id ~= #availableQuests then
			self:setCurrent(availableQuests[id + 1].new(self))
		end
		selector.hideHub()
	end)

	Cron.After(5, function() selector.hideHub() end)
end

function Manager:setCurrent(quest)
	if not quest:isDoable() then trace("Quest is not doable", quest.getLocalizedNameSTATIC()) end
	self.current = quest
	quest:start()
end

function Manager:updateQuestTriggers()
	self.refreshAvailable = self.refreshAvailable + 1 -- debounce
	if self.refreshAvailable < 10 then return else self.refreshAvailable = 0 end

	if self.current then return false end -- no triggers if currently on quest
	self.available = {}
	for _, quest in pairs(self.quests) do
		if quest:isDoable() == true then
			quest:setupTrigger()
			table.insert(self.available, quest)
		end
	end
	if #self.available == 0 then return end
end

function Manager:updateQuest(dt)
	self.current:update(dt)

	if self.current:isLost() then
		log(self.current.name .. " quest triggered isLost")
		self.current:failure()
		self.current:cleanup()
		self.current = nil
		return false
	end
	if self.current:isDone() then
		log(self.current.name .. " quest triggered isDone")
		self.current:success()
		self.current:cleanup()
		self.current = nil
		return false
	end
	return true
end

function Manager:getAvailable()
	return self.available
end

function Manager:update(dt)
	-- if not on quest update quest triggers
	if not self.current then
		self:updateQuestTriggers()
		return
	end
	if not self:updateQuest(dt) then
		return false
	end
end

return Manager:new()

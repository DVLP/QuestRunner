-- (c)identity - do not copy - there's QuestTemplate available for copying
local QuestStage = {}

function QuestStage:new(runner, name, description)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.ruuner = runner
	o.name = name
	o.description = description
	o.active = false
	return o
end

function QuestStage:start()
	print("QuestStage:start", "not implemented in stage: " .. self.name)
	return false
end

function QuestStage:isDone()
	print("QuestStage:isDone", "not implemented in stage: " .. self.name)
	return false
end

function QuestStage:isLost()
	print("QuestStage:isLost", "not implemented in stage: " .. self.name)
end

function QuestStage:update(dt)
	print("QuestStage:update", "not implemented in stage: " .. self.name)
end

function QuestStage:cleanup(didWin)
	print("QuestStage:cleanup", "not implemented in stage: " .. self.name)
end

return QuestStage

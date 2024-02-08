-- (c)identity - part of QuestRunner - abstract class to be inherited by quest stages
local Quest = {}

function Quest:new(runner, name, description, level)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.runner = runner
	o.name = name
	o.description = description
	o.level = level or 1
	o.stages = {}
	o.currStage = nil
	o.currentId = 0
	return o
end

function Quest:start()
	print("Quest:start is not implemented in quest: " .. self.name)
	return nil
end

function Quest:failure()
	print("Quest:failure is not implemented in quest: " .. self.name)
	return nil
end

function Quest:success()
	print("Quest:success is not implemented in quest: " .. self.name)
	return nil
end

function Quest:isDoable()
	print("Quest:isDoable is not implemented in quest: " .. self.name)
	return nil
end

function Quest:cleanup()
end

function Quest:isDone()
	if self.currentId == 0 then return false end -- not started
	if self.currentId > #self.stages then return true end -- all finished - beyond last quest
	if self.currStage:isDone() then
		self.currStage.active = false
		self.currStage:cleanup(true)
		self:nextStage()
	end
	return false
end

function Quest:isLost()
	if self.currentId == 0 then return false end -- not started
	if self.currentId > #self.stages then return false end -- all finished - beyond last quest
	if self.currStage:isLost() then
		self.currStage.active = false
		self.currStage:cleanup(false)
		self.currentId = 0
		self.currStage = nil
		return true
	end
end

function Quest:nextStage()
	local nextStage = self.stages[self.currentId + 1]
	self.currentId = self.currentId + 1
	self.currStage = nextStage
	if self.currStage then
		self.currStage:start()
		self.currStage.active = true
	elseif not self.finalized then
		self.finalized = true
	end
end

function Quest:addStage(stage)
	stage.runner = self.runner
	table.insert(self.stages, stage)
end

function Quest:update(dt)
	if self.currStage then self.currStage:update(dt) end
end

return Quest

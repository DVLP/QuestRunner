-- (c)1dentity - the template is free to use, modify and publish
local QuestStage = require("lib/abstract/QuestStage")
local Nav = require("lib/Nav")
local Lang = require("lib/Lang")

local TIME_LIMIT = 60
local name = Lang:get("reach_destination")
local description = Lang:get("dont_be_late")

local reachDestinationStage = QuestStage:new()

function reachDestinationStage:new(runner)
	return QuestStage.new(reachDestinationStage, runner, name, description)
end

function reachDestinationStage:start()
	self.time = 0
	self.timeStart = self.time
	self.timeLimit = self.time + TIME_LIMIT
	self.reachedDestination = false

	local startPos = self.runner.Scene.locations["badlandRoad"].waypoints[1].pos
	self.runner.Scene:setup(self.runner.Scene.locations["badlandRoad"])

	self.runner.HUD.QuestMessage(self.name .. ': ' .. self.description)
	GameInstance.GetAudioSystem():Play(CName"ui_jingle_quest_new")

	self.destination = Vector4.new(startPos)
	Nav.clearCustomPin()
	Nav.placeCustomPin(self.destination)
end

function reachDestinationStage:update(dt)
	self.time = self.time + dt
	if Vector4.Distance(Game.GetPlayer():GetWorldPosition(), self.destination) < 10 then
		self.reachedDestination = true
	end
	self.runner.Scene:update(true)
end

function reachDestinationStage:isDone()
	if self.reachedDestination then return true end
	return false
end

function reachDestinationStage:isLost()
	if not self.runner.Utils.isAlive(Game.GetPlayer()) then
		self.runner.HUD.QuestMessage(Lang:get("you_died"))
		return true
	end

	if self.time > self.timeLimit then return true end
	return false
end

return reachDestinationStage

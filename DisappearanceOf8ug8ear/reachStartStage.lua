-- (c)1dentity - do not copy - there's QuestTemplate available for copying
local QuestStage = require("lib/abstract/QuestStage")
local Nav = require("lib/Nav")
local Lang = require("lib/Lang")

local TIME_LIMIT = 5 * 60
local nameKey = "find_bb"
local descriptionKey = "she_cant_hold_on"

local reachStartStage = QuestStage:new()

function reachStartStage:new(runner)
	return QuestStage.new(reachStartStage, runner, Lang:get(nameKey), Lang:get(descriptionKey))
end

function reachStartStage:start()
	self.time = 0
	self.timeStart = self.time
	self.timeLimit = self.time + TIME_LIMIT
	self.reachedLocation = false

	local startPos = self.runner.Scene.locations["IllBeDam"].waypoints[1].pos
	self.runner.Scene:setup(self.runner.Scene.locations["IllBeDam"])

	self.runner.HUD.QuestMessage(self.name .. ': ' .. self.description)
	GameInstance.GetAudioSystem():Play(CName"ui_jingle_quest_new")

	self.destination = Vector4.new(startPos)
	Nav.clearCustomPin()
	Nav.placeCustomPin(self.destination)
end

function reachStartStage:update(dt)
	self.time = self.time + dt
	if Vector4.Distance(Game.GetPlayer():GetWorldPosition(), self.destination) < 10 then
		self.reachedLocation = true
	end
	self.runner.Scene:update(true)

	local secLeft = math.floor(self.timeLimit - self.time)
	if secLeft < 60 and secLeft ~= 0 then
		if secLeft % 10 == 0 then self.runner.HUD.QuestMessage(string.format(Lang:get("hurry_up_x_left"), secLeft .. "s")) end
	end
end

function reachStartStage:isDone()
	if self.reachedLocation then return true end
	return false
end

function reachStartStage:isLost()
	if not self.runner.Utils.isAlive(Game.GetPlayer()) then
		self.runner.HUD.QuestMessage(Lang:get("you_died"))
		return true
	end

	if self.time > self.timeLimit then
		self.runner.HUD.QuestMessage(Lang:get("bugbear_is_dead"))
		return true
	end
	return false
end

function reachStartStage:cleanup()
end

return reachStartStage

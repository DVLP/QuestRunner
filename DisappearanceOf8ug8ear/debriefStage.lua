-- (c)1dentity - do not copy - there's QuestTemplate available for copying
local QuestStage  = require("lib/abstract/QuestStage")
local Lang = require("lib/Lang")
local Nav = require("lib/Nav")
local Util = require("Util")

local nameKey = "leave"
local descriptionKey = "viktor_must_start_the_procedure"
local TIME_LIMIT = 5 * 60 -- 5 mins

local debriefStage = QuestStage:new()

function debriefStage:new(runner)
	return QuestStage.new(debriefStage, runner, Lang:get(nameKey), Lang:get(descriptionKey))
end

function debriefStage:start()
	self.time = 0
	self.timeStart = self.time
	self.timeLimit = self.time + TIME_LIMIT
	self.leftTheArea = false
	self.bugbearTaken = false

	local pos2 = self.runner.Scene.locations["IllBeDam"].waypoints[2].pos
	self.viktorChair = Vector4.new(pos2.x, pos2.y, pos2.z, pos2.w)
	self.runner.HUD.QuestMessage(self.name .. ': ' .. self.description)
	self.runner.HUD.Warning(Lang:get("dont_touch_bugbear_and_leave"))
	GameInstance.GetAudioSystem():Play(CName"ui_jingle_quest_update")
end

function debriefStage:update(dt)
	self.time = self.time + dt
	if Vector4.Distance(Game.GetPlayer():GetWorldPosition(), self.viktorChair) > 20 then
		self.leftTheArea = true
	end

	if Vector4.Distance(self.bugbear:GetWorldPosition(), self.viktorChair) > 10 then
		self.bugbearTaken = true
	end

	Util.showTimeLeft(self.runner.HUD.QuestMessage, self.timeLimit - self.time)

	self.runner.Scene:update(true)
end

function debriefStage:isDone()
	if self.leftTheArea then return true end
	return false
end

function debriefStage:isLost()
	if self.time > self.timeLimit then
		self.runner.HUD.QuestMessage(Lang:get("bugbear_is_dead"))
		return true
	end
	if self.bugbearTaken then
		self.runner.HUD.QuestMessage(Lang:get("you_shouldve_left_her"))
		return true
	end

	if not self.runner.Utils.isAlive(Game.GetPlayer()) then
		return true
	end
	if IsDefined(self.bugbear) and not self.runner.Utils.isAlive(self.bugbear) then
		self.runner.HUD.QuestMessage(Lang:get("bugbear_is_dead"))
		return true
	end
	return false
end

function debriefStage:cleanup()
end

return debriefStage

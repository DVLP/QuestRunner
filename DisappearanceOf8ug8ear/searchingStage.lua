-- (c)1dentity - do not copy - there's QuestTemplate available for copying
local QuestStage  = require("lib/abstract/QuestStage")
local Nav = require("lib/Nav")
local Lang = require("lib/Lang")
local Util = require("Util")

local nameKey = "shes_down_there"
local descriptionKey = "find_her_and_bring_her_back"
local TIME_LIMIT = 60 * 10

local searchingStage = QuestStage:new()

function searchingStage:new(runner)
	return QuestStage.new(searchingStage, runner, Lang:get(nameKey), Lang:get(descriptionKey))
end

function searchingStage:start()
	self.time = 0
	self.timeStart = self.time
	self.timeLimit = self.time + TIME_LIMIT
	self.reachedLocation = false
	local payloadPos = self.runner.Scene.locations["IllBeDam"].payloads[1].pos
	self.destination = Vector4.new(payloadPos.x, payloadPos.y, payloadPos.z, payloadPos.w)
	self.runner.HUD.QuestMessage(self.name .. ': ' .. self.description)
	GameInstance.GetAudioSystem():Play(CName"ui_jingle_quest_update")

	self.runner.Cron.After(3, function()
		self.runner.Phone.sendMessage("8ug8earNew", Lang:get("BB_hurry_up_netrunners_breaking_in"))
	end)
end

function searchingStage:update(dt)
	self.time = self.time + dt
	if Vector4.Distance(Game.GetPlayer():GetWorldPosition(), self.destination) < 3 then
		self.reachedLocation = true
	end

	Util.showTimeLeft(self.runner.HUD.QuestMessage, self.timeLimit - self.time)

	self.runner.Scene:update(true)
end

function searchingStage:isDone()
	-- prevents moving to the new stage until BB is ready
	if IsDefined(self.bugbear) and self.reachedLocation then return true end
	return false
end

function searchingStage:isLost()
	if self.time > self.timeLimit then
		self.runner.HUD.QuestMessage(Lang:get("bugbear_is_dead"))
		return true
	end
	if IsDefined(self.bugbear) and not self.runner.Utils.isAlive(self.bugbear) then
		self.runner.HUD.QuestMessage(Lang:get("bugbear_is_dead"))
		return true
	end
	return false
end

function searchingStage:cleanup()
end

return searchingStage

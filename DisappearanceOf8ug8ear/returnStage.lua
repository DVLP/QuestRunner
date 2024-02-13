-- (c)1dentity - do not copy - there's QuestTemplate available for copying
local QuestStage  = require("lib/abstract/QuestStage")
local Nav = require("lib/Nav")
local Lang = require("lib/Lang")

local nameKey = "return_bb"
local descriptionKey = "put_her_in_car_take_to_viktor"
local TIME_LIMIT = 15 * 60 -- 15 mins

local returnStage = QuestStage:new()

function returnStage:new(runner)
	return QuestStage.new(returnStage, runner, Lang:get(nameKey), Lang:get(descriptionKey))
end

function returnStage:start()
									--1  2   3   4   5   6   7   8  9   10  11    12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32    33    34    35    36    37    38    39
	self.distanceMessageTriggers = { 2, 11, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 186, 210, 220, 227, 240, 266, 298, 310, 360, 415, 430, 455, 550, 1000, 2500, 2500, 3000, 3500, 4000, 4500, 4750}
	-- 161 - end of walkway
	-- 186 - second walkway start
	-- 210 - square end with welded gate
	self.crashComplainLevels = { "BB_drive_carefully", "BB_that_hurt", "BB_broke_my_spine" }
	self.complainsUsed = {}

	self.currentStoryTrigger = 0

	self.time = 0
	self.damageSustained = 0
	self.timeStart = self.time
	self.timeLimit = self.time + TIME_LIMIT
	self.reachedLocation = false
	self.shownLeaveMessage = false
	self.bbStartPos = self.runner.Scene.locations["IllBeDam"].payloads[1].pos

	self.runner.onVehicleCrash = function(playerVehicle)
		local force = playerVehicle:GetCollisionForce():Length()
		-- one big hit will kill her instantly
		if force > 19 then
			force = 100
			self:crashComplain(3)
		elseif force > 1.5 then
			self:crashComplain(2)
		elseif force > 0.05 then
			self:crashComplain(1)
		end
		self.damageSustained = self.damageSustained + force
	end

	local pos = self.runner.Scene.locations["IllBeDam"].waypoints[2].pos
	self.viktorChairPos = Vector4.new(pos.x, pos.y, pos.z, pos.w)
	self.runner.HUD.QuestMessage(self.name .. ': ' .. self.description)
	GameInstance.GetAudioSystem():Play(CName"ui_jingle_quest_update")

	Nav.clearCustomPin()
	Nav.placeCustomPin(self.viktorChairPos)
end

function returnStage:crashComplain(level)
	if not self.complainsUsed[level] then
		self.runner.Phone.sendMessage("8ug8earNew", Lang:get(self.crashComplainLevels[level]))
		self.complainsUsed[level] = true
	end
end

function returnStage:update(dt)
	-- moving away with BB picked up
	local distanceAway = Vector4.Distance(Game.GetPlayer():GetWorldPosition(), self.bbStartPos)

	local measuringStart = self.currentStoryTrigger + 1
	for i = measuringStart, #self.distanceMessageTriggers do
		if distanceAway > self.distanceMessageTriggers[i] then
			self.currentStoryTrigger = i
			if i > 23 and not self.setToNeutral then
				self.setToNeutral = true
				-- at first we're keeping her attitude as friendly so when she's picked up the first time it's in a nicer manner
				-- we're setting her attitude to neutral so she can be killed(accidentally, hopefully) and the quest can be lost
				self.bugbear:GetAttitudeAgent():SetAttitudeTowards(GetPlayer():GetAttitudeAgent(), EAIAttitude.AIA_Neutral)
			end
			local message = Lang:get("bb_storyline_" .. i)
			self.runner.Phone.sendMessage("8ug8earNew", message)
		end
	end

	-- Approaching Viktor clinic's chair
	if not self.shownLeaveMessage and Vector4.Distance(Game.GetPlayer():GetWorldPosition(), self.viktorChairPos) < 10 then
		self.shownLeaveMessage = true
		self.runner.HUD.QuestMessage(Lang:get("leave_bugbear_on_chair"))
	end

	self.time = self.time + dt
	if self.bugbear and Vector4.Distance(self.bugbear:GetWorldPosition(), self.viktorChairPos) < 1.5 then
		self.reachedLocation = true
	end

	local secLeft = math.floor(self.timeLimit - self.time)
	if secLeft < 60 and secLeft ~= 0 then
		if secLeft % 10 == 0 then self.runner.HUD.QuestMessage(string.format(Lang:get("hurry_up_x_left"), secLeft .. "s")) end
	end

	self.runner.Scene:update(true)
end

function returnStage:isDone()
	if self.reachedLocation then return true end
	return false
end

function returnStage:isLost()
	if self.damageSustained >= 50 then
		self.runner.HUD.Warning(Lang:get("bugbear_is_dead_in_trunk"))
		return true
	end
	if not self.runner.Utils.isAlive(Game.GetPlayer()) then
		self.runner.HUD.QuestMessage(Lang:get("you_died"))
		return true
	end
	if not self.bugbear or not self.runner.Utils.isAlive(self.bugbear) then
		Game.GetPreventionSpawnSystem():RequestDespawn(self.bugbear:GetEntityID())
		self.runner.HUD.QuestMessage(Lang:get("bugbear_is_dead"))
		return true
	end
	if self.time > self.timeLimit then
		self.runner.HUD.QuestMessage(Lang:get("bugbear_is_dead"))
		return true
	end
	return false
end

function returnStage:cleanup()
	self.runner.onVehicleCrash = nil
end

return returnStage

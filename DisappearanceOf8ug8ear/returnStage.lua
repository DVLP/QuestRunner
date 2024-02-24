-- (c)1dentity - do not copy - there's QuestTemplate available for copying
local QuestStage  = require("lib/abstract/QuestStage")
local Nav = require("lib/Nav")
local Lang = require("lib/Lang")
local Util = require("Util")

local nameKey = "return_bb"
local descriptionKey = "put_her_in_car_take_to_viktor"
local TIME_LIMIT = 15 * 60 -- 15 mins

local returnStage = QuestStage:new()

function returnStage:new(runner)
	return QuestStage.new(returnStage, runner, Lang:get(nameKey), Lang:get(descriptionKey))
end

function returnStage:start()
									--1  2   3   4   5   6   7   8  9   10  11    12   13   14   15   16   17   18   19   20   21   22   23   24   25   26   27   28   29   30   31   32    33    34    35    36    37    38    39
	self.distanceMessageTriggers = { 2, 11, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 186, 210, 220, 227, 240, 266, 298, 310, 360, 415, 430, 455, 550, 1000, 2500, 2500, 3000, 3500, 4000, 4500, 4830}
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
		elseif force > 0.001 then
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
	local playerPos = GetPlayer():GetWorldPosition()
	local distanceAway = Vector4.Distance(playerPos, self.bbStartPos)

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
	if not self.shownLeaveMessage and Vector4.Distance(playerPos, self.viktorChairPos) < 10 then
		self.shownLeaveMessage = true
		self.runner.HUD.QuestMessage(Lang:get("leave_bugbear_on_chair"))

		-- Illuminate Viktor's surgery chair
		-- check for lighting support and add chair spotlight and underglow
		if self.runner.Lighting then
			-- Spotlight
			self.runner.Lighting.AddSpotlight(Vector4.new(-1546.3228, 1235.1268, 14.410301, 1), EulerAngles.new(0, -90, 0), 3, Color.new({Red = 100, Green = 100, Blue = 100}), 10, 45)
			-- Underglow
			self.runner.Lighting.AddSpotlight(Vector4.new(-1546.3679, 1235.0557, 11.410301, 1), EulerAngles.new(0, 90, 0), 0.5, Color.new({Red = 255, Green = 6, Blue = 181}), 100, 130)
		end
	end

	if not self.shownPlace8ug8ear and Vector4.Distance(playerPos, self.viktorChairPos) < 0.9 then
		self.shownPlace8ug8ear = true
		local options = {
			{ text = "Place 8ug8ear", icon = self.runner.selector.JACK_IN_ICON }
		}
		self.runner.selector.create("Surgical chair", options, function(id)
			local psmEvent = PSMPostponedParameterBool.new()
		    psmEvent.id = CName"forceDropBody"
		    psmEvent.value = true
		    GetPlayer():QueueEvent(psmEvent)
		    -- Removing Unconscious should prevent from picking her up again but it doesn't
		    -- StatusEffectHelper.RemoveStatusEffect(self.bugbear, TweakDBID.new("BaseStatusEffect.Unconscious"), self.bugbear:GetEntityID())
	    	self.runner.Cron.After(0.1, function()
	    		self.bugbear:SetDisableRagdoll(true, true)
	    		local posOnChair = Vector4.new(-1546.95, 1234.28, 11.492, 1)
				local rotOnChair = 147.213
				self.runner.Cron.After(3, function()
					self.delivered8ug8ear = true
				end)
				self.runner.Spawner.MoveNPC(self.bugbear, posOnChair, rotOnChair, function()
					self.runner.Spawner.PlayAnimationOnTarget(self.bugbear, "alt__lie_netrunner_chair__dead__01", nil, function()
						-- prevent somehow picking her up again
						-- ApplyStatus(self.bugbear, "BaseStatusEffect.NonInteractable")
					end)
				end)
			end)
			self.runner.selector.hideHub()
		end)
	end

	if self.shownPlace8ug8ear and Vector4.Distance(playerPos, self.viktorChairPos) > 1 then
		self.shownPlace8ug8ear = false
		self.runner.selector.hideHub()
	end

	if not self.backToFriendly and Vector4.Distance(playerPos, self.viktorChairPos) < 50 then
		self.backToFriendly = true
		-- changing her attitude back to friendly(when close to Viktor's) to carry her from the trunk in a civilised manner
		self.bugbear:GetAttitudeAgent():SetAttitudeTowards(GetPlayer():GetAttitudeAgent(), EAIAttitude.AIA_Friendly)
	end

	self.time = self.time + dt

	Util.showTimeLeft(self.runner.HUD.QuestMessage, self.timeLimit - self.time)

	self.runner.Scene:update(true)
end

function returnStage:isDone()
	if self.delivered8ug8ear then
		return true
	end
	return false
end

function returnStage:isLost()
	if self.damageSustained >= 50 then
		self.runner.HUD.Warning(Lang:get("bugbear_is_dead_in_trunk"))
		return true
	end
	if not self.runner.Utils.isAlive(GetPlayer()) then
		self.runner.HUD.QuestMessage(Lang:get("you_died"))
		return true
	end
	if IsDefined(self.bugbear) and not self.runner.Utils.isAlive(self.bugbear) then
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

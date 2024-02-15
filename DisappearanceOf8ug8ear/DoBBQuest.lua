-- (c)identity - do not copy - there's QuestTemplate available for copying
local Lang = require("lib/Lang")
local Quest = require("lib/abstract/Quest")

-- quest stages
local ReachStartStage = require("reachStartStage")
local SearchingStage = require("searchingStage")
local ReturnStage = require("returnStage")
local DebriefStage = require("debriefStage")

local Locations = require("Locations")
local log, error, trace = table.unpack(require("lib/Log"))

local nameKey = "disappearance_of_bb"
local descriptionKey = "netrunners_kidnapped_bb"
local finishedFact = "qr_disappearance_of_8ug8ear_finished"
local failedFact = "qr_disappearance_of_8ug8ear_failed"
local level = 55

local DoBBQuest = Quest:new()
-- static function to get the name before instantiation
function DoBBQuest.getLocalizedNameSTATIC() return Lang:get(nameKey) end

function DoBBQuest:new(runner)
	return Quest.new(DoBBQuest, runner, Lang:get(nameKey), Lang:get(descriptionKey), level)
end

function DoBBQuest:start()
	self:addStage(ReachStartStage:new(self.runner))
	self:addStage(SearchingStage:new(self.runner))
	self:addStage(ReturnStage:new(self.runner))
	self:addStage(DebriefStage:new(self.runner))
	self.inCombat = false

	-- once in combat
	self.isInCombatTimerId = self.runner.Cron.Every(1, function ()
		if GetPlayer():IsInCombat() then
			self.inCombat = true
		end
		self:addBBNumberIfClose(true)
	end)

	self.bugbear = nil
	self.runner.Scene.onEnemySpawn = function(spawnedObject)
		-- make enemies aggressive like in a hostile area
		spawnedObject:GetAttitudeAgent():SetAttitudeTowards(GetPlayer():GetAttitudeAgent(), EAIAttitude.AIA_Hostile)

		-- always in combat
		if self.inCombat then
			local reactionComp = spawnedObject.reactionComponent
			reactionComp:SetReactionPreset(TweakDBInterface.GetReactionPresetRecord(TweakDBID.new("ReactionPresets.Ganger_Aggressive")))
			reactionComp:TriggerCombat(GetPlayer())
		end
	end

	self:RequestSpawnBB()

	self.runner.jumboText.show(self.name, 55, true)
	self.runner.Cron.After(3, function ()
		self.runner.HUD.QuestMessage(self.description)
	end)

	self.runner.Cron.After(6, function ()
		self:nextStage()
	end)
end

function DoBBQuest:RequestSpawnBB()
	local bbSpawnConfig = self.runner.Scene.locations["IllBeDam"].npcs[1]
	self.bbSpawnPos = bbSpawnConfig.pos
	self:SpawnBugBearWhenReady()
end

function DoBBQuest:SpawnBugBearWhenReady()
	if not self.runner.Spawner.CanSpawn(Game.GetPlayer():GetWorldPosition(), self.bbSpawnPos, 60) then
		self.retrySpawnBBTimerId = self.runner.Cron.After(2, function ()
			self:SpawnBugBearWhenReady()
		end)
		return
	end
	if self.bugbearSpawnRequested then return end
	self.bugbearSpawnRequested = true
	self.runner.Spawner.SpawnNPCWithRetry(TweakDBID.new(0x5F7049F1, 0x1F), self.bbSpawnPos, self.bbSpawnPos.w, false, function(spawnedObject)
		-- Warning - this should also trigger on respawn
		self.bugbear = spawnedObject
		self.stages[1].bugbear = self.bugbear
		self.stages[2].bugbear = self.bugbear
		self.stages[3].bugbear = self.bugbear
		self.stages[4].bugbear = self.bugbear
		StatusEffectHelper.ApplyStatusEffect(spawnedObject, TweakDBID.new("BaseStatusEffect.Unconscious"), spawnedObject:GetEntityID())
	end, 999)
end

function DoBBQuest:isDoable()
	-- only if not on a QR mission
	if self.runner.Manager.current ~= nil then return false end

	-- if the quest was finished or failed it cannot be started again
	if Game.GetQuestsSystem():GetFactStr(finishedFact) == 1 or Game.GetQuestsSystem():GetFactStr(failedFact) == 1 then return false end
	-- not available until first mission was completed
	if Game.GetQuestsSystem():GetFactStr("q001_done") == 0 then return false end
	-- not available before Getting Warmer mission or if 8ug8ear was killed in it
	if Game.GetQuestsSystem():GetFactStr("rey_09_finished") == 0 or Game.GetQuestsSystem():GetFactStr("rey_09_target_died") == 1 then return false end
	return true
end

function DoBBQuest:success()
	GameInstance.GetAudioSystem():Play(CName"ui_jingle_quest_success")
	self.runner.Utils.giveXP(tonumber(1000))
	self.runner.Utils.giveStreetCred(tonumber(1000))
	Game.AddToInventory("Items.money", tonumber(5000))
	self.runner.HUD.QuestMessage(Lang:get("quest_success"))
	Game.GetQuestsSystem():SetFactStr(finishedFact, 1)
end

function DoBBQuest:failure()
	GameInstance.GetAudioSystem():Play(CName"ui_jingle_quest_failed")
	Game.GetQuestsSystem():SetFactStr(failedFact, 1)
end

function DoBBQuest:cleanup()
	self.runner.Cron.Halt(self.isInCombatTimerId)
	self.runner.Cron.Halt(self.retrySpawnBBTimerId)
	self.runner.Spawner.Despawn(self.bugbear)
end

function DoBBQuest:phonecallResponseOptions()
	-- For available icons see QuestRunner/lib/ui_icons.jpg
	local options = {
		{ text = Lang:get("im_on_my_way"), icon = self.runner.selector.CLOCK_ICON }
	}
	self.runner.selector.create("8ug8earNew", options, function(id)
		self.runner.Manager:setCurrent(DoBBQuest:new(self.runner, self.name, self.description, level))
		self.runner.selector.hideHub()
	end)
	self.runner.Cron.After(5, function() self.runner.selector.hideHub() end)
end

function DoBBQuest:setupTrigger()
	if not self:isDoable() then return end

	if not self.locationsAdded then
		for i = 1, #Locations do self.runner.Scene:addLocation(Locations[i]) end
		self.locationsAdded = true
	end

	self:sendDistressMessages()
	self:addBBNumberIfClose()
end

function DoBBQuest:sendDistressMessages()
	if self.distressMessageSent then return end
	self.distressMessageSent = true

	self.runner.Cron.After(3, function ()
		-- TODO: Move Phone to singleton
		local fixerId = self.runner.rootFixerId
		local fixerLocalizedName = self.runner.Lang:get(fixerId)
		self.runner.Phone.addContact(fixerId, fixerLocalizedName, "")
		self.runner.Phone.setContactProperty(fixerId, "isCallable", true)
		self.runner.Phone.sendMessage(fixerId, Lang:get("fx_dead_man_switch_message"))
		self.runner.Phone.sendMessage(fixerId, Lang:get("fx_dead_man_switch_message_2"))
		self.runner.Phone.sendMessage(fixerId, Lang:get("fx_bb_distress_call"))
		self.runner.Phone.sendMessage(fixerId, Lang:get("fx_bb_distress_call_2"))
		self.runner.Phone.sendMessage(fixerId, Lang:get("fx_bb_distress_call_3"))
		self.runner.Phone.RegisterCallCallback(fixerId, function()
			if self:isDoable() then
				self:phonecallResponseOptions()
				return true
			else
				return false
			end
		end)
	end)
end

function DoBBQuest:addBBNumberIfClose(questStarted)
	local nameKey = "8ug8earNew"
	if self.runner.Phone.getContact(nameKey) then return end
	if Vector4.Distance(GetPlayer():GetWorldPosition(), self.runner.Scene.locations["IllBeDam"].waypoints[1].pos) > 400 then return end

	local localizedName = Lang:get("bb_new_contact")
	local isNew = self.runner.Phone.addContact(nameKey, localizedName, Lang:get("bb_new_contact_second_line"))
	self.runner.Phone.setContactProperty(nameKey, "questRelated", true)

	if isNew then
		self.runner.Phone.showNewContactNotification("", localizedName, 7)
	end
	self.runner.Cron.After(3, function()
		if not questStarted then
			self.runner.Phone.sendMessage(nameKey, Lang:get("bb_call_me_for_coordinates"))
			self.runner.Phone.setContactProperty(nameKey, "isCallable", true)
			self.runner.Phone.RegisterCallCallback(nameKey, function()
				if self:isDoable() then
					self:phonecallResponseOptions()
					return true
				else
					return false
				end
			end)
		else
			self.runner.Phone.sendMessage(nameKey, Lang:get("bb_im_at_bottom_of_dam"))
		end
	end)
end

return DoBBQuest

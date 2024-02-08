-- (c)1dentity - the template is free to use, modify and publish
local Lang = require("lib/Lang")
local Quest = require("lib/abstract/Quest")
local log, error, trace = table.unpack(require("lib/Log"))
local Locations = require("Locations")

-- quest stages
local ReachDestinationStage = require("reachDestinationStage")

local name = Lang:get("mrguy_quest")
local description = Lang:get("mrguy_quest_description")
local level = 55

local MrGuyQuest = Quest:new()
MrGuyQuest.name = name

function MrGuyQuest:new(runner)
	return Quest.new(MrGuyQuest, runner, name, description, level)
end

function MrGuyQuest:start()
	for i = 1, #Locations do self.runner.Scene:addLocation(Locations[i]) end

	-- add multiple quest stages here
	self:addStage(ReachDestinationStage:new(self.runner))

	self.runner.Scene.onEnemySpawn = function(spawnedObject)
		-- make enemies aggressive like in a hostile area
		spawnedObject:GetAttitudeAgent():SetAttitudeTowards(GetPlayer():GetAttitudeAgent(), EAIAttitude.AIA_Hostile)
	end

	self.runner.jumboText.show(self.name, 55, true)
	self.runner.Cron.After(1, function ()
		self.runner.HUD.QuestMessage(self.description)
	end)

	self.runner.Cron.After(4, function ()
		self:nextStage()
	end)
end

function MrGuyQuest:isDoable()
	-- conditions to allow doing the quest i.e. checking a fact and returning false if not met
	-- i.e. not available until the first game quest is finished 
	if Game.GetQuestsSystem():GetFactStr("q001_done") == 0 then return false end
	return true
end

function MrGuyQuest:success()
	GameInstance.GetAudioSystem():Play(CName"ui_jingle_quest_success")
	-- give some rewards
	self.runner.Utils.giveXP(tonumber(1000))
	self.runner.Utils.giveStreetCred(tonumber(1000))
	Game.AddToInventory("Items.money", tonumber(5000))
	self.runner.HUD.QuestMessage(Lang:get("quest_success"))
end

function MrGuyQuest:failure()
	GameInstance.GetAudioSystem():Play(CName"ui_jingle_quest_failed")
end

function MrGuyQuest:phonecallResponseOptions()
	local options = {
		{ text = Lang:get("im_on_my_way"), icon = self.runner.selector.CLOCK_ICON },
		{ text = Lang:get("maybe_another_time"), icon = self.runner.selector.NONE_ICON },		
	}
	self.runner.selector.create("mrGuy", options, function(id)
		if id == 0 then
			-- if chosen 1, start the quest
			self.runner.Manager:setCurrent(MrGuyQuest:new(self.runner, name, description, level))
		end
		self.runner.selector.hideHub()
	end)
	self.runner.Cron.After(5, function() self.runner.selector.hideHub() end)
end

function MrGuyQuest:setupTrigger()
	if self.triggerSet or not self:isDoable() then return end
	self.triggerSet = true

	local nameKey = "mrGuy"
	local localizedName = Lang:get("mission_contact")
	local isNew = self.runner.Phone.addContact(nameKey, localizedName, Lang:get("mission_contact_second_line"))
	self.runner.Phone.setContactProperty(nameKey, "questRelated", true)

	if isNew then
		self.runner.Cron.After(12, function() self.runner.Phone.showNewContactNotification("", localizedName, 7) end)
	end
	self.runner.Cron.After(5, function()
		self.runner.Phone.sendMessage(nameKey, Lang:get("mrguy_quest_request_message"))
	end)

	self.runner.Phone.setContactProperty(nameKey, "isCallable", true)
	self.runner.Phone.RegisterCallCallback(nameKey, function()
		self:phonecallResponseOptions()
		return true
	end)
end

return MrGuyQuest

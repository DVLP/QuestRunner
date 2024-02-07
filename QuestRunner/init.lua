local GameUI = require("lib/GameUI")
local GameSettings = require("lib/GameSettings")
local Lang = require("module/Lang")
-- local Panopticon = require("module/Panopticon")
local Manager = require("module/Manager")
local selector = require("lib/interactionUI")
local HUD = require("module/HUD")
local log, errorLog, trace, Logger = table.unpack(require("module/Log"))
local jumboText = require("lib/Subtitle")
local ui = require("lib/interactionUI")
local Cron = require("lib/Cron")
local Scene = require("module/Scene")
local Phone = require("module/Phone")
local Spawner = require("module/Spawner")
local Utils = require("module/Utils")

local Runner = {
	version = "0.0.1",
	debugLevel = "error",
	allQuestsContact = false,
	locale = "en-us",
	isReady = false,
	rootFixerId = "1dentity",
	gameState = {
		inMenu = false,
		inGame = false,
		inCET = false,
		timeDilation = false,
	},
}

Logger.setLevel(Runner.debugLevel)

function Runner.resetState()
	Runner.gameState = {
		inMenu = false,
		inGame = false,
		inCET = false,
		timeDilation = false,
	}
end

Runner.Cron = Cron
Runner.Manager = Manager
Manager.runner = Runner
Runner.Spawner = Spawner
Runner.Phone = Phone
Runner.ui = ui
Runner.Scene = Scene
Runner.Lang = Lang
Runner.Utils = Utils
Runner.selector = selector
Runner.jumboText = jumboText
Runner.HUD = HUD

local onReadyCallbacks = {}
function Runner.onReady(callback)
	if Runner.isReady then return callback() end
	table.insert(onReadyCallbacks, callback)
end
registerForEvent("onInit", function()
	if not GetPlayer() then
		log("QuestRunner:onInit: Not in game")
		return
	end
	GameUI.Listen(function(state)
		local event = state.event
		local inMenu = Runner.Utils.isInMenu(event)
		if inMenu ~= nil then Runner.gameState.inMenu = inMenu end

		if state.menu == "DeathMenu" or event == "SessionEnd" or event == "LoadingFinish" then
			Runner.resetState()
		end
	end)

	GameUI.OnSessionStart(function() Runner.gameState.inGame = true end)
	GameUI.OnSessionEnd(function() Runner.gameState.inGame = false end)

	ObserveAfter('TimeDilationEventsTransitions', 'OnEnter', function(this) Runner.gameState.timeDilation = true end)
	ObserveAfter('TimeDilationEventsTransitions', 'OnExit', function(this) Runner.gameState.timeDilation = false end)

	Observe("vehicleUIGameController", "OnVehicleCollision", function(this)
		if Runner.onVehicleCrash then
			local vehicle = GetMountedVehicle(Game.GetPlayer())
			if vehicle then
				Runner.onVehicleCrash(vehicle)
			end
		end
	end)

	-- Panopticon:initialize()
	Runner.locale = tostring(NameToString(GameSettings.Get("/language/OnScreen")))
	Lang:init(Runner.locale)

	ui.init()
	Scene:init()
	jumboText.init()
	Phone.init()
	Spawner.init()

	-- readd phone contact after mod reload
	Runner.gameState.inGame = not GameUI.IsDetached()
	Runner.isReady = true

	for i = 1, #onReadyCallbacks do
		onReadyCallbacks[i]()
	end
	onReadyCallbacks = {}
end)

registerForEvent("onUpdate", function(dt)
	if Runner.gameState.inMenu or not Runner.gameState.inGame or not Runner.isReady then return end
	Cron.Update(dt)
	ui.update()
	Manager:update(dt)

	if Runner.debounce then return end
	Runner.debounce = true
	Cron.After(0.1, function() Runner.debounce = false end)

	if Runner.gameState.inGame and not Runner.mainContactAdded then
		Runner.mainContactAdded = true
		Runner.addPhoneContacts()
	end

	jumboText.update()
end)

registerForEvent("onOverlayOpen", function() Runner.gameState.inCET = true end)
registerForEvent("onOverlayClose", function() Runner.gameState.inCET = false end)

-- for development of dependent quests
function Runner.overrideLogLevel(level)
	Logger.setLevel(level)
end

function Runner.addPhoneContacts()
	-- Debug phone contact with access to all quests
	if Runner.allQuestsContact then
		if Game.GetQuestsSystem():GetFactStr("q001_done") == 0 then
			Cron.After(5, function() Runner.addPhoneContacts() end)
			return
		end
		local nameId = Runner.rootFixerId
		local localizedName = Lang:get(nameId)
		local isNew = Phone.addContact(nameId, localizedName, Lang:get("contactSubtitle"))
		Phone.setContactProperty(nameId, "questRelated", true)
		if isNew then
			Cron.After(10, function() Phone.showNewContactNotification("", localizedName, 7) end)
			Cron.After(5, function()
				Phone.sendMessage(nameId, Lang:get("welcomeMessage"))
			end)
		else
			-- TODO: send a random reminder message
		end

		Phone.setContactProperty(nameId, "isCallable", true)
		Phone.RegisterCallCallback(nameId, function()
			Manager:getQuestOptions()
			return true
		end)
	end
end

return Runner

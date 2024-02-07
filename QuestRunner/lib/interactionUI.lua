local HUD = require("module/HUD")
-- https://www.nexusmods.com/cyberpunk2077/articles/413
-- Modified by 1dentity - free to use

local ui = {
	baseControler = nil,
	hub = nil,
	callback = nil,
	hubShown = false,
	selectedIndex = 0,
	input = false,
}

function ui.showBasic(title, text, callback)
	ui.create(title, {{ text = text, icon = ui.COURIER_ICON, type = ui.TYPE_IMPORTANT }}, callback)
end

function ui.create(title, options, callback)
	ui.hideHub()
	local choices = {}
	for i, option in ipairs(options) do
		table.insert(choices, ui.createChoice(option.text, option.icon, option.type))
	end
	local hub = ui.createHub(title, choices)
	ui.callback = callback
	ui.showHub(hub)
	-- impose NoCombat restriction - this may be not enough
	PlayerGameplayRestrictions.PushForceRefreshInputHintsEventToPSM(Game.GetPlayer())
end

---@param localizedName string
---@param icon gamedataChoiceCaptionIconPart_Record
---@param choiceType gameinteractionsChoiceType
---@return gameinteractionsvisListChoiceData
function ui.createChoice(localizedName, icon, choiceType) -- Creates and returns a choice
	local choice = gameinteractionsvisListChoiceData.new()
	choice.localizedName = localizedName or "Choice"
	choice.inputActionName = "None"

	if icon then
		local part = gameinteractionsChoiceCaption.new()
		part:AddPartFromRecord(icon)
		choice.captionParts = part
	end

	if choiceType then
		local choiceT = gameinteractionsChoiceTypeWrapper.new()
		choiceT:SetType(choiceType)
		choice.type = choiceT
	end

	return choice
end

---@param title string
---@param choices table
---@param activityState gameinteractionsvisEVisualizerActivityState
---@return gameinteractionsvisListChoiceHubData
function ui.createHub(title, choices, activityState) -- Creates and returns a hub
	local hub = gameinteractionsvisListChoiceHubData.new()
	hub.title = title or "Title"
	hub.choices = choices or {}
	hub.activityState = activityState or gameinteractionsvisEVisualizerActivityState.Active
	hub.hubPriority = 1
	hub.id = 69420 + math.random(99999)

	return hub
end

function ui.showHub(hub)
	if not ui.baseControler then
		print("ERROR: No baseControler. After modules reload press Esc twice (open/close menu) to fix it")
		HUD.Warning("ERROR: No baseControler. After modules reload press Esc twice (open/close menu) to fix it")
		HUD.QuestMessage("Press Esc twice and try again")
		return
	end
	ui.hub = hub
	local data = DialogChoiceHubs.new()
	data.choiceHubs = { hub }

	ui.baseControler.AreDialogsOpen = #data.choiceHubs > 0
	ui.baseControler.dialogIsScrollable = #data.choiceHubs > 1

	ui.baseControler:OnDialogsSelectIndex(0)
	ui.baseControler:UpdateDialogsData(data)
	ui.baseControler:OnInteractionsChanged()
	ui.baseControler:UpdateListBlackboard()
	ui.baseControler:OnDialogsActivateHub(hub.id)

	ui.hubShown = true
	ui.selectedIndex = 0
	PlayerGameplayRestrictions.PushForceRefreshInputHintsEventToPSM(Game.GetPlayer())
end

function ui.hideHub() -- Hides the hub
	if not ui.hub or not ui.baseControler then return end

	local data = DialogChoiceHubs.new()
	ui.baseControler:UpdateDialogsData(data)
	ui.baseControler:OnInteractionsChanged()
	ui.baseControler:UpdateListBlackboard()

	ui.hubShown = false
	PlayerGameplayRestrictions.RemoveAllGameplayRestrictions(Game.GetPlayer())
end

-- function ui.registerChoiceCallback(choiceIndex, callback) -- Register a callback for a choice via index, starting at 1
--	 ui.callbacks[choiceIndex] = callback
-- end

function ui.clearCallbacks() -- Remove all callbacks
	ui.callback = nil
end

function ui.setConsts()
	ui.TYPE_IMPORTANT = gameinteractionsChoiceType.QuestImportant
	ui.TYPE_INACTIVE = gameinteractionsChoiceType.Inactive

	ui.COURIER_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.CourierIcon")
	ui.CLOCK_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.WaitIcon")
	ui.FRAGILE_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.LootIcon")
	ui.ACTION_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.ActionIcon")
	ui.TAKE_CONTROL_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.TakeControl")
	ui.CHANGE_TO_FRIENDLY_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.ChangeToFriendlyIcon")
	ui.JACK_IN_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.JackInIcon")
	ui.USE_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.UseIcon")
	ui.ON_OFF_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.OnOff")
	ui.DISTRACT_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.DistractIcon")
	ui.AIM_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.Aim")
	ui.OPEN_VENDOR_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.OpenVendorIcon") -- eurodollar sign
	ui.PHONE_CALL_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.PhoneCall") -- empty space (aligns with others)
	ui.NONE_ICON = TweakDBInterface.GetChoiceCaptionIconPartRecord("ChoiceCaptionParts.None") -- no icon - no empty space
end

-- Register needed observers
function ui.init()
	ui.setConsts()
	Observe("InteractionUIBase", "OnInitialize", function(this) ui.baseControler = this end)
	Observe("InteractionUIBase", "OnInteractionsChanged", function(this) ui.baseControler = this end)
	Observe("InteractionUIBase", "OnDialogsData", function(this) ui.baseControler = this end)
	-- Look at any item to trigger this hook i.e. a dropped gun
	ObserveAfter('InteractionUIBase', 'OnLootingData', function(this) ui.baseControler = this end)
	-- After reloading mods press Esc twice and voila, baseControler is available again
	ObserveBefore("dialogWidgetGameController", "OnMenuVisibilityChange", function(this) ui.baseControler = this end)

	Observe('PlayerPuppet', 'OnAction', function(_, action)
		if ui.input or not ui.hubShown then return end
		local actionName = Game.NameToString(action:GetName(action))
		local actionType = action:GetType(action).value

		if actionName == 'ChoiceScrollUp' then
			if actionType == 'BUTTON_PRESSED' then
				ui.selectedIndex = ui.selectedIndex - 1
				if ui.selectedIndex < 0 then
					ui.selectedIndex = #ui.hub.choices - 1
				end
				ui.input = true
			end
		elseif actionName == 'ChoiceScrollDown' then
			if actionType == 'BUTTON_PRESSED' then
				ui.selectedIndex = ui.selectedIndex + 1
				if ui.selectedIndex > #ui.hub.choices - 1 then
					ui.selectedIndex = 0
				end
				ui.input = true
			end
		elseif actionName == 'ChoiceApply' then
			if actionType == 'BUTTON_PRESSED' then
				-- if ui.callbacks[ui.selectedIndex + 1] then
				--	 ui.callbacks[ui.selectedIndex + 1](ui.selectedIndex)
				-- end
				ui.callback(ui.selectedIndex)
				ui.input = true
			end
		end
	end)

	Override("InteractionUIBase", "OnDialogsSelectIndex", function(_, idx, wrapped) -- Avoid index getting set by game
		if ui.hubShown then
			if idx ~= ui.selectedIndex then
				return
			end
		end
		wrapped(idx)
	end)

	Override("InteractionUIBase", "OnDialogsData",
		function(_, value, wrapped) -- Avoid interaction getting overriden by game
			if ui.hubShown then return end
			wrapped(value)
		end)

	Override("dialogWidgetGameController", "OnDialogsActivateHub",
		function(_, id, wrapped) -- Avoid interaction getting overriden by game
			if ui.hubShown and id ~= ui.hub.id then return end
			wrapped(id)
		end)
end

function ui.update() -- Run every frame to avoid unwanted changes
	if ui.hubShown then
		Game.GetBlackboardSystem():Get(GetAllBlackboardDefs().UIInteractions):SetInt(GetAllBlackboardDefs().UIInteractions.SelectedIndex, ui.selectedIndex)
	end
	ui.input = false -- Avoid double input
end

return ui

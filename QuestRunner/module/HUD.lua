function QuestMessage(text, time, isWarning)
	if text == nil or text == "" then return end

	local message = SimpleScreenMessage.new()
	message.message = text
	message.isShown = true
	message.duration = time and time or 5.00 -- warning type won't disappear at all without duration provided

	local blackboardDefs = Game.GetAllBlackboardDefs()
	local blackboardUI = Game.GetBlackboardSystem():Get(blackboardDefs.UI_Notifications)
	local type = isWarning and blackboardDefs.UI_Notifications.WarningMessage or blackboardDefs.UI_Notifications.OnscreenMessage
	blackboardUI:SetVariant(type, ToVariant(message), true)
end

function Warning(text, time)
	QuestMessage(text, time, true)
end

return { QuestMessage = QuestMessage, Warning = Warning }

local Utils = {}

function Utils.isAlive(player)
	local health = Game.GetStatPoolsSystem():GetStatPoolValue(player:GetEntityID(), gamedataStatPoolType.Health, false)
	return health ~= 0
end

function Utils.giveXP(amount)
	DS = PlayerDevelopmentSystem.GetInstance(Game.GetPlayer()):GetDevelopmentData(Game.GetPlayer());
	DS:AddExperience(amount, gamedataProficiencyType.Level, telemetryLevelGainReason.Gameplay);
end

function Utils.giveStreetCred(amount)
	DS = PlayerDevelopmentSystem.GetInstance(Game.GetPlayer()):GetDevelopmentData(Game.GetPlayer());
	DS:AddExperience(amount, gamedataProficiencyType.StreetCred, telemetryLevelGainReason.Gameplay);
end

local menuStartEventList = {
	ScannerOpen = true, MenuOpen = true, PhotoModeOpen = true, PopupOpen = true, QuickHackOpen = true, ShardOpen = true, WheelOpen = true,
	TutorialOpen = true, LoadingStart = true, CyberspaceEnter = true, BraindancePlay = true, BraindanceEdit = true
}

local menuEndEventList = {
	ScannerClose = true, MenuClose = true, PhotoModeClose = true, PopupClose = true, QuickHackClose = true, ShardClose = true, WheelClose = true,
	TutorialClose = true, LoadingFinish = true, CyberspaceExit = true, CyberspaceEnter = true, BraindanceExit = true
}

function Utils.isInMenu(eventName)
	if menuStartEventList[eventName] then return true end
	if menuEndEventList[eventName] then return false end
	return nil
end

return Utils

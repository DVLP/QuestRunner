-- (c)1dentity - do not copy - there's QuestTemplate available for copying
local Lang = require("lib/Lang")
local DoBBQuest = require("DoBBQuest")
local log, errorLog, trace, Logger = table.unpack(require("lib/Log"))

local DoBB = {
	version = "0.3.0",
	debug = false,
}

registerForEvent("onInit", function()
	Lang:autoLocaleSet()
	local QuestRunner = GetMod("QuestRunner")
	-- Logger.setLevel("trace")
	-- QuestRunner.overrideLogLevel("trace") -- setting logging level of QuestRunner - use for development only

	QuestRunner.onReady(function ()
		DoBBQuest.icon = QuestRunner.selector.JACK_IN_ICON
	end)

	if QuestRunner.onGameStart == nil then
		errorLog("Outdated version of Quest Runner dependency detected. onGameStart not supported!")
		return
	end

	QuestRunner.onGameStart(function ()
		QuestRunner.Manager:addQuest(DoBBQuest)
	end)
end)

return DoBB

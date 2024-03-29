local Lang = require("lib/Lang")
local MrGuyQuest = require("MrGuyQuest")
local log, errorLog, trace, Logger = table.unpack(require("lib/Log"))

local QuestTemplate = {
	version = "0.3.11",
	debug = true,
}

registerForEvent("onInit", function()
	Lang:autoLocaleSet()
	local QuestRunner = GetMod("QuestRunner")
	-- Logging level should only be increased during development. In production should be default (error)
	-- Logger.setLevel("trace") -- more verbose logging, there's also debug
	-- QuestRunner.overrideLogLevel("trace") -- setting logging level of QuestRunner

	QuestRunner.onReady(function ()
		Lang:addExternalLang(QuestRunner.Lang)
		-- For available icons see QuestRunner/lib/ui_icons.jpg
		MrGuyQuest.icon = QuestRunner.selector.CLOCK_ICON
	end)

	QuestRunner.onGameStart(function ()
		QuestRunner.Manager:addQuest(MrGuyQuest)
	end)
end)

return QuestTemplate

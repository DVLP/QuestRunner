local Lang = require("lib/Lang")
Lang:autoLocaleSet()
local MrGuyQuest = require("MrGuyQuest")
local log, errorLog, trace, Logger = table.unpack(require("lib/Log"))

local QuestTemplate = {
	version = "0.0.1",
	debug = true,
	locale = Lang.locale,
}

registerForEvent("onInit", function()
	Lang:setLocale(QuestTemplate.locale)
	local QuestRunner = GetMod("QuestRunner")
	Logger.setLevel("trace")
	QuestRunner.overrideLogLevel("trace") -- setting logging level of QuestRunner - use for development only

	QuestRunner.onReady(function ()
		-- For available icons see QuestRunner/lib/ui_icons.jpg
		MrGuyQuest.icon = QuestRunner.selector.CLOCK_ICON
		QuestRunner.Manager:addQuest(MrGuyQuest)
	end)
end)

return QuestTemplate

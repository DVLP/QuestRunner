-- (c)1dentity - do not copy - there's QuestTemplate available for copying
local Lang = require("lib/Lang")
Lang:autoLocaleSet()
local DoBBQuest = require("DoBBQuest")
local log, errorLog, trace, Logger = table.unpack(require("lib/Log"))

local DoBB = {
	version = "0.0.5",
	debug = false,
	locale = Lang.locale
}

registerForEvent("onInit", function()
	local QuestRunner = GetMod("QuestRunner")
	Logger.setLevel("error")
	-- QuestRunner.overrideLogLevel("trace") -- setting logging level of QuestRunner - use for development only

	QuestRunner.onReady(function ()
		DoBBQuest.icon = QuestRunner.selector.JACK_IN_ICON
		QuestRunner.Manager:addQuest(DoBBQuest)
	end)
end)

return DoBB

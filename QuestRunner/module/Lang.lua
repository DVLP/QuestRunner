local log, errorLog, trace, Logger = table.unpack(require("module/Log"))
local LangENUS = require("locale/en-us")

local Lang = {}
local defaultLocale = "en-us"
function Lang:new() return self end

function Lang:init(locale)
	self.locales = {}
	self:addTranslation(LangENUS)
	self:setLocale(locale)
	self.isInitialized = true
end

function Lang:addTranslation(translation)
	for locale, translations in pairs(translation) do
		if self.locales[locale] then
			-- Merge new keys in
			for key, value in pairs(translations) do
				self.locales[locale][key] = value
			end
		else
			self.locales[locale] = translations
		end
	end
	-- reload reverse cache
	self:setLocale(self.locale)
end

function Lang:setLocale(locale)
	self.locale = locale
	self.default = self.locales[defaultLocale]
	if not self.locales[locale] then
		log("Lang: Locale", locale, "not available. Using default", defaultLocale)
	end
	self.current = self.locales[locale] or self.default
	self.reverse = {}
	for k, v in pairs(self.default) do
		if self.current[k] then v = self.current[k] end
		self.reverse[v] = k
	end
	
end

function Lang:get(key)
	local value = self.current[key] or self.default[key]
	if not value then errorLog("Error, key not found", key) end
	return value
end

function Lang:getKeyByValue(text)
	return self.reverse[text] or nil
end

return Lang:new()

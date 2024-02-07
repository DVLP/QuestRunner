-- (c)identity - do not copy - there's QuestTemplate available for copying
local log, errorLog, trace = table.unpack(require("lib/Log"))
local Lang = {
	locale = "en-us",
	locales = {},
}
local defaultLocale = "en-us"
function Lang:new() return self end

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

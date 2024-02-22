-- (c)identity - part of QuestRunner
local log, errorLog, trace = table.unpack(require("lib/Log"))
local Lang = {
	locale = "en-us",
	locales = {},
	gender = "male",
	extLangs = {},
}
local defaultLocale = "en-us"
function Lang:new() return self end

function Lang:autoLocaleSet()
	Lang:loadTranslation(defaultLocale) -- for defaults
	local locale = Game.GetSettingsSystem():GetVar("/language", "OnScreen"):GetValue().value
	Lang:loadTranslation(locale)
	Lang:setLocale(locale)
	self.gender = (GetPlayer():GetResolvedGenderName() == CName("Male")) and "male" or "female"
end

function Lang:loadTranslation(locale)
	local localeFile = require("locale/" .. locale)
	if not localeFile then
		log("Locale file not found. Keeping default.")
		return
	end
	self:addTranslation(localeFile)
end

function Lang:addExternalLang(extLang)
	table.insert(self.extLangs, extLang)
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

		if locale ~= defaultLocale then
			local d = self.locales[defaultLocale]
			for key, value in pairs(d) do
				if self.locales[locale][key] == nil then
					errorLog("Key", key, "missing in locale", locale)
				end
			end
		end
	end
	self.default = self.locales[defaultLocale]
end

function Lang:setLocale(locale)
	self.locale = locale
	self.default = self.locales[defaultLocale]
	if not self.locales[locale] then
		log("Lang: Locale", locale, "not available. Using default", defaultLocale)
	end
	self.current = self.locales[locale] or self.default

	self:buildReverseLookupIndex()
end

function Lang:buildReverseLookupIndex()
	self.reverse = {}
	for k, v in pairs(self.default) do
		if self.current[k] then v = self.current[k] end
		self.reverse[v] = k
	end
end

function formatForGender(string, gender)
	local pattern = "([A-Za-z ])Æ{([^}]+)}"
	local result = string.gsub(string, pattern, function(letter, options)
		local optionArr = {}
		for option in options:gmatch("[^|]+") do
			table.insert(optionArr, option)
		end
		local index = (gender == "male") and 1 or 2
		return letter .. optionArr[index]
	end)
	if string.find(result, pattern) then
		return formatForGender(result, gender)
	end
	return result
end

function Lang:get(key, isOptional)
	if not self.current then
		errorLog("Lang: Locale not set. Notice: Lang:get cannot be used before onInit CET event")
		return
	end
	local value = self.current[key] or self.default[key]
	if not value then
		for i, extLang in ipairs(self.extLangs) do
			value = extLang:get(key, true)
			if value then break end
		end
		if not value then
			if isOptional then return nil end
			errorLog("Error, key not found", key)
		end
	end
	return formatForGender(value, self.gender)
end

function Lang:getKeyByValue(text)
	return self.reverse[text] or nil
end

return Lang:new()

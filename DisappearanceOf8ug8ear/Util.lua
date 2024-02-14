local Lang = require("lib/Lang")

local Util = {}
function Util.showTimeLeft(ShowMessage, secLeftFloat)
	-- only activate when the 10th of the second is 0
	if math.floor(secLeftFloat * 10) % 10 ~= 0 then return end

	local secLeft = math.floor(secLeftFloat)
	if secLeft % 60 == 0 and secLeft ~= 0 then
		local messageTemplate = secLeft <= 180 and Lang:get("hurry_up_x_left") or Lang:get("x_left")
		ShowMessage(string.format(messageTemplate, math.floor(secLeft / 60) .. " min"))
	end
	if secLeft < 60 and secLeft ~= 0 and secLeft % 10 == 0 then
		ShowMessage(string.format(Lang:get("hurry_up_x_left"), secLeft .. "s"))
	end
end

return Util

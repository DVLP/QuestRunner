local Cron = require("lib/Cron")

local Lighting = {}
function Lighting.AddSpotlight(pos, rot, strength, color, beamWidthAngle, beamWidthFalloff)
	local transform = Game.GetPlayer():GetWorldTransform()
	transform:SetPosition(pos)
	transform:SetOrientationEuler(rot)
	local entityID = WorldFunctionalTests.SpawnEntity("base\\flashlight\\light.ent", transform, '')

	Cron.RunWithRetry(0.5, 20, function()
		local lightEntity = Game.FindEntityByID(entityID)
		if lightEntity == nil then return false end
		local light = lightEntity:FindComponentByName("Light5520")
		light:SetStrength(strength)
		light:SetColor(color)
		light:SetAngles(beamWidthAngle, beamWidthFalloff)
	end)
end
return Lighting

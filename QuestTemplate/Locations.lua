-- (c)1dentity - the template is free to use, modify and publish without permission
local Locations = {
	{
		id = "northOakPond",
		-- Locations to go to
		waypoints = {
			-- Next to a pond at the bottom of North Oak text
			{ pos = { x = 110.53763, y = 824.15906, z = 128.7217, w = 1 }},
		},
		-- enemy spawning areas - w is the radius in meters of spawn
		spawnpoints = {
			{ pos = { x = 110.53763, y = 824.15906, z = 128.7217, w = 1 }},
		},
		-- important places i.e. with things to take
		payloads = {},
		-- NOT YET SUPPORTED: precise sniper locations with heading angle - unlike with other options w is not radius but an angle
		snipers = {},
		npcs = {
			{ pos = { x = 110.53763, y = 824.15906, z = 128.7217, w = 1 }}
		},
	},
}
return Locations

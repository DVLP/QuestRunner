-- (c)1dentity - do not copy - there's QuestTemplate available for copying
local Locations = {
	{
		id = "IllBeDam",
		-- Locations to go to
		waypoints = {
			{ pos = { x = 943.12244, y = -2938.4763, z = 204.57115, w = 1 }}, -- entrance to dam area
			{ pos = { x = -1547.1716, y = 1233.8855, z = 11.520233, w = 1 }}, -- Viktor's clinic chair
			-- { pos = { x = -1250.7344, y = 1141.2177, z = 16.810791, w = 1 }}, -- debrief location in front of Data INC
		},
		-- enemy spawning areas - w is the radius in meters of spawn
		spawnpoints = {
			{ pos = { x = 943.12244, y = -2938.4763, z = 204.77115, w = 1 }, flat = true, }, -- top of the ladder - entrance between concrete barriers

			-- above the walk
			{ pos = { x = 1057.2399, y = -2889.4766, z = 211.85278, w = 0.5 }, flat = true, spawnDistance = 200 }, -- top of elevator
			{ pos = { x = 1221.7007, y = -2875.7305, z = 211.85278, w = 0.5 }, flat = true, spawnDistance = 200 }, -- second elevator

			{ pos = { x = 875.5156, y = -3035.285, z = 215.46603, w = 1 }, flat = true, }, -- other side of the road sniper(s)

			{ pos = { x = 883.9316, y = -2906.5752, z = 205.94937, w = 2 }, flat = false, }, -- nearby hill, group hanging out

			{ pos = { x = 963.29155, y = -2909.644, z = 185.95279, w = 6 }, flat = false, }, -- first landing downstairs
			{ pos = { x = 991.70306, y = -2897.9082, z = 185.65279, w = 6 }, flat = true, }, -- a square behind the first gate

			{ pos = { x = 1006.3372, y = -2892.48, z = 187.67316, w = 0.3 }, flat = true,}, -- small bridge start
			{ pos = { x = 1019.691, y = -2891.6006, z = 187.6644, w = 0.3 }, flat = true,}, -- small bridge middle
			{ pos = { x = 1030.6248, y = -2890.641, z = 187.6644, w = 0.3 }, flat = true,}, -- small bridge end

			{ pos = { x = 1056.4957, y = -2870.2986, z = 187.6644, w = 1 }, flat = true,}, -- corner of the long walkway entrance
			{ pos = { x = 1124.2974, y = -2876.0208, z = 189.65704, w = 1 }, flat = true,}, -- third platform
			{ pos = { x = 1154.3064, y = -2873.5527, z = 189.65703, w = 1 }, flat = true,}, -- 4th platform
			{ pos = { x = 1213.9773, y = -2868.1458, z = 189.6579, w = 1 }, flat = true,}, -- 5th platform
			{ pos = { x = 1046.8519, y = -2887.773, z = 185.65279, w = 5.5 }, flat = true,}, -- first elevator area
			{ pos = { x = 1064.3547, y = -2881.3992, z = 189.65628, w = 1 }},
			{ pos = { x = 1094.475, y = -2878.7869, z = 189.65651, w = 1 }},
			{ pos = { x = 1133.346, y = -2864.069, z = 187.6644, w = 0.5 }},
			{ pos = { x = 1184.0437, y = -2871.1367, z = 189.657, w = 1 }},
			{ pos = { x = 1220.5411, y = -2856.9023, z = 187.6644, w = 0.5 }}
		},
		-- important places i.e. with things to take or someone to rescue
			-- Payload 1 - downstairs at the end of the walkway - 2m radius
			-- Payload 2 - second to last platform - 2m radius	 
		payloads = {
			{ pos = { x = 1218.3695, y = -2870.9814, z = 185.75279, w = 1 }}, { pos = { x = 1184.2081, y = -2871.0027, z = 189.6572, w = 2 }}
		},
		-- precise sniper locations with heading angle - unlike with other options w is not radius but an angle
		snipers = {
			{ pos = { x = 927.143, y = -2899.4167, z = 187.66743, w = 0.5 }}
		}, -- { { i = 0, j = 0, k = -0.7190412, r = 0.69496745 } } -- Behind a rock before the entrance
		-- { x = 1214.8214, y = -2878.562, z = 201.6799, w = 1 }  -- { i = 0, j = 0, k = -0.6672695, r = -0.74481636 } -- Last concrete elevation - sniper location

		npcs = {
			-- 0x5F7049F1 is bugbear
			{ id = 0x5F7049F1, pos = { x = 1218.8695, y = -2870.8114, z = 185.65279, w = 0.5 } }
		},
	},
}
return Locations

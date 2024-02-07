local Location = {
	id = nil, -- (string) Unique ID string - safe ascii name with no spaces
	name = nil, -- (string) Localised name

	waypoints = nil, -- <Vector4> Locations to follow i.e. Entrance, then victim to save etc
	spawnpoints = nil, -- <Vector4> Enemy spawn locations - param w is the max radius of spawning
	snipers = nil, -- <Vector4> Sniper spawn locations - unlike in spawnpoints, param w is the direction to spawn
	payloads = nil, -- <Vector4> Loot spawn locations, a car to take
	npcs = nil, -- <Vector4> NPCs
}

Location.__index = Location
setmetatable(Location, { __call = function(cls, ...) return cls.new(...) end })

function Location.new(id, name, waypoints, spawnpoints, snipers, payloads, npcs, type)
	local self = setmetatable({}, Location)
	self.id = id
	self.name = name
	self.waypoints = waypoints
	self.spawnpoints = spawnpoints
	self.snipers = snipers
	self.payloads = payloads
	self.npcs = npcs
	self.type = type
	return self
end

return Location

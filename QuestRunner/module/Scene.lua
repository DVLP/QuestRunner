-- (c)1dentity - part of Quest Runner custom mission framework
local Location = require("module/Location")
local locationList = require("data/LocationList")
local Spawner = require("module/Spawner")
local Cron = require("lib/Cron")
local EnemyList = require("data/EnemyList")
local CyberwareList = require("data/CyberwareList")

local Scene = {}

function Scene:new()
	local o = {}

	o.locationConfig = {}
	o.firstEnemy = nil
	o.enemyClassList = EnemyList
	o.lootClassList = CyberwareList

	o.doneSpawnpoints = {}
	o.donePayloads = {}

	o.isActive = false

	o.locations = {}
	o.onEnemySpawn = nil

	self.__index = self

	return setmetatable(o, self)
end

function Scene:setup(locationConfig)
	self.doneSpawnpoints = {}
	self.donePayloads = {}
	self.locationConfig = locationConfig
end

function copyArrVec4(arr)
	local newArr = {}
	for i, v in ipairs(arr) do
		newArr[i] = Vector4.new(v.x, v.y, v.z, v.w)
	end
	return newArr
end

function copyLocationConfig(arr)
	local newArr = {}
	for i, v in ipairs(arr) do
		newArr[i] = { pos = Vector4.new(v.pos.x, v.pos.y, v.pos.z, v.pos.w) }
	end
	return newArr
end

function orDefault(value, defaultValue)
	if value == nil then return defaultValue end
	return value
end

function parseSpawnpointsConfig(arr)
	local newArr = {}
	for i, v in ipairs(arr) do
		newArr[i] = { flat = orDefault(v.flat, false), spawnDistance = orDefault(v.spawnDistance, 90), pos = Vector4.new(v.pos.x, v.pos.y, v.pos.z, v.pos.w) }
	end
	return newArr
end

function copyNPCConfig(arr)
	local newArr = {}
	for i, v in ipairs(arr) do
		newArr[i] = { id = v.id, pos = Vector4.new(v.pos.x, v.pos.y, v.pos.z, v.pos.w) }
	end
	return newArr
end

function Scene:addLocation(item)
	local waypoints = item.waypoints and copyLocationConfig(item.waypoints) or {}
	local spawnpoints = item.spawnpoints and parseSpawnpointsConfig(item.spawnpoints) or {}
	local snipers = item.snipers and copyLocationConfig(item.snipers) or {}
	local payloads = item.payloads and copyLocationConfig(item.payloads) or {}
	local npcs = item.npcs and copyNPCConfig(item.npcs) or {}
	local location = Location.new(item.id, item.name, waypoints, spawnpoints, snipers, payloads, npcs, item.type)

	self.locations[item.id] = location
end

-- set a list of potential enemies that will be randomly spawned in spawnpoints
function Scene:setEnemyClassList(enemyClassList)
	self.enemyClassList = enemyClassList
end

-- set a list of potential loot that will be randomly spawned in "payloads" locations
function Scene:setLootClassList(lootClassList)
	self.lootClassList = lootClassList
end

function Scene:update(isActive)
	self.isActive = isActive
	if not isActive then return end

	local plPos = Game.GetPlayer():GetWorldPosition()
	local viewDir = Game.GetPlayer():GetWorldForward()

	if self.locationConfig.spawnpoints then
		-- spawn enemies at spawnpoints
		for i, spawnpoint in ipairs(self.locationConfig.spawnpoints) do
			local pos = spawnpoint.pos
			local locL = Vector4.new(pos)
			locL.w = 1;
			if not self.doneSpawnpoints[i] then
				if Spawner.CanSpawn(plPos, locL, spawnpoint.spawnDistance, not spawnpoint.flat) then
					self.doneSpawnpoints[i] = true
					Spawner.SpawnRandomMofosGroupInRadius(self.enemyClassList, pos, pos.w, spawnpoint.spawnDistance, not spawnpoint.flat, function(spawnedObject)
						self.onEnemySpawn(spawnedObject)
						self.firstEnemy = spawnedObject
					end)
				end
			end
		end
		-- Spawn payload / loot at payloads
		for i, payload in ipairs(self.locationConfig.payloads) do
			local pos = payload.pos
			local locL = Vector4.new(pos)
			locL.w = 1;
			if not self.donePayloads[i] then
				if self.firstEnemy and Spawner.CanSpawn(plPos, locL, 100) then
					self.donePayloads[i] = true
					Spawner.SpawnRandomLootItem(self.lootClassList, locL, locL.w, self.firstEnemy)
				end
			end
		end
	end
end
return Scene:new()

-- (c)1dentity - part of Quest Runner custom mission framework
local Cron = require("lib/Cron")
local log, errorLog, trace = table.unpack(require("module/Log"))

local Spawner = {}
local worldNPCs = {}
local awaitingSpawnCallbacks = {}
local time = 0
local lastUpdate = 0
local UPDATE_INTERVAL = 1
local SPAWN_TIMEOUT = 5
function Spawner.init()
	Observe('PreventionSystem', 'OnPreventionUnitSpawnedRequest', function(_, request)
		local result = request.requestResult
		local reqId = request.requestResult.requestID
		local req
		local reqOnSpawnIndex

		for j, awaitingReq in ipairs(awaitingSpawnCallbacks) do
			if awaitingReq.reqId == reqId then
				req = awaitingReq
				reqOnSpawnIndex = j
			end
		end

		local wnpc = worldNPCs[req.npcID]
		if not wnpc then
			errorLog("Spawned request doesn't match npc ID")
			return
		end

		for i, spawnedObject in ipairs(result.spawnedObjects) do
			if time - req.requestTime > SPAWN_TIMEOUT then
				Spawner.Despawn(spawnedObject)
				wnpc.isSpawning = false
			else
				-- if spawnedObject:IsA('NPCPuppet') then
				wnpc.ref = spawnedObject
				wnpc.entityID = spawnedObject:GetEntityID()
				wnpc.isSpawning = false
				wnpc.spawned = true
				wnpc.spawnedAtLeastOnce = true
				wnpc.onSpawn(spawnedObject)
				-- end
			end
		end
		table.remove(awaitingSpawnCallbacks, reqOnSpawnIndex)
	end)

	Observe("PreventionSystem", "OnPreventionUnitDespawnedRequest", function(this, request)
		local wnpc = Spawner.GetNPCByEntityID(request.entityID)
		if not wnpc then
			-- Not necessarily an error, npc not controlled by us i.e. police
			log("OnPreventionUnitDespawnedRequest: NPC for entity ID not found")
			return
		end

		wnpc.entityID = nil
		wnpc.spawned = false
		if wnpc.onDespawn then wnpc.onDespawn() end
	end)
end

function Spawner.Update(dt)
	time = time + dt
	if time - lastUpdate < UPDATE_INTERVAL then return end
	lastUpdate = time

	local plPos = GetPlayer():GetWorldPosition()

	-- update last NPC positions
	for i, wnpc in pairs(worldNPCs) do
		if wnpc.spawned and IsDefined(wnpc.ref) then
			local objPos = wnpc.ref:GetWorldPosition()
			-- only update last npc pos when the player is close enough so the terrain won't stream out
			if Vector4.Distance(plPos, objPos) < 80 then
				wnpc.pos = wnpc.ref:GetWorldPosition()
			end
			local health = Game.GetStatPoolsSystem():GetStatPoolValue(wnpc.entityID, gamedataStatPoolType.Health, false)
			wnpc.isDead = health == 0
			wnpc.health = health
			wnpc.state = wnpc.ref:GetHighLevelStateFromBlackboard()
			wnpc.isDefeated = wnpc.ref:IsDefeated()
		end
	end

	-- cleanup dead to prevent respawning
	for i, wnpc in pairs(worldNPCs) do
		if not wnpc.spawned and not wnpc.isSpawning and wnpc.isDead then
			worldNPCs[i] = nil
		end
	end

	-- Detect if spawned NPC fell through the floor
	for i, wnpc in pairs(worldNPCs) do
		if wnpc.spawned and not wnpc.isSpawning and Vector4.Distance2D(wnpc.spawnPos, wnpc.pos) < 2 and wnpc.spawnPos.z - wnpc.pos.z > 3 then
			wnpc.pos = Vector4.new(wnpc.spawnPos)
			Spawner.Despawn(wnpc.ref)
			wnpc.spawned = false
			wnpc.isSpawning = false
		end
	end

	-- spawn NPCs (new and despawned)
	for i, wnpc in pairs(worldNPCs) do
		-- if character is close to their original spawn pos, repsawn at original (to prevent drifting away in precise spawn locations)
		local isCloseToOriginalSpawn = Vector4.Distance2D(wnpc.spawnPos, wnpc.pos) < 2
		local spawnPos = isCloseToOriginalSpawn and wnpc.spawnPos or wnpc.pos
		if not wnpc.spawned and not wnpc.isSpawning and Spawner.CanSpawn(plPos, wnpc.pos, wnpc.spawnDistance, wnpc.getGround) then
			wnpc.isSpawning = true
			wnpc.spawnStartedAt = time

			-- if the character was lying on the ground, spawn higher
			if not isCloseToOriginalSpawn and (wnpc.isDefeated or wnpc.state == gamedataNPCHighLevelState.Unconscious) then
				spawnPos.z = spawnPos.z + 2
			end

			local spawnRadius = (not wnpc.spawnedAtLeastOnce) and wnpc.spawnRadius or 0
			local getGround = (not wnpc.spawnedAtLeastOnce) and wnpc.getGround or false
			Spawner.RequestNPCSpawn(wnpc.id, wnpc.tdbid, spawnPos, spawnRadius, getGround)
		end
	end
end

function Spawner.GetNPCByEntityID(entityID)
	for i, wnpc in pairs(worldNPCs) do
		if wnpc.entityID and wnpc.entityID.hash == entityID.hash then
			return wnpc
		end
	end
	return nil
end

function Spawner.GetGroundHeightAt(pos, rayDepth, rayStartOffset)
	if not pos then return nil end
	local rayStart = Vector4.new(pos)
	local rayEnd = Vector4.new(pos)
	rayStart.z = rayStart.z + rayStartOffset
	rayEnd.z = rayEnd.z - rayDepth
	rayStart.w = 0
	rayEnd.w = 0

	local terrainHit, tRes = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(rayStart, rayEnd, CName'Terrain', true, false)
	local staticHit, sRes = Game.GetSpatialQueriesSystem():SyncRaycastByCollisionGroup(rayStart, rayEnd, CName'Static', true, false)
	if not terrainHit and not staticHit then
		return nil
	end
	if not tRes:IsValid() then return Vector4.Vector3To4(sRes.position) end
	if not sRes:IsValid() then return Vector4.Vector3To4(tRes.position) end
	local tHitPos = Vector4.Vector3To4(tRes.position)
	local sHitPos = Vector4.Vector3To4(sRes.position)
	local posW1 = Vector4.new(pos)
	tHitPos.w = 0
	sHitPos.w = 0
	posW1.w = 0
	return Vector4.Distance(posW1, tHitPos) < Vector4.Distance(posW1, sHitPos) and tHitPos or sHitPos
end

-- if the spawn point and everything in its radius are at the same height there's no need to find the ground
function Spawner.GetFlatSpawnPositionInRadius(pos, spawnRadius)
	local spreadX = (math.random() * 2 - 1) * spawnRadius
	local spreadY = (math.random() * 2 - 1) * spawnRadius
	return Vector4.new(pos.x - spreadX, pos.y - spreadY, pos.z, pos.w)
end

-- like above but also tries multiple times in the given radius until a ray finds the ground i.e. for sloping terrain
function Spawner.GetGroundedSpawnPositionInRadius(pos, spawnRadius, isWarmup)
	local newPos
	-- Issues with casting a ray beause the objects are not stream in yet
	-- TODO: Find a way to stream in the world at coords without looking
	for i = 1, 10, 1 do
		local spawnPosition = Spawner.GetFlatSpawnPositionInRadius(pos, spawnRadius)

		-- the terrain in the radius may be sloping so we're also checking with a higher starting point and larger depth
		newPos = Spawner.GetGroundHeightAt(spawnPosition, 2, 0.3)
		if newPos == nil then
			newPos = Spawner.GetGroundHeightAt(spawnPosition, 4, 2)
		end -- try again with higher height buffer
		if newPos == nil then
			newPos = Spawner.GetGroundHeightAt(spawnPosition, 3, 6)
		end -- try again with higher height buffer
		if newPos then break end
		if i == 10 and newPos == nil then
			if not isWarmup then errorLog("Spawn pos still nil!!!") end
			newPos = spawnPosition
		end
	end
	return newPos
end

function Spawner.CanSpawn(playerPos, objPos, spawnDist, requireTerrainHeight)
	spawnDist = spawnDist and spawnDist or 50
	local viewDir = Game.GetPlayer():GetWorldForward()
	local locDir = Vector4.Normalize(Vector4.new(objPos.x - playerPos.x, objPos.y - playerPos.y, objPos.z - playerPos.z, 0))
	local distanceDotFactor = math.max(0.5, Vector4.Dot(viewDir, locDir))
	local dist = Vector4.Distance2D(playerPos, objPos)
	local inRange = dist < (spawnDist * distanceDotFactor)

	-- local playerEyesPos, forward = Game.GetTargetingSystem():GetCrosshairData(Game.GetPlayer())
	-- local posVisible = Game.GetSenseManager():IsPositionVisible(objPos, playerEyesPos, false)
	-- why is IsPositionVisible so unreliable?
	if inRange then
		if requireTerrainHeight and not Spawner.GetGroundHeightAt(objPos, 2, 0.3) then
			trace("Can't spawn, ground not found", objPos)
			return false
		end
		-- if posVisible then
		--	 return true
		-- elseif dist < (spawnDist / 2 * distanceDotFactor) then
		--	 log("True despite not visible!")
			return true
		-- end
	end

	return false
end

function Spawner.reset()
	worldNPCs = {}
	awaitingSpawnCallbacks = {}
end

-- Send NPC far away, which triggers a despawn - workaround for broken RequestDespawn
function Spawner.Despawn(spawnedObject)
	if spawnedObject == nil or not IsDefined(spawnedObject) then return end

	local teleportCmd = AITeleportCommand.new()
	teleportCmd.position = Vector4.new(9999, 9999, 0, 1)
	teleportCmd.rotation = 1
	teleportCmd.doNavTest = false
	spawnedObject:GetAIControllerComponent():SendCommand(teleportCmd)

	-- This doesn't do anything but maybe keeps some counters clearer
	Game.GetPreventionSpawnSystem():RequestDespawn(spawnedObject:GetEntityID())
end

local npcID = 1
function Spawner.SpawnNPC(npcTweakDBID, pos, spawnRadius, spawnDistance, getGround, onSpawn, onDespawn)
	local newNpcID = npcID
	npcID = npcID + 1
	worldNPCs[npcID] = {
		id = npcID,
		enitityID = nil,
		tdbid = npcTweakDBID,
		spawnPos = Vector4.new(pos),
		pos = pos,
		isDead = false,
		health = nil,
		spawned = false,
		isSpawning = false,
		spawnRadius = spawnRadius,
		spawnDistance = spawnDistance,
		getGround = getGround,
		onSpawn = onSpawn,
		onDespawn = onDespawn,
	}
end

function Spawner.RequestNPCSpawn(npcID, npcTweakDBID, pos, spawnRadius, getGround)
	local player = Game.GetPlayer()
	local heading = player:GetWorldForward()
	local spawnPositionGrounded = pos
	if getGround then
		spawnPositionGrounded = Spawner.GetGroundedSpawnPositionInRadius(pos, spawnRadius)
	else
		spawnPositionGrounded = Spawner.GetFlatSpawnPositionInRadius(pos, spawnRadius)
	end

	local spawnTransform = player:GetWorldTransform()
	spawnTransform:SetPosition(spawnPositionGrounded)
	spawnTransform:SetOrientationEuler(EulerAngles.new(0, 0, math.random(0, 360)))
	local reqId = Game.GetPreventionSpawnSystem():RequestUnitSpawn(npcTweakDBID, spawnTransform)
	table.insert(awaitingSpawnCallbacks, {
		npcID = npcID,
		reqId = reqId,
		requestTime = time,
	})
end

-- Workaround: owner param is for using an NPC as a proxy to spawn loose items
function Spawner.SpawnRandomLootItem(lootClassList, pos, spawnRadius, owner)
	local spawnPosition = Spawner.GetGroundedSpawnPositionInRadius(pos, spawnRadius)
	local item = ItemID.FromTDBID(TweakDBID.new(lootClassList[math.random(1, #lootClassList)]))

	Game.GetTransactionSystem():GiveItem(owner, item, 1)

	local instructions = { DropInstruction.Create(item, 1) }
	Game.GetLootManager():SpawnItemDropOfManyItems(owner, instructions, CName"playerDropBag", spawnPosition)
end

function Spawner.SpawnRandomMofosGroupInRadius(characterClassList, pos, spawnRadius, spawnDistance, getGround, onSpawn, onDespawn)
	local minEnemies = math.max(1, math.ceil(spawnRadius / 3))
	local maxEnemies = math.max(2, math.ceil(spawnRadius * 1.2))
	local enemyCount = math.floor(math.random(minEnemies, maxEnemies))
	for i = 1, enemyCount, 1 do
		Spawner.SpawnRandomMofoInRadius(characterClassList, pos, spawnRadius, spawnDistance, getGround, onSpawn, onDespawn)
	end
end

function Spawner.SpawnRandomMofoInRadius(characterClassList, pos, spawnRadius, spawnDistance, getGround, onSpawn, onDespawn)
	Spawner.SpawnNPC(TweakDBID.new(characterClassList[math.random(1, #characterClassList)]), pos, spawnRadius, spawnDistance, getGround, onSpawn, onDespawn)
end

return Spawner

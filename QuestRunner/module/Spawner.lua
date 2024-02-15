-- (c)1dentity - part of Quest Runner custom mission framework
local Cron = require("lib/Cron")
local log, errorLog, trace = table.unpack(require("module/Log"))

local Spawner = {}

local awaitingSpawnCallbacks = {}
function Spawner.init()
	Observe('PreventionSystem', 'OnPreventionUnitSpawnedRequest', function(_, request)
		local result = request.requestResult
		local reqId = request.requestResult.requestID
		for i, v in ipairs(result.spawnedObjects) do
			local spawnedObject = result.spawnedObjects[i]
			if spawnedObject:IsA('NPCPuppet') then
				local tbidHash = spawnedObject:GetTDBID().hash
				local callback
				for i, req in ipairs(awaitingSpawnCallbacks) do
					if req.reqId == reqId then
						req.onSpawn(spawnedObject)
						table.remove(awaitingSpawnCallbacks, i)
						break
					end
				end
			end
		end
	end)
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
	local spreadX = math.random(-spawnRadius, spawnRadius) + math.random() - 1
	local spreadY = math.random(-spawnRadius, spawnRadius) + math.random() - 1
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
		newPos = Spawner.GetGroundHeightAt(spawnPosition, 1, 0.3)
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

function Spawner.CanSpawn(playerPos, objPos, spawnDist)
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
		-- if posVisible then
		--	 return true
		-- elseif dist < (spawnDist / 2 * distanceDotFactor) then
		--	 log("True despite not visible!")
			return true
		-- end
	end

	return false
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

function Spawner.SpawnNPCWithRetry(npcTweakDBID, pos, spawnRadius, getGround, onSpawn, attempt)
	local useTimeout = true
	local timeouted = false
	Cron.After(2, function ()
		if useTimeout then
			if attempt == nil then
				attempt = 0
			elseif attempt ~= 999 then
				attempt = attempt + 1
			end
			timeouted = true
			if attempt ~= 999 and attempt > 5 then
				return
			end
			Spawner.SpawnNPCWithRetry(npcTweakDBID, pos, spawnRadius, getGround, onSpawn, attempt)
		end
	end)
	Spawner.SpawnNPC(npcTweakDBID, pos, spawnRadius, getGround, function(spawnedObject)
		if timeouted then
			Spawner.Despawn(spawnedObject)
			return
		end
		useTimeout = false
		onSpawn(spawnedObject)
	end)
end

function Spawner.SpawnNPC(npcTweakDBID, pos, spawnRadius, getGround, onSpawn)
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
		reqId = reqId,
		onSpawn = onSpawn,
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

function Spawner.SpawnRandomMofosGroupInRadius(characterClassList, pos, spawnRadius, getGround, callback)
	local minEnemies = math.max(1, math.ceil(spawnRadius / 3))
	local maxEnemies = math.max(2, math.ceil(spawnRadius * 1.2))
	local enemyCount = math.floor(math.random(minEnemies, maxEnemies))
	for i = 1, enemyCount, 1 do
		Spawner.SpawnRandomMofoInRadius(characterClassList, pos, spawnRadius, getGround, callback)
	end
end

function Spawner.SpawnRandomMofoInRadius(characterClassList, pos, spawnRadius, getGround, callback)
	Spawner.SpawnNPCWithRetry(TweakDBID.new(characterClassList[math.random(1, #characterClassList)]), pos, spawnRadius, getGround, callback)
end

return Spawner

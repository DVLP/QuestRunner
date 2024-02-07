local Nav = {
	ids = {}
}

function Nav.placeCustomPin(loc)
	Nav.clearCustomPin()
	local mappinData = MappinData.new()
	mappinData.mappinType = "Mappins.DefaultStaticMappin" -- "Mappins.QuestStaticMappinDefinition"
	mappinData.active = true
	mappinData.visibleThroughWalls = true
	mappinData.variant = gamedataMappinVariant.CustomPositionVariant -- gamedataMappinVariant.DefaultQuestVariant -- gamedataMappinVariant.CustomPositionVariant
	local mappinId = Game.GetMappinSystem():RegisterMappin(mappinData, loc)
	if mappinId then
		table.insert(Nav.ids, mappinId)
		Game.GetMappinSystem():SetMappinPosition(mappinId, loc)
		Game.GetMappinSystem():SetMappinActive(mappinId, true)
		-- WorldMapMenuGameControllerRef:UntrackCustomPositionMappin()
		-- WorldMapMenuGameControllerRef:TrackMappin(mappinData)
	end
end

function Nav.clearCustomPin()
	if #Nav.ids > 0 then
		for i, mappinId in ipairs(Nav.ids) do
			Game.GetMappinSystem():SetMappinActive(nil, false)
			Game.GetMappinSystem():UnregisterMappin(mappinId)
			-- WorldMapMenuGameController:UntrackCustomPositionMappin()
		end
		Nav.ids = {}
	end
end

return Nav

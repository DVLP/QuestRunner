local lastCheck = 5
registerForEvent("onUpdate", function(dt)
	if lastCheck - dt > 0 then
		lastCheck = lastCheck - dt
		return
	end
	lastCheck = 5
	if not Game then return end
	local player = Game.GetPlayer()
	if not player then return end
	local vehicle = Game.GetMountedVehicle(player)
	local isPlayingMusic = (vehicle and vehicle:IsRadioReceiverActive()) or (player:GetPocketRadio() and player:GetPocketRadio():IsActive())
	if not isPlayingMusic then return end
	local trackName = vehicle and vehicle:GetRadioReceiverTrackName() or player:GetPocketRadio():GetTrackName()
	if not trackName or trackName.hash_lo ~= 0x0000CE9B then return end
	Game.GetAudioSystem():RequestSongOnRadioStation(CName"radio_station_05_pop", CName"mus_radio_05_pop_heres_a_thought")
end)

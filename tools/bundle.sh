# Cleanup
if [[ "$(pwd)" == */tools ]]; then
  cd ..
fi

# pack QuestRunner
rm -rf ./tmp
rm -rf ./deploy
mkdir -p deploy
mkdir -p ./tmp/bin/x64/plugins/cyber_engine_tweaks/mods
cp -r ./QuestRunner ./tmp/bin/x64/plugins/cyber_engine_tweaks/mods/QuestRunner
cd tmp
find ./bin/x64/plugins/cyber_engine_tweaks/mods/QuestRunner -name "*.log" -type f -delete
find ./bin/x64/plugins/cyber_engine_tweaks/mods/QuestRunner -name "*.sqlite3" -type f -delete
cp -r ../QuestRunnerWolf/packed/archive .
7z.exe a -tzip -r ./QuestRunner *
mv ./QuestRunner.zip ../deploy/
cd ..
rm -rf ./tmp

# pack QuestTemplate
mkdir -p ./tmp/bin/x64/plugins/cyber_engine_tweaks/mods
cp -r ./QuestTemplate ./tmp/bin/x64/plugins/cyber_engine_tweaks/mods/QuestTemplate
cd tmp
find ./bin/x64/plugins/cyber_engine_tweaks/mods/QuestTemplate -name "*.log" -type f -delete
find ./bin/x64/plugins/cyber_engine_tweaks/mods/QuestTemplate -name "*.sqlite3" -type f -delete
7z.exe a -tzip -r ./QuestTemplate *
mv ./QuestTemplate.zip ../deploy/
cd ..
rm -rf ./tmp

# pack Disappearance of 8ug8ear
mkdir -p ./tmp/bin/x64/plugins/cyber_engine_tweaks/mods
cp -r ./DisappearanceOf8ug8ear ./tmp/bin/x64/plugins/cyber_engine_tweaks/mods/DisappearanceOf8ug8ear
cd tmp
find ./bin/x64/plugins/cyber_engine_tweaks/mods/DisappearanceOf8ug8ear -name "*.log" -type f -delete
find ./bin/x64/plugins/cyber_engine_tweaks/mods/DisappearanceOf8ug8ear -name "*.sqlite3" -type f -delete
7z.exe a -tzip -r ./DisappearanceOf8ug8ear *
mv ./DisappearanceOf8ug8ear.zip ../deploy/
cd ..
rm -rf ./tmp

# pack Remove that stupid song
mkdir -p ./tmp/bin/x64/plugins/cyber_engine_tweaks/mods
cp -r ./RemoveThatStupidSong ./tmp/bin/x64/plugins/cyber_engine_tweaks/mods/RemoveThatStupidSong
cd tmp
find ./bin/x64/plugins/cyber_engine_tweaks/mods/RemoveThatStupidSong -name "*.log" -type f -delete
find ./bin/x64/plugins/cyber_engine_tweaks/mods/RemoveThatStupidSong -name "*.sqlite3" -type f -delete
7z.exe a -tzip -r ./RemoveThatStupidSong *
mv ./RemoveThatStupidSong.zip ../deploy/
cd ..
rm -rf ./tmp

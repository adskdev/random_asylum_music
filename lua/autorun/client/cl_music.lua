print("[Random Asylum Music] SCRIPT STARTED! Waiting for gamemode init...")

local musicFolder = "sound/ra_music/" 
local musicTracks = {}

local files, _ = file.Find(musicFolder .. "*.mp3", "GAME")

if files then
    for _, filename in ipairs(files) do
        table.insert(musicTracks, musicFolder .. filename)
    end

    table.sort(musicTracks)
    
    for _, path in ipairs(musicTracks) do
        print("[Random Asylum Music] Loaded: " .. path)
    end
end

print("[Random Asylum Music] Total tracks loaded: " .. #musicTracks)

local musicVolume = CreateClientConVar("ra_music_volume", "0.8", true, false)

local currentMusic = nil
local isRoundActive = false

local function PlayRoundMusic(serverNumber)
    print("[Random Asylum Music] RoundStart received! Starting music...")
    isRoundActive = true

    if IsValid(currentMusic) then
        currentMusic:Stop()
        currentMusic = nil
    end

    if #musicTracks == 0 then 
        print("[Random Asylum Music] No tracks found! Skipping.") 
        return 
    end

    serverNumber = serverNumber or math.random(1, #musicTracks)

    local safeIndex = (serverNumber % #musicTracks) + 1 
    local trackToPlay = musicTracks[safeIndex]
    
    local vol = musicVolume:GetFloat() or 0.8
    
    sound.PlayFile(trackToPlay, "noplay noblock", function(station, errCode, errStr)
        if not isRoundActive then
            if IsValid(station) then station:Stop() end
            return
        end

        if IsValid(station) then
            currentMusic = station
            currentMusic:EnableLooping(true)
            currentMusic:SetVolume(vol)
            currentMusic:Play()
            print("[Random Asylum Music] Playing Synced Track: " .. trackToPlay)
        else
            print("[Random Asylum Music] FAILED to play " .. trackToPlay)
        end
    end)
end

local function StopRoundMusic()
    isRoundActive = false
    if IsValid(currentMusic) then
        currentMusic:Stop()
        currentMusic = nil
    end
end

hook.Add("Initialize", "RandomAsylumMusic_Init", function()
    if GAMEMODE and GAMEMODE.Name == "Random Asylum" then
        print("[Random Asylum Music] Gamemode confirmed. Registering net hooks...")

        net.Receive("RandomAsylum_RoundStart", function()
            local randomNum = net.ReadUInt(8) 
            PlayRoundMusic(randomNum) 
        end)

        net.Receive("RandomAsylum_RoundEnd", function() 
            StopRoundMusic() 
        end)
    end
end)

hook.Add("Think", "RandomAsylumMusic_VolumeUpdate", function()
    if IsValid(currentMusic) then
        currentMusic:SetVolume(musicVolume:GetFloat() or 0.8)
    end
end)

hook.Add("OnEntityRemoved", "RandomAsylumMusic_Cleanup", function(ent)
    if IsValid(ent) and ent == LocalPlayer() then
        StopRoundMusic()
    end
end)
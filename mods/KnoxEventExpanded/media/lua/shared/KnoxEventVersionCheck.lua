local function onGameTimeLoadedSP()
	KnoxEventVersionAPI.instance:setKnoxEventSPVersion("v0.2.1");
end

local function onGameTimeLoadedMP()
	KnoxEventVersionAPI.instance:setKnoxEventMPVersion("v0.2.1");
end

if not isClient() and not isServer()  then
    Events.OnGameTimeLoaded.Add(onGameTimeLoadedSP)
end

if not isClient() and isServer()  then
    Events.OnGameTimeLoaded.Add(onGameTimeLoadedMP)
end

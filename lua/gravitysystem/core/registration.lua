local TESTGRAVITY = TESTGRAVITY
TESTGRAVITY.Maps = {}

function TESTGRAVITY.RegisterMap( mapname, data )
	TESTGRAVITY.Maps[mapname] = data
	print("[Gravity System] - Added Support for the map '" .. mapname .. "' ")
end

-- For the alenxadrovich obj planets
function TESTGRAVITY.RegisterPlanet( id, map, data )
	local MapData = TESTGRAVITY.Maps[map]
	if not MapData or not next(MapData) then ErrorNoHalt("Attempting to register a planet with a non-existant mapdata!!!") return end
	MapData.Planets = MapData.Planets or {}
	MapData.Planets[id] = data
	print("[Gravity System] - Registered Planet '" .. map .. "'")
end

--------- Execute the code below ONLY if the map has actual support to this addon.
function TESTGRAVITY.IsThisMapSupported()
	local MapData = TESTGRAVITY.Maps
	return MapData[game.GetMap()]
end
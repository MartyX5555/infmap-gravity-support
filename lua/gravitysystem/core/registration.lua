local TESTGRAVITY = TESTGRAVITY
TESTGRAVITY.Maps = {}

function TESTGRAVITY.RegisterMap( mapname, MapData )
	if MapData.surfacedata and next(MapData.surfacedata) then
		MapData.hassurface = true
	else
		print("[Gravity System | WARNING] - Attempting to declare a surface with a invalid or non-existant surfacedata! Ignoring declaration....")
	end
	timer.Simple(0, function()
		if next(MapData.Planets) then
			MapData.hascustomplanets = true
		else
			print("[Gravity System | WARNING] - Attempting to declare a list of planets but the list is empty or invalid! Ignoring declaration....")
		end
	end)
	MapData.Planets = {}
	TESTGRAVITY.Maps[mapname] = MapData
	print("[Gravity System | INFO] - Added Support for the map '" .. mapname .. "' ")
end

-- For the alenxadrovich obj planets
function TESTGRAVITY.RegisterPlanet( id, map, data )
	local MapData = TESTGRAVITY.Maps[map]
	if not MapData or not next(MapData) then ErrorNoHalt("Attempting to register a planet with a non-existant mapdata!!!") return end

	MapData.Planets[id] = data
	print("[Gravity System] - Registered Planet '" .. map .. "'")
end

--------- Execute the code below ONLY if the map has actual support to this addon.
function TESTGRAVITY.IsThisMapSupported()
	local MapData = TESTGRAVITY.Maps
	return MapData[game.GetMap()]
end
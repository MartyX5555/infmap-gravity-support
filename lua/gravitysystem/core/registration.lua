local GRAVSYSTEM = GRAVSYSTEM
GRAVSYSTEM.Maps = {}

local current_map = game.GetMap()
function GRAVSYSTEM.RegisterMap( mapname, MapData )
	if current_map ~= mapname then return end
	if MapData.surfacedata then
		if next(MapData.surfacedata) then
			MapData.hassurface = true
		else
			print("[Gravity System | WARNING] - Attempting to declare a surface with a invalid or non-existant surfacedata! Ignoring declaration....")
		end
	end
	timer.Simple(0, function()
		if next(MapData.Planets) then
			MapData.hascustomplanets = true
		else
			print("[Gravity System | WARNING] - Attempting to declare a list of planets but the list is empty or invalid! Ignoring declaration....")
		end
	end)
	MapData.Planets = {}
	GRAVSYSTEM.Maps[mapname] = MapData
	print("[Gravity System | INFO] - Added Support for the map '" .. mapname .. "'")
end

-- For the alenxadrovich obj planets
function GRAVSYSTEM.RegisterPlanet( id, map, data )
	if current_map ~= map then return end
	local MapData = GRAVSYSTEM.Maps[map]
	if not MapData or not next(MapData) then ErrorNoHalt("Attempting to register a planet with a non-existant mapdata!!!") return end

	data.name = data.name or "unknown"
	MapData.Planets[id] = data
	print("[Gravity System | INFO] - Registering Planet '" .. id .. "' (" .. data.name .. ")")
end

--------- Execute the code below ONLY if the map has actual support to this addon.
function GRAVSYSTEM.IsThisMapSupported()
	local MapData = GRAVSYSTEM.Maps
	return MapData[current_map]
end
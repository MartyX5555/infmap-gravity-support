local GRAVSYSTEM = GRAVSYSTEM
local MapName = "gm_infmap"

-- Supported maps. If your map needs gravity support, use the function below with the required info
-- If infmaps planets are detected in the registered map, they will be automatically supported.
GRAVSYSTEM.RegisterMap( MapName, {

	-- If it has a surface, a flat, infinite horizontal gravity layer will be put in the map.
	surfacedata = {
		gravity = GRAVSYSTEM_EARTH_GRAVITY, -- m/s^2
		gravsealevel = 0, -- Z value to define the sea level. unused atm.
		gravlossheight = 1000000, -- height where gravity starts to decrease
		gravmaxheight = 3000000, -- maximum height before gravity is completely off.
	},
	ignoreinfplanets = false, -- If there's a reason to ignore the support to the generated infmap planets, use this.
} )

-- If your map has obj like planets or non infmaps one.
-- For the alenxadrovich obj planets
--[[
GRAVSYSTEM.RegisterPlanet( "earthtest", MapName, {
	name = "A planet for testing purposes", -- the real planet name. Potentially seen for huds.
	origin = Vector(0,0,10000000), -- The planet's center
	gravtype = "spherical", -- available types: spherical, flat. This change the gravity direction inside of area.
	gravity = GRAVSYSTEM_EARTH_GRAVITY,
	gravlossheight = 3000000, -- height where gravity starts to decrease. spherical type only.
	gravmaxheight = 6000000, -- maximum height before gravity is completely off.
} )

]]
local MapName2 = "gm_infmap_earth_scaled"
-- Supported maps. If your map needs gravity support, use the function below with the required info
-- If infmaps planets are detected in the registered map, they will be automatically supported.
GRAVSYSTEM.RegisterMap( MapName2, {
	ignoreinfplanets = true, -- If there's a reason to ignore the support to the generated infmap planets, use this.
} )

GRAVSYSTEM.RegisterPlanet( "scaledearth", MapName2, {
	name = "The scaled Earth", -- the real planet name. Potentially seen for huds.
	origin = Vector(-159694,28274.6,-758438), -- The planet's center
	gravtype = "spherical", -- available types: spherical, flat. This change the gravity direction inside of area.
	gravity = GRAVSYSTEM_EARTH_GRAVITY,
	gravlossheight = 3000000, -- height where gravity starts to decrease. spherical type only.
	gravmaxheight = 6000000, -- maximum height before gravity is completely off.
} )

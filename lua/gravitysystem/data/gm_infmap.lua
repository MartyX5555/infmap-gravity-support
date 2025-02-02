local TESTGRAVITY = TESTGRAVITY
local MapName = "gm_infmap"

-- Supported maps. If your map needs gravity support, use the function below with the required info
-- If infmaps planets are detected in the registered map, they will be automatically supported.
TESTGRAVITY.RegisterMap( MapName, {

	-- If it has a surface, a flat, infinite horizontal gravity layer will be put in the map.
	surfacedata = {
		gravity = TESTGRAVITY_EARTH_GRAVITY, -- m/s^2
		gravsealevel = 0, -- Z value to define the sea level. unused atm.
		gravlossheight = 1000000, -- height where gravity starts to decrease
		gravmaxheight = 3000000, -- maximum height before gravity is completely off.
	},
	ignoreinfplanets = false, -- If there's a reason to ignore the support to the generated infmap planets, use this.
} )

-- If your map has obj like planets or non infmaps one.
-- For the alenxadrovich obj planets
TESTGRAVITY.RegisterPlanet( "earthtest", MapName, {
	origin = Vector(0,0,0), -- The planet's center
	gravtype = "spherical", -- available types: spherical, flat. This change the gravity direction inside of area.
	gravity = TESTGRAVITY_EARTH_GRAVITY,
	gravlossheight = 1000, -- height where gravity starts to decrease. spherical type only.
	gravmaxheight = 2000, -- maximum height before gravity is completely off.
} )
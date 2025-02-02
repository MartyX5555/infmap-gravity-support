TESTGRAVITY = TESTGRAVITY or {}
TESTGRAVITY.GlobalEnts = TESTGRAVITY.GlobalEnts or {}
TESTGRAVITY.prop_container = TESTGRAVITY.prop_container or {}
TESTGRAVITY.BlacklistedEntities = { -- A list of classes that should not be added into the list.
	player       = true,
	prop_door    = true,
	prop_dynamic = true,
	func_        = true,
	infmap_      = true,
}

-- Global values for the sake of the user.
TESTGRAVITY_EARTH_GRAVITY = 9.80665
TESTGRAVITY_MOON_GRAVITY = 1.6249
TESTGRAVITY_VENUS_GRAVITY = 8.87
TESTGRAVITY_JUPITER_GRAVITY = 24.79

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

local MapName = game.GetMap()
-- Supported maps. If your map needs gravity support, use the function below with the required info
-- If infmaps planets are detected in the registered map, they will be automatically supported.
TESTGRAVITY.RegisterMap( MapName, {

	-- If it has a surface, a flat, infinite horizontal gravity layer will be put in the map.
	hassurface = true,
	surfacedata = {
		gravity = TESTGRAVITY_EARTH_GRAVITY, -- m/s^2
		gravsealevel = 0, -- Z value to define the sea level. unused atm.
		gravlossheight = 1000000, -- height where gravity starts to decrease
		gravmaxheight = 3000000, -- maximum height before gravity is completely off.
	},
} )

-- If your map has obj like planets or non infmaps one.
-- For the alenxadrovich obj planets
TESTGRAVITY.RegisterPlanet( "earthtest", MapName, {
	origin = Vector(0,0,5000000), -- The planet's center
	gravtype = "flat", -- available types: spherical, flat. This change the gravity direction inside of area.
	gravity = TESTGRAVITY_EARTH_GRAVITY,
	gravlossheight = 10000, -- height where gravity starts to decrease. spherical type only.
	gravmaxheight = 10000, -- maximum height before gravity is completely off.
} )

local MapData = TESTGRAVITY.Maps[MapName]
local PlanetData = MapData.Planets
if not MapData or not next(MapData) then return end
--------- Execute the code below ONLY if the map has actual support to this addon.


local function HasBlacklistedPatterns(class)
	for pattern, _ in pairs(TESTGRAVITY.BlacklistedEntities) do
		if string.StartsWith(class, pattern) then
			return true
		end
	end
	return false
end

-- Adds entities to the system
local function AddEntity(ent)
	timer.Simple(0, function()
		if not IsValid(ent) then return end
		if ent:EntIndex() == 0 then return end
		if HasBlacklistedPatterns(ent:GetClass()) then return end
		local physobj = ent:GetPhysicsObject()
		if not IsValid(physobj) then return end

		local GlobalEnts = TESTGRAVITY.GlobalEnts
		GlobalEnts[ent] = true
		ent:CallOnRemove("infmap_gravity", function()
			GlobalEnts[ent] = nil
		end)
	end)
end
hook.Remove("OnEntityCreated", "InfMap.GravitySystem.AddEntity")
hook.Add("OnEntityCreated", "InfMap.GravitySystem.AddEntity", AddEntity)


--[[
	sets the gravity to props that can (or potentially) move.

	Now, please note that different mechanics will be taken depending on the gravity value.

	- If the gravity is 0, the EnableGravity bool will be false. Simple as that
	- If the gravity is @9.8m/s, then it uses the default gmod gravity. EnableGravity will be true unless the prop is gravityless by default.
	- Any other value, the system will use a custom applyforce like emulator in order to scale it properly. EnableGravity will be FALSE.
]]

local function SetGravity(ent, physobj, dir, gravity)

	local prop_container = TESTGRAVITY.prop_container
	local HasOriginalDir = dir:GetNormalized() == Vector(0,0,1)
	if gravity == 0 then --print("no gravity")
		physobj:OriginalEnableGravity(false)

	elseif gravity ~= TESTGRAVITY_EARTH_GRAVITY or not HasOriginalDir then --print("prop uses custom gravity")

		if not prop_container[ent] then
			prop_container[ent] = true
		end

		physobj:OriginalEnableGravity(false)

	elseif HasOriginalDir then --print("prop uses normal gravity")

		if prop_container[ent] then
			prop_container[ent] = nil
		end
		physobj:OriginalEnableGravity(true)
	end

	ent.cgravityvalue = gravity
	ent.cgravitydirection = dir
end

-- Is the entity inside of a planet?
local function IsEntityInInfMapPlanet(ent)

	for _, planet in pairs(InfMap.planet_chunk_table) do
		if not IsValid(planet) then continue end
		local PlanetPos = planet:GetPos()
		local PlanetRadius = planet:GetPlanetRadius()

		local distanceSqrt = (ent:GetPos() - PlanetPos):LengthSqr()
		if distanceSqrt < PlanetRadius ^ 2 then
			return true
		end
	end

	return false
end

--[[
	I would had loved to not hack or interfiere with the gmod functions, but this time it was a need for this to work.
	Since we need to avoid systems and people not to enable the gravity of props while they are in the void (aka low gravity or none) but the addon to control that only.

	You can still disable the gravity of props inside of planets or where the gravity is present, and they will be gravityless at all times (unless its turned on), even if they go to space and return.
	Just make sure to build your vehicles on earthlike gravity, to preserve the gravity bool during copy operations.
]]
local PHYSOBJ = FindMetaTable("PhysObj")
PHYSOBJ.OriginalEnableGravity = PHYSOBJ.OriginalEnableGravity or PHYSOBJ.EnableGravity

function PHYSOBJ:EnableGravity(bool, ...)
	local ent = self:GetEntity()
	if not IsValid(ent) then return end

	local cgravity = ent.cgravityvalue
	local HasOriginalDir = ent.cgravitydirection:GetNormalized() == Vector(0,0,1)
	if cgravity == TESTGRAVITY_EARTH_GRAVITY and HasOriginalDir then

		if not bool then
			ent.CustomGravity = true
		else
			ent.CustomGravity = nil
		end

		self:OriginalEnableGravity(bool, ...)
	elseif bool then
		ent.CustomGravity = nil
	end
end

local fakezero = 0.00000000000001 -- ply:SetGravity doenst remove the gravity at 0, but adding more zeroes does the trick, cool.
local function EnvironmentCheck()

	MapData = TESTGRAVITY.Maps[MapName]
	PlanetData = MapData.Planets

	local GlobalEnts = TESTGRAVITY.GlobalEnts
	-- Prop gravity pull
	for ent, _ in pairs(GlobalEnts) do
		if not IsValid(ent) then continue end
		local phys = ent:GetPhysicsObject()
		if not IsValid(phys) then continue end
		if ent.CustomGravity then continue end

		local gravdir = vector_origin
		local finalgravity = 0

		-- Infmap planets
		if IsEntityInInfMapPlanet(ent) then

			gravdir = gravdir + Vector(0,0,1) * TESTGRAVITY_EARTH_GRAVITY
			finalgravity = finalgravity + TESTGRAVITY_EARTH_GRAVITY
		end

		-- User created planets
		if PlanetData and next(PlanetData) then

			local entpos = ent:GetPos()
			for _, planet in pairs(PlanetData) do
				if not next(planet) then continue end

				local PlanetPos = planet.origin --Entity(1):SetPos(PlanetPos)
				local GravRadius = planet.gravmaxheight

				local dir = entpos - PlanetPos
				local distanceSqrt = dir:LengthSqr()
				if distanceSqrt < GravRadius ^ 2 then

					local cgravity = 0
					local cgravdir = vector_origin

					if planet.gravtype == "spherical" then
						local height = math.sqrt(distanceSqrt) - planet.gravlossheight
						local ratio = math.min(1, height / planet.gravmaxheight)
						local realratio = math.min(1, 1 - ratio)

						cgravity = planet.gravity * realratio
						cgravdir = dir:GetNormalized() * cgravity

					elseif planet.gravtype == "flat" then

						cgravity = planet.gravity
						cgravdir = Vector(0,0,1) * cgravity
					end

					gravdir = gravdir + cgravdir
					finalgravity = finalgravity + cgravity

				end
			end
		end

		if MapData and next(MapData) then
			local surfacedata = MapData.surfacedata

			local entpos = ent:GetPos()
			local height = entpos.z - surfacedata.gravlossheight

			if height < surfacedata.gravmaxheight then

				local ratio = math.min(1, height / surfacedata.gravmaxheight)
				local realratio = math.min(1, 1 - ratio)

				local cgravity = surfacedata.gravity * realratio

				gravdir = gravdir + Vector(0,0,1) * cgravity
				finalgravity = finalgravity + cgravity

			end
		end

		SetGravity(ent, phys, gravdir, finalgravity)
	end

	-- Player gravity pull
	for _, ply in pairs(player.GetAll()) do

		local finalgravity = fakezero
		if IsEntityInInfMapPlanet(ply) then
			finalgravity = finalgravity + 1
		end

		-- User created planets
		if PlanetData and next(PlanetData) then

			local entpos = ply:GetPos()
			for _, planet in pairs(PlanetData) do
				if not next(planet) then continue end

				local PlanetPos = planet.origin --Entity(1):SetPos(PlanetPos)
				local GravRadius = planet.gravmaxheight

				local dir = entpos - PlanetPos
				local distanceSqrt = dir:LengthSqr()
				if distanceSqrt < GravRadius ^ 2 then

					local cgravity = 0

					if planet.gravtype == "flat" then -- supports flat type ATM
						local adaptratio = (planet.gravity / TESTGRAVITY_EARTH_GRAVITY)
						cgravity = adaptratio
					end

					finalgravity = finalgravity + cgravity
				end
			end
		end

		if MapData and next(MapData) then
			local surfacedata = MapData.surfacedata

			local entpos = ply:GetPos()
			local height = entpos.z - surfacedata.gravlossheight
			local ratio = math.Clamp(height / surfacedata.gravmaxheight, 0, 1)
			local realratio = (1 + fakezero) - ratio

			local adaptratio = (surfacedata.gravity / TESTGRAVITY_EARTH_GRAVITY) * realratio

			finalgravity = finalgravity + adaptratio
		end

		ply:SetGravity(finalgravity)

	end
end
hook.Remove("Think", "InfMap.GravitySystem.EnvironmentCheck")
hook.Add("Think", "InfMap.GravitySystem.EnvironmentCheck", EnvironmentCheck)


local function MonitorProps()

	local prop_container = TESTGRAVITY.prop_container
	for ent,_ in pairs(prop_container) do
		if not IsValid(ent) then continue end
		local phys = ent:GetPhysicsObject()

		if IsValid(phys) and not phys:IsAsleep() then
			local dir = ent.cgravitydirection
			local force = phys:GetMass() * -dir * 39.37 -- This gives us the force in kg*source_unit/s^2
			local dt = engine.TickInterval() -- The time interval over which the force acts on the object (in seconds)
			phys:ApplyForceCenter( force * dt ) -- Multiplying the two gives us the impulse in kg*source_unit/s

			debugoverlay.Line(ent:GetPos(),ent:GetPos() - dir * 1000, 0.1, Color(0,255,115), true)
		end
	end
end

hook.Remove("Tick", "InfMap.GravitySystem.MonitorProps")
hook.Add("Tick", "InfMap.GravitySystem.MonitorProps", MonitorProps)

TESTGRAVITY = TESTGRAVITY or {}

TESTGRAVITY_EARTH_GRAVITY = 9.80665
TESTGRAVITY_MOON_GRAVITY = 1.6249
TESTGRAVITY_VENUS_GRAVITY = 8.87
TESTGRAVITY_JUPITER_GRAVITY = 24.79

TESTGRAVITY.Maps = {}
function TESTGRAVITY.RegisterMap( mapname, data )
	TESTGRAVITY.Maps[mapname] = data
end

-- Supported maps by default
TESTGRAVITY.RegisterMap( "gm_infmap", {

	-- If it has a surface, a flat, infinite horizontal gravity layer will be put in the map.
	hassurface = true,
	surfacedata = {
		gravity = TESTGRAVITY_EARTH_GRAVITY, -- m/s^2
		gravsealevel = 0, -- Z value to define the sea level. unused atm.
		gravlossheight = 1000000, -- height where gravity starts to decrease
		gravmaxheight = 3000000, -- maximum height before gravity is completely off.
		airdensity = 1
	},
	hasplanets = true, -- if the map has planets, the system will look for planets created by the vanilla infmap base. Only infmaps created planets atm.
} )

local MapData = TESTGRAVITY.Maps[game.GetMap()]
if not MapData or not next(MapData) then return end
--------- Execute the code below ONLY if the map has actual support to this addon.


--[[
	sets the gravity to props that can (or potentially) move.

	Now, please note that different mechanics will be taken depending on the gravity value.

	- If the gravity is 0, the EnableGravity bool will be false. Simple as that
	- If the gravity is @9.8m/s, then it uses the default gmod gravity. EnableGravity will be true unless the prop is gravityless by default.
	- Any other value, the system will use a custom applyforce like emulator in order to scale it properly. EnableGravity will be FALSE.

]]
local prop_container = {}
local function SetGravity(ent, physobj, gravity)

	if gravity == 0 then
		--print("no gravity")
		physobj:OriginalEnableGravity(false)
		--physobj:EnableDrag( false )
		--physobj:SetDragCoefficient(-math.huge)
	elseif gravity ~= TESTGRAVITY_EARTH_GRAVITY then
		--print("prop uses custom gravity")

		if not prop_container[ent] then
			prop_container[ent] = true
			physobj:OutputDebugInfo()
		end

		physobj:OriginalEnableGravity(false)

		--physobj:SetDragCoefficient(-math.huge)
		--physobj:EnableDrag( false )
		ent.centgravity = gravity

	else
		--print("prop uses normal gravity")

		if prop_container[ent] then
			prop_container[ent] = nil
			ent.centgravity = nil
		end
		physobj:OriginalEnableGravity(true)
		--physobj:SetDragCoefficient(1)
	end
end

-- Is the entity inside of a planet?
local function IsEntityInPlanet(ent)

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

if not PHYSOBJ.OriginalEnableGravity then
	PHYSOBJ.OriginalEnableGravity = PHYSOBJ.EnableGravity
end

function PHYSOBJ:EnableGravity(bool, ...)
	local ent = self:GetEntity()
	if not IsValid(ent) then return end

	if IsEntityInPlanet(ent) then

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

local GlobalEnts = {}
-- A list of classes that should not be added into the list.
local Blacklist = {
	prop_door = true,
	prop_dynamic = true,
	func_ = true,
}

local function HasBlacklistedPatterns(class)
	for pattern, _ in pairs(Blacklist) do
		if string.StartsWith(class, pattern) then
			return true
		end
	end
	return false
end

-- Adds entities to the system
local function AddEntity(ent)
	timer.Simple(0, function()
		if not IsValid(ent) then return end--print("not valid") return end
		if ent:EntIndex() == 0 then return end--print("system entity") return end
		if HasBlacklistedPatterns(ent:GetClass()) then return end --print("blacklisted") return end
		local physobj = ent:GetPhysicsObject()
		if not IsValid(physobj) then return end

		GlobalEnts[ent] = true
		ent:CallOnRemove("infmap_gravity", function()
			GlobalEnts[ent] = nil
		end)
	end)
end
hook.Remove("OnEntityCreated", "SimSpeed.AddEntity")
hook.Add("OnEntityCreated", "SimSpeed.AddEntity", AddEntity)

local function GravityCheck()

	for ent, _ in pairs(GlobalEnts) do
		if not IsValid(ent) then continue end
		local phys = ent:GetPhysicsObject()
		if not IsValid(phys) then return end

		if IsEntityInPlanet(ent) and not ent.CustomGravity then
			SetGravity(ent, phys, TESTGRAVITY_EARTH_GRAVITY)
		elseif MapData and next(MapData) and not ent.CustomGravity then
			local surfacedata = MapData.surfacedata

			local entpos = ent:GetPos()
			local height = entpos.z - surfacedata.gravlossheight
			local ratio = math.min(1, height / surfacedata.gravmaxheight)
			local realratio = math.min(1, 1 - ratio)

			local cgravity = surfacedata.gravity * realratio

			SetGravity(ent, phys, cgravity)
		else
			SetGravity(ent, phys, 0)
		end
	end

	local fakezero = 0.00000000000001 -- ply:SetGravity doenst remove the gravity at 0, but adding more zeroes does the trick, cool.
	for _, ply in pairs(player.GetAll()) do
		if IsEntityInPlanet(ply) then
			ply:SetGravity(1)
		elseif MapData and next(MapData) then
			local surfacedata = MapData.surfacedata

			local entpos = ply:GetPos()
			local height = entpos.z - surfacedata.gravlossheight
			local ratio = math.Clamp(height / surfacedata.gravmaxheight, 0, 1)
			local realratio = (1 + fakezero) - ratio

			local adaptratio = (surfacedata.gravity / TESTGRAVITY_EARTH_GRAVITY) * realratio --print("current gravity:", adaptratio , cgravity)

			ply:SetGravity(adaptratio)
		else
			ply:SetGravity(fakezero)
		end
	end
end
hook.Remove("Think", "InfMap_Gravity_Support_Think")
hook.Add("Think", "InfMap_Gravity_Support_Think", GravityCheck)

local function MonitorProps()

	for ent,_ in pairs(prop_container) do
		if not IsValid(ent) then continue end
		local phys = ent:GetPhysicsObject()

		if IsValid(phys) and not phys:IsAsleep() then

			local force = phys:GetMass() * Vector( 0, 0, -ent.centgravity ) * 39.37 -- This gives us the force in kg*source_unit/s^2
			local dt = engine.TickInterval() -- The time interval over which the force acts on the object (in seconds)
			phys:ApplyForceCenter( force * dt ) -- Multiplying the two gives us the impulse in kg*source_unit/s
		end
	end
end

hook.Remove("Tick", "InfMap_Gravity_Support_Tick")
hook.Add("Tick", "InfMap_Gravity_Support_Tick", MonitorProps)

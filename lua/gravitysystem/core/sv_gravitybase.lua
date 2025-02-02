
TESTGRAVITY.prop_container = TESTGRAVITY.prop_container or {}

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

local cmap = game.GetMap()
local fakezero = 0.00000000000001 -- ply:SetGravity doenst remove the gravity at 0, but adding more zeroes does the trick, cool.
local function EnvironmentCheck()
	if not TESTGRAVITY.IsThisMapSupported() then return end

	local MapData = TESTGRAVITY.Maps[cmap]
	local PlanetData = MapData.Planets

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
		if not MapData.ignoreinfplanets and IsEntityInInfMapPlanet(ent) then

			gravdir = gravdir + Vector(0,0,1) * TESTGRAVITY_EARTH_GRAVITY
			finalgravity = finalgravity + TESTGRAVITY_EARTH_GRAVITY
		end

		-- User created planets
		if MapData.hascustomplanets then

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

		if MapData.hassurface then
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
		if MapData.hascustomplanets then

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

		if MapData.hassurface then
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
	if not TESTGRAVITY.IsThisMapSupported() then return end

	local prop_container = TESTGRAVITY.prop_container
	for ent,_ in pairs(prop_container) do
		if not IsValid(ent) then continue end
		local phys = ent:GetPhysicsObject()

		if IsValid(phys) and not phys:IsAsleep() then
			local dir = ent.cgravitydirection
			local force = phys:GetMass() * -dir * 39.37 -- This gives us the force in kg*source_unit/s^2
			local dt = engine.TickInterval() -- The time interval over which the force acts on the object (in seconds)
			phys:ApplyForceCenter( force * dt ) -- Multiplying the two gives us the impulse in kg*source_unit/s

			debugoverlay.Line(ent:GetPos(),ent:GetPos() - dir * 10, 0.1, Color(0,255,115), true)
		end
	end
end

hook.Remove("Tick", "InfMap.GravitySystem.MonitorProps")
hook.Add("Tick", "InfMap.GravitySystem.MonitorProps", MonitorProps)

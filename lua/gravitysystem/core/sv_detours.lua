local TESTGRAVITY = TESTGRAVITY
--[[
	I would had loved to not hack or interfiere with the gmod functions, but this time it was a need for this to work.
	Since we need to avoid systems and people not to enable the gravity of props while they are in the void (aka low gravity or none) but the addon to control that only.

	You can still disable the gravity of props inside of planets or where the gravity is present, and they will be gravityless at all times (unless its turned on), even if they go to space and return.
	Just make sure to build your vehicles on earthlike gravity, to preserve the gravity bool during copy operations.
]]
timer.Simple(0, function()
	if not TESTGRAVITY.IsThisMapSupported() then return end

	local PHYSOBJ = FindMetaTable("PhysObj")
	if not PHYSOBJ.OriginalEnableGravity then
		PHYSOBJ.OriginalEnableGravity = PHYSOBJ.EnableGravity
	end

	function PHYSOBJ:EnableGravity(bool, ...)
		local ent = self:GetEntity()
		if not IsValid(ent) then return end

		local cgravity = ent.cgravityvalue
		local normgravdir = isvector(ent.cgravitydirection) and ent.cgravitydirection:GetNormalized() or Vector(0,0,1)
		local HasOriginalDir = normgravdir == Vector(0,0,1)
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
end)



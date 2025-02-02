local GRAVSYSTEM = GRAVSYSTEM


GRAVSYSTEM.GlobalEnts = GRAVSYSTEM.GlobalEnts or {}
GRAVSYSTEM.BlacklistedEntities = { -- A list of classes that should not be added into the list.
	player       = true,
	prop_door    = true,
	prop_dynamic = true,
	func_        = true,
	infmap_      = true,
}

local function HasBlacklistedPatterns(class)
	for pattern, _ in pairs(GRAVSYSTEM.BlacklistedEntities) do
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

		local GlobalEnts = GRAVSYSTEM.GlobalEnts
		GlobalEnts[ent] = true
		ent:CallOnRemove("infmap_gravity", function()
			GlobalEnts[ent] = nil
		end)
	end)
end
hook.Remove("OnEntityCreated", "InfMap.GravitySystem.AddEntity")
hook.Add("OnEntityCreated", "InfMap.GravitySystem.AddEntity", AddEntity)
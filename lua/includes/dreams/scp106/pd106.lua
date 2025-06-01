pd106 = {}

local class_106 = {
	["npc_cpt_scp_106_old"] = true,
	["npc_cpt_scp_106"] = true,
	["npc_106"] = true,
	["drg_uescp106ver2"] = true,
	["drg_uescp106b2"] = true,
	["106"] = true,
	["npc_cpt_scpunity_106"] = true,
	["dughoo_scpcb_106"] = true,
	["drg_dughoo_old106"] = true,
	["dughoo_scpsl_scp106"] = true,
}
pd106.class_106 = class_106

hook.Add("EntityTakeDamage", "SCP106_PD", function(ply, dmg)
	local attacker = IsValid(dmg:GetAttacker()) and dmg:GetAttacker() or dmg:GetInflictor()
	if not IsValid(ply) or not IsValid(attacker) or not class_106[attacker:GetClass()] or not (ply:IsPlayer() or ply:IsNPC()) then return end
	if ply:IsNPC() then pd106.PutNPCInPD(ply) return true end
	if ply:IsDreaming() then return true end

	pd106.PutInPD(ply)
	return true
end)

function pd106.PutInPD(ply, puddle)
	if ply:IsDreaming() or timer.Exists(ply:SteamID() .. "_106PD") then return end
	ply:EmitSound("scp106pd/corrision.wav")
	if not puddle then
		puddle = ents.Create("ent_106pd_puddle")
		puddle:SetPos(ply:GetPos())
		puddle:Spawn()
	end
	ply.PDOutPos = ply:GetPos()
	ply.PDOutPuddle = puddle

	ply:SetMoveType(MOVETYPE_FLY)
	ply:Freeze(true)

	SafeRemoveEntityDelayed(puddle, 60 * 5)

	local start, time = ply:GetPos(), CurTime()
	local name = ply:SteamID() .. "_106PD"
	timer.Create(name, 0, 0, function()
		if not IsValid(ply) then return end
		ply:SetMoveType(MOVETYPE_FLY)
		ply:Freeze(true)
		ply:SetPos(start - Vector(0, 0, 40 * (CurTime() - time)))
		ply:SetAbsVelocity(vector_origin)
		ply:SetNoTarget(true)
	end)

	timer.Simple(2, function()
		timer.Remove(name)
		if not IsValid(ply) then return end
		ply:SetDream("scp106")

		timer.Simple(0.1, function()
			ply:Freeze(false)
		end)
	end)
end

function pd106.PutNPCInPD(ent, puddle)
	if timer.Exists(ent:EntIndex() .. "_106PD") then return end
	ent:EmitSound("scp106pd/corrision.wav")
	if not puddle then
		puddle = ents.Create("ent_106pd_puddle")
		puddle:SetPos(ent:GetPos())
		puddle:Spawn()
	end

	ent:SetMoveType(MOVETYPE_NONE)
	SafeRemoveEntityDelayed(puddle, 60 * 5)

	local start, time = ent:GetPos(), CurTime()
	local name = ent:EntIndex() .. "_106PD"
	timer.Create(name, 0, 0, function()
		if not IsValid(ent) then return end
		ent:SetPos(start - Vector(0, 0, 40 * (CurTime() - time)))
		ent:SetAbsVelocity(vector_origin)
	end)

	timer.Simple(3, function()
		timer.Remove(name)
		SafeRemoveEntity(ent)
	end)
end


function pd106.ExitPD(ply, trick)
	if timer.Exists(ply:SteamID() .. "_106PD") then return end
	ply:EmitSound("scp106pd/decay.wav")

	ply:SetMoveType(MOVETYPE_FLY)
	ply:Freeze(true)
	ply:SetDream(0)

	local start, time = (ply.PDOutPos or ply:GetPos()) - Vector(0, 0, 65), CurTime()
	local ent = ply.PDOutPuddle
	if IsValid(ent) then
		ent:SetClosing(CurTime())
		SafeRemoveEntityDelayed(ent, 15)
		ent.Closing = true
	end

	local name = ply:SteamID() .. "_106PD"
	timer.Create(name, 0, 0, function()
		if not IsValid(ply) then return end
		ply:SetMoveType(MOVETYPE_FLY)
		ply:Freeze(true)
		ply:SetPos(start + Vector(0, 0, 40 * (CurTime() - time)))
		ply:SetAbsVelocity(vector_origin)
	end)

	timer.Simple(2, function()
		timer.Remove(name)
		if not IsValid(ply) then return end
		ply:Freeze(false)
		ply:SetMoveType(MOVETYPE_WALK)
	end)
end
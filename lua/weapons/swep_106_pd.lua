AddCSLuaFile()

SWEP.PrintName = "SCP-106(PD)"
SWEP.Category = "SCP"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.Author = "noskill"
SWEP.Purpose = "Left - Send player to PD / Attack\nRight click - Phase through doors/bullets\nR - Open Portal Menu"
SWEP.DisableDuplicator = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

SWEP.FireRate = 2

function SWEP:PrimaryAttack()
	if CLIENT then
		self:SetNextPrimaryFire(CurTime() + self.FireRate)
		return
	end

	local owner = self.Owner
	local tr = owner:GetEyeTraceNoCursor()
	local ent = tr.Entity
	if not IsValid(tr.Entity) or tr.HitPos:DistToSqr(ply:EyePos()) > 30 ^ 2 then return end

	if not ent:IsPlayer() or ent:IsDreaming() then
		ent:TakeDamage(20, owner, self)
	else
		pd106.PutInPD(ply)
	end
end
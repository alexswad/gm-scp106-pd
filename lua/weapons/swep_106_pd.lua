AddCSLuaFile()

SWEP.PrintName = "SCP-106(PD)[wip]"
SWEP.Category = "SCP"
SWEP.Spawnable = false
SWEP.AdminOnly = true
SWEP.Author = "eskill"
SWEP.Purpose = "Left - Send player to PD / Attack\nRight click - Teleport In/Out of PD\nR - Laught"
SWEP.DisableDuplicator = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.WorldModel = ""
SWEP.ViewModel = ""

function SWEP:Deploy()
	self:SetHoldType("normal")
end

function SWEP:Initialize()
	self:SetHoldType("normal")
	if not pd106 then self:Remove() return end
end

function SWEP:PrimaryAttack()
	if CLIENT then return end

	local owner = self:GetOwner()
	local tr = owner:GetEyeTraceNoCursor()
	local ent = tr.Entity
	if not IsValid(tr.Entity) or not (ent:IsPlayer() or ent:IsNPC()) or tr.HitPos:DistToSqr(owner:EyePos()) > 80 ^ 2 then return end

	if not ent:IsPlayer() or ent:IsDreaming() then
		ent:TakeDamage(80, owner, self)
		self:SetNextPrimaryFire(CurTime() + 4)
	else
		self:SetNextPrimaryFire(CurTime() + 2)
		pd106.PutInPD(ent)
	end
	self:SetNextPrimaryFire(CurTime() + 1)
end

function SWEP:Reload()
	if CLIENT then return end

	if not self.NextLaugh or self.NextLaugh < CurTime() then
		local owner = self:GetOwner()
		owner:EmitSound("scp106pd/laugh.wav")
		self.NextLaugh = CurTime() + 5
		owner:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
		timer.Simple(5, function()
			owner:SetCollisionGroup(COLLISION_GROUP_PLAYER)
		end)
	end
end

function SWEP:SecondaryAttack()
	if CLIENT then return end
	self:SetNextSecondaryFire(CurTime() + 5)

	local owner = self:GetOwner()
	if owner:IsDreaming() then
		pd106.ExitPD(owner, true)
	else
		pd106.PutInPD(owner)
	end
end
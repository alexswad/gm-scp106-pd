AddCSLuaFile()

SWEP.PrintName = "SCP-106 (Dreams)"
SWEP.Category = "Dreams - SCP"
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Author = "eskill"
SWEP.Purpose = "Left - Send player to PD / Attack\nRight click - Teleport In/Out of PD\nR - Phase"
SWEP.DisableDuplicator = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"
SWEP.WorldModel = ""

function SWEP:Deploy()
	self:SetHoldType("normal")
end

function SWEP:Initialize()
	self:SetHoldType("normal")
	if SERVER and not pd106 then self:Remove() return end
end

function SWEP:ShouldDrawViewModel()
	return false
end

function SWEP:PrimaryAttack()
	if CLIENT then return end

	local owner = self:GetOwner()
	if not owner:IsDreaming() then
		local tr = owner:GetEyeTraceNoCursor()
		local ent = tr.Entity
		if not IsValid(tr.Entity) or not (ent:IsPlayer() or ent:IsNPC()) or tr.HitPos:DistToSqr(owner:EyePos()) > 80 ^ 2 then return end

		if not ent:IsPlayer() then
			ent:TakeDamage(80, owner, self)
			self:SetNextPrimaryFire(CurTime() + 2)
		else
			self:SetNextPrimaryFire(CurTime() + 2)
			pd106.PutInPD(ent)
		end
	elseif owner.DreamRoom and not owner.DreamRoom.notvalid then
		local trply = owner:GetDream():TracePlayers(owner.DreamRoom.name, owner:GetDreamPos() + Vector(0, 0, 64), owner:EyeAngles():Forward(), 300, {[owner] = true})
		if trply then
			trply:TakeDamage(50, owner, self)
		end
	end
	self:SetNextPrimaryFire(CurTime() + 1)
end

function SWEP:Reload()
	if CLIENT or self:GetOwner():IsDreaming() then return end

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
	if not self:GetOwner():IsOnGround() or CLIENT then return end
	self:SetNextSecondaryFire(CurTime() + 5)

	local owner = self:GetOwner()
	if owner:IsDreaming() then
		pd106.ExitPDSWEP(owner)
	else
		pd106.PutInPD(owner)
	end
end
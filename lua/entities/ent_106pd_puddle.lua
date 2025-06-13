AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "106 Puddle (Small)"
ENT.Author = "eskil"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.Category = "Dreams - SCP"
ENT.Spawnable = true
ENT.PhysgunDisabled = true

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "CreationTime")
	self:NetworkVar("Float", 1, "Closing")
end

ENT.Size = {Vector(-20, -20, -1), Vector(6, 6, 3)}
ENT.DrawSize = 160
function ENT:Initialize()
	self:SetCreationTime(CurTime())
	self:DrawShadow(false)
	if SERVER then
		self:DropToFloor()
		self:SetSolid(SOLID_BBOX)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		self:SetTrigger(true)
		self:SetCollisionBounds(self.Size[1], self.Size[2])
	else
		self:SetRenderBounds(self.Size[1] * 20, self.Size[2] * 20)
	end
end

function ENT:StartTouch(ply)
	if self.PuddleGrace and self.PuddleGrace > CurTime() or self.Closing or not ply:IsPlayer() and not ply:IsNPC() then return end
	ply:SetPos(self:GetPos())
	self.PuddleGrace = CurTime() + 1
	if ply:IsNPC() then
		if pd106.class_106[ply:GetClass()] then return end
		pd106.PutNPCInPD(ply, self)
		return
	end
	pd106.PutInPD(ply, self)
end

local mat = Material("scp106/cracks")
local mat2 = Material("scp106/puddle")
function ENT:Draw()
	self:DrawShadow(false)
	self:DestroyShadow()
	local cracksize, drawsize = self.DrawSize - 10, self.DrawSize
	local size, size2
	if self:GetClosing() == 0 then
		size = math.ease.InSine(math.min(1, (CurTime() - self:GetCreationTime() + 0.4) / 2)) * cracksize
		size2 = math.ease.InSine(math.min(1, (CurTime() - self:GetCreationTime() + 0.4) / 2)) * drawsize
	else
		size = math.ease.InSine(math.Clamp((self:GetClosing() - CurTime() + 4) / 2, 0, 1)) * cracksize
		size2 = math.ease.InSine(math.Clamp((self:GetClosing() - CurTime() + 4) / 2, 0, 1)) * drawsize
	end

	render.SetMaterial(mat)
	render.DrawQuadEasy(self:GetPos() + Vector(0, 0, 1), Vector(0, 0, 1), size, size, color_white, 0)

	render.SetMaterial(mat2)
	render.DrawQuadEasy(self:GetPos() + Vector(0, 0, 1), Vector(0, 0, 1), size2, size2, color_white, 0)
end

if CLIENT then
	timer.Simple(3, function()
		if Dreams or not LocalPlayer():IsListenServerHost() then return end
		Derma_Query("SCP-106 Pocket Dimension requires the DREAMS Module to function, would you like to open the workshop page?", "SCP-106 PD", "Download Now",
		function() gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3430729756") end, "Remind me later", function() end)
	end)
end
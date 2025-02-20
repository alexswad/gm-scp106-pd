AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "scp106_phys"
ENT.Author = "eskil"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.SCP106 = false

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "CreationTime")
	self:NetworkVar("Float", 1, "Closing")
end

function ENT:Initialize()
	self:SetCreationTime(CurTime())
	self:DrawShadow(false)
	if SERVER then
		self:DropToFloor()
		self:SetSolid(SOLID_BBOX)
		self:SetTrigger(true)
		self:SetCollisionBounds(Vector(-4, -4, -1), Vector(4, 4, 2))
	end
end

function ENT:StartTouch(ply)
	if self.Closing or not ply:IsPlayer() then return end
	pd106.PutInPD(ply, self)
end

local mat = Material("models/scp106/rooms/cracks")
local mat2 = Material("models/scp106/rooms/puddle")
function ENT:Draw()
	self:DrawShadow(false)
	self:DestroyShadow()
	local size, size2
	if self:GetClosing() == 0 then
		size = math.ease.InSine(math.min(1, (CurTime() - self:GetCreationTime() + 0.4) / 2)) * 150
		size2 = math.ease.InSine(math.min(1, (CurTime() - self:GetCreationTime() + 0.4) / 2) ) * 160
	else
		size = math.ease.InSine(math.max(0, (self:GetClosing() - CurTime() + 4) / 2)) * 150
		size2 = math.ease.InSine(math.max(0, (self:GetClosing() - CurTime() + 4) / 2) ) * 160
	end

	render.SetMaterial(mat)
	render.DrawQuadEasy(self:GetPos() + Vector(0, 0, 1), Vector(0, 0, 1), size, size, color_white, 0)

	render.SetMaterial(mat2)
	render.DrawQuadEasy(self:GetPos() + Vector(0, 0, 1), Vector(0, 0, 1), size2, size2, color_white, 0)
end

if CLIENT then
	timer.Simple(3, function()
		if Dreams then return end
		Derma_Query("SCP-106 Pocket Dimension now requires the Dreams Module to function, would you like to open the workshop page?", "SCP-106 PD", "Open Workshop Page", 
		function() gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3430729756") end, "Ignore for now", function() end)
	end)
end
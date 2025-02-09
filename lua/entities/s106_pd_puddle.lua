AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "scp106_phys"
ENT.Author = "eskil"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.SCP106 = false

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "CreationTime")
end

function ENT:Initialize()
	self:SetCreationTime(CurTime())
	self:DrawShadow(false)
	if SERVER then self:DropToFloor() end
end

local mat = Material("models/scp106/rooms/puddle")
function ENT:Draw()
	self:DrawShadow(false)
	self:DestroyShadow()
	local size = math.Clamp(0, 130, (CurTime() - self:GetCreationTime()) * 32)
	render.SetMaterial(mat)
	render.DrawQuadEasy(self:GetPos() + Vector(0, 0, 1), Vector(0, 0, 1), size, size, color_white, 0)
end
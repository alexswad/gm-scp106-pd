// Based off a WIP project called dreams, readdapted to demonstrate the concept in a more familiar way

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "scp106_phys"
ENT.Author = "eskil"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.SCP106PD = true

local normal = function(c, b, a)
	return ((b - a):Cross(c - a)):GetNormalized()
end

function ENT:Think()
	if self:GetPhysModel() ~= "" and not self.Phys then
		local f = file.Read(self:GetPhysModel(), "GAME")
		if not f then self.Phys = {} print(self:GetPhysModel()) return end
		self.Phys = util.JSONToTable(f)
	end

	if SERVER then
		self:NextThink(CurTime() + 0.1)
		for k, v in pairs(player.GetAll()) do
			if v:GetDrivingMode() ~= util.NetworkStringToID("drive_106") then continue end
			local rorg = self:RWTL(v:GetPos())
			local max, min = self:OBBMaxs(), self:OBBMins()
			if rorg.x < min.x or rorg.y < min.y or rorg.z < min.z or rorg.x > max.x or rorg.y > max.y or rorg.z > max.z then continue end
			self:RoomThink(v, rorg)
		end
	end

	if CLIENT then
		self:SetNoDraw(true)
		self:SetNextClientThink(CurTime() + 1)
	end
	return true
end


function ENT:RoomThink(ply, rorg)
	local t = self.PType
	if t == "8hallway" then
		if rorg:DistToSqr(Vector(0, 0, -184)) > 600 ^ 2 then
			local rand = math.random(1, 8)
			if rand == 1 then
				pd106.TP_Exit(ply)
			elseif rand == 2 or rand == 3 then
				pd106.TP_Fakeout(ply)
			elseif rand == 4 or rand == 5 or rand == 7 then
				pd106.TP_4Hallway(ply)
			elseif rand == 6 or rand == 8 then
				pd106.TP_ThroneRoom(ply)
			end
		end
	elseif t == "4hallway" then
		if rorg:DistToSqr(Vector(0, 0, -184)) > 400 ^ 2 then
			local rand = math.random(1, 4)
			if rand == 1 or rand == 2 then
				pd106.TP_Walkway(ply)
			elseif rand == 3 then
				pd106.TP_Fakeout(ply)
			elseif rand == 4 then
				pd106.TP_ThroneRoom(ply)
			end
		end
	elseif t == "walkway" then
		if rorg:DistToSqr(Vector(1144.457031, -1.187500, 64.000000)) < 20 ^ 2 then
			pd106.TP_Exit(ply)
		end
	elseif t == "throneroom" then
		if ply:KeyDown(IN_DUCK) then
			pd106.TP_Walkway(ply)
		end

		ply.PD106MSG = ply.PD106MSG or CurTime() + 3
		if ply.PD106MSG < CurTime() then
			ply:ChatPrint("KNEEL")
			ply.PD106MSG = CurTime() + 0.5
		end
	elseif t == "exit" and not ply.ExitingPD then
		if rorg:DistToSqr(Vector(290.714844, 7.031250, -80.011719)) < 10 ^ 2 then
			pd106.ExitPD(ply)
		end
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "RV1")
	self:NetworkVar("Float", 1, "RV2")
	self:NetworkVar("Float", 2, "RV3")
	self:NetworkVar("String", 0, "PhysModel")
end

function ENT:GetRealPos()
	return Vector(self:GetRV1(), self:GetRV2(), self:GetRV3())
end

function ENT:SetRealPos(vec)
	self:SetRV1(math.Round(vec.x, 3))
	self:SetRV2(math.Round(vec.y, 3))
	self:SetRV3(math.Round(vec.z, 3))
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

local mat = Material("sprites/glow02")
function ENT:Draw()
	self:DrawModel()
	if self.throne or self.throne ~= nil and self:GetPhysModel():find("throneroom") then
		local lookat = (self:RWTL(LocalPlayer():GetPos() + Vector(0, 0, 64)) - Vector(0, -200, 70)):Angle()
		self:DrawSprite(mat, Vector(0, -200, 70) + lookat:Right() * 2.5, 6)
		self:DrawSprite(mat, Vector(0, -200, 70) + lookat:Right() * -2.5, 6)
		self.throne = true
	else
		self.throne = false
	end
	
end

function ENT:DrawSprite(mat, pos, size)
	render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
	render.SetMaterial(mat)
	pos = self:RLTW(pos)
	local lpos = LocalPlayer():GetPos() + Vector(0, 0, 64)
	local dist = lpos:Distance(pos)
	if dist < 320 then
		pos = pos + (pos - lpos):GetNormalized() * math.max(-dist, -10)
		render.DrawSprite(pos, size / dist * 10, size / dist * 10, color_white)
	else
		pos = pos + (pos - lpos):GetNormalized() * (-dist + 70)
		render.DrawSprite(pos, size / dist * 10, size / dist * 10, color_white)
	end
	render.OverrideBlend(false)
	//render.DrawWireframeSphere(pos, 3, 3, 3, Color(255, 0, 0), false)
end

local ang_zero = Angle(0, 0, 0)
function ENT:RLTW(pos)
	return LocalToWorld(pos, ang_zero, self:GetRealPos(), self:GetAngles())
end

function ENT:RWTL(pos)
	return WorldToLocal(pos, ang_zero, self:GetRealPos(), self:GetAngles())
end
AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "scp106_obstacle"
ENT.Author = "eskil"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.SCP106PD = true

function ENT:Initialize()
	self:SetModel("models/scp106/rooms/obstacle.mdl")
	self:SetModelScale(0.7)
end

function ENT:Think()
	self:NextThink(CurTime())
	if CLIENT then self:SetNoDraw(true) self:SetNextClientThink(CurTime()) end
	if IsValid(self:GetParent()) then
		local d = CurTime() * 150 % 720
		local dir = d > 360 and -1 or 1
		if not SERVER then self:SetRealPos(self:GetParent():GetPos() + Vector(0, 0, 100) + Vector(dir < 0 and 250 * 2 or 0, 0, 0) + Angle(0, (dir * d) + (dir < 0 and 180 or 0), 0):Forward() * 250) end
		self:SetPos(self:GetParent():GetPos() + Vector(0, 0, 100) + Vector(dir < 0 and 250 * 2 or 0, 0, 0) + Angle(0, (dir * d) + (dir < 0 and 180 or 0), 0):Forward() * 250)

		for k, v in ipairs(player.GetAll()) do
			if SERVER then
				if v:GetPos():DistToSqr(self:GetPos()) < 85 ^ 2 and v:Alive() then
					drive.PlayerStopDriving(v)
					v:KillSilent()
					v:SetNoTarget(false)
				end
			else
				if v:GetPos():DistToSqr(self:GetRealPos()) < 190 ^ 2 and not v:Alive() then
					if v.Hit106Sound and v.Hit106Sound > CurTime() then v.Hit106Sound = CurTime() + 5 continue end
					v:EmitSound("scp106pd/hit.wav")
					v.Hit106Sound = CurTime() + 5
				end
			end
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

function ENT:Draw()
	self:DrawModel()
end

local ang_zero = Angle(0, 0, 0)
function ENT:RLTW(pos)
	return LocalToWorld(pos, ang_zero, self:GetRealPos(), self:GetAngles())
end

function ENT:RWTL(pos)
	return WorldToLocal(pos, ang_zero, self:GetRealPos(), self:GetAngles())
end
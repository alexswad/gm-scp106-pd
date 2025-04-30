local CurTime = CurTime
local math_cos = math.cos
local math_abs = math.abs
local IsValid = IsValid
local Vector = Vector

if not DREAMS then // autorefresh fix
	Dreams.LoadDreams()
	return
end

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


function pd106.ExitPD(ply)
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


local function add(mdl, offset, tp_pos, tp_ang, lighting)
	local room = DREAMS:AddRoom(mdl, "models/scp106/rooms/" .. mdl .. ".mdl", "data_static/dreams/106/" .. mdl .. ".dat", offset)
	room.tp_pos = tp_pos
	room.tp_ang = tp_ang
	room.MdlLighting = lighting
end

add("8hallway", vector_origin, Vector(0, 0, 100), nil, {0.1, 0.15, 0.1})
add("4hallway", Vector(-1500, 0, 0), Vector(0, 0, 60), nil, {0.4, 0.35, 0.35})
add("fakeout", Vector(-700, 1650, 500), Vector(-230, 0, -50), Angle(0, 180, 0), {0.8, 0.2, 0.2})
add("throneroom", Vector(0, -1500, 0), Vector(0, 150, -140), Angle(0, 270, 0), {1, 0.2, 0.2})
add("exit", Vector(-2000, -1500, 500), Vector(-230, 0, -50), Angle(0, 180, 0), {0.7, 0.4, 0.4})
add("coffins", Vector(2000, 1500, 500), Vector(-290 , 0, -130), Angle(0, 0, 0), {0.4, 0.4, 0.4})
add("walkway", Vector(0, 1600, 0), Vector(-1150, 30, 100), Angle(0, 0, 0), {0.4, 0.5, 0.4})

DREAMS.MoveSpeed = 10
DREAMS.ShiftSpeed = 10
DREAMS.JumpPower = 200
DREAMS.Gravity = 600

local bob = 0
local bd = false

local height = Vector(0, 0, 64)
function DREAMS:CalcView(ply, view)
	local ang = ply:EyeAngles()
	local cos = math_cos(bob)
	local cos2 = math_cos(bob + 0.5)
	ang:RotateAroundAxis(ang:Right(), 0.2 + cos2 * 0.8)
	ang:RotateAroundAxis(ang:Forward(), cos * 4)
	local vel = ply:GetVelocity()
	if math_abs(vel.z) < 1 then
		bob = (bob + Vector(vel.x, vel.y, 0):Length() * FrameTime() / 35) % 6
		if bob % 3 < 0.1 and not bd then
			bd = bob + 0.1
			surface.PlaySound("scp106pd/step" .. math.random(1, 3) .. ".wav")
		elseif bd and bob > bd then
			bd = false
		end
	else
		bob = bob - bob * 0.2
	end
	view.angles = ang
	view.origin = ply:GetDreamPos() + height
end

local mat = Material("sprites/glow02")
local sprite_offset = Vector(0, -200, 70)
local pd_skybox, pd_obstacle
function DREAMS:Draw(ply)
	Dreams.Meta.Draw(self, ply)

	if not IsValid(pd_skybox) then
		pd_skybox = ClientsideModelSafe("models/scp106/rooms/skybox.mdl")
		pd_skybox:SetNoDraw(true)
		pd_skybox:SetModelScale(-4)
	end

	if not IsValid(pd_obstacle) then
		pd_obstacle = ClientsideModelSafe("models/scp106/rooms/obstacle.mdl")
		pd_obstacle:SetNoDraw(true)
		pd_obstacle:SetModelScale(0.8)
	end

	render.SuppressEngineLighting(true)
	pd_skybox:SetPos(ply:GetDreamPos() + Vector(0, 0, 64))
	pd_skybox:DrawModel()

	local obs = self:CalcObstaclePos()
	self.ObsPos = obs
	pd_obstacle:SetPos(self.Rooms["walkway"].offset + obs)
	pd_obstacle:DrawModel()
	render.SuppressEngineLighting(false)

	local room = ply.DreamRoom
	if not room or room.name ~= "throneroom" then return end

	local lookat = ((ply:GetDreamPos() + height) - (room.offset + sprite_offset)):Angle()
	self:DrawSprite(mat, room.offset + sprite_offset + lookat:Right() * 2.5, 40)
	self:DrawSprite(mat, room.offset + sprite_offset + lookat:Right() * -2.5, 40)
end

local flicker
function DREAMS:DrawHUD(ply, w, h)
	if flicker and flicker > CurTime() then
		surface.SetDrawColor(0, 0, 0, 255 * ((flicker + 0.4) - CurTime()))
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end
	Dreams.Meta.DrawHUD(self, ply, w, h)
end

function DREAMS:CalcObstaclePos()
	local d = CurTime() * 150 % 720
	local dir = d > 360 and -1 or 1
	return Vector(0, 0, 100) + Vector(dir < 0 and 250 * 2 or 0, 0, 0) + Angle(0, (dir * d) + (dir < 0 and 180 or 0), 0):Forward() * 250
end

function DREAMS:SetupFog(ply)
	local name = ply.DreamRoom and ply.DreamRoom.name
	render.FogStart(5)
	render.FogEnd((name == "throneroom" or name == "exit") and 230 or 150)
	render.FogMaxDensity(1)
	if name == "throneroom" or name == "fakeout" or name == "4hallway" or name == "exit" then
		render.FogColor(0, 0, 0)
	elseif name == "coffins" then
		render.FogEnd(300)
		render.FogColor(27, 27, 27)
	else
		render.FogColor(3, 17, 12)
	end
	render.FogMode(MATERIAL_FOG_LINEAR)
	return true
end

function DREAMS:DrawSprite(mats, pos, size)
	render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
	render.SetMaterial(mats)
	local lpos = LocalPlayer():GetDreamPos() + height
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

function DREAMS:TPToRoom(ply, room)
	room = self.Rooms[room]
	local tp_pos, tp_ang = room.offset + room.tp_pos, room.tp_ang
	ply:SetDreamPos(tp_pos)
	ply:SetAbsVelocity(vector_origin)
	if tp_ang then ply:SetEyeAngles(tp_ang) end
end

if SERVER then
	function DREAMS:Think(ply)
		local room = ply.DreamRoom
		local ply_table = ply:GetTable()
		if not room then return end
		local t = room.name
		local rorg = ply:GetDreamPos() - room.offset
		if rorg.z < -500 then
			ply:Kill()
			return
		end

		if not ply_table.PD_DMGTIME or ply_table.PD_DMGTIME < CurTime() then // its damage time
			ply:TakeDamage(1)
			if t == "throneroom" then
				ply_table.PD_DMGTIME = CurTime() + 1 / 6
			else
				ply_table.PD_DMGTIME = CurTime() + 1
			end
		end

		if t == "8hallway" then
			if rorg:DistToSqr(Vector(0, 0, -184)) > 600 ^ 2 then
				math.randomseed(ply:Health() + CurTime())
				local rand = math.random(1, 10)
				if rand == 1 then
					self:TPToRoom(ply, "exit")
				elseif rand == 2 or rand == 3 then
					self:TPToRoom(ply, "fakeout")
				elseif rand == 4 or rand == 5 or rand == 7 then
					self:TPToRoom(ply, "4hallway")
				elseif rand == 6 or rand == 8 then
					self:TPToRoom(ply, "throneroom")
				elseif rand == 9 or rand == 10 then
					ply:Kill()
				end
			end
		elseif t == "4hallway" then
			if rorg:DistToSqr(Vector(0, 0, -184)) > 400 ^ 2 then
				math.randomseed(ply:Health() + CurTime())
				local rand = math.random(1, 4)
				if rand == 1 then
					self:TPToRoom(ply, "coffins")
				elseif rand == 2 then
					self:TPToRoom(ply, "walkway")
				elseif rand == 3 then
					self:TPToRoom(ply, "fakeout")
				elseif rand == 4 then
					self:TPToRoom(ply, "throneroom")
				end
			end
		elseif t == "walkway" then
			if rorg:DistToSqr(Vector(1144.457031, -1.187500, 64.000000)) < 20 ^ 2 then
				self:TPToRoom(ply, "exit")
			end
			if self.ObsPos and rorg:DistToSqr(self.ObsPos) < 70 ^ 2 and ply:Alive() then
				ply:Kill()
			end
		elseif t == "throneroom" then
			if ply:KeyDown(IN_DUCK) then
				self:TPToRoom(ply, "walkway")
			end

			ply.PD106MSG = ply.PD106MSG or CurTime() + 3
			if ply.PD106MSG < CurTime() then
				ply:ChatPrint("KNEEL")
				ply.PD106MSG = CurTime() + 0.5
			end
		elseif t == "exit" then
			if rorg:DistToSqr(Vector(290.714844, 7.031250, -80.011719)) < 15 ^ 2 then
				pd106.ExitPD(ply)
			end
		elseif t == "coffins" then
			if rorg:DistToSqr(Vector(205.765625, 182.507812, -169.50000)) < 30 ^ 2 then
				math.randomseed(ply:Health() + CurTime())
				local rand = math.random(1, 4)
				if rand == 1 then
					self:TPToRoom(ply, "8hallway")
				elseif rand == 3 or rand == 2 then
					self:TPToRoom(ply, "fakeout")
				elseif rand == 4 then
					self:TPToRoom(ply, "throneroom")
				end
			end
		end
	end

	function DREAMS:ThinkSelf()
		self.ObsPos = self:CalcObstaclePos()
	end

	function DREAMS:Start(ply)
		Dreams.Meta.Start(self, ply)
		self:TPToRoom(ply, "8hallway")
	end
else
	function DREAMS:Start(ply)
		Dreams.Meta.Start(self, ply)
		RunConsoleCommand("stopsound")

		timer.Simple(0.2, function()
			ply:EmitSound("scp106pd/ambience.wav", 75, 100, 0.3)
		end)
	end

	function DREAMS:End(ply)
		Dreams.Meta.End(self, ply)
		ply:StopSound("scp106pd/ambience.wav")
	end

	local lastroom
	function DREAMS:Think(ply)
		local room = ply.DreamRoom
		if lastroom ~= room then
			ply:EmitSound("scp106pd/laugh.wav")
			flicker = CurTime() + 0.7
			lastroom = room
		end

		if not room then return end
		if room.name == "walkway" then
			local rorg = ply:GetDreamPos() - room.offset
			if not self.PDHitSound and self.ObsPos and rorg:DistToSqr(self.ObsPos) < 120 ^ 2 and not ply:Alive() then
				ply:EmitSound("scp106pd/hit.wav")
				self.PDHitSound = true
			elseif ply:Alive() then
				self.PDHitSound = nil
			end
		elseif room.name == "8hallway" then
			if not self.PDHitSound and not ply:Alive() then
				ply:EmitSound("scp106pd/laugh.wav")
				self.PDHitSound = true
			elseif ply:Alive() then
				self.PDHitSound = nil
			end
		end
	end
end
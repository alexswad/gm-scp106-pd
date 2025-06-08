local CurTime = CurTime
local math_cos = math.cos
local math_abs = math.abs
local IsValid = IsValid
local Vector = Vector
local custom_motionblur = include("scp106/blur.lua")
if SERVER then include("scp106/pd106.lua") end

if not DREAMS then -- autorefresh fix
	Dreams.LoadDreams()
	return
end

DREAMS.Marks = {}
DREAMS.Triggers = {}
DREAMS.Entities = {}
DREAMS.Debug = 1

function DREAMS:StartMove(ply, mv, cmd)
	local speed, jump
	if ply.DreamRoom and ply.DreamRoom.name == "pd4" then
		speed = 8
		jump = 50
	end
	Dreams.Meta.StartMove(self, ply, mv, cmd, speed, jump)
end
-- DREAMS.StartMove = DREAMS.StartMoveFly

local function add(mdl, offset, mdl_lighting, lighting)
	local room = DREAMS:AddRoom(mdl, nil, "data/dreams/" .. mdl .. ".dat", offset)
	room.MdlLighting = mdl_lighting or lighting
	room.Lighting = lighting
	table.Merge(DREAMS.Marks, room.marks or {})
	table.Merge(DREAMS.Triggers, room.triggers or {})
	table.Merge(DREAMS.Entities, room.entities or {})
	return room
end

add("pd1", vector_origin)
add("pd2", Vector(3000, 3000, 10))
add("pd3", Vector(-2500, -3000, -1400), nil, {0.1, 0.2, 0.1})
add("pd4", Vector(1500, -3000))

DREAMS.MoveSpeed = 5
DREAMS.ShiftSpeed = 13
DREAMS.JumpPower = 200
DREAMS.Gravity = 500
DREAMS.Debug = 0

function DREAMS:CalcObstaclePos1()
	local d = CurTime() * 120 % 720
	local dir = d > 360 and -1 or 1
	return self.Marks["obs1"].pos + Vector(dir < 0 and 170 * 2 or 0, 0, 0) + Angle(0, (dir * d) + (dir < 0 and 180 or 0), 0):Forward() * 170
end

function DREAMS:CalcObstaclePos2()
	local d = CurTime() * 120 % 720
	local dir = d > 360 and -1 or 1
	return self.Marks["obs2"].pos + Vector(0, dir < 0 and 170 * 2 or 0, 0) - Angle(0, (dir * d) + (dir < 0 and 180 or 0), 0):Right() * 170
end

local dist = 9000
local b_eye, v_eye
function DREAMS:CalcPlane()
	local d = CurTime() * 22 % 720
	local t = CurTime() * 22 % 360
	local dir = d > 360 and -1 or 1
	b_eye = math_abs(t / 360 * dist - dist / 2) < 1600
	v_eye = Vector((-dist / 2 + dist * t / 360) * dir, 0, 400) + self.Rooms["pd4"].offset
	return v_eye, dir, b_eye
end

function DREAMS:CalcPD1Eyes()
	local t = CurTime() * 20 % 360
	return self.Marks["pd_8center"].pos + Angle(0, t, 80):Forward() * 900
end

----------------------------------------------------
function DREAMS:Teleport(ply, mark)
	mark = self.Marks[mark]
	if not mark.pos then mark = table.Random(mark) end
	ply:SetDreamPos(mark.pos)
	if mark.angles then
		ply:SetEyeAngles(mark.angles)
	end
	ply.S106_HasBeen[mark] = true
	ply.DREAMS_FDGrace = CurTime() + 3
	ply.S106_Ignore = CurTime() + 3
end

function DREAMS:InTrigger(ply, trigger)
	local tbl = self.Triggers[trigger]
	if not tbl then return false end
	local pos = ply:GetDreamPos()
	if not tbl.phys.AA then
		for k, v in ipairs(tbl.phys) do
			if pos:WithinAABox(v.AA, v.BB) then return true end
		end
		return false
	else
		return pos:WithinAABox(tbl.phys.AA, tbl.phys.BB)
	end
end

function DREAMS:SetupDataTables()
	self:NetworkVar("Float", 0, "Door1Open")
	self:NetworkVar("Float", 1, "Door2Open")
end

if SERVER then
	local obs1, obs2
	function DREAMS:ThinkSelf()
		if self:GetDoor1Open(0) ~= 0 and CurTime() - self:GetDoor1Open(0) > 2 then
			self.Entities["door1"].phys.Disabled = true
		else
			self.Entities["door1"].phys.Disabled = nil
		end

		if self:GetDoor2Open(0) ~= 0 and CurTime() - (self:GetDoor2Open(CurTime() + 1)) > 2 then
			self.Entities["door2"].phys.Disabled = true
		else
			self.Entities["door2"].phys.Disabled = nil
		end

		if self.TrickDoorReset < CurTime() then
			if self:GetDoor2Open(0) ~= 0 then self:SetDoor2Open(0) end
			if self:GetDoor1Open(0) ~= 0 then self:SetDoor1Open(0) end
		end
		obs1 = self:CalcObstaclePos1()
		obs2 = self:CalcObstaclePos2()
		self:CalcPlane()
	end

	DREAMS:AddNetSender("obs_death")
	DREAMS.TrickDoorReset = 0
	function DREAMS:Think(ply)
		local room = ply.DreamRoom
		local name = room.name
		local pos = ply:GetDreamPos()
		local immune = ply:HasWeapon("swep_106_pd")
		local ndmg = 1

		if pos.z < -4000 then
			ply:Kill()
			return
		end

		if name == "pd1" and pos:DistToSqr(self.Marks["pd_8center"].pos) > 360 ^ 2 and (not ply.S106_Ignore or ply.S106_Ignore < CurTime()) then
			math.randomseed(ply:Health() + CurTime())
			local rand = math.random(1, 10)
			if rand == 1 then
				self:Teleport(ply, "pd_8hallway")
			elseif rand == 2 or rand == 3 then
				self:Teleport(ply, "pd_trick")
			elseif rand == 4 or rand == 5 or rand == 7 then
				self:Teleport(ply, "pd_4hallway")
			elseif rand == 6 or rand == 8 or rand == 10 then
				if ply.S106_HasBeen["pd_pillars"] then
					self:Teleport(ply, "pd_exit")
				else
					self:Teleport(ply, "pd_pillars")
				end
			elseif rand == 9 then
				ply:Kill()
			end
		elseif name == "pd2" then
			if self:InTrigger(ply, "tp_throneroom") then
				self:Teleport(ply, "pd_throneroom")
			end

			if self:InTrigger(ply, "trick_trigger") then
				self.TrickDoorReset = CurTime() + 3
			end

			if self:InTrigger(ply, "fallgrace") then
				ply.DREAMS_FDGrace = CurTime() + 2
			end

			if self:InTrigger(ply, "throneroom") then
				ndmg = 4
				if ply:KeyDown(IN_DUCK) then
					ply:SetHealth(math.max(ply:Health(), 40))
					self:Teleport(ply, "pd_trench")
				end
			end

			if self:InTrigger(ply, "random") then
				local rand = math.random(1, 5)
				if rand == 1 then
					self:Teleport(ply, "pd_exit")
				elseif rand == 2 then
					self:Teleport(ply, "pd_trick")
				elseif rand == 3 or rand == 4 or rand == 5 then
					if ply.S106_HasBeen["pd_pillars"] then
						self:Teleport(ply, "pd_exit")
					else
						self:Teleport(ply, "pd_pillars")
					end
				end
			end

			if self:InTrigger(ply, "exit") then
				pd106.ExitPD(ply)
			end

			if pos:DistToSqr(obs1) < 100 ^ 2 and ply:Alive() then
				ply:Kill()
				self:SendCommand("obs_death", ply)
			end

			if pos:DistToSqr(obs2) < 100 ^ 2 and ply:Alive() then
				ply:Kill()
				self:SendCommand("obs_death", ply)
			end
		elseif name == "pd3" then
			if self:InTrigger(ply, "exit_pillars") then
				local rand = math.random(1, 3)
				if rand == 1 then
					self:Teleport(ply, "pd_trick")
				elseif rand == 2 or rand == 3 then
					self:Teleport(ply, "pd_exit")
				end
			end
		elseif name == "pd4" then
			if self:InTrigger(ply, "exit_trench") then
				self:Teleport(ply, "pd_exit")
			end

			if not ply.S106_LastDmg or ply.S106_LastDmg < CurTime() then
				if b_eye and not self:InTrigger(ply, "safezone") then
					ply:TakeDamage(1)
					ply.S106_LastDmg = CurTime() + 0.3
				else
					ply:TakeDamage(1)
					ply.S106_LastDmg = CurTime() + 2
				end
			end
		end

		if not ply.S106_LastDmg or ply.S106_LastDmg < CurTime() then
			ply:TakeDamage(ndmg)
			ply.S106_LastDmg = CurTime() + 1
		end
	end

	function DREAMS:KeyPress(ply, key)
		if key == IN_USE then
			local _, _, _, solid, _ = Dreams.Lib.TraceRayPhys(ply.DreamRoom.phys, ply:GetDreamPos() + Vector(0, 0, 64), ply:EyeAngles():Forward(), 50)
			if solid and solid.Entity then
				if solid.Entity.name == "door2_button" and self:GetDoor2Open(0) == 0 then
					self:SetDoor2Open(CurTime())
				elseif solid.Entity.name == "door1_button" and self:GetDoor1Open(0) == 0 then
					self:SetDoor1Open(CurTime())
				end
			end
		end
	end

	function DREAMS:GetFallDamage(ply, speed)
		if ply.DREAMS_FDGrace and ply.DREAMS_FDGrace > CurTime() then return false end
		local dmg = math.max(0, speed * 0.06)
		return dmg > 40 and dmg
	end

	function DREAMS:Start(ply)
		Dreams.Meta.Start(self, ply)
		ply.S106_HasBeen = {}
		self:Teleport(ply, "pd_8hallway")
		ply:SetActiveWeapon(ply:GetWeapon("swep_106_pd") or NULL)
	end
end

function DREAMS:SwitchWeapon(ply, old, new)
	if IsValid(new) and new:GetClass() ~= "swep_106_pd" then return true end
end

--------------------------------------------
if SERVER then return end

DREAMS:AddNetReceiver("obs_death", function(dream, ply)
	timer.Simple(0.1, function()
		ply:EmitSound("scp106pd/hit.wav")
	end)
end)

local bob = 0
local bd = false
local flicker = 0
local lastflicker = 0

local mat = Material("sprites/glow02")
local mdl106
local pillar_time = 0
local chase
local spot = 0
function DREAMS:DrawPillar106(ply)
	if pillar_time == 0 then
		pillar_time = CurTime()
	end
	local time = CurTime() - pillar_time

	if not IsValid(mdl106) then
		mdl106 = ClientsideModelSafe("models/cpthazama/scp/106_old.mdl")
		mdl106:SetNoDraw(true)
		mdl106:ResetSequence("walk")
	end
	local pos
	chase = false
	if time < 10 then
		spot = 1
		pos = self.Marks["scp1"].pos
	elseif time < 20 then
		if spot ~= 2 then
			flicker = CurTime() + 0.4
		end
		pos = self.Marks["scp2"].pos
		spot = 2
	elseif time < 30 then
		if spot ~= 3 then
			flicker = CurTime() + 0.4
		end
		pos = self.Marks["scp3"].pos
		spot = 3
	else
		if spot ~= 4 then
			flicker = CurTime() + 0.4
		end
		chase = true
		spot = 4
	end

	if not chase then
		mdl106:SetPos(pos)
		mdl106:DrawModel()
		mdl106:SetCycle(0.2)
		local face = (ply:GetDreamPos() - pos):Angle()
		mdl106:SetAngles(Angle(0, face.y, 0))

		cam.IgnoreZ(true)
		pos = pos + Vector(0, 0, 82)
		self:DrawSprite(mat, pos + face:Right() * 2.5, 15)
		self:DrawSprite(mat, pos + face:Right() * -2.5, 15)
		cam.IgnoreZ(false)
	end
end

function DREAMS:Start(ply)
	self:StopPlaneSound()
	pillar_time = 0
	flicker = CurTime() + 5
	lastflicker = flicker

	timer.Simple(0.5, function()
		flicker = CurTime() + 0.8
		ply:EmitSound("scp106pd/ambience.wav", 75, 100, 0.3)
		ply:EmitSound("scp106pd/laugh.wav")
	end)
end

function DREAMS:End(ply)
	ply:StopSound("scp106pd/ambience.wav")
	self:StopPlaneSound()
	timer.Simple(0.1, function()
		ply:StopSound("scp106pd/ambience.wav")
		self:StopPlaneSound()
	end)
end

local height = Vector(0, 0, 64)
local theight = Vector(0, 0, 48)
local planegrace = 0
function DREAMS:CalcView(ply, view)
	local ang = ply:EyeAngles()
	local cos = math_cos(bob)
	local cos2 = math_cos(bob + 0.5)
	ang:RotateAroundAxis(ang:Right(), 0.2 + cos2 * 0.8)
	ang:RotateAroundAxis(ang:Forward(), cos * 4)
	local vel = ply:GetVelocity()
	if math_abs(vel.z) < 100 then
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
	if ply.DreamRoom.name == "pd4" then
		if b_eye and not self:InTrigger(ply, "safezone") and planegrace < CurTime() then
			local pdist = v_eye - ply:GetDreamPos()
			local dir = pdist:Angle()
			pdist = 1 / pdist:Distance(vector_origin) * 500

			view.origin = ply:GetDreamPos() + theight + dir:Right() * math.random(1, 3) * pdist + dir:Up() * math.random(1, 3) * pdist
			ply:SetEyeAngles(dir)
		else
			view.origin = ply:GetDreamPos() + theight
		end
	else
		view.origin = ply:GetDreamPos() + height
	end
end

function DREAMS:DrawSprite(mats, pos, size)
	local fog = render.GetFogMode()
	render.FogMode(MATERIAL_FOG_NONE)
	render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
	render.SetMaterial(mats)
	render.DrawSprite(pos, size, size, color_white)
	render.OverrideBlend(false)
	render.FogMode(fog)
end

local pd_skybox
local plane = Material("scp106/pd_plane")
local plane_eye = Material("scp106/pd_planeeye")
local plane_eye_middle = Material("scp106/pd_planeeye_middle")
function DREAMS:Draw(ply, rt)
	if not IsValid(pd_skybox) then
		pd_skybox = ClientsideModelSafe("models/dreams/skybox.mdl")
		pd_skybox:SetNoDraw(true)
		pd_skybox:SetModelScale(-50)
	end

	render.SuppressEngineLighting(true)
	pd_skybox:SetPos(ply:GetDreamPos() + Vector(0, 0, 64))
	pd_skybox:DrawModel()
	render.SuppressEngineLighting(false)

	Dreams.Meta.Draw(self, ply, rt)
	if ply.DreamRoom.name == "pd1" then
		local pos = self:CalcPD1Eyes() + Vector(0, 0, 60)
		local lookat = ((ply:GetDreamPos() + height) - pos):Angle()
		self:DrawSprite(mat, pos + lookat:Right() * 4, 10)
		self:DrawSprite(mat, pos + lookat:Right() * -4, 10)
	elseif self:InTrigger(ply, "throneroom") then
		local pos = self.Marks["pd_eyes"].pos
		local lookat = ((ply:GetDreamPos() + height) - pos):Angle()
		self:DrawSprite(mat, pos + lookat:Right() * 2.5, 7)
		self:DrawSprite(mat, pos + lookat:Right() * -2.5, 7)
	elseif ply.DreamRoom.name == "pd3" then
		self:DrawPillar106(ply)
	end

	if ply.DreamRoom.name == "pd4" then
		local fog = render.GetFogMode()
		render.FogMode(MATERIAL_FOG_NONE)
		local pos, dir, eye = self:CalcPlane()
		self:CheckPlaneSound()
		render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_MIN, BLEND_SRC_COLOR, BLEND_DST_COLOR, BLENDFUNC_MAX )
		render.SetMaterial(eye and plane_eye or plane)
		render.DrawQuadEasy(pos, Vector(0, 0, -1), 7000, 7000, Color(255, 255, 255), dir == -1 and 0 or 180)
		render.SetMaterial(plane_eye_middle)
		render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
		if eye then render.DrawQuadEasy(pos, Vector(0, 0, -1), 7000, 7000, Color(255, 255, 255), dir == -1 and 0 or 180) end
		render.OverrideBlend(false)
		render.FogMode(fog)
	else
		self:StopPlaneSound()
	end

	custom_motionblur(0.05, 0.2, 0.01)
	DrawMotionBlur(0.1, 0.5, 0.08)
end

local lastpos
local kneel = Material("scp106/kneel")
local playedsound
function DREAMS:DrawHUD(ply, w, h)
	if flicker < CurTime() and lastpos and lastpos:DistToSqr(ply:GetDreamPos()) > 150 ^ 2 then
		flicker = CurTime() + 0.8
		planegrace = CurTime() + 4
	end
	lastpos = ply:GetDreamPos()

	if flicker and flicker > CurTime() then
		surface.SetDrawColor(0, 0, 0, 255 * ((flicker + 0.4) - CurTime()))
		surface.DrawRect(0, 0, ScrW(), ScrH())
		if lastflicker == 0 and flicker ~= lastflicker then
			ply:EmitSound("scp106pd/laugh.wav")
		end
		lastflicker = flicker
	else
		lastflicker = 0
	end

	if self:InTrigger(ply, "throneroom") then
		local time = CurTime() % 10
		if time > 1 and time < 1.12 then
			if not playedsound then
				ply:EmitSound("scp106pd/Kneel.wav")
				playedsound = true
			end
			surface.SetDrawColor(0, 0, 0)
			surface.DrawRect(0, 0, ScrW(), ScrH())
			render.SetMaterial(kneel)
			render.DrawScreenQuadEx(-10, -50, ScrW() / 1.5, ScrH() / 1.5)
		elseif time > 1.14 and time < 1.22 then
			surface.SetDrawColor(0, 0, 0)
			surface.DrawRect(0, 0, ScrW(), ScrH())
			render.SetMaterial(kneel)
			render.DrawScreenQuadEx(ScrW() / 3, ScrH() / 3, ScrW() / 1.5, ScrH() / 1.5)
		elseif time > 1.25 and time < 1.36 then
			render.SetMaterial(kneel)
			render.DrawScreenQuad()
		end
	else
		playedsound = false
	end
	Dreams.Meta.DrawHUD(self, ply, w, h)
end

function DREAMS:CalcDoorSeq(prop, num)
	local mdl = prop.CMDL
	local cnum = (CurTime() - num) / 2.5
	if num > 0 then
		if not prop.playedsound then
			prop.playedsound = true
			LocalPlayer():EmitSound("scp106pd/dooropen3.wav", 100, 90, math.Clamp(50 ^ 2 / prop.origin:DistToSqr(LocalPlayer():GetDreamPos()), 0, 0.8))
		end

		mdl:SetSequence("open")
		mdl:SetCycle(cnum)
		if cnum > 0.8 then
			prop.phys.Disabled = true
		end
	else
		mdl:SetSequence("closed")
		prop.phys.Disabled = false
		prop.playedsound = false
	end
end

function DREAMS:RenderProps(props)
	for a, b in ipairs(props) do
		self:DrawPropModel(b)
		if b.name == "door1_prop" then
			b.phys = b.phys or self.Entities["door1"].phys
			self:CalcDoorSeq(b, self:GetDoor1Open(0))
		elseif b.name == "door2_prop" then
			b.phys = b.phys or self.Entities["door2"].phys
			self:CalcDoorSeq(b, self:GetDoor2Open(0))
		elseif b.name == "obs_prop1" then
			b.CMDL:SetRenderOrigin(self:CalcObstaclePos1())
		elseif b.name == "obs_prop2" then
			b.CMDL:SetRenderOrigin(self:CalcObstaclePos2())
		end
	end
end

function DREAMS:RenderRooms(ply, drawall)
	Dreams.Meta.RenderRooms(self, ply, drawall)
	if ply.DreamRoom.name == "pd1" then
		self.MoveEffect = (self.MoveEffect or 0) + FrameTime() * 0.01
		self.Rooms["pd1"].CMDL:SetSequence("moving")
		self.Rooms["pd1"].CMDL:SetCycle(self.MoveEffect)
	else
		self.MoveEffect = 0
	end
end

function DREAMS:SetupFog(ply)
	local name = ply.DreamRoom.name
	render.FogStart(5)
	render.FogEnd(150)
	render.FogMaxDensity(1)
	if name == "pd2" or name == "pd1" then
		render.FogColor(0, 0, 0)
		if name == "pd1" then
			render.FogEnd(230 - ply:GetDreamPos():Distance(self.Marks["pd_8center"].pos) / 2)
		else
			render.FogEnd(200)
			if self:InTrigger(ply, "throneroom") then
				render.FogEnd(400)
			end
		end
	elseif name == "pd4" then
		render.FogMaxDensity(0.90)
		render.FogColor(10, 46, 36, 124)
	elseif name == "pd3" then
		render.FogColor(3, 17, 12)
		render.FogEnd(150 * math.min(15, 1 / math.abs(ply:EyeAngles().x) * 100))
	end
	render.FogMode(MATERIAL_FOG_LINEAR)
	return true
end

function DREAMS:HUDShouldDraw(ply, str)
	if str == "CHudWeaponSelection" and not ply:HasWeapon("swep_106_pd") then return false end
end

function DREAMS:CheckPlaneSound()
	if not self.PlaneSound then
		self.PlaneSound = CreateSound(LocalPlayer(), "scp106pd/plane_loop.wav")
		self.PlaneSound:SetSoundLevel(0)
		self.PlaneSound:PlayEx(0.1, 100)

		timer.Create("106PD_PlaneSound", 11, 0, function()
			if not self.PlaneSound then
				timer.Remove("106PD_PlaneSound")
				return
			end
			self.PlaneSound:Stop()
			timer.Simple(0, function()
				self.PlaneSound:PlayEx(math.min(0.8, 1000 / LocalPlayer():GetDreamPos():Distance(v_eye)), 100)
			end)
		end)
	end

	if not self.LastSoundUpdate or self.LastSoundUpdate < CurTime() then
		self.PlaneSound:ChangeVolume(math.min(0.8, 1000 / LocalPlayer():GetDreamPos():Distance(v_eye)))
		self.LastSoundUpdate = CurTime() + 0.1
	end
end

function DREAMS:StopPlaneSound()
	LocalPlayer():StopSound("scp106pd/plane_loop.wav")
	timer.Remove("106PD_PlaneSound")
	if self.PlaneSound then
		self.PlaneSound:Stop()
		self.PlaneSound = nil
	end
end

function DREAMS:Init()
	self:StopPlaneSound()
end
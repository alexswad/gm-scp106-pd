local CurTime = CurTime
local math_cos = math.cos
local math_abs = math.abs
local IsValid = IsValid
local Vector = Vector

if not DREAMS then -- autorefresh fix
	Dreams.LoadDreams()
	return
end

DREAMS.Marks = {}
DREAMS.Triggers = {}
DREAMS.Entities = {}
DREAMS.StartMove = DREAMS.StartMoveFly

function DREAMS:StartMove(ply, mv, cmd)
	local speed
	if ply.DreamRoom.name == "pd4" then
		speed = 7
	end
	Dreams.Meta.StartMove(self, ply, mv, cmd, speed)
end

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

DREAMS.MoveSpeed = 50
DREAMS.ShiftSpeed = 130
DREAMS.JumpPower = 50
DREAMS.Gravity = 500
DREAMS.Debug = 1


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

local dist = 5000
local b_eye, v_eye
function DREAMS:CalcPlane()
	local d = CurTime() * 20 % 720
	local t = CurTime() * 20 % 360
	local dir = d > 360 and -1 or 1
	b_eye = math_abs(t / 360 * dist - dist / 2) < 1600
	v_eye = Vector((-dist / 2 + dist * t / 360) * dir, 0, 250) + self.Rooms["pd4"].offset
	return v_eye, dir, b_eye
end

function DREAMS:CalcPD1Eyes()
	local t = CurTime() * 20 % 360
	return self.Marks["pd_8center"].pos + Angle(0, t, 80):Forward() * 900
end


----------------------------------------------------
function DREAMS:Teleport(ply, mark)
	mark = self.Marks[mark]
	ply:SetDreamPos(mark.pos)
	if mark.angles then
		ply:SetEyeAngles(mark.angles)
	end
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
	end

	function DREAMS:Think(ply)
		local room = ply.DreamRoom
		local name = room.name
		local pos = ply:GetDreamPos()
		if name == "pd1" and pos:DistToSqr(self.Marks["pd_8center"].pos) > 360 ^ 2 then
			math.randomseed(ply:Health() + CurTime())
			local rand = math.random(1, 10)
			if rand == 1 then
				self:Teleport(ply, "pd_exit")
			elseif rand == 2 or rand == 3 then
				self:Teleport(ply, "pd_trick")
			elseif rand == 4 or rand == 5 or rand == 7 then
				self:Teleport(ply, "pd_4hallway")
			elseif rand == 6 or rand == 8 or rand == 10 then
				self:Teleport(ply, "pd_pillars")
			elseif rand == 9 then
				ply:Kill()
			end
		elseif name == "pd2" then

		elseif name == "pd3" then

		elseif name == "pd4" then
			
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
end

--------------------------------------------
if SERVER then return end

local bob = 0
local bd = false

local height = Vector(0, 0, 64)
local theight = Vector(0, 0, 48)
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
		if b_eye and not self:InTrigger(ply, "safezone") then ply:SetEyeAngles((v_eye - ply:GetDreamPos()):Angle()) end
		view.origin = ply:GetDreamPos() + theight
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
local mat = Material("sprites/glow02")
local plane = Material("scp106/pd_plane")
local plane_eye = Material("scp106/pd_planeeye")
local plane_eye_middle = Material("scp106/pd_planeeye_middle")
function DREAMS:Draw(ply, rt)
	if not IsValid(pd_skybox) then
		pd_skybox = ClientsideModelSafe("models/dreams/skybox.mdl")
		pd_skybox:SetNoDraw(true)
		pd_skybox:SetModelScale(-10)
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
	elseif ply.DreamRoom.name == "pd4" then
		local fog = render.GetFogMode()
		render.FogMode(MATERIAL_FOG_NONE)
		local pos, dir, eye = self:CalcPlane()
		render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_MIN, BLEND_SRC_COLOR, BLEND_DST_COLOR, BLENDFUNC_MAX )
		render.SetMaterial(eye and plane_eye or plane)
		render.DrawQuadEasy(pos, Vector(0, 0, -1), 5000, 5000, Color(255, 255, 255), dir == -1 and 0 or 180)
		render.SetMaterial(plane_eye_middle)
		render.OverrideBlend( true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD )
		if eye then render.DrawQuadEasy(pos, Vector(0, 0, -1), 5000, 5000, Color(255, 255, 255), dir == -1 and 0 or 180) end
		render.OverrideBlend(false)
		render.FogMode(fog)
	end

	DrawMotionBlur(0.1, 0.5, 0.08)
end

local flicker
local kneel = Material("scp106/kneel")
function DREAMS:DrawHUD(ply, w, h)
	if flicker and flicker > CurTime() then
		surface.SetDrawColor(0, 0, 0, 255 * ((flicker + 0.4) - CurTime()))
		surface.DrawRect(0, 0, ScrW(), ScrH())
	end

	if self:InTrigger(ply, "throneroom") then
		local time = CurTime() % 10
		if time > 1 and time < 1.12 then
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
		end
	elseif name == "pd4" then
		render.FogMaxDensity(0.90)
		render.FogColor(10, 46, 36, 124)
		render.FogEnd(150)
	else
		render.FogColor(3, 17, 12)
	end
	render.FogMode(MATERIAL_FOG_LINEAR)
	return true
end
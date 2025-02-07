// Based off a WIP project called dreams, readdapted to demonstrate the concept in a more familiar way
// TODO: Optimize everything because this was coded across 10 days in hopes of it just being done

AddCSLuaFile("dreams_106/4hallway.lua")
AddCSLuaFile("dreams_106/8hallway.lua")
AddCSLuaFile("dreams_106/exit.lua")
AddCSLuaFile("dreams_106/fakeout.lua")
AddCSLuaFile("dreams_106/throneroom.lua")
AddCSLuaFile("dreams_106/walkway.lua")

local intersectrayplane = util.IntersectRayWithPlane
local normal = function(c, b, a)
	return ((b - a):Cross(c - a)):GetNormalized()
end

local function check(a, b, c, p)
	local cr1 = (b - a):Cross(c - a)
	local cr2 = (b - a):Cross(p - a)
	return cr1:Dot(cr2) >= 0
end

local bob = 0
local bd = false

drive.Register("drive_106", {
	CalcView = function(self, view)
		local ang = self.Player:EyeAngles()
		local cos = math.cos(bob)
		local cos2 = math.cos(bob + 0.5)
		ang:RotateAroundAxis(ang:Right(), 0.2 + cos2 * 0.8)
		ang:RotateAroundAxis(ang:Forward(), cos * 4)
		local vel = self.Player:GetVelocity()
		if math.abs(vel.z) < 1 then
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
		view.origin = self.Player:GetPos() + Vector(0, 0, 64)
	end,

	StartMove = function(self, mv, cmd)
		local ply = self.Player
		ply:SetMoveType(MOVETYPE_NOCLIP)
		if SERVER then ply:SetNoTarget(true) end

		mv:SetVelocity(ply:GetAbsVelocity())
		mv:SetOrigin(ply:GetNetworkOrigin())

		local ang = mv:GetMoveAngles()
		local pos = Vector(0, 0, 0)
		local speed = 8
		if cmd:KeyDown(IN_SPEED) then
			speed = 8
		end

		if cmd:KeyDown(IN_MOVERIGHT) then
			pos:Add(ang:Right())
		end

		if cmd:KeyDown(IN_MOVELEFT) then
			pos:Add(-ang:Right())
		end

		if cmd:KeyDown(IN_FORWARD) then
			pos:Add(Angle(0, ang.y, 0):Forward())
		end

		if cmd:KeyDown(IN_BACK) then
			pos:Add(-Angle(0, ang.y, 0):Forward())
		end

		pos:Normalize()
		local vel = mv:GetVelocity() * 0.9 + pos * speed

		if vel:IsEqualTol(Vector(0, 0, 0), 3) then
			vel = Vector(0, 0, 0)
		end

		if vel.z < 0 then vel:Set(Vector(vel.x, vel.y, math.min(vel.z, -1) / 0.9)) end
		vel:Add(Vector(0, 0, -600 * FrameTime()))
		mv:SetVelocity(vel)

	end,

	Move = function(self, mv)
		local vel, org = mv:GetVelocity(), mv:GetOrigin()
		local onfloor
		local props = ents.FindByClass("s106_phys")
		if SERVER and #props == 0 then pd106.ExitPD(self.Player) return end
		if SERVER and self.Player:GetPos().z - props[1]:GetPos().z < -1000 and self.Player.PDGraceTime and self.Player.PDGraceTime < CurTime() then
			drive.PlayerStopDriving(self.Player)
			self.Player:KillSilent()
			self.Player:SetNoTarget(false)
			return
		end
		for k, prop in pairs(props) do
			local rnorm, rorg = prop:WorldToLocalAngles(vel:Angle()):Forward(), prop:RWTL(org)
			local rvel = rnorm * vel:Length()

			local woff = Vector(0, 0, 32)
			for _, s in pairs(prop.Phys or {}) do
				local norm = normal(s.plane[1], s.plane[2], s.plane[3])
				local worg = rorg + woff
				local rvel_len = rvel:Length()
				local hit = intersectrayplane(worg + norm * rvel_len, -norm, s.plane[1], norm)
				local fhit = norm:IsEqualTol(Vector(0, 0, 1), 0.3)
					and intersectrayplane(rorg + Vector(0, 0, 1) * rvel_len * 2, Vector(0, 0, -1), s.plane[1], norm)
				local wd, fd = hit and (worg - hit + norm):Dot(norm) or 0, fhit and (rorg - fhit + norm):Dot(norm) or 0
				if not fhit and hit and (hit:DistToSqr(worg) < 16 ^ 2 or wd < 0 and wd > -2) or fhit and (fhit:DistToSqr(rorg) < 1 or fd < 0 and fd > -2 * math.abs(rvel.z / 10)) then
					local a, b, c, d = unpack(s.vertices)
					local e = fhit or hit
					if check(a, b, c, e) and check(b, c, a, e) and check(c, d, a, e) and check(d, a, b, e) then
						if fhit then
							onfloor = true
							rorg = Vector(rorg.x, rorg.y, fhit.z)
							rvel = Vector(rvel.x, rvel.y, 0)
							self.Player.PDLRoom = prop
						else
							rorg = hit - Vector(0, 0, 32) + norm * 16
						end
					end
				end
			end

			org = prop:RLTW(rorg)
			vel = prop:LocalToWorldAngles(rvel:Angle()):Forward() * rvel:Length()
		end

		if onfloor and mv:KeyPressed(IN_JUMP) then
			vel = Vector(vel.x, vel.y, 200)
			mv:SetVelocity(vel)
		end

		mv:SetOrigin(org + vel * FrameTime())
		mv:SetVelocity(vel)
	end,

	FinishMove =  function( self, mv )
		self.Entity:SetNetworkOrigin( mv:GetOrigin() )
		self.Entity:SetAbsVelocity( mv:GetVelocity() )
		//self.Entity:SetAngles( mv:GetMoveAngles() )

		if SERVER and IsValid(self.Entity:GetPhysicsObject()) then
			local phys = self.Entity:GetPhysicsObject()
			phys:EnableMotion(true)
			phys:SetPos(mv:GetOrigin())
			phys:Wake()
			phys:EnableMotion(false)
		end
	end,
},"drive_base")


if SERVER then
	pd106 = pd106 or {}
	pd106.ents = pd106.ents or {}
	local pdents = pd106.ents
	local function create_ent(model, pos)
		local ent = ents.Create("s106_phys")
		ent:SetRealPos(pos)
		ent:SetPos(pos)
		ent:Spawn()
		ent:SetModel("models/scp106/rooms/" .. model .. ".mdl")
		ent:SetPhysModel("lua/dreams_106/" .. model .. ".lua")
		ent.PType = model
		pdents[model] = ent
		return ent
	end


	function pd106.InitPD()
		if IsValid(pdents["8hallway"]) then return end
		local pdoff = Vector(-50000, 100000, -10000)
		create_ent("8hallway", pdoff)
		create_ent("4hallway", pdoff + Vector(-1500, 0, 0))
		create_ent("fakeout", pdoff + Vector(-700, 1650, 500))
		local walk = create_ent("walkway", pdoff + Vector(0, 1600, 0))
		local obstacle = ents.Create("s106_obstacle")
		obstacle:SetParent(walk)
		obstacle:SetPos(walk:GetPos())
		obstacle:SetRealPos(walk:GetPos())
		obstacle:Spawn()
		create_ent("throneroom", pdoff + Vector(0, -1500, 0))
		create_ent("exit", pdoff + Vector(-2000, -1500, 500))
	end

	function pd106.PutInPD(ply)
		pd106.InitPD()
		if ply:IsDrivingEntity() then return end
		ply:EmitSound("scp106pd/corrision.wav")
		local puddle = ents.Create("s106_pd_puddle")
		puddle:SetPos(ply:GetPos())
		puddle:Spawn()
		ply.PDOutPos = ply:GetPos()
		ply:SetNoTarget(true)
		SafeRemoveEntityDelayed(puddle, 60 * 3)
		timer.Create(ply:SteamID() .. "_106PD", 0, 0, function()
			ply:SetMoveType(MOVETYPE_FLY)
			ply:Freeze(true)
			ply:SetPos(ply:GetPos() - Vector(0, 0, 30 * FrameTime()))
		end)
		timer.Simple(2, function()
			ply.PDGraceTime = CurTime() + 3
			timer.Stop(ply:SteamID() .. "_106PD")
			drive.PlayerStartDriving(ply, ply, "drive_106")

			timer.Simple(0.1, function()
				ply:SetPos(pdents["8hallway"]:RLTW(Vector(0, 0, 100)))
				ply:Freeze(false)
				ply:SetActiveWeapon(nil)
			end)
		end)
	end

	function pd106.TP_4Hallway(ply)
		ply:SetPos(pdents["4hallway"]:RLTW(Vector(0, 0, 60)))
	end

	function pd106.TP_Fakeout(ply)
		ply:SetPos(pdents["fakeout"]:RLTW(Vector(-230, 0, -50)))
		ply:SetEyeAngles(pdents["fakeout"]:WorldToLocalAngles(Angle(0, 180, 0)))
	end

	function pd106.TP_ThroneRoom(ply)
		ply:SetPos(pdents["throneroom"]:RLTW(Vector(0, 150, -150)))
		ply:SetEyeAngles(pdents["throneroom"]:WorldToLocalAngles(Angle(0, 270, 0)))
	end

	function pd106.TP_Walkway(ply)
		ply:SetPos(pdents["walkway"]:RLTW(Vector(-1150, 30, 100)))
		ply:SetEyeAngles(pdents["walkway"]:WorldToLocalAngles(Angle(0, 0, 0)))
	end

	function pd106.TP_Exit(ply)
		ply:SetPos(pdents["exit"]:RLTW(Vector(-230, 0, -50)))
		ply:SetEyeAngles(pdents["exit"]:WorldToLocalAngles(Angle(0, 180, 0)))
	end

	function pd106.ExitPD(ply)
		ply.ExitingPD = true
		drive.PlayerStopDriving(ply)
		timer.Simple(0, function()
			timer.Simple(0.2, function()
				EmitSound("scp106pd/decay.wav", ply.PDOutPos + Vector(0, 0, 32))
			end)
			ply:SetPos(ply.PDOutPos - Vector(0, 0, 64))
			ply:SetNoTarget(false)
			timer.Create(ply:SteamID() .. "_106PD", 0, 0, function()
				ply:SetMoveType(MOVETYPE_FLY)
				ply:Freeze(true)
				ply:SetPos(ply:GetPos() + Vector(0, 0, 30 * FrameTime()))
				if ply:GetPos().z - ply.PDOutPos.z > 5 then
					timer.Stop(ply:SteamID() .. "_106PD")
					ply:Freeze(false)
					ply:SetMoveType(MOVETYPE_WALK)
					ply.ExitingPD = false
				end
			end)
		end)
	end

	local class_106 = {
		["npc_cpt_scp_106_old"] = true,
		["npc_cpt_scp_106"] = true,
		["npc_106"] = true,
		["drg_uescp106ver2"] = true,
		["drg_uescp106b2"] = true,
		["106"] = true,
	}
	pd106.class_106 = class_106

	hook.Add("EntityTakeDamage", "test", function(ply, dmg)
		local attacker = IsValid(dmg:GetAttacker()) and dmg:GetAttacker() or dmg:GetInflictor()
		if not IsValid(ply) or not IsValid(attacker) or not class_106[attacker:GetClass()] or not ply:IsPlayer() then return end

		pd106.PutInPD(ply)
		return true
	end)

	timer.Create("Damage106PD", 1, 0, function()
		for k, v in pairs(player.GetAll()) do
			if not v:IsDrivingEntity() or v:GetDrivingMode() ~= util.NetworkStringToID("drive_106") then continue end
			v:TakeDamage(0.5)
			if v.PDLRoom == pd106.ents["throneroom"] then
				v:TakeDamage(4)
			end
		end
	end)

	local pp = function(v)
		if v:IsDrivingEntity() and v:GetDrivingMode() == util.NetworkStringToID("drive_106") then return false end
	end
	hook.Add("PlayerSpawnObject", "106PD_Restrict", pp)
	hook.Add("PlayerSpawnSENT", "106PD_Restrict", pp)
	hook.Add("PlayerSpawnNPC", "106PD_Restrict", pp)
	hook.Add("PlayerSpawnSWEP", "106PD_Restrict", pp)
	hook.Add("CanPlayerSuicide", "106PD_Restrict", pp)
	hook.Add("PlayerNoClip", "106PD_Restrict", pp)
else
	local lastroom
	local pd_skybox
	local flicker
	hook.Add("PostDrawOpaqueRenderables", "SCPdraw_106_pd", function()
		if not LocalPlayer():IsDrivingEntity() or LocalPlayer():GetDrivingMode() ~= util.NetworkStringToID("drive_106") then 
			if LocalPlayer().PDLoopSound then
				LocalPlayer():StopSound("scp106pd/ambience.wav")
				LocalPlayer().PDLoopSound = nil
			end
			return
		end

		if not LocalPlayer().PDLoopSound then
			RunConsoleCommand("stopsound")
			timer.Simple(0.2, function()
				LocalPlayer():EmitSound("scp106pd/ambience.wav", 75, 100, 0.3)
			end)
			LocalPlayer().PDLoopSound = true
		end

		if not IsValid(pd_skybox) then
			pd_skybox = ClientsideModel("models/scp106/rooms/skybox.mdl")
			pd_skybox:SetNoDraw(true)
			pd_skybox:SetModelScale(-4)
		end

		render.SuppressEngineLighting(true)
		pd_skybox:SetPos(LocalPlayer():GetPos() + Vector(0, 0, 64)) 
		pd_skybox:DrawModel() 
		render.SuppressEngineLighting(false)

		for k, v in pairs(ents.FindByClass("s106_*")) do
			if not v.SCP106PD then continue end
			local max, min = v:OBBMaxs(), v:OBBMins()
			local rorg = v:RWTL(LocalPlayer():GetPos() + Vector(0, 0, 2))
			if v:GetClass() ~= "s106_obstacle" and lastroom ~= v and (rorg.x < min.x or rorg.y < min.y or rorg.z < min.z or rorg.x > max.x or rorg.y > max.y or rorg.z > max.z) then continue end

			render.DepthRange(0.1, 0)
			render.SuppressEngineLighting(true)

			render.SetAmbientLight(255 ,255 , 255)

			v:SetRenderOrigin(v:GetRealPos())

			v:DrawModel()

			render.SuppressEngineLighting(false)
			cam.IgnoreZ(false)
			if v:GetClass() == "s106_obstacle" then continue end
			if lastroom ~= v then
				LocalPlayer():EmitSound("scp106pd/laugh.wav")
				flicker = CurTime() + 0.7
			end
			lastroom = v
		end
	end)

	// Yes, this is all garbage and quickly done, thanks for noticing
	hook.Add("SetupWorldFog", "SCPdraw_106_pd_fog", function()
		//if true then return end
		if not LocalPlayer():IsDrivingEntity() or LocalPlayer():GetDrivingMode() ~= util.NetworkStringToID("drive_106") then return end
		render.FogStart(5)
		render.FogEnd(IsValid(lastroom) and (lastroom.throne or lastroom:GetPhysModel():find("exit")) and 230 or 150)
		if IsValid(lastroom) and (lastroom.throne or lastroom:GetPhysModel():find("fakeout") or lastroom:GetPhysModel():find("4hallway") or lastroom:GetPhysModel():find("exit"))  then
			render.FogColor(0, 0, 0)
		else
			render.FogColor(3, 17, 12)
		end
		render.FogMaxDensity(1)
		render.FogMode(MATERIAL_FOG_LINEAR)
		return true
	end)

	hook.Add("SetupSkyboxFog", "SCPdraw_106_pd_fog", function(s)
		//if true then return end
		if not LocalPlayer():IsDrivingEntity() or LocalPlayer():GetDrivingMode() ~= util.NetworkStringToID("drive_106") then return end
		render.FogStart(10 * s)
		render.FogEnd(100 * s)
		render.FogColor(0, 0, 0)
		render.FogMode(MATERIAL_FOG_LINEAR)
		render.FogMaxDensity(1)
		return true
	end)

	hook.Add("PreDrawHUD", "SCPpd106_flicker", function()
		if not flicker or flicker and flicker < CurTime() then return end
		cam.Start2D()

		surface.SetDrawColor(0, 0, 0, 255 * ((flicker + 0.4) - CurTime()))
		surface.DrawRect(0, 0, ScrW(), ScrH())

		cam.End2D()
	end)
end
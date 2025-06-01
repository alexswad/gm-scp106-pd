if SERVER then return end
local NextDraw = 0
local LastDraw = 0
local mat_MotionBlur = Material( "pp/motionblur" )
local mat_Screen = Material( "pp/fb" )
local tex_MotionBlur = render.GetMoBlurTex0()

return function( addalpha, drawalpha, delay )

	if ( drawalpha == 0 ) then return end

	-- Copy the backbuffer to the screen effect texture
	render.UpdateScreenEffectTexture()

	-- If it's been a long time then the buffer is probably dirty, update it
	if ( CurTime() - LastDraw > 0.5 ) then

		mat_Screen:SetFloat( "$alpha", 1 )

		render.PushRenderTarget( tex_MotionBlur )
			render.SetMaterial( mat_Screen )
			render.DrawScreenQuadEx(0, 0, ScrW(), ScrH())
		render.PopRenderTarget()

	end

	-- Set up out materials
	mat_MotionBlur:SetFloat( "$alpha", drawalpha )
	mat_MotionBlur:SetTexture( "$basetexture", tex_MotionBlur )

	if ( NextDraw < CurTime() && addalpha > 0 ) then

		NextDraw = CurTime() + delay

		mat_Screen:SetFloat( "$alpha", addalpha )
		render.PushRenderTarget( tex_MotionBlur )
			render.SetMaterial( mat_Screen )
			render.DrawScreenQuadEx(0, 10 *  math.abs(math.sin(CurTime() * 1.5)), ScrW(), ScrH() - 30)
		render.PopRenderTarget()

	end

	render.SetMaterial( mat_MotionBlur )
	render.DrawScreenQuadEx(0, 10 * math.abs(math.cos(CurTime() * 1.5)), ScrW(), ScrH())

	LastDraw = CurTime()

end
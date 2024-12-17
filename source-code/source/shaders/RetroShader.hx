package shaders;

import flixel.system.FlxAssets.FlxShader;



class Retro extends FlxShader
{

	@:glFragmentSource('
        #pragma header
        vec2 uv = openfl_TextureCoordv.xy;
        vec2 fragCoord = openfl_TextureCoordv*openfl_TextureSize;
        vec2 iResolution = openfl_TextureSize;
        uniform float iTime;
        #define iChannel0 bitmap
        #define texture flixel_texture2D
        #define fragColor gl_FragColor
        #define mainImage main

		void main()
		{
            float RES = 3200.0;
            float VINGETE = 0.0;
            vec2 res = vec2(RES,RES*(iResolution.y / iResolution.x));
            
            // Simulate lo-res. In a real game, you would just render at lo-res.
            uv -= mod(uv, 1.0 / res);
        
            vec3 color = texture(iChannel0, uv).xyz;
            
            float vingette = 1.0 - VINGETE * length(2.0*uv-1.0);
            color *= vingette;
            
            // less colors default 4
            color -= mod(color, 1.0 / 8.0);
        
            // Output to screen
            fragColor = vec4(color,1.0);           
		}')
	public function new()
	{
		super();
	}
}
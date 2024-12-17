package shaders;

import flixel.system.FlxAssets.FlxShader;



class Data extends FlxShader
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
        
        void main( out vec4 fragColor, in vec2 fragCoord )
        {
            // fetch buffer a
            ivec2 u = ivec2(fragCoord);
            vec4 tex = texelFetch(iChannel0, u, 0);
            
            // fetch buffer b
            if(iFrame % 8 != 0  && tex.w > 0.)u = ivec2(tex.xy);
            fragColor = texelFetch(iChannel1, u, 0);
        }')
	public function new()
	{
		super();
	}
}
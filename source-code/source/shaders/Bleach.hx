package shaders;

import flixel.system.FlxAssets.FlxShader;



class Bleach extends FlxShader
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
        
        float scale = 2.0;
        vec4 c = vec4(0.2124,0.7153,0.0722,0.0);
        
        vec4 bleach(vec4 p, vec4 m, vec4 s) 
        {
            vec4 a = vec4(1.0);
            vec4 b = vec4(2.0);
            float l = dot(m,c);
            float x = clamp((l - 0.45) * 10.0, 0.0, 1.0);
            vec4 t = b * m * p;
            vec4 w = a - (b * (a - m) * (a - p));
            vec4 r = mix(t, w, vec4(x) );
            return mix(m, r, s);
        }
        
        void mainImage( out vec4 fragColor, vec2 fragCoord )
        {
            vec2 uv = fragCoord.xy / iResolution.xy;
            vec4 p = texture(iChannel0,uv);
            vec4 k = vec4(vec3(dot(p,c)),p.a);
            fragColor = bleach(k, p, vec4(scale));
        }        
        
        
        
        ')
	public function new()
	{
		super();
	}
}
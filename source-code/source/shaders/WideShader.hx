package shaders;

import flixel.system.FlxAssets.FlxShader;



class Wide extends FlxShader
{

	@:glFragmentSource('
    #pragma header

    void main()
    {
		vec2 pos = openfl_TextureCoordv;
		pos -= 0.5;
		float xx = abs(cos(pos.x));
		float yy = abs(cos(pos.y*0.2625));
		pos *= xx*yy;
		pos += 0.5;
		gl_FragColor = flixel_texture2D(bitmap, pos);
    }')
	public function new()
	{
		super();
	}
}
package backend;

import openfl.utils.Assets;
import haxe.Json;
import backend.Song;

typedef SprayFile = {
	var SprColors:Array<String>;
	var Sprays:Array<String>;
	var SpraySongs:Array<String>;
}

class SprayData {
	public static function loadPreset() {
		var spraySet:SprayFile = getPresetFile();
	}

	public static function getPresetFile():SprayFile {
		var rawJson:String = null;
		var path:String = Paths.getSharedPath('images/tvorog/sprayPart/Presets/PresetSettings.json');
		if(Assets.exists(path)) {
			rawJson = Assets.getText(path);
		}
		else
		{
			return null;
		}
		return cast tjson.TJSON.parse(rawJson);
	}
}

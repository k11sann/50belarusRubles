package backend;

import openfl.utils.Assets;
import haxe.Json;
import backend.Song;

typedef ChooseFile = {
    var SelectedColor:String;
	var ChooseSong:Array<Dynamic>;
	var ModSongs:Array<Dynamic>;
    var CharSize:Array<Dynamic>;
}

class ChooseData {
	public static function loadChoose() {
		var creditSet:ChooseFile = getChooseFile();
	}

	public static function getChooseFile():ChooseFile {
		var rawJson:String = null;
		var path:String = Paths.getSharedPath('images/tvorog/choose/choose.json');
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

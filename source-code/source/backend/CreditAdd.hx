package backend;

import openfl.utils.Assets;
import haxe.Json;
import backend.Song;

typedef CreditFile = {
	var CreditName:Array<Dynamic>;
}

class CreditData {
	public static function loadCredit() {
		var creditSet:CreditFile = getCreditFile();
	}

	public static function getCreditFile():CreditFile {
		var rawJson:String = null;
		var path:String = Paths.getSharedPath('images/tvorog/credit/credits.json');
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

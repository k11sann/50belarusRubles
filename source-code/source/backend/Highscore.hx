package backend;
import flixel.input.keyboard.FlxKey;

class Highscore
{
	public static var weekScores:Map<String, Int> = new Map();
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var songRating:Map<String, String> = new Map<String, String>();
	public static var settings:Map<String, Bool> = new Map();
	

	public static function resetSong(song:String, diff:Int = 0):Void
	{
		var daSong:String = formatSong(song, diff);
		setScore(daSong, 0);
		setRating(daSong, 'NONE');
	}

	public static function resetWeek(week:String, diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);
		setWeekScore(daWeek, 0);
	}

	public static function saveScore(song:String, score:Int = 0, ?diff:Int = 0, ?rating:String = 'NONE'):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
				if(rating != 'NONE' || rating != getRating(song, diff)) setRating(daSong, rating);
			}
		}
		else {
			setScore(daSong, score);
			if(rating != 'NONE') setRating(daSong, rating);
		}
	}

	public static function saveWeekScore(week:String, score:Int = 0, ?diff:Int = 0):Void
	{
		var daWeek:String = formatSong(week, diff);

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setWeekScore(daWeek, score);
		}
		else
			setWeekScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}
	static function setWeekScore(week:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	static function setRating(song:String, rating:String):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songRating.set(song, rating);
		FlxG.save.data.songRating = songRating;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:Int):String
	{
		return Paths.formatToSongPath(song) + Difficulty.getFilePath(diff);
	}

	public static function getScore(song:String, diff:Int):Int
	{
		var daSong:String = formatSong(song, diff);
		if (!songScores.exists(daSong))
			setScore(daSong, 0);

		return songScores.get(daSong);
	}

	public static function getRating(song:String, diff:Int):String
	{
		var daSong:String = formatSong(song, diff);
		if (!songRating.exists(daSong))
			setRating(daSong, 'NONE');

		return songRating.get(daSong);
	}

	public static function getWeekScore(week:String, diff:Int):Int
	{
		var daWeek:String = formatSong(week, diff);
		if (!weekScores.exists(daWeek))
			setWeekScore(daWeek, 0);

		return weekScores.get(daWeek);
	}

	public static function load():Void
	{
		if (FlxG.save.data.weekScores != null)
		{
			weekScores = FlxG.save.data.weekScores;
		}
		if (FlxG.save.data.songScores != null)
		{
			songScores = FlxG.save.data.songScores;
		}
		if (FlxG.save.data.songRating != null)
		{
			songRating = FlxG.save.data.songRating;
		}

		if (FlxG.save.data.settings != null)
		{
			settings = FlxG.save.data.settings;
		}
	}

	public static function loadSettings():Void
		{
			if (FlxG.save.data.settings != null)
			{
				settings = FlxG.save.data.settings;
			}
			else{
				saveSettings('downScroll', false);
				saveSettings('antialiasing', true);
				saveSettings('lowQuality', false);
				saveSettings('ghostTapping', false);
				saveSettings('arrowBar', false);
				saveSettings('healthDisable', false);

				ClientPrefs.keyBinds['note_left'][0] = 'D';
				ClientPrefs.keyBinds['note_down'][0] = 'F';
				ClientPrefs.keyBinds['note_up'][0] = 'J';
				ClientPrefs.keyBinds['note_right'][0] = 'K';
				ClientPrefs.saveSettings();
			}
		}

	public static function saveSettings(setting:String, type:Bool):Void
		{
			setSettings(setting, type);
		}
	static function setSettings(setting:String, type:Bool):Void
		{
			// Reminder that I don't need to format this song, it should come formatted!
			settings.set(setting, type);
			FlxG.save.data.settings = settings;
			FlxG.save.flush();
		}

	public static function getSettings(setting:String):Bool
		{
			return settings.get(setting);
		}
}
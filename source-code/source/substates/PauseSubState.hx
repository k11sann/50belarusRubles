package substates;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.FlxObject;
import flixel.addons.display.FlxBackdrop;

import flixel.addons.transition.FlxTransitionableState;

import flixel.util.FlxStringUtil;

import states.ChooseState;
//import options.OptionsState;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<FlxText>;

	var menuItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['RESUME', 'RESTART SONG', 'EXIT TO MENU'];
	var difficultyChoices = [];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;
	var practiceText:FlxText;
	var skipTimeText:FlxText; 
	//var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	public static var songName:String = null;

	override function create()
	{
		if(Difficulty.list.length < 2) menuItemsOG.remove('Change Difficulty'); //No need to change difficulty if there is only one!

		if(PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			
			var num:Int = 0;
			//if(!PlayState.instance.startingSong)
			//{
			//	num = 1;
			//	menuItemsOG.insert(3, 'Skip Time');
			//}
			menuItemsOG.insert(3 + num, 'End Song');
		}
		menuItems = menuItemsOG;

		for (i in 0...Difficulty.list.length) {
			var diff:String = Difficulty.getString(i);
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');


		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if(pauseSong != null) pauseMusic.loadEmbedded(Paths.music('spray'), true, true);
		}
		catch(e:Dynamic) {}
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var backdrop = new FlxBackdrop(Paths.image("tvorog/gride"));
		backdrop.cameras = [FlxG.camera];
		backdrop.velocity.set(50, 50);
		add(backdrop);

		//var levelInfo:FlxText = new FlxText(20, 15, 0, PlayState.SONG.song, 32);
		//levelInfo.scrollFactor.set();
		//levelInfo.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//levelInfo.updateHitbox();
		//add(levelInfo);
//
		//var musTest:FlxText = new FlxText(20, 15 + 101, 0, "Musician : ", 32);
		//musTest.scrollFactor.set();
		//musTest.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//musTest.updateHitbox();
		//add(musTest);
//
		//var chartTest:FlxText = new FlxText(20, 15 + 101, 0, "Chart : ", 32);
		//chartTest.scrollFactor.set();
		//chartTest.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//chartTest.updateHitbox();
		//add(chartTest);
//
		//var rublesTest:FlxText = new FlxText(20, 15 + 101, 0, "", 32);
		//rublesTest.scrollFactor.set();
		//rublesTest.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//rublesTest.updateHitbox();
		//add(rublesTest);
//
		//if (PlayState.SONG.song=="Test"){
		//	musTest.text = musTest.text+"kwawi spreire";
		//	chartTest.text = chartTest.text+"pizdaa";
		//	rublesTest.text = "test suka";
		//}
		//else if (PlayState.SONG.song=="goool"){
		//	musTest.text = musTest.text+"SanyaLitui";
		//	chartTest.text = chartTest.text+"SanyaLitui";
		//	rublesTest.text = "GOOOOOOOOOOOOOOOOOOOOOOOOOOOOL";
		//}
		//else{
		//	musTest.text = musTest.text+"invalid";
		//	chartTest.text = chartTest.text+"invalid";
		//	rublesTest.text = "bebebe";
		//}

		//var creditImage:FlxSprite = new FlxSprite().loadGraphic(Paths.image("tvorog/songCredit/"+PlayState.SONG.song));
		//creditImage.scale.set(1,1);
		//creditImage.screenCenter();
		//creditImage.x += FlxG.width - (creditImage.width*2) + (creditImage.width);
		//creditImage.y += FlxG.height/4;
		//creditImage.updateHitbox();
		//add(creditImage);

		//var logoImage:FlxSprite = new FlxSprite().loadGraphic(Paths.image("tvorog/logo"));
		//logoImage.scale.set(0.5,0.5);
		//logoImage.x = -logoImage.width;
		//logoImage.y =  50;
		//logoImage.updateHitbox();
		//add(logoImage);

		//musTest.alpha = 0;
		//chartTest.alpha = 0;
		//rublesTest.alpha = 0;
		//levelInfo.alpha = 0;

		//creditImage.alpha = 0;
		//logoImage.alpha = 0;

		//levelInfo.x = FlxG.width - (levelInfo.width + 20);
		//musTest.x = FlxG.width - (musTest.width + 20);
		//chartTest.x = FlxG.width - (chartTest.width + 20);
		//rublesTest.x = FlxG.width - (rublesTest.width + 20);

		var defY = 25;

		FlxTween.tween(bg, {alpha: 0.45}, 0.4, {ease: FlxEase.quadOut});
		FlxTween.tween(backdrop, {alpha: 1}, 1, {ease: FlxEase.quadOut});
		//FlxTween.tween(creditImage, {alpha: 1, x: creditImage.x-(creditImage.width)}, 1, {ease: FlxEase.quadInOut});
		//FlxTween.tween(logoImage, {alpha: 1, x: logoImage.x + (logoImage.width*2)+50}, 1, {ease: FlxEase.quadInOut});
		//FlxTween.tween(levelInfo, {alpha: 1, y: defY}, 0.4, {ease: FlxEase.bounceOut, startDelay: 0.3});
		//FlxTween.tween(musTest, {alpha: 1, y: defY*2}, 0.4, {ease: FlxEase.bounceOut, startDelay: 0.5});
		//FlxTween.tween(chartTest, {alpha: 1, y: defY*3}, 0.4, {ease: FlxEase.bounceOut, startDelay: 0.7});
		//FlxTween.tween(rublesTest, {alpha: 1, y: defY*4}, 0.4, {ease: FlxEase.bounceOut, startDelay: 0.9});

		grpMenuShit = new FlxTypedGroup<FlxText>();
		add(grpMenuShit);

		//missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		//missingTextBG.scale.set(FlxG.width, FlxG.height);
		//missingTextBG.updateHitbox();
		//missingTextBG.alpha = 0.6;
		//missingTextBG.visible = false;
		//add(missingTextBG);
		//
		//missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		//missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//missingText.scrollFactor.set();
		//missingText.visible = false;
		//add(missingText);

		regenMenu();
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}
	
	function getPauseSong()
	{
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if(formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none')) return null;

		return (formattedSongName != '') ? formattedSongName : formattedPauseMusic;
	}

	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	override function update(elapsed:Float)
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		if(controls.BACK)
		{
			close();
			return;
		}

		//updateSkipTextStuff();
		if (controls.UI_UP_P)
		{
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P)
		{
			changeSelection(1);
		}

		var daSelected:String = menuItems[curSelected];
		//switch (daSelected)
		//{
		//	case 'Skip Time':
		//		if (controls.UI_LEFT_P)
		//		{
		//			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		//			curTime -= 1000;
		//			holdTime = 0;
		//		}
		//		if (controls.UI_RIGHT_P)
		//		{
		//			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		//			curTime += 1000;
		//			holdTime = 0;
		//		}
//
		//		if(controls.UI_LEFT || controls.UI_RIGHT)
		//		{
		//			holdTime += elapsed;
		//			if(holdTime > 0.5)
		//			{
		//				curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
		//			}
//
		//			if(curTime >= FlxG.sound.music.length) curTime -= FlxG.sound.music.length;
		//			else if(curTime < 0) curTime += FlxG.sound.music.length;
		//			updateSkipTimeText();
		//		}
		//}

		if (controls.ACCEPT && (cantUnpause <= 0 || !controls.controllerMode))
		{
			//if (menuItems == difficultyChoices)
			//{
			//	try{
			//		if(menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected)) {
//
			//			var name:String = PlayState.SONG.song;
			//			var poop = Highscore.formatSong(name, curSelected);
			//			PlayState.SONG = Song.loadFromJson(poop, name);
			//			PlayState.storyDifficulty = curSelected;
			//			MusicBeatState.resetState();
			//			FlxG.sound.music.volume = 0;
			//			PlayState.changedDifficulty = true;
			//			PlayState.chartingMode = false;
			//			return;
			//		}					
			//	}catch(e:Dynamic){
			//		trace('ERROR! $e');
//
			//		var errorStr:String = e.toString();
			//		if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart
			//		missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
			//		missingText.screenCenter(Y);
			//		missingText.visible = true;
			//		missingTextBG.visible = true;
			//		FlxG.sound.play(Paths.sound('cancelMenu'));
//
			//		super.update(elapsed);
			//		return;
			//	}
//
//
			//	menuItems = menuItemsOG;
			//	regenMenu();
			//}

			switch (daSelected)
			{
				case "RESUME":
					close();
				case "RESTART SONG":
					restartSong();
				case "Leave Charting Mode":
					restartSong();
					PlayState.chartingMode = false;
				//case 'Skip Time':
				//	if(curTime < Conductor.songPosition)
				//	{
				//		PlayState.startOnTime = curTime;
				//		restartSong(true);
				//	}
				//	else
				//	{
				//		if (curTime != Conductor.songPosition)
				//		{
				//			PlayState.instance.clearNotesBefore(curTime);
				//			PlayState.instance.setSongTime(curTime);
				//		}
				//		close();
				//	}
				case 'End Song':
					close();
					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.finishSong(true);
				case "EXIT TO MENU":
					#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
					PlayState.deathCounter = 0;
					PlayState.seenCutscene = false;

					Mods.loadTopMod();
					if(PlayState.isStoryMode)
						MusicBeatState.switchState(new ChooseState());
					else 
						MusicBeatState.switchState(new ChooseState());

					FlxG.sound.playMusic(Paths.music('tvorogMenu'));
					PlayState.changedDifficulty = false;
					PlayState.chartingMode = false;
					FlxG.camera.followLerp = 0;
			}
		}
	}

	public static function restartSong(noTrans:Bool = false)
	{
		PlayState.instance.paused = true; // For lua
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if(noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		for (item in grpMenuShit.members)
			{
				item.alpha = 0.55;
			}

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		grpMenuShit.members[curSelected].alpha=1;
	}

	function regenMenu():Void {
		for (i in 0...grpMenuShit.members.length) {
			var obj = grpMenuShit.members[0];
			obj.kill();
			grpMenuShit.remove(obj, true);
			obj.destroy();
		}

		for (i in 0...menuItems.length) {
			var item:FlxText = new FlxText(0, 0, 300, menuItemsOG[i], 32);
			item.scrollFactor.set();
			item.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			item.updateHitbox();
			item.screenCenter(X);
			item.y = 300+(75 * i);
			grpMenuShit.add(item);

			//if(menuItems[i] == 'Skip Time')
			//{
			//	skipTimeText = new FlxText(0, 0, 0, '', 64);
			//	skipTimeText.setFormat(Paths.font("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			//	skipTimeText.scrollFactor.set();
			//	skipTimeText.borderSize = 2;
			//	skipTimeTracker = item;
			//	add(skipTimeText);
//
			//	updateSkipTextStuff();
			//	updateSkipTimeText();
			//}
		}
		curSelected = 0;
		changeSelection();
	}
	
	//function updateSkipTextStuff()
	//{
	//	if(skipTimeText == null || skipTimeTracker == null) return;
//
	//	skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
	//	skipTimeText.y = skipTimeTracker.y;
	//	skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	//}
//
	//function updateSkipTimeText()
	//{
	//	skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	//}
}

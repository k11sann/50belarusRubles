package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.TvorogSettings;


import backend.Highscore;
import backend.Song;
import backend.Difficulty;
import backend.ChooseSongs;
import states.PlayState;

import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.ColorMatrixFilter;
import openfl.Lib;
import openfl.filters.ShaderFilter;	

import shaders.VHShader;

#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end
//import states.SprayState;

class ChooseState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.3'; // This is also used for Discord RPC
	public static var curSelected:Int = 1;
	public static var curMixSelected:Int = 0;

	private static var lastDifficultyName:String = Difficulty.getDefault();

	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public var chooseData:ChooseFile;

	var songItems:FlxTypedGroup<FlxSprite>;
	public var songMixItems:FlxTypedGroup<FlxText>;
	var uiGroup:FlxTypedGroup<FlxSprite>;
	
	var scoreSprite:FlxSprite;
	var mixSprite:FlxSprite;
	var startSprite:FlxSprite;
	var zamokSprite:FlxSprite;
	var bag:FlxSprite;

	var leftSprite:FlxSprite;
	var rightSprite:FlxSprite;

	var resultRankSprite:FlxSprite;
	var resultRankChar:FlxSprite;

	var lights:FlxSprite;

	var hintText:FlxText;
	var scoreText:FlxText;
	
	var gradeTween:FlxTween;
	var gradeColorTween:FlxTween;
	var colorTw:FlxTween;

	public var camHUD:FlxCamera;

	var canBut:Bool=false;
	var canTime:Float=0.4;
	var canStart:Bool=true;
	var canAnim:Bool=true;
	var unkAll:Bool=false;

	var lerpScore:Int;
	var backScore:Int;
	var secretNumber:Int;

	public var curDifficulty:Int = 1;

	public var songShit:Array<String> = [];
	public var allAvaliableSongs:Array<String> = [
		"one",
		"two",
		"three",
		"four",
		"five",
		"six",
		"seven",
		"eight",
		"nine",
		"ten"
	];
	public var songColorShit:Array<String> = [];
	public var songMixShit:Array<String> = [];

	var videoUrl:String;
	var selectedColor:String;

	var camFollow:FlxObject;

	var filters:Array<BitmapFilter> = []; //filters

	var filterMap:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}>;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		//ClientPrefs.loadPrefs();

		Highscore.load();

		//Highscore.loadSettings();

		FlxG.mouse.visible=false;

		FlxG.updateFramerate = ClientPrefs.tvorogGameplaySet['framerate'];
		FlxG.drawFramerate = ClientPrefs.tvorogGameplaySet['framerate'];

		//#if MODS_ALLOWED
		//Mods.pushGlobalMods();
		//#end
		//Mods.loadTopMod();

		var yScroll:Float = Math.max(0.25 - (0.05 * (songShit.length - 4)), 0.1);
		bag = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bag.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		bag.scrollFactor.set(0, yScroll);
		bag.setGraphicSize(Std.int(bag.width * 1.175));
		bag.updateHitbox();
		bag.screenCenter();
		bag.color = 0xff59565f;
		add(bag);
		

		songItems = new FlxTypedGroup<FlxSprite>(); // группы
		add(songItems);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		lights = new FlxSprite(-80).loadGraphic(Paths.image('tvorog/choose/lights'));
		lights.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		lights.scrollFactor.set(0, yScroll);
		lights.updateHitbox();
		lights.setGraphicSize(Std.int(bag.width * 1.175));
		lights.screenCenter();
		lights.blend = 'add';
		add(lights);

		uiGroup = new FlxTypedGroup<FlxSprite>();
		add(uiGroup);
		songMixItems = new FlxTypedGroup<FlxText>(); // группы
		add(songMixItems);

		chooseData = ChooseData.getChooseFile();
		for (i in 0...chooseData.ChooseSong.length){
			songShit[i] = chooseData.ChooseSong[i][0];
			songColorShit[i] = chooseData.ChooseSong[i][2];
		}
		selectedColor = chooseData.SelectedColor;

		for (i in 0...songShit.length)
		{
			var songItem:FlxSprite = new FlxSprite();
			songItem.updateHitbox();
			var offset:Float = (FlxG.width/2) - (Math.max(songShit.length, 4) - 4) * 80;
			songItem.x = (i * (FlxG.width/2)) + offset;
			//songItem.y = 150;
			songItem.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
			songItem.frames = Paths.getSparrowAtlas('tvorog/choose/characters/' + allAvaliableSongs[i]);
			songItem.animation.addByPrefix('idle', "idle", 24, true);
			songItem.animation.addByPrefix('hey', "hey", 24, false);
			songItem.animation.play('idle');
			songItems.add(songItem);
			if (i==0){
				songItem.color = FlxColor.WHITE;
			}
			else{
				songItem.color = FlxColor.fromString('0x080808');
			}

			songItem.scale.set(chooseData.CharSize[i][0], chooseData.CharSize[i][0]);
			songItem.y = chooseData.CharSize[i][1];
		}

		var blackline:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width)*songShit.length, Std.int(FlxG.height/4)+50, FlxColor.fromString('0x070709'));
		blackline.y = FlxG.height - (blackline.height/2)-30;
		blackline.scrollFactor.set(0, 0);
		uiGroup.add(blackline);

		var blackline:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width)*songShit.length, 50, FlxColor.fromString('0x070709'));
		blackline.y = 0;
		blackline.scrollFactor.set(0, 0);
		uiGroup.add(blackline);

		scoreSprite = new FlxSprite(); // score txt
		scoreSprite.scrollFactor.set(0, yScroll);
		scoreSprite.frames = Paths.getSparrowAtlas('tvorog/choose/playText');
		scoreSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		scoreSprite.scrollFactor.set(0, 0);
		scoreSprite.animation.addByPrefix('idle', "scoreAnim", 6, true);
		scoreSprite.animation.play('idle');
		scoreSprite.scale.set(0.4, 0.4);
		scoreSprite.updateHitbox();
		scoreSprite.screenCenter(X);
		scoreSprite.x -= Std.int(FlxG.width/3);
		scoreSprite.y = Std.int(FlxG.height)-Std.int(FlxG.height/4);
		uiGroup.add(scoreSprite);	

		mixSprite = new FlxSprite(); // mix txt
		mixSprite.scrollFactor.set(0, yScroll);
		mixSprite.frames = Paths.getSparrowAtlas('tvorog/choose/playText');
		mixSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		mixSprite.animation.addByPrefix('idle', "mixAnim", 6, true);
		mixSprite.animation.play('idle');
		mixSprite.scale.set(0.4, 0.4);
		mixSprite.updateHitbox();
		mixSprite.screenCenter(X);
		mixSprite.scrollFactor.set(0, yScroll);
		mixSprite.x += Std.int(FlxG.width/3);
		mixSprite.y = Std.int(FlxG.height)-Std.int(FlxG.height/4);
		uiGroup.add(mixSprite);	

		startSprite = new FlxSprite(); // mix txt
		startSprite.scrollFactor.set(0, yScroll);
		startSprite.updateHitbox();
		startSprite.frames = Paths.getSparrowAtlas('tvorog/choose/playText');
		startSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		startSprite.animation.addByPrefix('idle', "startAnim", 6, true);
		startSprite.animation.play('idle');
		startSprite.scale.set(0.3, 0.3);
		startSprite.screenCenter(X);
		startSprite.y = FlxG.height-175;
		uiGroup.add(startSprite);	

		zamokSprite = new FlxSprite().loadGraphic(Paths.image('tvorog/choose/zamok'));
		zamokSprite.scrollFactor.set(0, yScroll);
		zamokSprite.updateHitbox();
		zamokSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		zamokSprite.scale.set(0.3, 0.3);
		zamokSprite.screenCenter();
		zamokSprite.kill();
		uiGroup.add(zamokSprite);	

		leftSprite = new FlxSprite(); // left arrow
		leftSprite.scrollFactor.set(0, 0);
		leftSprite.updateHitbox();
		leftSprite.frames = Paths.getSparrowAtlas('tvorog/choose/playArrow');
		leftSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		leftSprite.animation.addByPrefix('idle', "arrowLEFT", 48, false);
		leftSprite.animation.play('idle');
		leftSprite.scale.set(0.4, 0.4);
		leftSprite.screenCenter();
		leftSprite.x -= 200;
		leftSprite.y += 50;
		uiGroup.add(leftSprite);	

		rightSprite = new FlxSprite(); // right arrow
		rightSprite.scrollFactor.set(0, 0);
		rightSprite.updateHitbox();
		rightSprite.frames = Paths.getSparrowAtlas('tvorog/choose/playArrow');
		rightSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		rightSprite.flipX=true;
		rightSprite.animation.addByPrefix('idle', "arrowLEFT", 48, false);
		rightSprite.animation.play('idle');
		rightSprite.scale.set(0.4, 0.4);
		rightSprite.screenCenter();
		rightSprite.x += 200;
		rightSprite.y += 50;
		uiGroup.add(rightSprite);	

		hintText = new FlxText(0, 0, 250, "[ TAB - OPTIONS ]", 20);
		hintText.scrollFactor.set(0, 0);
		hintText.updateHitbox();
		hintText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		hintText.borderSize = 1.25;
		hintText.x = FlxG.width-(hintText.width+25);
		hintText.y = 13;
		hintText.alpha = 0.5;
		uiGroup.add(hintText);

		var tvrgText:FlxText = new FlxText(0, 0, 250, "TVOROG STREET 0.5", 20);
		tvrgText.scrollFactor.set(0, 0);
		tvrgText.updateHitbox();
		tvrgText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tvrgText.borderSize = 1.25;
		tvrgText.x = 0+Std.int(hintText.width/3)-50;
		tvrgText.y = 13;
		tvrgText.alpha = 0.5;
		uiGroup.add(tvrgText);

		scoreText = new FlxText(100, 100, FlxG.width, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.scrollFactor.set();
		scoreText.borderSize = 1.25;
		scoreText.x = 100;
		scoreText.y = FlxG.height-100;
		//hintText.screenCenter();
		scoreText.updateHitbox();
		uiGroup.add(scoreText);

		resultRankSprite = new FlxSprite(); // score txt
		resultRankSprite.scrollFactor.set();
		resultRankSprite.frames = Paths.getSparrowAtlas('tvorog/results/ranks');
		resultRankSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		resultRankSprite.animation.addByPrefix('idle', "rankAnim", 6, true);
		resultRankSprite.animation.play('idle');
		resultRankSprite.scale.set(0.4, 0.4);
		resultRankSprite.updateHitbox();
		resultRankSprite.screenCenter(X);
		resultRankSprite.x -= 500;
		resultRankSprite.y = 75;
		uiGroup.add(resultRankSprite);

		resultRankChar = new FlxSprite(); // score txt
		resultRankChar.scrollFactor.set();
		resultRankChar.frames = Paths.getSparrowAtlas('tvorog/results/ranks');
		resultRankChar.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		resultRankChar.animation.addByPrefix('A', "rankAanim", 6, true);
		resultRankChar.animation.addByPrefix('B', "rankBanim", 6, true);
		resultRankChar.animation.addByPrefix('C', "rankCanim", 6, true);
		resultRankChar.animation.addByPrefix('NONE', "rankNONEanim", 6, true);
		resultRankChar.scale.set(0.3, 0.3);
		resultRankChar.updateHitbox();
		resultRankChar.screenCenter(X);
		resultRankChar.x -= 500-175;
		resultRankChar.y = 75;
		uiGroup.add(resultRankChar);	

		changeItem(-1);

		super.create();

		FlxG.camera.follow(camFollow, null, 9);

		if (ClientPrefs.tvorogSet['lowQuality']==false){
			filterMap = [ // фильтры!
				//"VHS" => {
				//	var shader = new VHS();
				//	{
				//		filter: new ShaderFilter(shader),
				//		onUpdate: function()
				//		{
				//			//#if (openfl >= "8.0.0")
				//			//shader.iTime.value = [Lib.getTimer() / 1000];
				//			//#else
				//			//shader.iTime = Lib.getTimer() / 1000;
				//			//#end
				//		}
				//	}
				//}
			];
			FlxG.camera.filters = filters;
			FlxG.game.filters = filters;
			FlxG.game.filtersEnabled = false;
	
			for (key in filterMap.keys()){
				filters.push(filterMap.get(key).filter);
			}
		}
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if(FlxG.sound.music == null) {
			FlxG.sound.playMusic(Paths.music('tvorogMenu'), 0);
		}

		if (backScore!=lerpScore){
			lerpScore = Math.floor(FlxMath.lerp(backScore, lerpScore, Math.exp(-elapsed * 24)));
			if (scoreText.text!=Std.string(lerpScore)){
				scoreText.text = Std.string(lerpScore);
			}
		}

		if (FlxG.keys.justPressed.TAB){
			MusicBeatState.switchState(new TvorogSettings());
			TvorogSettings.onPlayState = false;
			if (PlayState.SONG != null)
			{
				PlayState.SONG.arrowSkin = null;
				PlayState.SONG.splashSkin = null;
				PlayState.stageUI = 'normal';
			}
		}
		if (FlxG.keys.justPressed.R && FlxG.keys.pressed.SHIFT){
			FlxG.sound.play(Paths.sound('pook'), 0.75);
			unkAll=true;
		}

		//if (FlxG.keys.justPressed.F && FlxG.keys.pressed.SHIFT){
		//	FlxG.sound.play(Paths.sound('pook'), 0.75);
		//	MusicBeatState.switchState(new SprayState());
		//}

		if (FlxG.sound.music.volume < 0.8)
			{
				FlxG.sound.music.volume += 0.5 * elapsed;
				if (FreeplayState.vocals != null)
					FreeplayState.vocals.volume += 0.5 * elapsed;
			}
			
		if (!selectedSomethin)
			{
				if ((FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A) && canBut==true)
					changeItem(-1);
	
				if ((FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D) && canBut==true)
					changeItem(1);

				if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.W){
					FlxG.sound.play(Paths.sound('peow'), 0.75);
					trace(songMixShit.length);
					if (songMixShit.length>1){
						changeMixItem(-1);
					}
					else{
						FlxG.sound.play(Paths.sound('pook'), 0.75);
					}
				}
	
				if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.S){
					FlxG.sound.play(Paths.sound('peow'), 0.75);
					trace(songMixShit.length);
					if (songMixShit.length>1){
						changeMixItem(1);
					}
					else{
						FlxG.sound.play(Paths.sound('pook'), 0.75);
					}
				}
	
				if (controls.ACCEPT)
				{
					if (canStart==true){
						FlxG.sound.play(Paths.sound('freeplaySelect'), 0.75);
						if (songShit[curSelected] == 'youtube')
						{
							CoolUtil.browserLoad(Std.string(videoUrl));
						}
						else
						{
							selectedSomethin = true;
							
	
							songItems.members[curSelected].animation.play('hey');
	
							startSprite.color = FlxColor.fromString('0x'+selectedColor);
	
							var meow:FlxTimer = new FlxTimer().start(1, function(tmr:FlxTimer) {
								trace(songMixShit[curMixSelected]);
								var songLowercase:String = Paths.formatToSongPath(songMixShit[curMixSelected]); //песня вибор
								var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
								trace(poop);
					
								try
								{
									PlayState.SONG = Song.loadFromJson(poop, songLowercase);
									PlayState.isStoryMode = false;
									PlayState.storyDifficulty = curDifficulty;
								}
								catch(e:Dynamic)
								{
									trace('ERROR! $e');
									FlxG.sound.play(Paths.sound('pook'), 0.75);
									return;
								}
								LoadingState.loadAndSwitchState(new PlayState());							
								//switch (songShit[curSelected])
								//{
								//	case 'test':
								//		MusicBeatState.switchState(new StoryMenuState());
								//	case 'goool':
								//		trace("goool");
								//		MusicBeatState.switchState(new FreeplayState());
								//}
							});
		
							for (i in 0...songItems.members.length)
							{
								if (i == curSelected)
									continue;
								FlxTween.tween(songItems.members[i], {y: songItems.members[i].x+300}, 1, {
									ease: FlxEase.quadIn,
									onComplete: function(twn:FlxTween)
									{
										songItems.members[i].kill();
									}
								});
							}
						}
					}
					else if (canAnim==true){
						canAnim=false;
						FlxG.sound.play(Paths.sound('pook'), 0.75);
						FlxTween.tween(zamokSprite, {x: zamokSprite.x-20}, 0.15, {ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
							FlxTween.tween(zamokSprite, {x: zamokSprite.x+40}, 0.15, {ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
								FlxTween.tween(zamokSprite, {x: zamokSprite.x-20}, 0.2, {ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
									canAnim=true;
								}});
							}});
						}});
					}
					
				}
				#if desktop
				if (controls.justPressed('debug_1'))
				{
					selectedSomethin = true;
					MusicBeatState.switchState(new MasterEditorMenu());
				}
				#end
			}
	
		if (canTime>0 && canBut==false){
			canTime -=elapsed;
		}
		else{
			canBut=true;
			canTime = 0.4;
		}

	

		if (ClientPrefs.tvorogSet['lowQuality']==false){
			for (filter in filterMap) //фильты!
				{
					if (filter.onUpdate != null)
						filter.onUpdate();
				}	
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0, ?fast:Bool=false)
	{
		canBut=false;
		if (huh==1){
			if (rightSprite!=null){
				rightSprite.animation.play('idle');
			}
		}
		else{
			if (leftSprite!=null){
				leftSprite.animation.play('idle');
			}
		}
		FlxG.sound.play(Paths.sound('peow'), 0.75);
		//songItems.members[curSelected].animation.play('idle');
		//songItems.members[curSelected].updateHitbox();
		//songItems.members[curSelected].screenCenter(X);
		if (gradeTween!=null){
			gradeTween.cancel();
		}

		gradeTween = FlxTween.tween(songItems.members[curSelected], {y: chooseData.CharSize[curSelected][1]+75}, 0.4, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
			gradeTween=null;
		}});

		if (gradeColorTween!=null){
			gradeColorTween.cancel();
		}

		gradeColorTween = FlxTween.color(songItems.members[curSelected], 0.5, songItems.members[curSelected].color, FlxColor.fromString('0x080808'), {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
			gradeColorTween=null;
		}});

		if (fast==false){
			curSelected += huh;
		}
		else{
			curSelected = huh;
		}

		if (curSelected >= songItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = songItems.length - 1;

		if (colorTw!=null){
			colorTw.cancel();
		}
		try{
			colorTw = FlxTween.color(lights, 1, lights.color, FlxColor.fromString('0x'+songColorShit[curSelected]), {onComplete: function(twn:FlxTween) {
				colorTw = null;
			}});
		} catch(e:Any) {
			colorTw = FlxTween.color(lights, 1, lights.color, FlxColor.fromString('0x353435'), {onComplete: function(twn:FlxTween) {
				colorTw = null;
			}});
		}

		gradeTween = FlxTween.tween(songItems.members[curSelected], {y: chooseData.CharSize[curSelected][1]}, 0.4, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
			gradeTween=null;
		}});

		try{
			backScore = Highscore.getScore(songShit[curSelected], curDifficulty);
			var rankCurrent = Std.string(Highscore.getRating(songShit[curSelected], curDifficulty));
			trace(rankCurrent+' rank');
			resultRankChar.animation.play(rankCurrent);
			if (songShit[curSelected]==songShit[0]){ // если первая песня
				startSprite.color = FlxColor.WHITE;
				resultRankSprite.color = FlxColor.WHITE;
				FlxTween.color(songItems.members[curSelected], 0.5, songItems.members[curSelected].color, FlxColor.WHITE, {ease: FlxEase.quadOut});
				if (zamokSprite.alive){
					FlxTween.tween(zamokSprite.scale, {x: 0, y: 0}, 0.4, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
						zamokSprite.kill();
						canStart=true;
					}});
				}
			}
			else if (Std.string(Highscore.getRating(songShit[curSelected-1], curDifficulty))!='NONE' && Std.string(Highscore.getRating(songShit[curSelected-1], curDifficulty))!='C'){ // если ранг есть
				FlxTween.color(songItems.members[curSelected], 0.5, songItems.members[curSelected].color, FlxColor.WHITE, {ease: FlxEase.quadOut});
				startSprite.color = FlxColor.WHITE;
				resultRankSprite.color = FlxColor.WHITE;
				if (zamokSprite.alive){
					FlxTween.tween(zamokSprite.scale, {x: 0, y: 0}, 0.4, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
						zamokSprite.kill();
						canStart=true;
					}});
				}
			}
			else{ // если пошёл нахуй
				if (!unkAll){
					if (Std.string(Highscore.getRating(songShit[curSelected], curDifficulty))=='C'){ // ЕСЛИ РАНГ ХУЙНЯ
						resultRankSprite.color = FlxColor.fromString('0xD64000');
					}
					startSprite.color = FlxColor.fromString('0xD64000');
					resultRankSprite.color = FlxColor.fromString('0xD64000');
					if (!zamokSprite.alive){
						zamokSprite.revive();
						canStart=false;
						FlxTween.tween(zamokSprite.scale , {x: 0.3, y: 0.3}, 0.4, {ease: FlxEase.quadOut});
					}
				}
			}
		}
		catch(e:Dynamic){
			scoreText.text = 'tvorog pizdec';
		}

		trace('bububub');
		addMixItems();

		camFollow.setPosition(songItems.members[curSelected].getGraphicMidpoint().x, Std.int(FlxG.height / 2));
	}

	function changeMixItem(huh:Int = 0, ?fast:Bool=false){
		songMixItems.members[curMixSelected].alpha=0.5;
		if (fast==false){
			curMixSelected += huh;
		}
		else{
			curMixSelected = huh;
		}

		if (curMixSelected >= songMixItems.members.length){
			curMixSelected = 0;
		}
		if (curMixSelected < 0){
			curMixSelected = songMixItems.members.length - 1;	
		}
		if (songMixItems.members[curMixSelected]!=null){
			songMixItems.members[curMixSelected].alpha = 1;
		}

		try{
			backScore = Highscore.getScore(songMixShit[curMixSelected], curDifficulty);
			var rankCurrent = Std.string(Highscore.getRating(songMixShit[curMixSelected], curDifficulty));
			trace(rankCurrent+' rank');
			resultRankChar.animation.play(rankCurrent);
			if (Std.string(Highscore.getRating(songMixShit[curMixSelected], curDifficulty))!='NONE' && Std.string(Highscore.getRating(songShit[curSelected-1], curDifficulty))!='C'){ // если ранг есть
				FlxTween.color(songItems.members[curSelected], 0.5, songItems.members[curSelected].color, FlxColor.WHITE, {ease: FlxEase.quadOut});
				startSprite.color = FlxColor.WHITE;
				resultRankSprite.color = FlxColor.WHITE;
			}
			else{ // если пошёл нахуй
				if (Std.string(Highscore.getRating(songMixShit[curMixSelected], curDifficulty))=='C'){ // ЕСЛИ РАНГ ХУЙНЯ
					resultRankSprite.color = FlxColor.fromString('0xD64000');
					startSprite.color = FlxColor.fromString('0xD64000');
					resultRankSprite.color = FlxColor.fromString('0xD64000');
				}
			}
		}
		catch(e:Dynamic){
			scoreText.text = 'tvorog pizdec';
		}
	}

	function addMixItems() {
		while (songMixItems.members.length>0){
			for (i in 0...songMixItems.members.length+1){
				if (songMixItems.members[i]!=null){
					songMixItems.members.remove(songMixItems.members[i]);
				}
			}
		}

		songMixShit = [];

		var mur:FlxText = new FlxText(0, 0, 275, "DEFAULT-MIX", 20);
		mur.setFormat(Paths.font("vcr.ttf"), Std.int(80/chooseData.ChooseSong[curSelected].length), FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		mur.scrollFactor.set();
		mur.updateHitbox();
		mur.borderSize = 1.25;
		mur.x = mixSprite.x-Std.int(mixSprite.width/2)-25;
		mur.y = mixSprite.y + 90;
		mur.alpha = 1;
		songMixItems.add(mur);
		songMixShit[0] = songShit[curSelected];
		
		if (chooseData.ChooseSong[curSelected].length>3){
			for(i in 3...chooseData.ChooseSong[curSelected].length){
				songMixShit[i-2] = chooseData.ChooseSong[curSelected][i];
				trace(songMixShit[i-2]);
				var mixerText:FlxText = new FlxText(0, 0, 275, "", 20);
				mixerText.setFormat(Paths.font("vcr.ttf"), Std.int(80/chooseData.ChooseSong[curSelected].length), FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				mixerText.scrollFactor.set();
				mixerText.updateHitbox();
				mixerText.borderSize = 1.25;
				mixerText.x = mixSprite.x-Std.int(mixSprite.width/2)-25;
				mixerText.y = mixSprite.y + 90 + (25 * (i-2));
				mixerText.text = Std.string(chooseData.ChooseSong[curSelected][1])+"-MIX";
				mixerText.alpha = 0.5;
				songMixItems.add(mixerText);
				trace("added");
			}
		}
	
		curMixSelected = 0;
	}
}

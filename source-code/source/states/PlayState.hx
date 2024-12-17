package states;

import backend.Highscore;
import backend.ClientPrefs;
import backend.StageData;
import backend.WeekData;
import backend.Spray;
import backend.Song;
import backend.Section;
import backend.Rating;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;

import openfl.Assets;
import openfl.utils.Assets as OpenFlAssets;
import openfl.events.KeyboardEvent;

import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.ColorMatrixFilter;
import openfl.Lib;
import openfl.filters.ShaderFilter;	

import shaders.RetroShader;
import shaders.VHShader;
import shaders.WideShader;
import shaders.DataMoshing;


import cutscenes.CutsceneHandler;
import cutscenes.DialogueBoxPsych;

//import states.StoryMenuState;
//import states.FreeplayState;
import states.ChooseState;
import states.editors.ChartingState;
import states.editors.CharacterEditorState;

import substates.PauseSubState;
//import substates.GameOverSubstate;

#if !flash
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

#if VIDEOS_ALLOWED
#if (hxCodec >= "3.0.0") import hxcodec.flixel.FlxVideo as VideoHandler;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler;
#else import vlc.MP4Handler as VideoHandler; #end
#end

import objects.Note.EventNote;
import objects.*;
import states.stages.objects.*;

#if LUA_ALLOWED
import psychlua.*;
#else
import psychlua.LuaUtils;
import psychlua.HScript;
#end

#if SScript
import tea.SScript;
#end

/**
 * This is where all the Gameplay stuff happens and is managed
 *
 * here's some useful tips if you are making a mod in source:
 *
 * If you want to add your stage to the game, copy states/stages/Template.hx,
 * and put your stage code there, then, on PlayState, search for
 * "switch (curStage)", and add your stage to that list.
 *
 * If you want to code Events, you can either code it on a Stage file or on PlayState, if you're doing the latter, search for:
 *
 * "function eventPushed" - Only called *one time* when the game loads, use it for precaching events that use the same assets, no matter the values
 * "function eventPushedUnique" - Called one time per event, use it for precaching events that uses different assets based on its values
 * "function eventEarlyTrigger" - Used for making your event start a few MILLISECONDS earlier
 * "function triggerEvent" - Called when the song hits your event's timestamp, this is probably what you were looking for
**/
class PlayState extends MusicBeatState
{
	public static var STRUM_X = 36; // 36
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	var filters:Array<BitmapFilter> = []; //filters

	var filtersHUD:Array<BitmapFilter> = []; //filters

	var filterMap:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}>;

	var filterMapHUD:Map<String, {filter:BitmapFilter, ?onUpdate:Void->Void}>;

	//event variables
	private var isCameraOnForcedPos:Bool = false;

	public var boyfriendMap:Map<String, Character> = new Map<String, Character>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	#if HSCRIPT_ALLOWED
	public var hscriptArray:Array<HScript> = [];
	public var instancesExclude:Array<String> = [];
	#end

	#if LUA_ALLOWED
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, FlxText> = new Map<String, FlxText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var playbackRate(default, set):Float = 1;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var middleCharGroup:FlxSpriteGroup;
	public var backGfGroup:FlxSpriteGroup;
	public var walkGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var stageUI:String = "normal";
	public static var isPixelStage(get, never):Bool;

	@:noCompletion
	static function get_isPixelStage():Bool
		return stageUI == "pixel" || stageUI.endsWith("-pixel");

	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var spawnTime:Float = 2000;

	public var inst:FlxSound;
	public var vocals:FlxSound;
	public var gameOver:FlxSound;
	public var opponentVocals:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	public var camFollow:FlxObject;
	private static var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	private var curSong:String = "";
	public var hitSec:Bool;

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	//public var healthBar:Bar;
	//public var timeBar:Bar;
	var songPercent:Float = 0;

	public var ratingsData:Array<Rating> = Rating.loadDefault();

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;

	public var guitarHeroSustains:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;
	var walkTwn:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;
	var defaultCamZoomBase:Float;

	public var hpBarTest:FlxSprite;
	
	//public var defaultTimeUpd:Float = (60/SONG.bpm)*4; // хп бар время
	//public var timeHealthBarUpd:Float = 2;
	public var canUpdTimer:Bool = false;

	public var allShapes:Array<String> = [];

	public var hpBarOFF:Bool = ClientPrefs.tvorogSet['healthDisable']; // false = нету хп бара / true = есть хп бар
	public var arrowBarOFF:Bool = ClientPrefs.tvorogSet['arrowBar']; // false = нету arrow bar / true = есть arroiw bar
	public var arrowBarTime:Float = 0;
	public var canSpray:Bool = false; //творог спрей
	public var delaySpray:Float = 0.0001; // через сколько будет ставиться каждая точка
	public var healthSpray:Float = 125.0; // запас спрея
	public static var healthSprayMAX:Float = 125.0; // max спрей
	public var sprayColorMain:String = 'red'; // цвет
	public var spraySize:Float = 0.05;
	public static var spraySizeMAX:Float = 0.1;
	public static var spraySizeMIN:Float = 0.01;
	public static var colorSpray:Array<String> = [];
	public var sprayShape:String;
	public var sprayShapeValue:Int = 0;
	public var sprayColorSprite:FlxSprite;
	public var sprayHealthSprite:FlxSprite;
	public var blacker:FlxSprite;
	public var spraySizeText:FlxText;

	public var gfSection:Bool=false;

	public var resultStatus:FlxSprite; //results
	public var resultScore:FlxSprite;
	public var resultScoreText:FlxText;
	public var resultMisses:FlxSprite;
	public var resultMissesText:FlxText;
	public var resultRankSprite:FlxSprite;
	public var resultRankChar:FlxSprite;
	public var isResult:Bool = false;
	public var rankChar:String;
	public var canCalculateScore:String = 'no';
	public var oldScore:Int = 0;
	public var newScore:Int = 0;
	public var nextSwitch:Int=1;
	public var canReSwitch:Bool = false;

	public var disablePlrs:Bool = false;

	public var charWalkTime:Float = 12;
	public var numbWalking:Int;

	public var canCamera:Bool=true;

	public var sprayCTRLz:Int = 0;
	public var sprayCount:Int;
	public var sprayFirst:Bool;
	public var sprayOper:Array<Int> = [];

	public var sprayCheat:Bool = false; //спрей чит
	public var isDead:Bool = false;
	public var canContinue:Bool = false;
	public var haveArrow = false;
	public var sound:FlxSound = null; // звук

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if DISCORD_ALLOWED
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Int> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	#if LUA_ALLOWED public var luaArray:Array<FunkinLua> = []; #end

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	private var luaDebugGroup:FlxTypedGroup<psychlua.DebugLuaText>;
	#end
	public var introSoundsSuffix:String = '';

	// Less laggy controls
	private var keysArray:Array<String>;
	public var songName:String;

	// Callbacks for stages
	public var startCallback:Void->Void = null;
	public var endCallback:Void->Void = null;

	override public function create()
	{
		//trace('Playback Rate: ' + playbackRate);
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		startCallback = startCountdown;
		endCallback = endSong;

		// for lua
		instance = this;

		FlxG.mouse.visible=false;

		PauseSubState.songName = null; //Reset to default
		playbackRate = ClientPrefs.getGameplaySetting('songspeed');

		keysArray = [
			'note_left',
			'note_down',
			'note_up',
			'note_right'
		];

		ClientPrefs.loadPrefs();

		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = 0.1;
		healthLoss = 0.115;
		instakillOnMiss = false;
		practiceMode = false;
		cpuControlled = false;
		guitarHeroSustains = false;

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		if (ClientPrefs.tvorogSet['lowQuality']==false){
			filterMap = [ // фильтры!
				"Retro" => {
					var shader = new Retro();
					{
						filter: new ShaderFilter(shader),
						onUpdate: function()
						{
							#if (openfl >= "8.0.0")
							shader.iTime.value = [Lib.getTimer() / 1000];
							#else
							shader.iTime = Lib.getTimer() / 1000;
							#end
						}
					}
				}
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
				//"Wide" => {
				//	wideShader = new Wide();
				//	{
				//		filter: new ShaderFilter(wideShader),
				//		onUpdate: function()
				//		{
				//			//#if (openfl >= "8.0.0")
				//			//shader.iTime.value = [Lib.getTimer() / 1000];
				//			//#else
				//			//shader.iTime = Lib.getTimer() / 1000;
				//			//#end
				//		}
				//	}
				//},
			];
			filterMapHUD = [ // фильтры!
				"Retro" => {
					var shader = new Retro();
					{
						filter: new ShaderFilter(shader),
						onUpdate: function()
						{
							#if (openfl >= "8.0.0")
							shader.iTime.value = [Lib.getTimer() / 1000];
							#else
							shader.iTime = Lib.getTimer() / 1000;
							#end
						}
					}
				},
				"VHS" => {
					var shader = new VHS();
					{
						filter: new ShaderFilter(shader),
						onUpdate: function()
						{
							//#if (openfl >= "8.0.0")
							//shader.iTime.value = [Lib.getTimer() / 1000];
							//#else
							//shader.iTime = Lib.getTimer() / 1000;
							//#end
						}
					}
				}
				//"Wide" => {
				//	wideShader = new Wide();
				//	{
				//		filter: new ShaderFilter(wideShader),
				//		onUpdate: function()
				//		{
				//			//#if (openfl >= "8.0.0")
				//			//shader.iTime.value = [Lib.getTimer() / 1000];
				//			//#else
				//			//shader.iTime = Lib.getTimer() / 1000;
				//			//#end
				//		}
				//	}
				//},
			];
			FlxG.camera.filters = filters;
			FlxG.game.filters = filters;
			FlxG.game.filtersEnabled = false;
			camHUD.filters = filtersHUD;
	
			for (key in filterMap.keys()){
				filters.push(filterMap.get(key).filter);
			}

			for (key in filterMapHUD.keys()){
				filtersHUD.push(filterMapHUD.get(key).filter);
			}
		}

		#if DISCORD_ALLOWED
		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		storyDifficultyText = Difficulty.getString();

		if (isStoryMode)
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		else
			detailsText = "Freeplay";

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		//GameOverSubstate.resetVariables();
		songName = Paths.formatToSongPath(SONG.song);
		if(SONG.stage == null || SONG.stage.length < 1) {
			SONG.stage = StageData.vanillaSongStage(songName);
		}
		curStage = SONG.stage;

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = StageData.dummy();
		}

		try{//ходьба
			numbWalking =  stageData.numbChars;
		}
		catch(e:Dynamic){
			numbWalking=0;
		}

		defaultCamZoom = stageData.defaultZoom;
		defaultCamZoomBase = stageData.defaultZoom;

		stageUI = "normal";
		if (stageData.stageUI != null && stageData.stageUI.trim().length > 0)
			stageUI = stageData.stageUI;
		else {
			if (stageData.isPixelStage)
				stageUI = "pixel";
		}

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		middleCharGroup = new FlxSpriteGroup(GF_X, GF_Y);
		backGfGroup = new FlxSpriteGroup();
		walkGroup = new FlxSpriteGroup();

		switch (curStage)
		{
			case 'stage': new states.stages.StageWeek1(); //Week 1
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		add(gfGroup);
		add(backGfGroup);
		add(middleCharGroup);
		add(dadGroup);
		add(boyfriendGroup);
		add(walkGroup);

		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		luaDebugGroup = new FlxTypedGroup<psychlua.DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		// "GLOBAL" SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'scripts/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		// STAGE SCRIPTS
		#if LUA_ALLOWED
		startLuasNamed('stages/' + curStage + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		startHScriptsNamed('stages/' + curStage + '.hx');
		#end

		if (!stageData.hide_girlfriend)
		{
			if(SONG.gfVersion == null || SONG.gfVersion.length < 1) SONG.gfVersion = 'gf'; //Fix for the Chart Editor
			gf = new Character(0, 0, SONG.gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			middleCharGroup.add(gf);
			startCharacterScripts(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterScripts(dad.curCharacter);

		boyfriend = new Character(0, 0, SONG.player1, true);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterScripts(boyfriend.curCharacter);

		var camPos:FlxPoint = FlxPoint.get(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		stagesFunc(function(stage:BaseStage) stage.createPost());

		comboGroup = new FlxSpriteGroup();
		add(comboGroup);
		uiGroup = new FlxSpriteGroup();
		add(uiGroup);
		//sprayGroup = new FlxSpriteGroup();
		//add(sprayGroup);
		noteGroup = new FlxTypedGroup<FlxBasic>();
		add(noteGroup);
		heatlhGroup = new FlxSpriteGroup();
		add(heatlhGroup);
		sprayUiGroup = new FlxSpriteGroup();
		add(sprayUiGroup);

		if (hpBarOFF == false){
			hpBarTest = new FlxSprite(); // хп бар создать
			hpBarTest.frames = Paths.getSparrowAtlas('tvorog/heatlhbar/heatlrbar');
			hpBarTest.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
			hpBarTest.scrollFactor.set(0, 0);
			hpBarTest.animation.addByPrefix('health1', "health1", 1);
			hpBarTest.animation.addByPrefix('health2', "health2", 1);
			hpBarTest.scale.set(0.5, 0.5);
			hpBarTest.origin.set(1,0);
			hpBarTest.updateHitbox();
			hpBarTest.screenCenter(X);
			hpBarTest.visible = false;
		}

		if (hpBarOFF==false) {
			hpBarTest.y = FlxG.height - 125;
			uiGroup.add(hpBarTest);	
		}


		Conductor.songPosition = -5000 / Conductor.songPosition;
		//var showTime:Bool = (ClientPrefs.data.timeBarType != 'Disabled');
		//timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		//timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//timeTxt.scrollFactor.set();
		//timeTxt.alpha = 0;
		//timeTxt.visible = false; // ggg
		//timeTxt.borderSize = 2;
		//timeTxt.visible = updateTime = showTime;
		//if(Highscore.getSettings('downScroll')) timeTxt.y = FlxG.height - 44;
		//if(ClientPrefs.data.timeBarType == 'Song Name') timeTxt.text = SONG.song;

		//timeBar = new Bar(0, timeTxt.y + (timeTxt.height / 4), 'timeBar', function() return songPercent, 0, 1);
		//timeBar.scrollFactor.set();
		//timeBar.screenCenter(X);
		//timeBar.alpha = 0;
		////timeBar.visible = showTime;
		//timeBar.visible = false; // ggg
		//uiGroup.add(timeBar);
		//uiGroup.add(timeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		noteGroup.add(strumLineNotes);

		//if(ClientPrefs.data.timeBarType == 'Song Name')
		//{
		//	timeTxt.size = 24;
		//	timeTxt.y += 3;
		//}

		var splash:NoteSplash = new NoteSplash(100, 100);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001; //cant make it invisible or it won't allow precaching

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateSong(SONG.song);

		noteGroup.add(grpNoteSplashes);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camPos.put();

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.2);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.snapToTarget();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		moveCameraSection();

		//healthBar = new Bar(0, FlxG.height * (!Highscore.getSettings('downScroll') ? 0.89 : 0.11), 'healthBar', function() return health, 0, 2);
		//healthBar.screenCenter(X);
		//healthBar.leftToRight = false;
		//healthBar.scrollFactor.set();
		////healthBar.visible = !ClientPrefs.data.hideHud;
		//healthBar.visible = false;
		//healthBar.alpha = ClientPrefs.data.healthBarAlpha;
		//reloadHealthBarColors();
		//uiGroup.add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		//iconP1.y = healthBar.y - 75;
		//iconP1.visible = !ClientPrefs.data.hideHud;
		iconP1.visible = false; /// ggg
		//iconP1.alpha = ClientPrefs.data.healthBarAlpha;
		uiGroup.add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		//iconP2.y = healthBar.y - 75;
		//iconP2.visible = !ClientPrefs.data.hideHud;
		//iconP2.alpha = ClientPrefs.data.healthBarAlpha;
		iconP2.visible = false; // ggg
		uiGroup.add(iconP2);

		//scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		//scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//scoreTxt.scrollFactor.set();
		//scoreTxt.borderSize = 1.25;
		////scoreTxt.visible = !ClientPrefs.data.hideHud;
		//scoreTxt.visible = false;
		//updateScore(false);
		//heatlhGroup.add(scoreTxt);

		//botplayTxt = new FlxText(400, timeBar.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		//botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//botplayTxt.scrollFactor.set();
		//botplayTxt.borderSize = 1.25;
		//botplayTxt.visible = cpuControlled;
		//uiGroup.add(botplayTxt);
		//if(Highscore.getSettings('downScroll'))
		//	botplayTxt.y = timeBar.y - 78;

		resultStatus = new FlxSprite(); // творог результатс
		resultStatus.frames = Paths.getSparrowAtlas('tvorog/results/resultText');
		resultStatus.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		resultStatus.animation.addByPrefix('lose', "lose", 6, true);
		resultStatus.animation.addByPrefix('win', "win", 6, true);
		resultStatus.scale.set(0.2, 0.2);
		resultStatus.screenCenter();
		resultStatus.scrollFactor.set();
		resultStatus.x += 15;
		resultStatus.y -= 10;
		resultStatus.updateHitbox();
		resultStatus.kill();
		uiGroup.add(resultStatus);	

		resultScore = new FlxSprite();
		resultScore.frames = Paths.getSparrowAtlas('tvorog/choose/playText');
		resultScore.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		resultScore.animation.addByPrefix('idle', "scoreAnim", 6, true);
		resultScore.animation.play('idle');
		resultScore.scale.set(0.4, 0.4);
		resultScore.screenCenter();
		resultScore.scrollFactor.set();
		resultScore.x -= 300;
		resultScore.y -= 0;
		resultScore.updateHitbox();
		resultScore.kill();
		uiGroup.add(resultScore);	

		resultScoreText = new FlxText(resultScore.x, resultScore.y+100, resultScore.width, "", 32);
		resultScoreText.setFormat(Paths.font("AppleLi.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		resultScoreText.scrollFactor.set();
		resultScoreText.borderSize = 1.25;
		resultScoreText.kill();
		uiGroup.add(resultScoreText);

		resultMisses = new FlxSprite(); // score txt
		resultMisses.frames = Paths.getSparrowAtlas('tvorog/choose/playText');
		resultMisses.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		resultMisses.animation.addByPrefix('idle', "missesAnim", 6, true);
		resultMisses.animation.play('idle');
		resultMisses.scale.set(0.4, 0.4);
		resultMisses.screenCenter();
		resultMisses.scrollFactor.set();
		resultMisses.x -= 300;
		resultMisses.y += 200;
		resultMisses.updateHitbox();
		resultMisses.kill();
		uiGroup.add(resultMisses);	

		resultMissesText = new FlxText(resultMisses.x, resultMisses.y+100, resultMisses.width, "", 32);
		resultMissesText.setFormat(Paths.font("AppleLi.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		resultMissesText.scrollFactor.set();
		resultMissesText.borderSize = 1.25;
		resultMissesText.kill();
		uiGroup.add(resultMissesText);


		blacker = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blacker.x -= Std.int(blacker.width/2);
		blacker.y -= 250;
		blacker.scale.set(25,25);
		blacker.scrollFactor.set(0,0);
		blacker.updateHitbox();
		blacker.alpha = 0;
		addBehindBF(blacker);


		uiGroup.cameras = [camHUD];
		heatlhGroup.cameras = [camHUD];
		//sprayGroup.cameras = [camHUD];
		noteGroup.cameras = [camHUD];
		sprayUiGroup.cameras = [camHUD];
		comboGroup.cameras = [camGame];

		startingSong = true;

		#if LUA_ALLOWED
		for (notetype in noteTypes)
			startLuasNamed('custom_notetypes/' + notetype + '.lua');
		for (event in eventsPushed)
			startLuasNamed('custom_events/' + event + '.lua');
		#end

		#if HSCRIPT_ALLOWED
		for (notetype in noteTypes)
			startHScriptsNamed('custom_notetypes/' + notetype + '.hx');
		for (event in eventsPushed)
			startHScriptsNamed('custom_events/' + event + '.hx');
		#end
		noteTypes = null;
		eventsPushed = null;

		if(eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		// SONG SPECIFIC SCRIPTS
		#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'data/$songName/'))
			for (file in FileSystem.readDirectory(folder))
			{
				#if LUA_ALLOWED
				if(file.toLowerCase().endsWith('.lua'))
					new FunkinLua(folder + file);
				#end

				#if HSCRIPT_ALLOWED
				if(file.toLowerCase().endsWith('.hx'))
					initHScript(folder + file);
				#end
			}
		#end

		var sprayData:SprayFile = SprayData.getPresetFile();
		var foundSong = false;
		for (i in 0...sprayData.SpraySongs.length){
			if (songName==sprayData.SpraySongs[i]){
				foundSong = true;
				for (i in 0...sprayData.Sprays.length){
					allShapes[i] = sprayData.Sprays[i];
				}
				for (i in 0...sprayData.SprColors.length){
					colorSpray[i] = sprayData.SprColors[i];
				}
				sprayShape = allShapes[0];
				boyfriend.alpha = 0;
				dad.alpha = 0;
				for (i in 0...colorSpray.length){
					var spriteColor = new FlxSprite();
					spriteColor.screenCenter(X);
					if (i<5){
						spriteColor.x += 147 +(62*i);
						spriteColor.y = 0+Std.int(FlxG.height/10);
					}
					else{
						spriteColor.x += 178 +(62*(i-5));
						spriteColor.y = 0+Std.int(FlxG.height/10)+24;
					}
					spriteColor.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
					spriteColor.scrollFactor.set();
					spriteColor.frames = Paths.getSparrowAtlas('tvorog/sprayPart/sprayNumb');
					spriteColor.animation.addByPrefix('numb', "numb"+(i+1), 6, true);
					spriteColor.scale.set(0.225,0.225);
					spriteColor.updateHitbox();
					spriteColor.animation.play('numb');
					spriteColor.alpha = 0;
					FlxTween.tween(spriteColor, {alpha: 0.9}, 2, {ease: FlxEase.quadIn});
	
					sprayUiGroup.add(spriteColor);	
				}
				sprayColorSprite = new FlxSprite(0,0).loadGraphic(Paths.image('tvorog/sprayPart/Presets/brushTextures/'+Std.string(sprayShape)));
				sprayColorSprite.color = FlxColor.fromString('0x'+colorSpray[0]);
				sprayColorSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
				sprayColorSprite.scale.set(0.45,0.45);
				sprayColorSprite.screenCenter(X);
				sprayColorSprite.x = FlxG.width-sprayColorSprite.width-25;
				sprayColorSprite.y = 0+Std.int(FlxG.height/10)-45;
				sprayColorSprite.scrollFactor.set();
				sprayColorSprite.alpha = 0;
				sprayUiGroup.add(sprayColorSprite);
				FlxTween.tween(sprayColorSprite, {alpha: 1}, 2, {ease: FlxEase.quadIn});
	
				var sprayShapeSprite = new FlxSprite(0,0);
				sprayShapeSprite.frames = Paths.getSparrowAtlas('tvorog/sprayPart/shape');
				sprayShapeSprite.animation.addByPrefix('shape', "shape", 6, true);
				sprayShapeSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
				sprayShapeSprite.scale.set(0.45,0.45);
				sprayShapeSprite.screenCenter(X);
				sprayShapeSprite.x = FlxG.width-sprayColorSprite.width-5;
				sprayShapeSprite.y = 0+Std.int(FlxG.height/10)-45;
				sprayShapeSprite.scrollFactor.set();
				sprayShapeSprite.updateHitbox();
				sprayShapeSprite.animation.play('shape');
				sprayShapeSprite.alpha = 0;
				sprayUiGroup.add(sprayShapeSprite);
				FlxTween.tween(sprayShapeSprite, {alpha: 1}, 2, {ease: FlxEase.quadIn});
	
				sprayHealthSprite = new FlxSprite();
				sprayHealthSprite.makeGraphic(150*4, 50, FlxColor.GREEN);
				sprayHealthSprite.screenCenter(X);
				sprayHealthSprite.x -= sprayHealthSprite.width;
				sprayHealthSprite.y = 0+Std.int(FlxG.height/10);
				sprayHealthSprite.scale.x = 0;
	
				for (i in 0...5){
					var keyText:FlxText = new FlxText(12, FlxG.height - (30 + (14 * i)), 0, "", 12);
					keyText.scrollFactor.set();
					keyText.setFormat("AppleLi.ttf", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
					keyText.alpha = 0;
					if (i==4){
						keyText.text = '[ NUMBERS ] - COLOR';
					}
					else if (i==3){
						keyText.text = '[ SHIFT ] - SHAPE';
					}
					else if (i==2){
						keyText.text = '[ CTRL + Z ] - UNDO';
					}
					else if (i==1){
						keyText.text = '[ MOUSEWHEEL ] - SIZE';
					}
					else{
						keyText.text = '[ F ] - SKIP';
					}
					sprayUiGroup.add(keyText);
					FlxTween.tween(keyText, {alpha: 0.9}, 2, {ease: FlxEase.quadIn, startDelay: 1 + (0.2*i)});
				}
	
				spraySizeText = new FlxText(12, FlxG.height - 58, 0, "", 24);
				spraySizeText.scrollFactor.set();
				spraySizeText.setFormat("AppleLi.ttf", 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				spraySizeText.alpha = 0;
				spraySizeText.x = FlxG.width - 325;
				spraySizeText.y = FlxG.height-58;
				sprayUiGroup.add(spraySizeText);
				FlxTween.tween(spraySizeText, {alpha: 0.9}, 2, {ease: FlxEase.quadIn});
	
				sprayUiGroup.add(sprayHealthSprite);
				FlxTween.tween(sprayHealthSprite.scale, {x: 1}, 2, {ease: FlxEase.quadIn});
				sprayPart(false);
	
				sound = FlxG.sound.play(Paths.sound('spray/sprayStart'+FlxG.random.int(1,4)), 10);		
				FlxG.sound.playMusic(Paths.music('spray'), 0);
				FlxG.sound.music.fadeIn(sound.length/1000, 0, 0.4);
				break;
			}
		}

		if(!foundSong){
			startCallback();
		}
		//RecalculateRating();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		//PRECACHING THINGS THAT GET USED FREQUENTLY TO AVOID LAGSPIKES
		Paths.sound('hitsound');
		for (i in 1...4) Paths.sound('missnote$i');
		Paths.image('alphabet');

		if (PauseSubState.songName != null)
			Paths.music(PauseSubState.songName);
		else if(Paths.formatToSongPath('spray') != 'none')
			Paths.music(Paths.formatToSongPath('spray'));

		resetRPC();

		callOnScripts('onCreatePost');

		cacheCountdown();
		cachePopUpScore();

		super.create();
		Paths.clearUnusedMemory();

		if(eventNotes.length < 1) checkEventNote();
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		songSpeed = value;
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);
		return value;
	}

	function set_playbackRate(value:Float):Float
	{
		#if FLX_PITCH
		if(generatedMusic)
		{
			vocals.pitch = value;
			opponentVocals.pitch = value;
			FlxG.sound.music.pitch = value;

			var ratio:Float = playbackRate / value; //funny word huh
			if(ratio != 1)
			{
				for (note in notes.members) note.resizeByRatio(ratio);
				for (note in unspawnNotes) note.resizeByRatio(ratio);
			}
		}
		playbackRate = value;
		FlxG.animationTimeScale = value;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * value;
		setOnScripts('playbackRate', playbackRate);
		#else
		playbackRate = 1.0; // ensuring -Crow
		#end
		return playbackRate;
	}

	#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
	public function addTextToDebug(text:String, color:FlxColor) {
		var newText:psychlua.DebugLuaText = luaDebugGroup.recycle(psychlua.DebugLuaText);
		newText.text = text;
		newText.color = color;
		newText.disableTime = 6;
		newText.alpha = 1;
		newText.setPosition(10, 8 - newText.height);

		luaDebugGroup.forEachAlive(function(spr:psychlua.DebugLuaText) {
			spr.y += newText.height + 2;
		});
		luaDebugGroup.add(newText);

		Sys.println(text);
	}
	#end

	//public function reloadHealthBarColors() {
	//	healthBar.setColors(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
	//		FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
	//}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterScripts(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterScripts(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					middleCharGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterScripts(newGf.curCharacter);
				}
		}
	}

	function startCharacterScripts(name:String)
	{
		// Lua
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/$name.lua';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(luaFile);
		if(FileSystem.exists(replacePath))
		{
			luaFile = replacePath;
			doPush = true;
		}
		else
		{
			luaFile = Paths.getSharedPath(luaFile);
			if(FileSystem.exists(luaFile))
				doPush = true;
		}
		#else
		luaFile = Paths.getSharedPath(luaFile);
		if(Assets.exists(luaFile)) doPush = true;
		#end

		if(doPush)
		{
			for (script in luaArray)
			{
				if(script.scriptName == luaFile)
				{
					doPush = false;
					break;
				}
			}
			if(doPush) new FunkinLua(luaFile);
		}
		#end

		// HScript
		#if HSCRIPT_ALLOWED
		var doPush:Bool = false;
		var scriptFile:String = 'characters/' + name + '.hx';
		#if MODS_ALLOWED
		var replacePath:String = Paths.modFolders(scriptFile);
		if(FileSystem.exists(replacePath))
		{
			scriptFile = replacePath;
			doPush = true;
		}
		else
		#end
		{
			scriptFile = Paths.getSharedPath(scriptFile);
			if(FileSystem.exists(scriptFile))
				doPush = true;
		}

		if(doPush)
		{
			if(SScript.global.exists(scriptFile))
				doPush = false;

			if(doPush) initHScript(scriptFile);
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		#if LUA_ALLOWED
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		#end
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:VideoHandler = new VideoHandler();
			#if (hxCodec >= "3.0.0")
			// Recent versions
			video.play(filepath);
			video.onEndReached.add(function()
			{
				video.dispose();
				startAndEnd();
				return;
			}, true);
			#else
			// Older versions
			video.playVideo(filepath);
			video.finishCallback = function()
			{
				startAndEnd();
				return;
			}
			#end
		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			if (isResult==false){
				resultShow(false, false);
			}
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(DialogueBoxPsych.parseDialogue(Paths.json(songName + '/dialogue')))" and it should load dialogue.json
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	function cacheCountdown()
	{
		var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
		var introImagesArray:Array<String> = switch(stageUI) {
			case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
			case "normal": ["ready", "set" ,"go"];
			default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
		}
		introAssets.set(stageUI, introImagesArray);
		var introAlts:Array<String> = introAssets.get(stageUI);
		for (asset in introAlts) Paths.image(asset);

		Paths.sound('intro3' + introSoundsSuffix);
		Paths.sound('intro2' + introSoundsSuffix);
		Paths.sound('intro1' + introSoundsSuffix);
		Paths.sound('introGo' + introSoundsSuffix);
	}

	public function sprayPart(end:Bool, ?skipped:Bool=false) // творог спрей
		{
			if (end==false){ // начало
				sprayChangeColor('ONE');
				FlxG.mouse.visible = true;
				gf.alpha = 1;
				var meow:FlxTimer = new FlxTimer().start(0.65, function(tmr:FlxTimer) {
					gf.animation.play('start');
				});
				camFollow.setPosition(gf.getGraphicMidpoint().x, gf.getGraphicMidpoint().y - 500);
				FlxTween.tween(gf, {alpha: 0}, 2, {ease: FlxEase.quadOut});
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom+0.25}, 2, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
					canSpray = true;
				}});
				//FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 2, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
				//	canSpray = true;
				//}});

			}
			else{ // конец
				if (FlxG.mouse.visible != false){
					moveCameraSection();

					var legmur:Float = 3;
					if (skipped==false){
						sound.stop();
						sound = FlxG.sound.play(Paths.sound('spray/sprayEnd'+FlxG.random.int(1,5)), 10);	
						legmur = sound.length/1000;
					}
					else{
						FlxG.sound.play(Paths.sound('resultADD'), 0.15);
						sound.stop();
						sound = FlxG.sound.play(Paths.sound('spray/spraySkip'+FlxG.random.int(1,2)), 10);	
						legmur = sound.length/1000;
					}
					var meow:FlxTimer = new FlxTimer().start(1.1, function(tmr:FlxTimer) {
						gf.animation.play('end');
					});
					FlxG.sound.music.stop();
					FlxG.mouse.visible = false;
					//camPos.x = gf.getGraphicMidpoint().x;
					//camPos.y = gf.getGraphicMidpoint().y - 100;
					canSpray = false;
					var xSize = 650;
					boyfriend.x = boyfriend.x + xSize;
					dad.x = dad.x - xSize;

					sprayHealthSprite.scale.x=0;
					sprayUiGroup.remove(sprayHealthSprite);

					for (part in 0...sprayUiGroup.length){
						if (sprayUiGroup.members[part]!=null){
							FlxTween.tween(sprayUiGroup.members[part], {alpha: 0}, 3, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
								sprayUiGroup.remove(sprayUiGroup.members[part]);
							}});
						}
					}

					FlxTween.tween(gf, {alpha: 1, x: gf.x-300}, legmur, {ease: FlxEase.quadOut});
					FlxTween.tween(boyfriend, {alpha: 1, x: boyfriend.x-xSize}, legmur, {ease: FlxEase.quadOut});
					FlxTween.tween(dad, {alpha: 1, x: dad.x+xSize}, legmur, {ease: FlxEase.quadOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, legmur, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
						//trace("pipipupukaka");
						startCountdown();
					}});
				}

			}
		}

	public function sprayChangeColor(color:String){
		switch(color){
			case 'ONE':
				sprayColorMain = colorSpray[0];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);
			case 'TWO':
				sprayColorMain = colorSpray[1];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);
			case 'THREE':
				sprayColorMain = colorSpray[2];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);	
			case 'FOUR':
				sprayColorMain = colorSpray[3];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);
			case 'FIVE':
				sprayColorMain = colorSpray[4];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);
			case 'SIX':
				sprayColorMain = colorSpray[5];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);	
			case 'SEVEN':
				sprayColorMain = colorSpray[6];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);	
			case 'EIGHT':
				sprayColorMain = colorSpray[7];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);	
			case 'NINE':
				sprayColorMain = colorSpray[8];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);		
			default : 	
				sprayColorMain = colorSpray[0];
				sprayColorSprite.color = FlxColor.fromString('0x'+sprayColorMain);	
		}
	}

	public function sprayChangeShape(){

		sprayShapeValue++;

		if (sprayShapeValue>=allShapes.length){
			sprayShapeValue = 0;
		}
		sprayShape = Std.string(allShapes[sprayShapeValue]);
		sprayColorSprite.loadGraphic(Paths.image('tvorog/sprayPart/Presets/brushTextures/'+Std.string(sprayShape)));
	}

	public function sprayBack(){// CTRL Z
		if (sprayCTRLz>-1 && sprayCount>0){

			for (i in 0...sprayOper.length){
				//trace(sprayOper[i]+' - yach #'+i);
			}
			var minSpray:Int = sprayOper.pop();

			var meow:Int = backGfGroup.members.length;

			//trace('minimu spray : '+minSpray);
			//trace('max spray : '+meow);

			while (meow>minSpray){
				for (i in minSpray...meow){ //sprayCount
					//trace(i);
					if (backGfGroup.members[i]!=null){
						//trace(i+' deleted');
						backGfGroup.members[i].destroy();
						backGfGroup.members.remove(backGfGroup.members[i]);
						meow-=1;
						if (sprayCheat==false){ // спрей чит трата
							healthSpray += 0.1;
						}
					}
					
				}				
			}

			sprayCount = meow;
			sprayCTRLz = meow;

			//trace(sprayOper[sprayOper.length]+' - yacheek');
			//trace(backGfGroup.members.length+' - members');
		}
		else{
			//trace('error');
			//trace('ctrlz='+sprayCTRLz+'; sprayCount='+sprayCount);
		}
	}
	
	public function arrowBar(animName:String, opponent:Bool=false){
		var noteUper:FlxSprite = new FlxSprite(); // мисс нота
		noteUper.updateHitbox();
		noteUper.scrollFactor.set(0,0);
		noteUper.frames = Paths.getSparrowAtlas("tvorog/arrows");
		noteUper.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		noteUper.animation.addByPrefix('anim', animName, 1);
		noteUper.animation.play('anim');
		noteUper.alpha = 1;
		if (animName=="arrowMISS"){
			noteUper.color = FlxColor.fromString('0x955CFF');
		}
		else if(animName=="arrowWIN" || animName=="arrowLOSE"){
			noteUper.color = FlxColor.WHITE;
		}
		else{
			noteUper.color = FlxColor.fromString('0x4B4B4B');
		}
		noteUper.scale.set(0.2,0.2);
		var countd:Float=3;
		if (opponent==false){
			noteUper.x = FlxG.width;
			noteUper.y = -30;
			if(animName=="arrowWIN" || animName=="arrowLOSE"){
				noteUper.velocity.set(-250,0);
				countd=6;
			}
			else{
				noteUper.velocity.set(-500,0);
			}
		}
		else{
			noteUper.x = 0-noteUper.width;
			noteUper.y = FlxG.height-noteUper.height+30;
			if(animName=="arrowWIN" || animName=="arrowLOSE"){
				noteUper.velocity.set(250,0);
				countd=6;
			}
			else{
				noteUper.velocity.set(500,0);
			}
		}
		heatlhGroup.add(noteUper);

		

		var meow:FlxTimer = new FlxTimer().start(countd, function(tmr:FlxTimer) {
			heatlhGroup.remove(noteUper);
		});
	}

	public function startCountdown()
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return false;
		}

		seenCutscene = true;
		inCutscene = false;
		var ret:Dynamic = callOnScripts('onStartCountdown', null, true);
		if(ret != LuaUtils.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;
			if (haveArrow==false){ // генерация
				generateStaticArrows(0);
				generateStaticArrows(1);
				for (i in 0...playerStrums.length) {
					//setOnScripts('defaultPlayerStrumX' + i, playerStrums.members[i].x);
					//setOnScripts('defaultPlayerStrumY' + i, playerStrums.members[i].y);
					playerStrums.members[i].screenCenter(X);
					playerStrums.members[i].x = playerStrums.members[i].x + 225 + (80 * i);
					playerStrums.members[i].scale.set(0.5,0.5);
				}
				for (i in 0...opponentStrums.length) {
					//setOnScripts('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
					//setOnScripts('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
					opponentStrums.members[i].screenCenter(X);
					opponentStrums.members[i].x = opponentStrums.members[i].x - 475 + (80 * i);
					opponentStrums.members[i].scale.set(0.5,0.5);
					//opponentStrums.members[i].visible = false;
					//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
				}
				haveArrow=true;
			}
			else{ // уже есть стрелки
				var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
				var strumLineY:Float = ClientPrefs.tvorogSet['downScroll'] ? (FlxG.height - 150) : 40;
				for (i in 0...playerStrums.length) {
					playerStrums.members[i].screenCenter(X);
					playerStrums.members[i].x = playerStrums.members[i].x + 225 + (80 * i);
					playerStrums.members[i].y = strumLineY;
					//playerStrums.members[i].scale.set(0.5,0.5);
					playerStrums.members[i].alpha = 1;
					playerStrums.members[i].playAnim('static');
				}
				for (i in 0...opponentStrums.length) {
					opponentStrums.members[i].screenCenter(X);
					opponentStrums.members[i].x = opponentStrums.members[i].x - 475 + (80 * i);
					opponentStrums.members[i].y = strumLineY;
					//opponentStrums.members[i].scale.set(0.5,0.5);
					opponentStrums.members[i].alpha = 1;
					//opponentStrums.members[i].visible = false;
					//if(ClientPrefs.data.middleScroll) opponentStrums.members[i].visible = false;
				}
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;
			setOnScripts('startedCountdown', true);
			callOnScripts('onCountdownStarted', null);

			var swagCounter:Int = 0;
			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return true;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return true;
			}
			moveCameraSection();

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				characterBopper(tmr.loopsLeft);

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				var introImagesArray:Array<String> = switch(stageUI) {
					case "pixel": ['${stageUI}UI/ready-pixel', '${stageUI}UI/set-pixel', '${stageUI}UI/date-pixel'];
					case "normal": ["ready", "set" ,"go"];
					default: ['${stageUI}UI/ready', '${stageUI}UI/set', '${stageUI}UI/go'];
				}
				introAssets.set(stageUI, introImagesArray);

				var introAlts:Array<String> = introAssets.get(stageUI);
				var antialias:Bool = (ClientPrefs.tvorogSet['antialiasing'] && !isPixelStage);
				var tick:Countdown = THREE;

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						tick = THREE;
					case 1:
						countdownReady = createCountdownSprite(introAlts[0], ClientPrefs.tvorogSet['antialiasing']);
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
						tick = TWO;
					case 2:
						countdownSet = createCountdownSprite(introAlts[1], ClientPrefs.tvorogSet['antialiasing']);
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
						tick = ONE;
					case 3:
						countdownGo = createCountdownSprite(introAlts[2], ClientPrefs.tvorogSet['antialiasing']);
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						tick = GO;
					case 4:
						tick = START;
						canPause = true;
						FlxG.sound.music.volume = 1; // звук он
				}

				notes.forEachAlive(function(note:Note) {
					if(ClientPrefs.data.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(ClientPrefs.data.middleScroll && !note.mustPress)
							note.alpha *= 0.35;
					}
				});

				stagesFunc(function(stage:BaseStage) stage.countdownTick(tick, swagCounter));
				callOnLuas('onCountdownTick', [swagCounter]);
				callOnHScript('onCountdownTick', [tick, swagCounter]);

				swagCounter += 1;
			}, 5);
		}
		return true;
	}

	public function playerDied(end:Bool=false){ // творог игрок умер
		if (end==false){
			startingSong = true;
			startedCountdown = false;
			gfSection = false;
			//canUpdTimer=false;
			isDead = true;

			if (walkTwn!=null){
				walkTwn.cancel();
				for (i in 0...walkGroup.members.length){
					if (walkGroup.members[i]!=null){
						walkGroup.members[i].velocity.set(FlxG.random.int(-300, -150),FlxG.random.int(-125, -50));
						walkGroup.members[i].acceleration.y = FlxG.random.int(300, 450);
						if (walkGroup.members[i].velocity.x>0){
							walkGroup.members[i].angularAcceleration = 30;
						}
						else{
							walkGroup.members[i].angularAcceleration = -30;
						}
						FlxTween.tween(walkGroup.members[i], {alpha: 0}, 1.2, {ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
							if (walkGroup.members[i]!=null){
								remove(walkGroup.members[i]);
							}
						}});
					}
				}
			}
			FlxTween.tween(blacker, {alpha: 0.5}, 2, {ease: FlxEase.quadOut}); // чёрный зад
			KillNotes();
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 90);
			//FlxG.sound.music.stop();
			//FlxG.sound.music.onComplete();
			FlxG.sound.music.volume = 0;
			inst.stop();
			vocals.stop();
			opponentVocals.stop();
			Conductor.songPosition == 0.0;
			while(grpNoteSplashes.members.length>0){
				for (part in 0...grpNoteSplashes.members.length){
					if (grpNoteSplashes.members[part]!=null){
						grpNoteSplashes.members[part].destroy();
						grpNoteSplashes.members.remove(grpNoteSplashes.members[part]);
					}
				}
			}
			while(unspawnNotes.length>0){
				for (part in 0...unspawnNotes.length){
					if (unspawnNotes[part]!=null){
						unspawnNotes[part].destroy();
						unspawnNotes.remove(unspawnNotes[part]);
					}
				}
			}
			var canDeleting=false;
			for (part in 0...opponentStrums.members.length){
				opponentStrums.members[part].velocity.set(FlxG.random.int(-250, 250),FlxG.random.int(-125, -50));
				opponentStrums.members[part].acceleration.y = FlxG.random.int(300, 450);
				opponentStrums.members[part].alpha = 1;
				FlxTween.tween(opponentStrums.members[part], {alpha: 0}, 2, {ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
					canDeleting=true;
					//opponentStrums.members[part].angularAcceleration =0;
					opponentStrums.members[part].acceleration.y=0;
					opponentStrums.members[part].velocity.set(0,0);
				}});
			}
			for (part in 0...playerStrums.members.length){
				playerStrums.members[part].velocity.set(FlxG.random.int(-250, 250),FlxG.random.int(-125, -50));
				playerStrums.members[part].acceleration.y = FlxG.random.int(300, 450);
				playerStrums.members[part].alpha = 1;
				FlxTween.tween(playerStrums.members[part], {alpha: 0}, 2, {ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
					canDeleting=true;
					//playerStrums.members[part].angularAcceleration =0;
					playerStrums.members[part].acceleration.y=0;
					playerStrums.members[part].velocity.set(0,0);
				}});
			}
			while(notes.members.length>0){
				for (part in 0...notes.members.length){
					if (notes.members[part]!=null){
						notes.members[part].destroy();
						notes.members.remove(notes.members[part]);
					}
				}
			}
			//trace('player died');
			FlxG.sound.list.remove(inst);
			FlxG.sound.list.remove(vocals);
			gameOver = new FlxSound();
			gameOver.loadEmbedded(Paths.music('gameOver'), true); // gameover
			FlxG.sound.list.add(gameOver);
			gameOver.volume = 0.5;
			gameOver.play();
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom+0.15}, 2, {ease: FlxEase.elasticOut});
			resultShow(false, true);
			eventsPushed = [];
		}
		else{ // died end
			canContinue = false;
			//FlxTimer.globalManager.clear();
			FlxTween.globalManager.clear();
			gameOver.fadeOut(2, 0, function(twn:FlxTween) {
				gameOver.stop();
				FlxG.sound.list.remove(gameOver);
			});
			health = 1;
			//trace('player conttinue');
			moveCameraSection();
			resultShow(true, true);
			FlxTween.tween(blacker, {alpha: 0}, 2, {ease: FlxEase.quadOut}); // чёрный зад
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
				isDead = false;
				startingSong = false;
				//canUpdTimer=true;
				generateSong(SONG.song);
	
				startCountdown();
			}});
			//startSong();
		}
	}

	public function resultShow(end:Bool=false, ?died:Bool=false){
		if (end==false){
			isResult = true;
			if (!resultStatus.alive){ // воскрес аним скоре
				resultStatus.revive();
			}

			if (!resultScore.alive){ // воскрес аним скоре
				resultScore.revive();
			}

			if (!resultScoreText.alive){ // воскрес текс скоре
				resultScoreText.revive();
			}
	
			if (!resultMisses.alive){ // воскрес аним мисс
				resultMisses.revive();
			}
	
			if (!resultMissesText.alive){ // воскрес текс мисс
				resultMissesText.revive();
			}

			resultStatus.alpha = 0;
			resultScore.alpha = 0;
			resultScoreText.alpha = 0;
			resultMisses.alpha = 0;
			resultMissesText.alpha = 0;

			camZooming = false;

			if (died==false){
				endingSong=true;
				canPause=false;
				FlxTween.tween(blacker, {alpha: 0.5}, 2, {ease: FlxEase.quadOut}); // чёрный зад
				KillNotes();
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 90);
				inst.stop();
				vocals.stop();
				opponentVocals.stop();
				Conductor.songPosition == 0.0;			
				for (part in 0...opponentStrums.members.length){
					opponentStrums.members[part].alpha = 1;
					FlxTween.tween(opponentStrums.members[part], {alpha: 0}, 2, {ease: FlxEase.quadIn});
				}
				for (part in 0...playerStrums.members.length){
					playerStrums.members[part].alpha = 1;
					FlxTween.tween(playerStrums.members[part], {alpha: 0}, 2, {ease: FlxEase.quadIn});
				}	
				nextSwitch = 1;
				resultStatus.animation.stop();
				resultStatus.animation.play('win');
				oldScore = 0;
				canReSwitch=true;
				//trace('victory!');
			}
			else{
				//trace('died results!');
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoomBase+0.2}, 2, {ease: FlxEase.elasticOut});

				FlxTween.tween(resultStatus, {alpha: 1, x: resultStatus.x+90}, 2, {ease: FlxEase.quadOut});
	
				FlxTween.tween(resultScore, {alpha: 1, x: resultScore.x+90}, 2, {ease: FlxEase.quadOut, startDelay: 0.1});
	
				FlxTween.tween(resultScoreText, {alpha: 1, x: resultScoreText.x+90}, 2, {ease: FlxEase.quadOut, startDelay: 0.2});
	
				FlxTween.tween(resultMisses, {alpha: 1, x: resultMisses.x+90}, 2, {ease: FlxEase.quadOut, startDelay: 0.3});
	
				FlxTween.tween(resultMissesText, {alpha: 1, x: resultMissesText.x+90}, 2, {ease: FlxEase.quadOut, startDelay: 0.4, onComplete: function(twn:FlxTween) {
					canContinue = true;
				}});
								
				resultStatus.animation.stop();
				resultStatus.animation.play('lose');
				resultScoreText.text = Std.string(songScore);
				resultMissesText.text = Std.string(songMisses);
				boyfriend.color = FlxColor.fromString("0x6601FF");
			}
		}
		else{
			resultMisses.alpha = 1;
			FlxTween.tween(resultMisses, {alpha: 0}, 1, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
				if (resultMisses.alive){
					resultMisses.x -= 90;
					resultMisses.kill();
				}
			}});

			resultScore.alpha = 1;
			FlxTween.tween(resultScore, {alpha: 0}, 1, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
				if (resultScore.alive){
					resultScore.x -= 90;
					resultScore.kill();
				}
			}});

			resultScoreText.alpha = 1;
			FlxTween.tween(resultScoreText, {alpha: 0}, 1, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
				if (resultScoreText.alive){
					resultScoreText.x -= 90;
					resultScoreText.kill();
				}
			}});

			resultMissesText.alpha = 1;
			FlxTween.tween(resultMissesText, {alpha: 0}, 1, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
				if (resultMissesText.alive){
					resultMissesText.x -= 90;
					resultMissesText.kill();
				}
			}});

			resultStatus.alpha = 1;
			FlxTween.tween(resultStatus, {alpha: 0}, 1, {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
				if (resultStatus.alive){
					resultStatus.x -= 90;
					resultStatus.kill();
				}
			}});

			if (died==true){
				songScore = 0;
				songMisses = 0;
				songHits = 0;
				combo = 0;
				isResult = false;
				arrowBarTime=0;

				if (boyfriend.color != FlxColor.WHITE){
					FlxTween.color(boyfriend, 1, boyfriend.color, FlxColor.WHITE, {ease: FlxEase.quadOut});
				}
			}
			else{
				canContinue=false;
				FlxTween.globalManager.clear();
				if (gameOver!=null){
					gameOver.fadeOut(1, 0, function(twn:FlxTween) {
						gameOver.stop();
						FlxG.sound.list.remove(gameOver);
					});
				}
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom - 0.2}, 1, {ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
					endSong();
				}});
			}
		}
	}

	public function resultSwitch(meow:Int){
		switch(meow)
		{
			case 1: // появление надписи вин
				gameOver = new FlxSound();
				gameOver.loadEmbedded(Paths.music('winSong'), true); // winover
				Conductor.bpm = 112;
				FlxG.sound.list.add(gameOver);
				gameOver.volume = 0;
				gameOver.play();
				gameOver.time = 7180; //6780

				gameOver.fadeIn(3, 0, 0.3);

				//trace('myrmyr');
				resultStatus.animation.stop();
				resultStatus.animation.play('win');
				resultStatus.scale.set(0,0);
				resultStatus.screenCenter();
				resultStatus.alpha=1;
				FlxG.sound.play(Paths.sound('resultPOW'), 0.5);
				FlxTween.tween(FlxG.camera, {zoom: 0.6}, 0.7, {ease: FlxEase.elasticOut});
				FlxTween.tween(resultStatus.scale, { x:0.2, y:0.2 }, 0.7,{ease: FlxEase.elasticOut, onComplete: function(twn:FlxTween) {
					nextSwitch+=1;
					canReSwitch=true;
				}});

			case 2: //размещение надписи вин
				FlxG.sound.play(Paths.sound('resultADD'), 0.4);
				FlxTween.tween(resultStatus, { x: FlxG.width - 300, y:100 }, 0.3,{ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
					nextSwitch+=1;
					canReSwitch=true;
				}});
			case 3: // появление надписей скор
				newScore = songScore;
				canCalculateScore == 'score';
				FlxG.sound.play(Paths.sound('resultPOW'), 0.5);
				resultScore.scale.set(0,0);
				resultScore.screenCenter();
				resultScoreText.screenCenter();
				resultScoreText.y +=30;
				resultScore.alpha=1;
				resultScoreText.alpha=1;
				resultScoreText.text = Std.string(songScore);
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.05}, 0.7, {ease: FlxEase.elasticOut});
				FlxTween.tween(resultScore.scale, { x:0.4, y:0.4 }, 0.7,{ease: FlxEase.elasticOut, onComplete: function(twn:FlxTween) {
					nextSwitch+=1;
					canReSwitch=true;
				}});
			case 4:
				FlxG.sound.play(Paths.sound('resultADD'), 0.4);
				FlxTween.tween(resultScore, { x:100, y: resultScore.y - 50}, 0.3,{ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
					FlxG.sound.play(Paths.sound('resultADD'), 0.4);
				}});
				FlxTween.tween(resultScoreText, { x: 125, y:resultScore.y }, 0.3,{ease: FlxEase.quadIn, startDelay: 0.3, onComplete: function(twn:FlxTween) {
					nextSwitch+=1;
					canReSwitch=true;
				}});
			case 5:
				newScore = songMisses;
				canCalculateScore == 'misses';
				FlxG.sound.play(Paths.sound('resultPOW'), 0.5);
				resultMisses.scale.set(0,0);
				resultMisses.alpha=1;
				resultMissesText.alpha=1;
				resultMisses.screenCenter();
				resultMissesText.screenCenter();
				resultMissesText.y +=30;
				resultMissesText.text = Std.string(songMisses);
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.05}, 0.7, {ease: FlxEase.elasticOut});
				FlxTween.tween(resultMisses.scale, { x:0.4, y:0.4 }, 0.7,{ease: FlxEase.elasticOut, onComplete: function(twn:FlxTween) {
					nextSwitch+=1;
					canReSwitch=true;
				}});
			case 6:
				FlxG.sound.play(Paths.sound('resultADD'), 0.4);
				FlxTween.tween(resultMisses, { x:100, y: resultScoreText.y +50 }, 0.3,{ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
					FlxG.sound.play(Paths.sound('resultADD'), 0.4);
				}});
				FlxTween.tween(resultMissesText, { x: 125, y:resultScoreText.y +125 }, 0.3,{ease: FlxEase.quadIn, startDelay: 0.3, onComplete: function(twn:FlxTween) {
					nextSwitch+=1;
					canReSwitch=true;
				}});
			case 7:
				FlxG.sound.play(Paths.sound('resultPOW'), 0.5);
				resultRankSprite = new FlxSprite(); // score txt
				resultRankSprite.scrollFactor.set();
				//resultRankSprite.updateHitbox();
				resultRankSprite.frames = Paths.getSparrowAtlas('tvorog/results/ranks');
				resultRankSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
				resultRankSprite.animation.addByPrefix('idle', "rankAnim", 6, true);
				resultRankSprite.animation.play('idle');
				resultRankSprite.scale.set(0, 0);
				resultRankSprite.screenCenter();
				resultRankSprite.x -= Std.int(resultRankSprite.width/4);
				resultRankSprite.y -= 35;
				uiGroup.add(resultRankSprite);	

				if (songMisses==0 && ratingsData[2].hits == 0){
					rankChar = 'A';
				}
				else if((songMisses>0 && songMisses < 5) || (ratingsData[2].hits > 0 && ratingsData[2].hits < 3)){
					rankChar = 'B';
				}
				else{
					rankChar = 'C';
				}

				resultRankChar = new FlxSprite(); // score txt
				resultRankChar.scrollFactor.set();
				//resultRankChar.updateHitbox();
				resultRankChar.frames = Paths.getSparrowAtlas('tvorog/results/ranks');
				resultRankChar.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
				resultRankChar.animation.addByPrefix('idle', "rank"+rankChar+"anim", 6, true);
				resultRankChar.animation.play('idle');
				resultRankChar.scale.set(0, 0);
				resultRankChar.screenCenter();
				resultRankChar.y += 100;
				uiGroup.add(resultRankChar);	
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.05}, 0.7, {ease: FlxEase.elasticOut});
				FlxTween.tween(resultRankSprite.scale, { x:0.4, y:0.4 }, 0.7,{ease: FlxEase.elasticOut, onComplete: function(twn:FlxTween) {
					FlxG.sound.play(Paths.sound('resultPOW'), 0.5);
					FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.05}, 0.7, {ease: FlxEase.elasticOut});
				}});		
				FlxTween.tween(resultRankChar.scale, { x:0.3, y:0.3 }, 0.7,{ease: FlxEase.elasticOut, startDelay: 0.7, onComplete: function(twn:FlxTween) {
					nextSwitch+=1;
					canReSwitch=true;
				}});		
			case 8:
				FlxG.sound.play(Paths.sound('resultADD'), 0.4);
				FlxTween.tween(resultRankSprite, { x:resultRankSprite.x-375-50, y:resultScore.y-300 }, 0.3,{ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
					FlxG.sound.play(Paths.sound('resultADD'), 0.4);
				}});		
				FlxTween.tween(resultRankChar, { x:resultRankChar.x-375+85, y:resultScore.y-300 }, 0.3,{ease: FlxEase.quadIn, startDelay: 0.3, onComplete: function(twn:FlxTween) {
					nextSwitch+=1;
					canReSwitch=true;
				}});		
			case 9:
				canReSwitch=false;
				FlxG.sound.play(Paths.sound('resultPOW'), 0.25);
				boyfriendIdleTime = 0;
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom - 0.05}, 0.3, {ease: FlxEase.elasticOut});
				//FlxTween.tween(gameOver, {volume: 0.75}, 0.3, {ease: FlxEase.quadOut});
				gameOver.volume = 1;
				//trace('meow');
				canContinue = true;
		}
	}

	

	inline private function createCountdownSprite(image:String, antialias:Bool):FlxSprite
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(image));
		spr.cameras = [camHUD];
		spr.scrollFactor.set();
		spr.updateHitbox();

		if (PlayState.isPixelStage)
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.screenCenter();
		spr.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		insert(members.indexOf(noteGroup), spr);
		FlxTween.tween(spr, {/*y: spr.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				remove(spr);
				spr.destroy();
			}
		});
		return spr;
	}

	public function addBehindGF(obj:FlxBasic)
	{
		insert(members.indexOf(middleCharGroup), obj);
	}
	public function addBehindBF(obj:FlxBasic)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxBasic)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
				invalidateNote(daNote);
			}
			--i;
		}
	}

	// fun fact: Dynamic Functions can be overriden by just doing this
	// `updateScore = function(miss:Bool = false) { ... }
	// its like if it was a variable but its just a function!
	// cool right? -Crow
	//public dynamic function updateScore(miss:Bool = false)
	//{
	//	var ret:Dynamic = callOnScripts('preUpdateScore', [miss], true);
	//	if (ret == LuaUtils.Function_Stop)
	//		return;
//
	//	var str:String = ratingName;
	//	if(totalPlayed != 0)
	//	{
	//		var percent:Float = CoolUtil.floorDecimal(ratingPercent * 100, 2);
	//		str += ' (${percent}%) - ${ratingFC}';
	//	}
//
	//	var tempScore:String = 'Score: ${songScore}'
	//	+ (!instakillOnMiss ? ' | Misses: ${songMisses}' : "")
	//	+ ' | Rating: ${str}';
	//	// "tempScore" variable is used to prevent another memory leak, just in case
	//	// "\n" here prevents the text from being cut off by beat zooms
	//	scoreTxt.text = '${tempScore}\n';
//
	//	if (!miss && !cpuControlled)
	//		doScoreBop();
//
	//	callOnScripts('onUpdateScore', [miss]);
	//}

	public dynamic function fullComboFunction()
	{
		var sicks:Int = ratingsData[0].hits;
		var goods:Int = ratingsData[1].hits;
		var bads:Int = ratingsData[2].hits;
		var shits:Int = ratingsData[3].hits;

		//ratingFC = "";
		//if(songMisses == 0)
		//{
		//	if (bads > 0 || shits > 0) ratingFC = 'FC';
		//	else if (goods > 0) ratingFC = 'GFC';
		//	else if (sicks > 0) ratingFC = 'SFC';
		//}
		//else {
		//	if (songMisses < 10) ratingFC = 'SDCB';
		//	else ratingFC = 'Clear';
		//}
	}

	public function doScoreBop():Void {
		//if(!ClientPrefs.data.scoreZoom)
		//	return;

		if(scoreTxtTween != null)
			scoreTxtTween.cancel();

		scoreTxt.scale.x = 1.075;
		scoreTxt.scale.y = 1.075;
		scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
			onComplete: function(twn:FlxTween) {
				scoreTxtTween = null;
			}
		});
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.time = time;
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			opponentVocals.time = time;
			#if FLX_PITCH
			vocals.pitch = playbackRate;
			opponentVocals.pitch = playbackRate;
			#end
		}
		vocals.play();
		opponentVocals.play();
		Conductor.songPosition = time;
	}

	public function startNextDialogue() {
		dialogueCount++;
		callOnScripts('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue() {
		callOnScripts('onSkipDialogue', [dialogueCount]);
	}

	function startSong():Void
	{
		startingSong = false;

		@:privateAccess
		FlxG.sound.playMusic(inst._sound, 1, false);
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();
		opponentVocals.play();

		if(startOnTime > 0) setSongTime(startOnTime - 500);
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		//FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		//FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence (with Time Left)
		if(autoUpdateRPC) DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var debugNum:Int = 0;
	private var noteTypes:Array<String> = [];
	private var eventsPushed:Array<String> = [];
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeed = PlayState.SONG.speed;
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		curSong = songData.song;

		vocals = new FlxSound();
		opponentVocals = new FlxSound();
		try
		{
			if (songData.needsVoices)
			{
				var playerVocals = Paths.voices(songData.song, (boyfriend.vocalsFile == null || boyfriend.vocalsFile.length < 1) ? 'Player' : boyfriend.vocalsFile);
				vocals.loadEmbedded(playerVocals != null ? playerVocals : Paths.voices(songData.song));
				
				var oppVocals = Paths.voices(songData.song, (dad.vocalsFile == null || dad.vocalsFile.length < 1) ? 'Opponent' : dad.vocalsFile);
				if(oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
			}
		}
		catch(e:Dynamic) {}

		#if FLX_PITCH
		vocals.pitch = playbackRate;
		opponentVocals.pitch = playbackRate;
		#end
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(opponentVocals);

		inst = new FlxSound();
		try {
			inst.loadEmbedded(Paths.inst(songData.song));
		}
		catch(e:Dynamic) {}
		FlxG.sound.list.add(inst);

		notes = new FlxTypedGroup<Note>();
		noteGroup.add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var file:String = Paths.json(songName + '/events');
		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file))
		#else
		if (OpenFlAssets.exists(file))
		#end
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				swagNote.scrollFactor.set();

				unspawnNotes.push(swagNote);

				final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				final floorSus:Int = Math.floor(susLength);

				if(floorSus > 0) {
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);

						sustainNote.correctionOffset = swagNote.height / 2;
						if(!PlayState.isPixelStage)
						{
							if(oldNote.isSustainNote)
							{
								oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
								oldNote.scale.y /= playbackRate;
								oldNote.updateHitbox();
							}

							if(ClientPrefs.tvorogSet['downScroll'])
								sustainNote.correctionOffset = 0;
						}
						else if(oldNote.isSustainNote)
						{
							oldNote.scale.y /= playbackRate;
							oldNote.updateHitbox();
						}

						if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
						else if(ClientPrefs.data.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}

				//if(!noteTypes.contains(swagNote.noteType)) {
				//	noteTypes.push(swagNote.noteType);
				//}
			}
		}
		if (!isDead){
			for (event in songData.events) //Event Notes
				for (i in 0...event[1].length)
					makeEvent(event, i);
		}

		unspawnNotes.sort(sortByTime);
		generatedMusic = true;
	}

	// called only once per different event (Used for precaching)
	function eventPushed(event:EventNote) {
		if (!isDead){
			eventPushedUnique(event);
			if(!isDead && eventsPushed.contains(event.event)) {
				return;
			}
	
			stagesFunc(function(stage:BaseStage) stage.eventPushed(event));
			eventsPushed.push(event.event);
		}
	}

	// called by every event with the same name
	function eventPushedUnique(event:EventNote) {
		switch(event.event) {
			case "Change Character":
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						var val1:Int = Std.parseInt(event.value1);
						if(Math.isNaN(val1)) val1 = 0;
						charType = val1;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);

			case 'Play Sound':
				Paths.sound(event.value1); //Precache sound
		}
		stagesFunc(function(stage:BaseStage) stage.eventPushedUnique(event));
	}

	function eventEarlyTrigger(event:EventNote):Float {
		var returnedValue:Null<Float> = callOnScripts('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], true, [], [0]);
		if(returnedValue != null && returnedValue != 0 && returnedValue != LuaUtils.Function_Continue) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	public static function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function makeEvent(event:Array<Dynamic>, i:Int)
	{
		if (!isDead){
			var subEvent:EventNote = {
				strumTime: event[0] + ClientPrefs.data.noteOffset,
				event: event[1][i][0],
				value1: event[1][i][1],
				value2: event[1][i][2]
			};
			eventNotes.push(subEvent);
			eventPushed(subEvent);
			callOnScripts('onEventPushed', [subEvent.event, subEvent.value1 != null ? subEvent.value1 : '', subEvent.value2 != null ? subEvent.value2 : '', subEvent.strumTime]);
		}
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X;
		var strumLineY:Float = ClientPrefs.tvorogSet['downScroll'] ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.tvorogSet['downScroll'];
			if (!isStoryMode && !skipArrowStartTween)
			{
				//babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = targetAlpha;

			if (player == 1){
				babyArrow.x = babyArrow.x - (25 * i);
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				babyArrow.x = babyArrow.x - (25 * i);
				opponentStrums.add(babyArrow);
			}

			//babyArrow.scale.set(babyArrow.scale.x-0.2,babyArrow.scale.y-0.2);

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		stagesFunc(function(stage:BaseStage) stage.openSubState(SubState));
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				opponentVocals.pause();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = false);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = false);
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		super.closeSubState();
		
		stagesFunc(function(stage:BaseStage) stage.closeSubState());
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer) if(!tmr.finished) tmr.active = true);
			FlxTween.globalManager.forEach(function(twn:FlxTween) if(!twn.finished) twn.active = true);

			paused = false;
			callOnScripts('onResume');
			resetRPC(startTimer != null && startTimer.finished);
		}
	}

	override public function onFocus():Void
	{
		if (health > 0 && !paused) resetRPC(Conductor.songPosition > 0.0);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused && autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		super.onFocusLost();
	}

	// Updating Discord Rich Presence.
	public var autoUpdateRPC:Bool = true; //performance setting for custom RPC things
	function resetRPC(?showTime:Bool = false)
	{
		#if DISCORD_ALLOWED
		if(!autoUpdateRPC) return;

		if (showTime)
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.data.noteOffset);
		else
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();
		opponentVocals.pause();

		FlxG.sound.music.play();
		#if FLX_PITCH FlxG.sound.music.pitch = playbackRate; #end
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			#if FLX_PITCH vocals.pitch = playbackRate; #end
		}

		if (Conductor.songPosition <= opponentVocals.length)
		{
			opponentVocals.time = Conductor.songPosition;
			#if FLX_PITCH opponentVocals.pitch = playbackRate; #end
		}
		vocals.play();
		opponentVocals.play();
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = false;
	var freezeCamera:Bool = false;
	var allowDebugKeys:Bool = true;

	override public function update(elapsed:Float)
	{
		if (endingSong && canReSwitch){ // end song results
			canReSwitch=false;
			//trace('bubub');
			resultSwitch(nextSwitch);
		}

		if (isResult==true){ // arrow bar результат йоу
			if (arrowBarTime <= 0){
				arrowBarTime = 0.55;
				if (isDead==false){
					arrowBar('arrowWIN', true);
					arrowBar('arrowWIN', false);
				}
				else{
					arrowBar('arrowLOSE', true);
					arrowBar('arrowLOSE', false);
				}
			}
			else{
				arrowBarTime-=elapsed;
			}
		}

		FlxG.camera.followLerp = 1.45 * cameraSpeed * playbackRate; // 2.4 2.15
		if(boyfriend.getAnimationName().startsWith('idle')) {
			boyfriendIdleTime += elapsed;
			if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
				boyfriendIdled = true;
				if (!isResult && boyfriend.color != FlxColor.WHITE){
					boyfriend.color = FlxColor.WHITE;
				}
			}
		} else {
			boyfriendIdleTime = 0;
		}
		callOnScripts('onUpdate', [elapsed]);

		super.update(elapsed);

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause && !isDead) //controls.PAUSE && 
			{
				var ret:Dynamic = callOnScripts('onPause', null, true);
				if(ret != LuaUtils.Function_Stop) {
					openPauseMenu();
				}
			}
		else if (isDead && canContinue && FlxG.keys.justPressed.ENTER){
			playerDied(true);
		}
		else if (!isDead && endingSong && FlxG.keys.justPressed.ENTER && canContinue){
			resultShow(true, false);
		}

		if (isDead && controls.BACK){ // back
			MusicBeatState.switchState(new ChooseState());
			FlxG.sound.playMusic(Paths.music('tvorogMenu'));
		}

		//if (FlxG.keys.justPressed.O){
		//	endSong();
		//}
		if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.I){
			if (disablePlrs==false){
				disablePlrs=true;
				dad.visible = false;
				gf.visible = false;
				boyfriend.visible = false;
			}
			else{
				disablePlrs=false;
				dad.visible = true;
				gf.visible = true;
				boyfriend.visible = true;
			}
		}

		if (canSpray==true){ //творог спрей меняется
			spraySizeText.text = 'SIZE : '+spraySize+' [ d: 0.05 ]';
			if (FlxG.mouse.wheel!=0){ // размер кисти
				var future1:Float = spraySize += (FlxG.mouse.wheel / 100);
				if (future1>spraySizeMAX){ //future1>spraySizeMIN
					spraySize = future1;
				}
			}

			sprayHealthSprite.scale.x = 1-(1 - (healthSpray/healthSprayMAX));

			if (FlxG.keys.pressed.SHIFT && FlxG.keys.justPressed.G && sprayCheat==false){ // читкод
				sprayCheat = true;
			}

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z){ // CTRL Z
				//trace("ctrl");
				sprayBack();
			}

			if (FlxG.keys.justPressed.ONE){ // ЦВЕТА!!!!
				sprayChangeColor('ONE');
			}
			else if (FlxG.keys.justPressed.TWO){
				sprayChangeColor('TWO');
			}
			else if (FlxG.keys.justPressed.THREE){
				sprayChangeColor('THREE');
			}
			else if (FlxG.keys.justPressed.FOUR){
				sprayChangeColor('FOUR');
			}
			else if (FlxG.keys.justPressed.FIVE){
				sprayChangeColor('FIVE');
			}
			else if (FlxG.keys.justPressed.SIX){
				sprayChangeColor('SIX');
			}
			else if (FlxG.keys.justPressed.SEVEN){
				sprayChangeColor('SEVEN');
			}
			else if (FlxG.keys.justPressed.EIGHT){
				sprayChangeColor('EIGHT');
			}
			else if (FlxG.keys.justPressed.NINE){
				sprayChangeColor('NINE');
			}


			if (FlxG.keys.justPressed.SHIFT){
				sprayChangeShape();
			}

			if (healthSpray>0){ //творог нажал спрей появился
				if (FlxG.mouse.justPressed && sprayFirst==false){
					sprayFirst = true;
				}
				if (FlxG.mouse.pressed){
					if (delaySpray>0){
						delaySpray-=elapsed;
					}
					else{
						var tvorog:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.image('tvorog/sprayPart/Presets/brushTextures/'+Std.string(sprayShape)));
						tvorog.scrollFactor.set();
						tvorog.updateHitbox();
						tvorog.color = FlxColor.fromString('0x'+sprayColorMain);
						tvorog.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
						tvorog.scale.set(spraySize,spraySize);
						tvorog.x = FlxG.mouse.screenX + (36 * FlxG.camera.zoom) + 45; //спавн спрея
						tvorog.y = (FlxG.mouse.screenY - (GF_Y*FlxG.camera.zoom + 225));
						//tvorog.scrollFactor.set(gf.scrollFactor.x, gf.scrollFactor.y);
						if (sprayFirst == true){
							sprayFirst=false;
							sprayCTRLz = sprayCount;
							sprayOper.push(sprayCTRLz);
							//trace(sprayOper.length+" - ypu winned this code");
							//trace('ctrlz = '+sprayCTRLz);
						}
						sprayCount++;
						//trace(sprayCount+' added spray count');
						delaySpray = 0.0001;
						if (sprayCheat==false){ // спрей чит трата
							healthSpray -= 0.1;
						}
						backGfGroup.add(tvorog);
					}			
				}
				if (FlxG.mouse.justReleased){
					if (sprayFirst==false){
						sprayFirst=true;
					}
				}
			}

			if (healthSpray<=0 || FlxG.keys.justPressed.F){
				sprayPart(true);
			}
		}

		if (curStage=="city2"){ // снег
			if (delaySpray <= 0){
				delaySpray=0.015;
				var sneginka:FlxSprite = new FlxSprite().makeGraphic(5, 5, FlxColor.WHITE);
				sneginka.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
				sneginka.scrollFactor.set(3,1);
				sneginka.x = FlxG.random.int(-Std.int(FlxG.width*1.7),Std.int(FlxG.width*1.7));
				sneginka.y = -500;
				sneginka.acceleration.set(FlxG.random.int(-50,50), 150);
				add(sneginka);
				var meow:FlxTimer = new FlxTimer().start(16, function(tmr:FlxTimer) {
					remove(sneginka);
				});

			}
			else{
				delaySpray-=elapsed;
			}
		}

		if (numbWalking>0){ //ходьба
			if (charWalkTime>0){
				charWalkTime -= elapsed;
			}
			else{
				charWalkTime = FlxG.random.float(15,20);
				var walkChar = new FlxSprite(); // score txt
				walkChar.scrollFactor.set(0.04, 0.01);
				walkChar.updateHitbox();
				if (Paths.getSparrowAtlas('tvorog/walkingChars/'+curStage+'-ghost')==null){
					walkChar.frames = Paths.getSparrowAtlas('tvorog/walkingChars/'+curStage);
					walkChar.alpha = 1;
				}
				else{
					walkChar.frames = Paths.getSparrowAtlas('tvorog/walkingChars/'+curStage+'-ghost');
					walkChar.alpha = 0.5;
				}
				walkChar.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
				walkChar.animation.addByPrefix('walk', "char"+FlxG.random.int(1, numbWalking), 1, true);
				walkChar.animation.play('walk');
				walkChar.scale.set(1.8, 1.8);
				walkChar.y = boyfriend.y+390+(40/FlxG.camera.zoom);
				walkGroup.add(walkChar);	
				var rand = FlxG.random.int(1,2);
				var moveDir=boyfriend.x + 1200;
				if (rand==2){
					walkChar.flipX=true;
					moveDir = moveDir * (-1);
				}
				walkChar.x = moveDir;
				if (walkTwn!=null){
					walkTwn.cancel();
				}
				trace("added walk");
				walkTwn = FlxTween.tween(walkChar, {x: moveDir*(-1)}, FlxG.random.float(10,15), {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
					walkGroup.remove(walkChar);
				}});		
			}
		}
		if (ClientPrefs.tvorogSet['lowQuality']==false){
			for (filter in filterMap) //фильты!
				{
					if (filter.onUpdate != null)
						filter.onUpdate();
				}	
			for (filter in filterMapHUD) //фильты!
				{
					if (filter.onUpdate != null)
						filter.onUpdate();
				}	
		}

		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);

		if(botplayTxt != null && botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if(!endingSong && !inCutscene && allowDebugKeys)
		{
			if (controls.justPressed('debug_1') && FlxG.keys.pressed.SHIFT)
				openChartEditor();
			else if (controls.justPressed('debug_2') && FlxG.keys.pressed.SHIFT)
				openCharacterEditor();
		}

		//if (healthBar.bounds.max != null && health > healthBar.bounds.max)
		//	health = healthBar.bounds.max;

		if (health > 2){
			health=2;
		}

		updateIconsScale(elapsed);
		//updateIconsPosition();

		if (startedCountdown && !paused)
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;

		if (startingSong && !isDead)
		{
			if (startedCountdown && Conductor.songPosition >= 0){
				startSong();
				//canUpdTimer=true; // хп бар может обновлятьтся
			}
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else if (!paused && !isDead) //updateTime
		{
			//var curTime:Float = Math.max(0, Conductor.songPosition - ClientPrefs.data.noteOffset);
			//songPercent = (curTime / songLength);

			//var songCalc:Float = (songLength - curTime);
			//if(ClientPrefs.data.timeBarType == 'Time Elapsed') songCalc = curTime;

			//var secondsTotal:Int = Math.floor(songCalc / 1000);
			//if(secondsTotal < 0) secondsTotal = 0;

			//if(ClientPrefs.data.timeBarType != 'Song Name')
			//	timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
		}

		if (camZooming)
		{
			if (canCamera){
				FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, Math.exp(-elapsed * 1.625 * camZoomingDecay * playbackRate));
			}
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, Math.exp(-elapsed * 3.125 * camZoomingDecay * playbackRate));
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote, dunceNote.strumTime]);
				callOnHScript('onSpawnNote', [dunceNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic && !isDead)
		{
			if(!inCutscene)
			{
				if(!cpuControlled)
					keysCheck();
				else
					playerDance();

				if(notes.length > 0 && !isDead)
				{
					if(startedCountdown && !isDead)
					{
						var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
						notes.forEachAlive(function(daNote:Note)
						{
							var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
							if(!daNote.mustPress) strumGroup = opponentStrums;

							daNote.scale.set(0.5,0.5);// уменьшение нот!

							var strum:StrumNote = strumGroup.members[daNote.noteData];
							daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

							if(daNote.mustPress && !isDead)
							{
								if(!isDead && cpuControlled && !daNote.blockHit && daNote.canBeHit && (daNote.isSustainNote || daNote.strumTime <= Conductor.songPosition))
									goodNoteHit(daNote);
							}
							else if (!isDead && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
								opponentNoteHit(daNote);

							if(daNote.isSustainNote && strum.sustainReduce){
								//daNote.scale.set(0.45,2.32);
								daNote.clipToStrumNote(strum);
							}

							// Kill extremely late notes and cause misses
							if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
							{
								if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
									noteMiss(daNote);

								daNote.active = daNote.visible = false;
								invalidateNote(daNote);
							}
						});
					}
					else
					{
						notes.forEachAlive(function(daNote:Note)
						{
							daNote.canBeHit = false;
							daNote.wasGoodHit = false;
						});
					}
				}
			}
			checkEventNote();
		}

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnScripts('cameraX', camFollow.x);
		setOnScripts('cameraY', camFollow.y);
		setOnScripts('botPlay', cpuControlled);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	// Health icon updaters
	public dynamic function updateIconsScale(elapsed:Float)
	{
		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, Math.exp(-elapsed * 9 * playbackRate));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();
	}

	//public dynamic function updateIconsPosition()
	//{
	//	var iconOffset:Int = 26;
	//	iconP1.x = healthBar.barCenter + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
	//	iconP2.x = healthBar.barCenter - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
	//}

	var iconsAnimations:Bool = true;
	//function set_health(value:Float):Float // You can alter how icon animations work here
	//{
	//	if(!iconsAnimations)
	//	{
	//		health = value;
	//		return health;
	//	}
//
	//	// update health bar
	//	health = value;
	//	var newPercent:Null<Float> = FlxMath.remapToRange(FlxMath.bound(healthBar.valueFunction(), healthBar.bounds.min, healthBar.bounds.max), healthBar.bounds.min, healthBar.bounds.max, 0, 100);
	//	healthBar.percent = (newPercent != null ? newPercent : 0);
//
	//	iconP1.animation.curAnim.curFrame = (healthBar.percent < 20) ? 1 : 0; //If health is under 20%, change player icon to frame 1 (losing icon), otherwise, frame 0 (normal)
	//	iconP2.animation.curAnim.curFrame = (healthBar.percent > 80) ? 1 : 0; //If health is over 80%, change opponent icon to frame 1 (losing icon), otherwise, frame 0 (normal)
//
	//	return health;
	//}

	function openPauseMenu()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if(FlxG.sound.music != null) {
			FlxG.sound.music.pause();
			vocals.pause();
			opponentVocals.pause();
		}
		if(!cpuControlled)
		{
			for (note in playerStrums)
				if(note.animation.curAnim != null && note.animation.curAnim.name != 'static')
				{
					note.playAnim('static');
					note.resetAnim = 0;
				}
		}
		openSubState(new PauseSubState());

		#if DISCORD_ALLOWED
		if(autoUpdateRPC) DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end
	}

	function openChartEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		chartingMode = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		DiscordClient.resetClientID();
		#end

		MusicBeatState.switchState(new ChartingState());
	}

	function openCharacterEditor()
	{
		FlxG.camera.followLerp = 0;
		persistentUpdate = false;
		paused = true;
		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();
		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
		MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
	}

	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnScripts('onGameOver', null, true);
			if(ret != LuaUtils.Function_Stop) {
				FlxG.animationTimeScale = 1;
				//boyfriend.stunned = true;
				deathCounter++;

				//paused = true;

				vocals.stop();
				opponentVocals.stop();
				FlxG.sound.music.stop();

				//persistentUpdate = false;
				//persistentDraw = false;

				//FlxTimer.globalManager.clear();
				//FlxTween.globalManager.clear();
				#if LUA_ALLOWED
				modchartTimers.clear();
				modchartTweens.clear();
				#end

				playerDied(false);

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if DISCORD_ALLOWED
				// Game Over doesn't get his its variable because it's only used here
				if(autoUpdateRPC) DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEvent(eventNotes[0].event, value1, value2, leStrumTime);
			eventNotes.shift();
		}
	}

	public function triggerEvent(eventName:String, value1:String, value2:String, strumTime:Float) {
		var flValue1:Null<Float> = Std.parseFloat(value1);
		var flValue2:Null<Float> = Std.parseFloat(value2);
		if(Math.isNaN(flValue1)) flValue1 = null;
		if(Math.isNaN(flValue2)) flValue2 = null;

		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				if(flValue2 == null || flValue2 <= 0) flValue2 = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = flValue2;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = flValue2;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = flValue2;
				}

			case 'Set GF Speed':
				if(flValue1 == null || flValue1 < 1) flValue1 = 1;
				gfSpeed = Math.round(flValue1);

			case 'Add Camera Zoom':
				if(FlxG.camera.zoom < 1.35) {
					if(flValue1 == null) flValue1 = 0.015;
					if(flValue2 == null) flValue2 = 0.03;

					if (canCamera){
						FlxG.camera.zoom += flValue1;
					}
					camHUD.zoom += flValue2;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						if(flValue2 == null) flValue2 = 0;
						switch(Math.round(flValue2)) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				if(camFollow != null)
				{
					isCameraOnForcedPos = false;
					if(flValue1 != null || flValue2 != null)
					{
						isCameraOnForcedPos = true;
						if(flValue1 == null) flValue1 = 0;
						if(flValue2 == null) flValue2 = 0;
						camFollow.x = flValue1;
						camFollow.y = flValue2;
					}
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnScripts('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf-') || dad.curCharacter == 'gf';
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf-') && dad.curCharacter != 'gf') {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnScripts('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnScripts('gfName', gf.curCharacter);
						}
				}
				//reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType != "constant")
				{
					if(flValue1 == null) flValue1 = 1;
					if(flValue2 == null) flValue2 = 0;

					var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed') * flValue1;
					if(flValue2 <= 0)
						songSpeed = newValue;
					else
						songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, flValue2 / playbackRate, {ease: FlxEase.linear, onComplete:
							function (twn:FlxTween)
							{
								songSpeedTween = null;
							}
						});
				}

			case 'Set Property':
				try
				{
					var split:Array<String> = value1.split('.');
					if(split.length > 1) {
						LuaUtils.setVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1], value2);
					} else {
						LuaUtils.setVarInArray(this, value1, value2);
					}
				}
				catch(e:Dynamic)
				{
					var len:Int = e.message.indexOf('\n') + 1;
					if(len <= 0) len = e.message.length;
					#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
					addTextToDebug('ERROR ("Set Property" Event) - ' + e.message.substr(0, len), FlxColor.RED);
					#else
					FlxG.log.warn('ERROR ("Set Property" Event) - ' + e.message.substr(0, len));
					#end
				}

			case 'Play Sound':
				if(flValue2 == null) flValue2 = 1;
				FlxG.sound.play(Paths.sound(value1), flValue2);

			case 'TVRG Gf.y':
				trace("tvrg event enabled");
				if(flValue1 == null) flValue1 = 0;
				if (gfSection){
					gfSection=false;
					moveCameraSection();
				} else{
					gfSection=true;
					camFollow.x = GF_X + (gf.width/2);
					camFollow.y = gf.getMidpoint().y + gf.cameraPosition[1] + girlfriendCameraOffset[1] - flValue1;
				}
				trace(gfSection+' gf section');
			
			case 'TVRG Camera Zoom inOut':
				if(flValue1!=null){
					canCamera=false;
					defaultCamZoom = flValue1;
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, flValue2, {ease: FlxEase.quadOut, onComplete: function (twn:FlxTween){
						canCamera=true;
					}});
				}
		}

		stagesFunc(function(stage:BaseStage) stage.eventCalled(eventName, value1, value2, flValue1, flValue2, strumTime));
		callOnScripts('onEvent', [eventName, value1, value2, strumTime]);
	}

	function moveCameraSection(?sec:Null<Int>):Void {
		if(sec == null) sec = curSection;
		if(sec < 0) sec = 0;

		if(SONG.notes[sec] == null) return;

		if (gf != null && SONG.notes[sec].gfSection)
		{
			camFollow.setPosition(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnScripts('onMoveCamera', ['gf']);
			return;
		}

		var isDad:Bool = (SONG.notes[sec].mustHitSection != true);
		hitSec = isDad;
		if (cameraAngle!=null){
			cameraAngle.cancel();
		}
		cameraAngle = FlxTween.tween(FlxG.camera, {angle: 0}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.quadOut, onComplete:
			function (twn:FlxTween)
			{
				cameraAngle = null;
			}
		});	
		if (!gfSection){
			moveCamera(isDad);
			callOnScripts('onMoveCamera', [isDad ? 'dad' : 'boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	var cameraAngle:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			if (!gfSection){
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
				camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
				tweenCamIn();
			}
		}
		else
		{
			if (!gfSection){
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
				camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
				camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];
			}

			if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	public function tweenCamIn() {
		if (songName == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		updateTime = false;
		FlxG.sound.music.volume = 0;

		vocals.volume = 0;
		vocals.pause();
		opponentVocals.volume = 0;
		opponentVocals.pause();

		if (isResult==false){
			resultShow(false, false);
		}

		//if(ClientPrefs.data.noteOffset <= 0 || ignoreNoteOffset) {
		//	resultShow(false, false);
		//	//endCallback();
		//} else {
		//	finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer) {
		//		resultShow(false, false);
		//		//endCallback();
		//	});
		//}
	}


	public var transitioning = false;
	public function endSong()
	{
		//Should kill you if you tried to cheat

		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= healthLoss;
				}
			}

			if(doDeathCheck()) {
				return false;
			}
		}

		//timeBar.visible = false;
		//timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		//#if ACHIEVEMENTS_ALLOWED
		//var weekNoMiss:String = WeekData.getWeekFileName() + '_nomiss';
		//checkForAchievement([weekNoMiss, 'ur_bad', 'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
		//#end

		var ret:Dynamic = callOnScripts('onEndSong', null, true);
		if(ret != LuaUtils.Function_Stop && !transitioning)
		{
			#if !switch
			//var percent:Float = ratingPercent;
			//if(Math.isNaN(percent)) percent = 0;
			Highscore.saveScore(SONG.song, songScore, storyDifficulty, rankChar);
			#end
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return false;
			}

			//if (isStoryMode)
			//{
			//	campaignScore += songScore;
			//	campaignMisses += songMisses;
//
			//	storyPlaylist.remove(storyPlaylist[0]);
//
			//	if (storyPlaylist.length <= 0)
			//	{
			//		Mods.loadTopMod();
			//		FlxG.sound.playMusic(Paths.music('freakyMenu'));
			//		#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
//
			//		MusicBeatState.switchState(new ChooseState());
			//		//MusicBeatState.switchState(new StoryMenuState());
//
			//		// if ()
			//		if(!ClientPrefs.getGameplaySetting('practice') && !ClientPrefs.getGameplaySetting('botplay')) {
			//			StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);
			//			Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
//
			//			FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
			//			FlxG.save.flush();
			//		}
			//		changedDifficulty = false;
			//	}
			//	else
			//	{
			//		var difficulty:String = Difficulty.getFilePath();
//
			//		trace('LOADING NEXT SONG');
			//		trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);
//
			//		FlxTransitionableState.skipNextTransIn = true;
			//		FlxTransitionableState.skipNextTransOut = true;
			//		prevCamFollow = camFollow;
//
			//		PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
			//		FlxG.sound.music.stop();
//
			//		LoadingState.loadAndSwitchState(new PlayState());
			//	}
			//}
			//else
			//{
			//	trace('WENT BACK TO FREEPLAY??');
			//	Mods.loadTopMod();
			//	#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
//
			//	//MusicBeatState.switchState(new FreeplayState());
			//	MusicBeatState.switchState(new ChooseState());
			//	FlxG.sound.playMusic(Paths.music('freakyMenu'));
			//	changedDifficulty = false;
			//}

			//trace('WENT BACK TO FREEPLAY??');
			Mods.loadTopMod();
			#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end

			//MusicBeatState.switchState(new FreeplayState());
			MusicBeatState.switchState(new ChooseState());
			FlxG.sound.playMusic(Paths.music('tvorogMenu'));
			changedDifficulty = false;
			
			transitioning = true;
		}
		return true;
	}

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;
			invalidateNote(daNote);
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	// Stores Ratings and Combo Sprites in a group
	public var comboGroup:FlxSpriteGroup;
	// Stores HUD Objects in a Group
	public var uiGroup:FlxSpriteGroup;

	public var heatlhGroup:FlxSpriteGroup; // хп бар

	//public var sprayGroup:FlxSpriteGroup; // спрей
	public var sprayUiGroup:FlxSpriteGroup; // спрей

	// Stores Note Objects in a Group
	public var noteGroup:FlxTypedGroup<FlxBasic>;

	private function cachePopUpScore()
	{
		var uiPrefix:String = '';
		var uiSuffix:String = '';
		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
		}

		for (rating in ratingsData)
			Paths.image(uiPrefix + rating.image + uiSuffix);
		for (i in 0...10)
			Paths.image(uiPrefix + 'num' + i + uiSuffix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0) {
			for (spr in comboGroup) {
				spr.destroy();
				comboGroup.remove(spr);
			}
		}

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		totalNotesHit += daRating.ratingMod;
		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;
		score = daRating.score;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				//RecalculateRating(false);
			}
		}

		var uiPrefix:String = "";
		var uiSuffix:String = '';
		var antialias:Bool = ClientPrefs.tvorogSet['antialiasing'];

		if (stageUI != "normal")
		{
			uiPrefix = '${stageUI}UI/';
			if (PlayState.isPixelStage) uiSuffix = '-pixel';
			antialias = !isPixelStage;
		}

		rating.loadGraphic(Paths.image(uiPrefix + daRating.image + uiSuffix));
		rating.screenCenter();
		rating.x = placement - 40;
		rating.y += 210;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = (!ClientPrefs.data.hideHud && showRating);
		rating.x += ClientPrefs.data.comboOffset[0];
		rating.y -= ClientPrefs.data.comboOffset[1];
		rating.antialiasing = ClientPrefs.tvorogSet['antialiasing'];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'combo' + uiSuffix));
		comboSpr.screenCenter();
		comboSpr.x = placement;
		comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
		comboSpr.visible = (!ClientPrefs.data.hideHud && showCombo);
		comboSpr.x += ClientPrefs.data.comboOffset[0];
		comboSpr.y -= ClientPrefs.data.comboOffset[1];
		comboSpr.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		comboSpr.y += 90;
		comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
		comboGroup.add(rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		var xThing:Float = 0;
		if (showCombo)
			comboGroup.add(comboSpr);

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiPrefix + 'num' + Std.int(i) + uiSuffix));
			numScore.screenCenter();
			numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
			numScore.y += 155 - ClientPrefs.data.comboOffset[3];

			if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			else numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.data.hideHud;
			numScore.antialiasing = ClientPrefs.tvorogSet['antialiasing'];

			//if (combo >= 10 || combo == 0)
			if(showComboNum)
				comboGroup.add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
			if(numScore.x > xThing) xThing = numScore.x;
		}
		comboSpr.x = xThing + 50;
		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.002 / playbackRate
		});
	}

	public var strumsBlocked:Array<Bool> = [];
	private function onKeyPress(event:KeyboardEvent):Void
	{

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode && !isDead)
		{
			#if debug
			//Prevents crash specifically on debug without needing to try catch shit
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end

			if(!isDead && FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		}
	}

	private function keyPressed(key:Int)
	{
		if(cpuControlled || paused || inCutscene || key < 0 || key >= playerStrums.length || !generatedMusic || endingSong || boyfriend.stunned) return;

		var ret:Dynamic = callOnScripts('onKeyPressPre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		// more accurate hit time for the ratings?
		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = FlxG.sound.music.time;

		// obtain notes that the player can hit
		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note):Bool {
			var canHit:Bool = !strumsBlocked[n.noteData] && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit;
			return n != null && canHit && !n.isSustainNote && n.noteData == key;
		});
		plrInputNotes.sort(sortHitNotes);

		var shouldMiss:Bool = !ClientPrefs.tvorogSet['ghostTapping'];

		if (plrInputNotes.length != 0) { // slightly faster than doing `> 0` lol
			var funnyNote:Note = plrInputNotes[0]; // front note

			if (plrInputNotes.length > 1) {
				var doubleNote:Note = plrInputNotes[1];

				if (doubleNote.noteData == funnyNote.noteData) {
					// if the note has a 0ms distance (is on top of the current note), kill it
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
					{
						// replace the note if its ahead of time (or at least ensure "doubleNote" is ahead)
						funnyNote = doubleNote;
					}
				}
			}
			goodNoteHit(funnyNote);
		}
		else if(shouldMiss)
		{
			callOnScripts('onGhostTap', [key]);
			noteMissPress(key);
		}

		// Needed for the  "Just the Two of Us" achievement.
		//									- Shadow Mario
		if(!keysPressed.contains(key)) keysPressed.push(key);

		//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
		Conductor.songPosition = lastTime;

		var spr:StrumNote = playerStrums.members[key];
		if(!isDead && strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
		{
			if (!isDead){
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
		callOnScripts('onKeyPress', [key]);
	}

	public static function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority)
			return 1;
		else if (!a.lowPriority && b.lowPriority)
			return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
		{
			var eventKey:FlxKey = event.keyCode;
			var key:Int = getKeyFromEvent(keysArray, eventKey);
			if(!controls.controllerMode && key > -1) {
				//trace('myurmyur');
				keyReleased(key);
			}
		}

	private function keyReleased(key:Int)
	{
		if(cpuControlled || !startedCountdown || paused || key < 0 || key >= playerStrums.length) return;

		var ret:Dynamic = callOnScripts('onKeyReleasePre', [key]);
		if(ret == LuaUtils.Function_Stop) return;

		var spr:StrumNote = playerStrums.members[key];
		if(spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
		callOnScripts('onKeyRelease', [key]);
	}

	public static function getKeyFromEvent(arr:Array<String>, key:FlxKey):Int
		{
			if(key != NONE)
			{
				for (i in 0...arr.length)
				{
					var note:Array<FlxKey> = Controls.instance.keyboardBinds[arr[i]];
					for (noteKey in note)
						if(key == noteKey)
							return i;
				}
			}
			return -1;
		}

	// Hold notes
	private function keysCheck():Void
	{
		// HOLDING
		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			if(controls.controllerMode)
			{
				pressArray.push(controls.justPressed(key));
				releaseArray.push(controls.justReleased(key));
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i] && strumsBlocked[i] != true)
					keyPressed(i);

		if (startedCountdown && !inCutscene && !boyfriend.stunned && generatedMusic)
		{
			if (notes.length > 0) {
				for (n in notes) { // I can't do a filter here, that's kinda awesome
					var canHit:Bool = (n != null && !strumsBlocked[n.noteData] && n.canBeHit
						&& n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);

					if (guitarHeroSustains)
						canHit = canHit && n.parent != null && n.parent.wasGoodHit;

					if (canHit && n.isSustainNote) {
						var released:Bool = !holdArray[n.noteData];

						if (!released)
							goodNoteHit(n);
					}
				}
			}

			if (!holdArray.contains(true) || endingSong)
				playerDance();

			//#if ACHIEVEMENTS_ALLOWED
			//else checkForAchievement(['oversinging']);
			//#end
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if((controls.controllerMode || strumsBlocked.contains(true)) && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i] || strumsBlocked[i] == true)
					keyReleased(i);
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(note);
		});

		noteMissCommon(daNote.noteData, daNote);
		var result:Dynamic = callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('noteMiss', [daNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.tvorogSet['ghostTapping']) return; //fuck it

		noteMissCommon(direction);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		callOnScripts('noteMissPress', [direction]);
	}

	function noteMissCommon(direction:Int, note:Note = null)
	{
		// score and data
		var subtract:Float = 0.05;
		if(note != null) subtract = note.missHealth;

		// GUITAR HERO SUSTAIN CHECK LOL!!!!
		if (note != null && guitarHeroSustains && note.parent == null) {
			if(note.tail.length > 0) {
				note.alpha = 0.35;
				for(childNote in note.tail) {
					childNote.alpha = note.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				note.missed = true;
				note.canBeHit = false;

				//subtract += 0.385; // you take more damage if playing with this gameplay changer enabled.
				// i mean its fair :p -Crow
				subtract *= note.tail.length + 1;
				// i think it would be fair if damage multiplied based on how long the sustain is -Tahir
			}

			if (note.missed)
				return;
		}
		if (note != null && guitarHeroSustains && note.parent != null && note.isSustainNote) {
			if (note.missed)
				return;

			var parentNote:Note = note.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0) {
				for (child in parentNote.tail) if (child != note) {
					child.missed = true;
					child.canBeHit = false;
					child.ignoreNote = true;
					child.tooLate = true;
				}
			}
		}

		if(instakillOnMiss)
		{
			vocals.volume = 0;
			opponentVocals.volume = 0;
			doDeathCheck(true);
		}

		var lastCombo:Int = combo;
		combo = 0;

		if (canPause){
			health -= healthLoss;
		}
		if(!practiceMode) songScore -= 10;
		if(!endingSong) { // иконка вылет
			songMisses++;
			boyfriend.color = FlxColor.fromString("0x6601FF");
			FlxG.sound.play(Paths.sound('missnote'+FlxG.random.int(1,3)), 0.05);
			var iconV:FlxSprite = new FlxSprite(boyfriend.getGraphicMidpoint().x - (boyfriend.getGraphicMidpoint().x/2), boyfriend.getGraphicMidpoint().y - (boyfriend.getGraphicMidpoint().y/2));
			iconV.frames = Paths.getSparrowAtlas("tvorog/missLabels");
			iconV.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
			iconV.updateHitbox();
			iconV.scrollFactor.set(boyfriend.scrollFactor.x, boyfriend.scrollFactor.y);
			iconV.animation.addByPrefix('idle', "miss"+FlxG.random.int(1,3), 1);
			iconV.animation.play('idle');
			iconV.scale.set(0.5,0.5);
			iconV.angle = FlxG.random.int(-30, 30);
			iconV.velocity.set(FlxG.random.int(-300, -150),FlxG.random.int(-125, -50));
			iconV.acceleration.y = FlxG.random.int(300, 450);
			if (iconV.velocity.x>0){
				iconV.angularAcceleration = 30;
			}
			else{
				iconV.angularAcceleration = -30;
			}
			addBehindBF(iconV); //доабвляет сзад бф
			iconV.alpha = 1;
			FlxTween.tween(iconV, {alpha: 0}, 1, {ease: FlxEase.quadIn, onComplete: function(twn:FlxTween) {
				if (iconV!=null){
					remove(iconV);
				}
			}});
			if (arrowBarOFF) arrowBar("arrowMISS", false);
			
		}
		totalPlayed++;
		//RecalculateRating(true);

		// play character anims
		var char:Character = boyfriend;
		if((note != null && note.gfNote) || (SONG.notes[curSection] != null && SONG.notes[curSection].gfSection)) char = gf;

		if(char != null && (note == null || !note.noMissAnimation) && char.hasMissAnimations)
		{
			var suffix:String = '';
			if(note != null) suffix = note.animSuffix;

			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, direction)))] + 'miss' + suffix;
			char.playAnim(animToPlay, true);

			//if(char != gf && lastCombo > 5 && gf != null && gf.animOffsets.exists('sad'))
			//{
			//	gf.playAnim('sad');
			//	gf.specialAnim = true;
			//}
		}
		vocals.volume = 0;
	}

	function opponentNoteHit(note:Note):Void
	{
		var result:Dynamic = callOnLuas('opponentNoteHitPre', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHitPre', [note]);
		if (health > healthGain && canPause){
			health -= healthGain*0.5;
		}
		if (songName != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = note.animSuffix;

			if (SONG.notes[curSection] != null)
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection)
					altAnim = '-alt';

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))] + altAnim;
			if(note.gfNote) char = gf;

			if(char != null)
			{
				char.playAnim(animToPlay, true);

				if (arrowBarOFF) arrowBar(Std.string("arrow"+(Std.int(Math.abs(note.noteData))+1)), true);

				if (hitSec && !gfSection){
					if (note.noteData == 0){
						camFollow.x = dad.getMidpoint().x + 150 + dad.cameraPosition[0] + opponentCameraOffset[0];
						camFollow.y = dad.getMidpoint().y - 100 + dad.cameraPosition[1] + opponentCameraOffset[1];
						camFollow.x -= 50;
						if (cameraAngle!=null){
							cameraAngle.cancel();
						}
						cameraAngle = FlxTween.tween(FlxG.camera, {angle: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.quadOut, onComplete:
							function (twn:FlxTween)
							{
								cameraAngle = null;
							}
						});						
					}
					else if (note.noteData == 1){
						camFollow.x = dad.getMidpoint().x + 150 + dad.cameraPosition[0] + opponentCameraOffset[0];
						camFollow.y = dad.getMidpoint().y - 100 + dad.cameraPosition[1] + opponentCameraOffset[1];
						camFollow.y += 50;
						if (cameraAngle!=null){
							cameraAngle.cancel();
						}
						cameraAngle = FlxTween.tween(FlxG.camera, {angle: 0}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.quadOut, onComplete:
							function (twn:FlxTween)
							{
								cameraAngle = null;
							}
						});	
					}
					else if (note.noteData == 2){
						camFollow.x = dad.getMidpoint().x + 150 + dad.cameraPosition[0] + opponentCameraOffset[0];
						camFollow.y = dad.getMidpoint().y - 100 + dad.cameraPosition[1] + opponentCameraOffset[1];
						camFollow.y -= 50;
						if (cameraAngle!=null){
							cameraAngle.cancel();
						}
						cameraAngle = FlxTween.tween(FlxG.camera, {angle: 0}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.quadOut, onComplete:
							function (twn:FlxTween)
							{
								cameraAngle = null;
							}
						});	
					}
					else if (note.noteData == 3){
						camFollow.x = dad.getMidpoint().x + 150 + dad.cameraPosition[0] + opponentCameraOffset[0];
						camFollow.y = dad.getMidpoint().y - 100 + dad.cameraPosition[1] + opponentCameraOffset[1];
						camFollow.x += 50;
						if (cameraAngle!=null){
							cameraAngle.cancel();
						}
						cameraAngle = FlxTween.tween(FlxG.camera, {angle: -1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.quadOut, onComplete:
							function (twn:FlxTween)
							{
								cameraAngle = null;
							}
						});		
					}
				}

				char.holdTimer = 0;
			}
		}

		if(!isDead && opponentVocals.length <= 0) vocals.volume = 1;
		strumPlayAnim(true, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		note.hitByOpponent = true;
		
		var result:Dynamic = callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('opponentNoteHit', [note]);

		if (!note.isSustainNote) invalidateNote(note);
	}

	public function goodNoteHit(note:Note):Void
	{
		if(note.wasGoodHit) return;
		if(cpuControlled && note.ignoreNote) return;

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		var result:Dynamic = callOnLuas('goodNoteHitPre', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHitPre', [note]);

		note.wasGoodHit = true;

		if(note.hitCausesMiss) {
			if(!note.noMissAnimation) {
				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animOffsets.exists('hurt')) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
			}

			noteMiss(note);
			if(!note.noteSplashData.disabled && !note.isSustainNote) spawnNoteSplashOnNote(note);
			if(!note.isSustainNote) invalidateNote(note);
			return;
		}

		if(!note.noAnimation) {
			var animToPlay:String = singAnimations[Std.int(Math.abs(Math.min(singAnimations.length-1, note.noteData)))];

			var char:Character = boyfriend;
			var animCheck:String = 'hey';
			if(note.gfNote)
			{
				char = gf;
				animCheck = 'cheer';
			}

			if(char != null)
			{
				char.playAnim(animToPlay + note.animSuffix, true);
				char.holdTimer = 0;

				if(note.noteType == 'Hey!') {
					if(char.animOffsets.exists(animCheck)) {
						char.playAnim(animCheck, true);
						char.specialAnim = true;
						char.heyTimer = 0.6;
					}
				}
			}
		}

		if(!cpuControlled)
		{
			var spr = playerStrums.members[note.noteData];
			if(spr != null) spr.playAnim('confirm', true); // нота вверх

			if (!hitSec && !gfSection){
				if (note.noteData == 0){
					camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
					camFollow.x = boyfriend.getMidpoint().x - 100 - boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
					camFollow.y = boyfriend.getMidpoint().y - 100 + boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
					camFollow.x -= 50;
					if (cameraAngle!=null){
						cameraAngle.cancel();
					}
					cameraAngle = FlxTween.tween(FlxG.camera, {angle: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.quadOut, onComplete:
						function (twn:FlxTween)
						{
							cameraAngle = null;
						}
					});	
				}
				else if (note.noteData == 1){
					camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
					camFollow.x = boyfriend.getMidpoint().x - 100 - boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
					camFollow.y = boyfriend.getMidpoint().y - 100 + boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
					camFollow.y += 50;
					if (cameraAngle!=null){
						cameraAngle.cancel();
					}
					cameraAngle = FlxTween.tween(FlxG.camera, {angle: 0}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.quadOut, onComplete:
						function (twn:FlxTween)
						{
							cameraAngle = null;
						}
					});	
				}
				else if (note.noteData == 2){
					camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
					camFollow.x = boyfriend.getMidpoint().x - 100 - boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
					camFollow.y = boyfriend.getMidpoint().y - 100 + boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
					camFollow.y -= 50;
					if (cameraAngle!=null){
						cameraAngle.cancel();
					}
					cameraAngle = FlxTween.tween(FlxG.camera, {angle: 0}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.quadOut, onComplete:
						function (twn:FlxTween)
						{
							cameraAngle = null;
						}
					});	
				}
				else if (note.noteData == 3){
					camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
					camFollow.x = boyfriend.getMidpoint().x - 100 - boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
					camFollow.y = boyfriend.getMidpoint().y - 100 + boyfriend.cameraPosition[0] + boyfriendCameraOffset[0];
					camFollow.x += 50;
					if (cameraAngle!=null){
						cameraAngle.cancel();
					}
					cameraAngle = FlxTween.tween(FlxG.camera, {angle: -1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.quadOut, onComplete:
						function (twn:FlxTween)
						{
							cameraAngle = null;
						}
					});	
				}
			}

			if (arrowBarOFF) arrowBar(Std.string("arrow"+(Std.int(Math.abs(note.noteData))+1)), false);


		}
		else strumPlayAnim(false, Std.int(Math.abs(note.noteData)), Conductor.stepCrochet * 1.25 / 1000 / playbackRate);
		vocals.volume = 1;

		if (!note.isSustainNote)
		{
			if (boyfriend.color != FlxColor.WHITE){
				boyfriend.color = FlxColor.WHITE;
			}
			combo++;
			if(combo > 9999) combo = 9999;
			popUpScore(note);
		}
		var gainHealth:Bool = true; // prevent health gain, *if* sustains are treated as a singular note
		if (guitarHeroSustains && note.isSustainNote) gainHealth = false;
		if (gainHealth) health += healthGain;

		var result:Dynamic = callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);
		if(result != LuaUtils.Function_Stop && result != LuaUtils.Function_StopHScript && result != LuaUtils.Function_StopAll) callOnHScript('goodNoteHit', [note]);

		if(!note.isSustainNote) invalidateNote(note);
	}

	public function invalidateNote(note:Note):Void {
		note.kill();
		notes.remove(note, true);
		note.destroy();
	}

	public function spawnNoteSplashOnNote(note:Note) {
		if(note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, note);
		grpNoteSplashes.add(splash);
	}

	override function destroy() {
		#if LUA_ALLOWED
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}
		luaArray = [];
		FunkinLua.customFunctions.clear();
		#end

		#if HSCRIPT_ALLOWED
		for (script in hscriptArray)
			if(script != null)
			{
				script.call('onDestroy');
				script.destroy();
			}

		while (hscriptArray.length > 0)
			hscriptArray.pop();
		#end

		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		FlxG.animationTimeScale = 1;
		#if FLX_PITCH FlxG.sound.music.pitch = 1; #end
		Note.globalRgbShaders = [];
		backend.NoteTypesConfig.clearNoteTypesData();
		instance = null;
		super.destroy();
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		if (SONG.needsVoices && FlxG.sound.music.time >= -ClientPrefs.data.noteOffset)
		{
			var timeSub:Float = Conductor.songPosition - Conductor.offset;
			var syncTime:Float = 20 * playbackRate;
			if (Math.abs(FlxG.sound.music.time - timeSub) > syncTime ||
			(vocals.length > 0 && Math.abs(vocals.time - timeSub) > syncTime) ||
			(opponentVocals.length > 0 && Math.abs(opponentVocals.time - timeSub) > syncTime))
			{
				resyncVocals();
			}
		}

		super.stepHit();

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	var lastBeatHit:Int = -1;

	override function beatHit()
	{
		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
			notes.sort(FlxSort.byY, ClientPrefs.tvorogSet['downScroll'] ? FlxSort.ASCENDING : FlxSort.DESCENDING);

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		characterBopper(curBeat);

		super.beatHit();
		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat);
		callOnScripts('onBeatHit');
	}

	public function characterBopper(beat:Int):Void
	{
		if (gf != null && beat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.getAnimationName().startsWith('sing') && !gf.stunned)
			gf.dance();
		if (boyfriend != null && beat % boyfriend.danceEveryNumBeats == 0 && !boyfriend.getAnimationName().startsWith('sing') && !boyfriend.stunned)
			boyfriend.dance();
		if (dad != null && beat % dad.danceEveryNumBeats == 0 && !dad.getAnimationName().startsWith('sing') && !dad.stunned)
			dad.dance();
	}

	public function playerDance():Void
	{
		var anim:String = boyfriend.getAnimationName();
		if(boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 #if FLX_PITCH / FlxG.sound.music.pitch #end) * boyfriend.singDuration && anim.startsWith('sing') && !anim.endsWith('miss'))
			boyfriend.dance();
	}

	override function sectionHit()
	{
		if (!isDead && !endingSong && SONG.notes[curSection] != null)
		{
			if (generatedMusic && !endingSong && !isCameraOnForcedPos)
				moveCameraSection();

			if (camZooming && FlxG.camera.zoom < 1.35)
			{
				if(canCamera){
					FlxG.camera.zoom += 0.015 * camZoomingMult;
				}
				camHUD.zoom += 0.03 * camZoomingMult;
			}
			if (numbWalking>0){
				for (i in 0...walkGroup.members.length){
					if(walkGroup.members[i]!=null){
						FlxTween.tween(walkGroup.members[i], {y: walkGroup.members[i].y+50}, 0.45, {type: BACKWARD, ease: FlxEase.quadOut});
					}
				}	
			}	

			if (hpBarTest!=null && hpBarOFF == false) // хп бар
				{
					if (ClientPrefs.tvorogSet['lowQuality']==false){
						var blackGraph:FlxSprite = new FlxSprite().makeGraphic(Std.int(hpBarTest.width), Std.int(hpBarTest.height), FlxColor.BLACK);
						blackGraph.x = hpBarTest.x;
						if (hpBarTest!=null){ // нота y
							blackGraph.y = hpBarTest.y;
						}
						uiGroup.add(blackGraph);
						var tween = FlxTween.tween(blackGraph, { x:blackGraph.x+hpBarTest.width }, (60/SONG.bpm)*2,{ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
							uiGroup.remove(blackGraph);
						}});
					};
					hpBarTest.alpha = 1;
					var tween = FlxTween.tween(hpBarTest, { alpha: 0 }, (60/SONG.bpm)*2, {ease: FlxEase.quadIn});
				}
			updateHealthbarRubl();

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.bpm = SONG.notes[curSection].bpm;
				//defaultTimeUpd = (60/SONG.bpm)*4; // хп бар меняет темп если меняется
				setOnScripts('curBpm', Conductor.bpm);
				setOnScripts('crochet', Conductor.crochet);
				setOnScripts('stepCrochet', Conductor.stepCrochet);
			}
			setOnScripts('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnScripts('altAnim', SONG.notes[curSection].altAnim);
			setOnScripts('gfSection', SONG.notes[curSection].gfSection);
		}
		super.sectionHit();

		setOnScripts('curSection', curSection);
		callOnScripts('onSectionHit');
	}

	#if LUA_ALLOWED
	public function startLuasNamed(luaFile:String)
	{
		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);
		if(!FileSystem.exists(luaToLoad))
			luaToLoad = Paths.getSharedPath(luaFile);

		if(FileSystem.exists(luaToLoad))
		#elseif sys
		var luaToLoad:String = Paths.getSharedPath(luaFile);
		if(OpenFlAssets.exists(luaToLoad))
		#end
		{
			for (script in luaArray)
				if(script.scriptName == luaToLoad) return false;

			new FunkinLua(luaToLoad);
			return true;
		}
		return false;
	}
	#end

	#if HSCRIPT_ALLOWED
	public function startHScriptsNamed(scriptFile:String)
	{
		#if MODS_ALLOWED
		var scriptToLoad:String = Paths.modFolders(scriptFile);
		if(!FileSystem.exists(scriptToLoad))
			scriptToLoad = Paths.getSharedPath(scriptFile);
		#else
		var scriptToLoad:String = Paths.getSharedPath(scriptFile);
		#end

		if(FileSystem.exists(scriptToLoad))
		{
			if (SScript.global.exists(scriptToLoad)) return false;

			initHScript(scriptToLoad);
			return true;
		}
		return false;
	}

	public function initHScript(file:String)
	{
		try
		{
			var newScript:HScript = new HScript(null, file);
			if(newScript.parsingException != null)
			{
				addTextToDebug('ERROR ON LOADING: ${newScript.parsingException.message}', FlxColor.RED);
				newScript.destroy();
				return;
			}

			hscriptArray.push(newScript);
			if(newScript.exists('onCreate'))
			{
				var callValue = newScript.call('onCreate');
				if(!callValue.succeeded)
				{
					for (e in callValue.exceptions)
					{
						if (e != null)
						{
							var len:Int = e.message.indexOf('\n') + 1;
							if(len <= 0) len = e.message.length;
								addTextToDebug('ERROR ($file: onCreate) - ${e.message.substr(0, len)}', FlxColor.RED);
						}
					}

					newScript.destroy();
					hscriptArray.remove(newScript);
					trace('failed to initialize tea interp!!! ($file)');
				}
				else trace('initialized tea interp successfully: $file');
			}

		}
		catch(e)
		{
			var len:Int = e.message.indexOf('\n') + 1;
			if(len <= 0) len = e.message.length;
			addTextToDebug('ERROR - ' + e.message.substr(0, len), FlxColor.RED);
			var newScript:HScript = cast (SScript.global.get(file), HScript);
			if(newScript != null)
			{
				newScript.destroy();
				hscriptArray.remove(newScript);
			}
		}
	}
	#end

	public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var result:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
		if(result == null || excludeValues.contains(result)) result = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
		return result;
	}

	public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		#if LUA_ALLOWED
		if(args == null) args = [];
		if(exclusions == null) exclusions = [];
		if(excludeValues == null) excludeValues = [LuaUtils.Function_Continue];

		var arr:Array<FunkinLua> = [];
		for (script in luaArray)
		{
			if(script.closed)
			{
				arr.push(script);
				continue;
			}

			if(exclusions.contains(script.scriptName))
				continue;

			var myValue:Dynamic = script.call(funcToCall, args);
			if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
			{
				returnVal = myValue;
				break;
			}

			if(myValue != null && !excludeValues.contains(myValue))
				returnVal = myValue;

			if(script.closed) arr.push(script);
		}

		if(arr.length > 0)
			for (script in arr)
				luaArray.remove(script);
		#end
		return returnVal;
	}

	public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic {
		var returnVal:Dynamic = LuaUtils.Function_Continue;

		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = new Array();
		if(excludeValues == null) excludeValues = new Array();
		excludeValues.push(LuaUtils.Function_Continue);

		var len:Int = hscriptArray.length;
		if (len < 1)
			return returnVal;
		for(i in 0...len) {
			var script:HScript = hscriptArray[i];
			if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
				continue;

			var myValue:Dynamic = null;
			try {
				var callValue = script.call(funcToCall, args);
				if(!callValue.succeeded)
				{
					var e = callValue.exceptions[0];
					if(e != null)
					{
						var len:Int = e.message.indexOf('\n') + 1;
						if(len <= 0) len = e.message.length;
						addTextToDebug('ERROR (${callValue.calledFunction}) - ' + e.message.substr(0, len), FlxColor.RED);
					}
				}
				else
				{
					myValue = callValue.returnValue;
					if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
					{
						returnVal = myValue;
						break;
					}

					if(myValue != null && !excludeValues.contains(myValue))
						returnVal = myValue;
				}
			}
		}
		#end

		return returnVal;
	}

	public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		if(exclusions == null) exclusions = [];
		setOnLuas(variable, arg, exclusions);
		setOnHScript(variable, arg, exclusions);
	}

	public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if LUA_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in luaArray) {
			if(exclusions.contains(script.scriptName))
				continue;

			script.set(variable, arg);
		}
		#end
	}

	public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null) {
		#if HSCRIPT_ALLOWED
		if(exclusions == null) exclusions = [];
		for (script in hscriptArray) {
			if(exclusions.contains(script.origin))
				continue;

			if(!instancesExclude.contains(variable))
				instancesExclude.push(variable);
			script.set(variable, arg);
		}
		#end
	}

	function strumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = opponentStrums.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(!isDead && spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	function updateHealthbarRubl(){ // хп бар!
		if (hpBarOFF==false){
			if (hpBarTest.visible!=true){
				hpBarTest.visible=true;
			}
			//if (hpBarTest.y!=playerStrums.members[1].y){ // если не ровно то ставит по ноте y ось
			//	hpBarTest.y = playerStrums.members[1].y;
			//}
			if (health < 0.75){ // хп бар смена цвета
				hpBarTest.color = FlxColor.fromString('0xff1431');
			}
			else if (health < 1.5){
				hpBarTest.color = FlxColor.fromString('0xff6430');
			}
			else{
				hpBarTest.color = FlxColor.fromString('0xa6ff14');
			}
			hpBarTest.animation.play("health"+FlxG.random.int(1,2));
		}
	}

	//public var ratingName:String = '?';
	//public var ratingPercent:Float;
	//public var ratingFC:String;
	//public function RecalculateRating(badHit:Bool = false) {
	//	setOnScripts('score', songScore);
	//	setOnScripts('misses', songMisses);
	//	setOnScripts('hits', songHits);
	//	setOnScripts('combo', combo);
//
	//	var ret:Dynamic = callOnScripts('onRecalculateRating', null, true);
	//	if(ret != LuaUtils.Function_Stop)
	//	{
	//		ratingName = '?';
	//		if(totalPlayed != 0) //Prevent divide by 0
	//		{
	//			// Rating Percent
	//			ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
	//			//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);
//
	//			// Rating Name
	//			ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
	//			if(ratingPercent < 1)
	//				for (i in 0...ratingStuff.length-1)
	//					if(ratingPercent < ratingStuff[i][1])
	//					{
	//						ratingName = ratingStuff[i][0];
	//						break;
	//					}
	//		}
	//		fullComboFunction();
	//	}
	//	//updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce
	//	setOnScripts('rating', ratingPercent);
	//	setOnScripts('ratingName', ratingName);
	//	setOnScripts('ratingFC', ratingFC);
	//}

	//#if ACHIEVEMENTS_ALLOWED
	//private function checkForAchievement(achievesToCheck:Array<String> = null)
	//{
	//	if(chartingMode) return;
//
	//	var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice') || ClientPrefs.getGameplaySetting('botplay'));
	//	if(cpuControlled) return;
//
	//	for (name in achievesToCheck) {
	//		if(!Achievements.exists(name)) continue;
//
	//		var unlock:Bool = false;
	//		if (name != WeekData.getWeekFileName() + '_nomiss') // common achievements
	//		{
	//			switch(name)
	//			{
	//				case 'ur_bad':
	//					unlock = (ratingPercent < 0.2 && !practiceMode);
//
	//				case 'ur_good':
	//					unlock = (ratingPercent >= 1 && !usedPractice);
//
	//				case 'oversinging':
	//					unlock = (boyfriend.holdTimer >= 10 && !usedPractice);
//
	//				case 'hype':
	//					unlock = (!boyfriendIdled && !usedPractice);
//
	//				case 'two_keys':
	//					unlock = (!usedPractice && keysPressed.length <= 2);
//
	//				case 'toastie':
	//					unlock = (!ClientPrefs.data.cacheOnGPU && !ClientPrefs.data.shaders && ClientPrefs.data.lowQuality && !Highscore.getSettings('antialiasing'));
//
	//				case 'debugger':
	//					unlock = (songName == 'test' && !usedPractice);
	//			}
	//		}
	//		else // any FC achievements, name should be "weekFileName_nomiss", e.g: "week3_nomiss";
	//		{
	//			if(isStoryMode && campaignMisses + songMisses < 1 && Difficulty.getString().toUpperCase() == 'HARD'
	//				&& storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
	//				unlock = true;
	//		}
//
	//		if(unlock) Achievements.unlock(name);
	//	}
	//}
	//#end

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(!ClientPrefs.data.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(!ClientPrefs.data.shaders) return false;

		#if (MODS_ALLOWED && !flash && sys)
		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), 'shaders/'))
		{
			var frag:String = folder + name + '.frag';
			var vert:String = folder + name + '.vert';
			var found:Bool = false;
			if(FileSystem.exists(frag))
			{
				frag = File.getContent(frag);
				found = true;
			}
			else frag = null;

			if(FileSystem.exists(vert))
			{
				vert = File.getContent(vert);
				found = true;
			}
			else vert = null;

			if(found)
			{
				runtimeShaders.set(name, [frag, vert]);
				//trace('Found shader $name!');
				return true;
			}
		}
			#if (LUA_ALLOWED || HSCRIPT_ALLOWED)
			addTextToDebug('Missing shader $name .frag AND .vert files!', FlxColor.RED);
			#else
			FlxG.log.warn('Missing shader $name .frag AND .vert files!');
			#end
		#else
		FlxG.log.warn('This platform doesn\'t support Runtime Shaders!');
		#end
		return false;
	}
	#end
}

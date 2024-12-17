package options;

import backend.StageData;
import backend.ClientPrefs;
import states.ChooseState;

import states.LoadingState;
import options.CreditsState;

import flixel.input.keyboard.FlxKey;

class TvorogSettings extends MusicBeatState
{
	var options:Array<String> = [
		'downScroll', 
		'antialiasing', 
		'lowQuality', 
		'framerate',
		'ghostTapping', 
		'arrowBar', 
		'healthDisable', 
		'note_left', 
		'note_down', 
		'note_up', 
		'note_right',
		'reset'
	];

	private var grpOptions:FlxTypedGroup<FlxText>;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	// arrows

    public var optionStatus:FlxText;
	public var optionDesc:FlxText;

	var minBoom:Int = 6;
	var maxBoom:Int = 14;

	var canPressed:Bool = true;
	var currentKey:String = 'none';

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end

		ClientPrefs.loadPrefs();

		FlxG.mouse.visible=false;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		bg.color = 0xff242324;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

		if (ClientPrefs.tvorogSet['lowQuality']==true){
			minBoom=1;
			maxBoom=3;
		}


		for (i in 0...options.length)
		{
			var optionText:FlxText = new FlxText(5, 0, 300, options[i], 20);
			optionText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			optionText.scrollFactor.set();
			optionText.updateHitbox();
			optionText.borderSize = 1.25;
            optionText.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
			var yOffset:Int;
			if (i >= options.length-5 && i < options.length-1){ // do notes
				yOffset= 90;
			}
			else if (i >= options.length-1) { // reset
				yOffset= 130;
			}
			else{
				yOffset= 30;
			}
			if (options[i]=='downScroll'){
				optionText.text = 'Down scroll';
			}
			else if (options[i]=='antialiasing'){
				optionText.text = 'Antialiasing';
			}
			else if (options[i]=='lowQuality'){
				optionText.text = 'Low Quality';
			}
			else if (options[i]=='framerate'){
				optionText.text = 'Framerate';
			}
			else if (options[i]=='ghostTapping'){
				optionText.text = 'Ghost Tapping';
			}
			else if (options[i]=='healthDisable'){
				optionText.text = 'Disable HP';
			}
			else if (options[i]=='note_left'){
				optionText.text = 'LEFT ARROW';
			}
			else if (options[i]=='note_down'){
				optionText.text = 'DOWN ARROW';
			}
			else if (options[i]=='note_up'){
				optionText.text = 'UP ARROW';
			}
			else if (options[i]=='note_right'){
				optionText.text = 'RIGHT ARROW';
			}
			else if (options[i]=='arrowBar'){
				optionText.text = 'funny arrw pls test';
			}
			else if (options[i]=='reset'){
				optionText.text = 'RESET';
			}
			optionText.y = yOffset + (50 * i);
			grpOptions.add(optionText);
		}

		optionDesc = new FlxText(0, FlxG.width-(FlxG.width/2+50), FlxG.height, "", 34);
		optionDesc.setFormat(Paths.font("vcr.ttf"), 34, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		optionDesc.scrollFactor.set();
		optionDesc.updateHitbox();
		optionDesc.borderSize = 1.25;
		optionDesc.antialiasing = ClientPrefs.tvorogSet['antialiasing'];	
		optionDesc.x = FlxG.width-optionDesc.width-20;
		optionDesc.y = 220;
		grpOptions.add(optionDesc);

		optionStatus = new FlxText(0, FlxG.width-(FlxG.width/2+50), FlxG.height, '', 62);
		optionStatus.setFormat(Paths.font("vcr.ttf"), 62, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		optionStatus.scrollFactor.set();
		optionStatus.updateHitbox();
		optionStatus.borderSize = 1.25;
		optionStatus.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
        optionStatus.x = FlxG.width-optionStatus.width-20;
		optionStatus.y = 40;
		grpOptions.add(optionStatus);

		changeSelection();

		super.create();
	}

	override function closeSubState() {
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Options Menu", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_UP_P && currentKey=='none') {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P && currentKey=='none') {
			changeSelection(1);
		}

		if (controls.BACK && currentKey=='none') {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			if(onPlayState)
			{
				StageData.loadDirectory(PlayState.SONG);
				LoadingState.loadAndSwitchState(new PlayState());
				FlxG.sound.music.volume = 0;
			}
			else MusicBeatState.switchState(new ChooseState());
		}
		if (controls.ACCEPT && currentKey=='none') {
            selectingSetting(options[curSelected]);
        }

		if (options[curSelected]=='framerate'){
			if ((FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A) && ClientPrefs.tvorogGameplaySet['framerate']>60){
				if (FlxG.keys.pressed.SHIFT){
					if (ClientPrefs.tvorogGameplaySet['framerate']-10<60){
						ClientPrefs.tvorogGameplaySet['framerate'] = 60;
					}
					else{
						ClientPrefs.tvorogGameplaySet['framerate'] -= 10;
					}
				}
				else{
					ClientPrefs.tvorogGameplaySet['framerate'] -= 1;
				}
				updateStatus('framerate');
				FlxG.sound.play(Paths.sound('resultADD'), 0.25);
				boom(Std.int(FlxG.random.int(minBoom, maxBoom)/2), 'true');
				onChangeFramerate();
			}
			else if ((FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D) && ClientPrefs.tvorogGameplaySet['framerate']<244){
				if (FlxG.keys.pressed.SHIFT){
					if (ClientPrefs.tvorogGameplaySet['framerate']+10>244){
						ClientPrefs.tvorogGameplaySet['framerate'] = 244;
					}
					else{
						ClientPrefs.tvorogGameplaySet['framerate'] += 10;
					}
				}
				else{
					ClientPrefs.tvorogGameplaySet['framerate'] += 1;
				}
				updateStatus('framerate');
				FlxG.sound.play(Paths.sound('resultADD'), 0.25);
				boom(Std.int(FlxG.random.int(minBoom, maxBoom)/2), 'true');
				onChangeFramerate();
			}
			else if (FlxG.keys.justPressed.RIGHT||FlxG.keys.justPressed.LEFT){
				FlxG.sound.play(Paths.sound('pook'), 0.75);
				boom(Std.int(FlxG.random.int(minBoom, maxBoom)/2), 'false');
			}
		}

		if (FlxG.keys.justPressed.TAB && currentKey=='none'){
			MusicBeatState.switchState(new CreditsState());
		}

		if (currentKey!='none'){
			if((FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY) && !controls.ACCEPT){
				var keyPressed:Int = FlxG.keys.firstJustPressed();
				var keyReleased:Int = FlxG.keys.firstJustReleased();
				if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE)
				{
					saveButtons(keyPressed);
					FlxG.sound.play(Paths.sound('resultADD'), 0.25);
					boom(FlxG.random.int(minBoom, maxBoom), 'key');
				}
				else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE))
				{
					saveButtons(keyPressed);
					FlxG.sound.play(Paths.sound('resultADD'), 0.25);
					boom(FlxG.random.int(minBoom, maxBoom), 'key');
				}
			}
		}
	}
	
	function changeSelection(change:Int = 0) {
        for (i in 0...options.length){
            grpOptions.members[i].alpha = 0.6;
        }
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;
        grpOptions.members[curSelected].alpha = 1;
        updateStatus(options[curSelected]);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function saveButtons(val:Int){
		ClientPrefs.keyBinds[currentKey][0]=val;
		ClientPrefs.keyBinds[currentKey][1]=val;
		optionStatus.text = 'STATUS : '+Std.string(ClientPrefs.keyBinds[currentKey][0]);
		ClientPrefs.saveSettings();

		ClientPrefs.loadPrefs();
		currentKey='none';
	}

    function updateStatus(setName:String) {
        switch(setName){
            case 'downScroll':
                optionStatus.text = 'STATUS : '+Std.string(ClientPrefs.tvorogSet['downScroll']);
				optionDesc.text = 'Default down scroll...';
            case 'antialiasing':
                optionStatus.text = 'STATUS : '+Std.string(ClientPrefs.tvorogSet['antialiasing']);
				optionDesc.text = 'True = not pixels\nFalse = pixel he';
            case 'lowQuality':
                optionStatus.text = 'STATUS : '+Std.string(ClientPrefs.tvorogSet['lowQuality']);
				optionDesc.text = 'FOR LOW PC\nLOW PERFORMANCE';
			case 'framerate':
				optionStatus.text = 'FPS : '+Std.string(ClientPrefs.tvorogGameplaySet['framerate']);
				optionDesc.text = 'Changes framerate per second.\nPress SHIFT for 10x multiplayer changes.\n[ more fps for cool spray section ]';
            case 'ghostTapping':
                optionStatus.text = 'STATUS : '+Std.string(ClientPrefs.tvorogSet['ghostTapping']);
				optionDesc.text = 'TRUE FOR NOOBS,\nDONT CHANGE';
			case 'arrowBar':
                optionStatus.text = 'STATUS : '+Std.string(ClientPrefs.tvorogSet['arrowBar']);
				optionDesc.text = 'Up and down\nblack arrows bar';
			case 'healthDisable':
                optionStatus.text = 'STATUS : '+Std.string(ClientPrefs.tvorogSet['healthDisable']);
				optionDesc.text = 'Disable hp';
			case 'note_left':
				optionStatus.text = 'STATUS : '+ClientPrefs.keyBinds[setName][0];
				optionDesc.text = 'leftArrowE';
			case 'note_down':
				optionStatus.text = 'STATUS : '+ClientPrefs.keyBinds[setName][0];
				optionDesc.text = 'downArrow';
			case 'note_up':
				optionStatus.text = 'STATUS : '+ClientPrefs.keyBinds[setName][0];
				optionDesc.text = 'up arrow';
			case 'note_right':
				optionStatus.text = 'STATUS : '+ClientPrefs.keyBinds[setName][0];
				optionDesc.text = 'RIGHT ARROW';
			case 'reset':
				optionStatus.text = 'RESET';
				optionDesc.text = 'Resets all settings';
        }
    }

    function selectingSetting(label:String) {
		switch(label) {
			case 'lowQuality':
                if (ClientPrefs.tvorogSet[label]==false){
                    ClientPrefs.tvorogSet[label]=true;
					minBoom = 1;
					maxBoom = 3;
                }
                else{
                    ClientPrefs.tvorogSet[label]=false;
					minBoom = 6;
					maxBoom = 14;
                }
				boom(FlxG.random.int(minBoom, maxBoom), Std.string(ClientPrefs.tvorogSet[label]));
				FlxG.sound.play(Paths.sound('resultADD'), 0.25);
			case 'antialiasing':
                if (ClientPrefs.tvorogSet[label]==false){
                    ClientPrefs.tvorogSet[label]=true;
                }
                else{
                    ClientPrefs.tvorogSet[label]=false;
                }
				boom(FlxG.random.int(minBoom, maxBoom), Std.string(ClientPrefs.tvorogSet[label]));
				FlxG.sound.play(Paths.sound('resultADD'), 0.25);
			case 'downScroll':
                if (ClientPrefs.tvorogSet[label]==false){
                    ClientPrefs.tvorogSet[label]=true;
                }
                else{
                    ClientPrefs.tvorogSet[label]=false;
                }
				boom(FlxG.random.int(minBoom, maxBoom), Std.string(ClientPrefs.tvorogSet[label]));
				FlxG.sound.play(Paths.sound('resultADD'), 0.25);
			case 'ghostTapping':
                if (ClientPrefs.tvorogSet[label]==false){
                    ClientPrefs.tvorogSet[label]=true;
                }
                else{
                    ClientPrefs.tvorogSet[label]=false;
                }
				boom(FlxG.random.int(minBoom, maxBoom), Std.string(ClientPrefs.tvorogSet[label]));
				FlxG.sound.play(Paths.sound('resultADD'), 0.25);
			case 'arrowBar':
                if (ClientPrefs.tvorogSet[label]==false){
                    ClientPrefs.tvorogSet[label]=true;
                }
                else{
                    ClientPrefs.tvorogSet[label]=false;
                }
				boom(FlxG.random.int(minBoom, maxBoom), Std.string(ClientPrefs.tvorogSet[label]));
				FlxG.sound.play(Paths.sound('resultADD'), 0.25);
			case 'healthDisable':
                if (ClientPrefs.tvorogSet[label]==false){
                    ClientPrefs.tvorogSet[label]=true;
                }
                else{
                    ClientPrefs.tvorogSet[label]=false;
                }
				boom(FlxG.random.int(minBoom, maxBoom), Std.string(ClientPrefs.tvorogSet[label]));
			case 'note_left':
				canPressed=false;
				currentKey = label;
				optionStatus.text = 'STATUS : ???';
			case 'note_down':
				canPressed=false;
				currentKey = label;
				optionStatus.text = 'STATUS : ???';
			case 'note_up':
				canPressed=false;
				currentKey = label;
				optionStatus.text = 'STATUS : ???';
			case 'note_right':
				canPressed=false;
				currentKey = label;
				optionStatus.text = 'STATUS : ???';
			case 'reset':
				FlxG.sound.play(Paths.sound('resultPOW'), 0.25);
				boom(FlxG.random.int(minBoom, maxBoom), 'true');
				ClientPrefs.resetSet();
				ClientPrefs.loadPrefs();
				onChangeFramerate();
				
		}
        updateStatus(label);
	}

	function boom(value:Int, animName:String) {
		for (i in 0...value){
			var meow:FlxTimer = new FlxTimer().start(0.05*i, function(tmr:FlxTimer) {
				FlxG.sound.play(Paths.sound('meow'), 0.1);
				var boomSpr:FlxSprite = new FlxSprite();
				boomSpr.frames = Paths.getSparrowAtlas("tvorog/settings");
				boomSpr.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
				var animationName;
				if (Std.string(animName) == "key"){
					animationName = Std.string(Std.string(animName)+FlxG.random.int(1,2));
					boomSpr.scale.set(0.5,0.5);
				}
				else{
					boomSpr.scale.set(0.2,0.2);
					animationName = Std.string(animName);
					if (Std.string(animName)=='true'){
						boomSpr.color = FlxColor.fromString('0x80FF00');
					}
					else{
						boomSpr.color = FlxColor.fromString('0xFF5100');
					}
				}
				boomSpr.animation.addByPrefix('idle', animationName, 4);
				boomSpr.animation.play('idle');
				boomSpr.scrollFactor.set();
				boomSpr.updateHitbox();
				boomSpr.angle = FlxG.random.int(-30, 30);
				boomSpr.velocity.set(FlxG.random.int(-550, 550),FlxG.random.int(-800, -400));
				boomSpr.acceleration.y = FlxG.random.int(600, 850);
				if (boomSpr.velocity.x>0){
					boomSpr.angularAcceleration = 40;
				}
				else{
					boomSpr.angularAcceleration = -40;
				}
				boomSpr.alpha = 1;
				boomSpr.screenCenter(X);
				boomSpr.y = FlxG.height-Std.int(boomSpr.height/2);
				add(boomSpr);
				FlxTween.tween(boomSpr, {alpha: 0}, 0.75, {ease: FlxEase.quadIn, startDelay: 0.5, onComplete: function(twn:FlxTween) {
					if (boomSpr!=null){
						remove(boomSpr);
					}
				}});				
			});
		}
	}

	function onChangeFramerate()
		{
			#if !html5 //Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
			if(ClientPrefs.tvorogGameplaySet['framerate'] > FlxG.drawFramerate)
			{
				FlxG.updateFramerate = ClientPrefs.tvorogGameplaySet['framerate'];
				FlxG.drawFramerate = ClientPrefs.tvorogGameplaySet['framerate'];
			}
			else
			{
				FlxG.drawFramerate = ClientPrefs.tvorogGameplaySet['framerate'];
				FlxG.updateFramerate = ClientPrefs.tvorogGameplaySet['framerate'];
			}
			trace(FlxG.updateFramerate);
			#end
		}

	override function destroy()
	{
		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
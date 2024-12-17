package options;

import backend.StageData;
import backend.ClientPrefs;
import backend.CreditAdd;

import states.LoadingState;
import options.TvorogSettings;

import flixel.input.keyboard.FlxKey;
import flixel.FlxObject;
import flixel.FlxG;
import flixel.util.FlxCollision;
import flixel.group.FlxGroup;

class CreditsState extends MusicBeatState
{
	public var creditNames:Array<String> = [];
	public var creditDescs:Array<String> = [];

	private var grpOptions:FlxTypedGroup<FlxText>;
    private var grpCards:FlxTypedGroup<FlxSprite>;
	private var uiGroup:FlxGroup;
	private static var curSelected:Int = 0;
	public static var menuBG:FlxSprite;
	public static var onPlayState:Bool = false;
	// arrows

    public var optionStatus:FlxText;
	public var creditDesc:FlxText;
    public var creditText:FlxText;
	public var creditIcon:FlxSprite;

	public var fireSprite:FlxSprite;
	public var redButton:FlxSprite;

	var minBoom:Int = 6;
	var maxBoom:Int = 14;

	var canPressed:Bool = true;
	var currentKey:String = 'none';

	var levelBounds:FlxGroup;

	var fireEnabled:Bool = false;
	var canButton:Bool = true;

	var fireTime:Float = 8;

	var bg:FlxSprite;

	override function create() {
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Credits", null);
		#end

		FlxG.mouse.visible=true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		bg.color = 0xff242324;
		bg.updateHitbox();

		bg.screenCenter();
		add(bg);

		grpOptions = new FlxTypedGroup<FlxText>();
		add(grpOptions);

        grpCards = new FlxTypedGroup<FlxSprite>();
        add(grpCards);

		uiGroup = new FlxGroup();
        add(uiGroup);

		creditText = new FlxText(0, 0, 250, "meow", 34);
		creditText.scrollFactor.set();
		creditText.setFormat(Paths.font("vcr.ttf"), 34, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		creditText.borderSize = 1.25;
		creditText.antialiasing = ClientPrefs.tvorogSet['antialiasing'];	
		creditText.updateHitbox();
		creditText.x = 0+creditText.width;
		creditText.y = 90;
		uiGroup.add(creditText);

		creditIcon = new FlxSprite();
		creditIcon.frames = Paths.getSparrowAtlas('tvorog/credit/creditChar');
		creditIcon.scrollFactor.set();
		creditIcon.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		creditIcon.scale.set(0.4,0.4);
		creditIcon.updateHitbox();
		creditIcon.y = 90-(creditIcon.height/2);
		creditIcon.x = 0+90;
		uiGroup.add(creditIcon);

		creditDesc = new FlxText(0, 0, 250, "rrr", 34);
		creditDesc.scrollFactor.set();
		creditDesc.updateHitbox();
		creditDesc.setFormat(Paths.font("vcr.ttf"), 34, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		creditDesc.borderSize = 1.25;
		creditDesc.antialiasing = ClientPrefs.tvorogSet['antialiasing'];	
		creditDesc.x = FlxG.width-(50+creditDesc.width);
		creditDesc.y = 90;
		uiGroup.add(creditDesc);

		fireSprite = new FlxSprite(); // творог результатс
		fireSprite.frames = Paths.getSparrowAtlas('tvorog/credit/fireAsset');
		fireSprite.scrollFactor.set();
		fireSprite.updateHitbox();
		fireSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		fireSprite.animation.addByPrefix('fire', "fire", 12, true);
		fireSprite.animation.play('fire');
		fireSprite.scale.x = 16;
		fireSprite.scale.y = 12;
		fireSprite.screenCenter(X);
		fireSprite.y = FlxG.height;
		fireSprite.alpha = 0;
		add(fireSprite);	

		redButton = new FlxSprite().loadGraphic(Paths.image('tvorog/credit/redButton'));
		redButton.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		redButton.scrollFactor.set();
		redButton.updateHitbox();
		redButton.x = FlxG.width - redButton.width + 25;
		redButton.y = FlxG.height - redButton.height + 25;
		redButton.scale.set(0.3,0.3);
		add(redButton);

		var creditData:CreditFile = CreditData.getCreditFile();
		for (i in 0...creditData.CreditName.length){
			creditNames[i] = creditData.CreditName[i][0];
			creditDescs[i] = creditData.CreditName[i][1];
		}

		for (i in 0...creditNames.length){
			creditIcon.animation.addByPrefix(creditNames[i], creditNames[i], 1, false);
		}

		changeSelection();

		super.create();

		levelBounds = FlxCollision.createCameraWall(FlxG.camera, true, 4);
	}

	override function closeSubState() {
		super.closeSubState();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Credits", null);
		#end
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_LEFT_P) {
			changeSelection(-1);
		}
		if (controls.UI_RIGHT_P) {
			changeSelection(1);
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new TvorogSettings());
		}
		if (controls.ACCEPT && !fireEnabled) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
			if (FlxG.keys.pressed.SHIFT){
				spawnCard(creditNames[curSelected], 10);
			}
			else{
				spawnCard(creditNames[curSelected]);
			}
        }

		//FlxG.collide(grpCards, grpCards);
		FlxG.collide(grpCards, levelBounds);

		if (fireEnabled){
			if (fireTime<=0){
				fireTime=8;
				fireEnabled=false;
			}
			else{
				fireTime -= elapsed;
			}
		}


		if (!canButton){
			for (card in 0...grpCards.members.length){
				if (grpCards.members[card]!=null){
					grpCards.members[card].updateHitbox();
				}
			}
		}

		if(canButton && FlxG.mouse.overlaps(redButton) && FlxG.mouse.justPressed){
			if (!fireEnabled){
				fireEnabled=true;
				FlxG.sound.play(Paths.sound('credit/creditFire'));
				FlxG.sound.play(Paths.sound('credit/creditScreams'));
				//FlxTween.color(bg, 1.25, bg.color, FlxColor.fromString('0x780D06'),{ease: FlxEase.quadIn});
				FlxTween.tween(fireSprite, { alpha: 0.5 }, 1.25,{ease: FlxEase.quadIn});
				for (card in 0...grpCards.members.length){
					if (grpCards.members[card]!=null){
						grpCards.members[card].acceleration.x = grpCards.members[card].acceleration.x * 3;
						var meow = FlxTween.tween(grpCards.members[card].scale, { x:0, y:0 }, fireTime-3,{ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
							if (grpCards.members[card]!=null){
								grpCards.remove(grpCards.members[card]);
							}
						}});
						var meow2 = FlxTween.color(grpCards.members[card], fireTime-1, grpCards.members[card].color, FlxColor.fromString('0x24150B'), {ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
							if (grpCards.members[card]!=null){
								grpCards.remove(grpCards.members[card]);
							}
						}});				
					}	
				}
				var meow = FlxTween.tween(redButton.scale, { x:redButton.scale.x-0.1, y:redButton.scale.y-0.1 }, 1,{ease: FlxEase.quadOut, onComplete: function(twn:FlxTween) {
					FlxTween.tween(redButton.scale, { x:redButton.scale.x+0.1, y:redButton.scale.y+0.1 }, 1,{ease: FlxEase.quadIn, startDelay: fireTime, onComplete: function(twn:FlxTween) {
						fireSprite.alpha = 0;
					}});
					//FlxTween.color(bg, 1, bg.color, FlxColor.fromString('0xff242324'),{ease: FlxEase.quadIn});
					FlxTween.tween(fireSprite, { alpha: 0 }, 1,{ease: FlxEase.quadIn, startDelay: fireTime});
				}});
			}
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = creditNames.length - 1;
		if (curSelected >= creditNames.length)
			curSelected = 0;
        creditText.text = creditNames[curSelected];
		creditDesc.text = creditDescs[curSelected];
		creditIcon.animation.play(creditNames[curSelected]);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

    function spawnCard(label:String, ?value:Int=1) {
		for (i in 0...value){
			var cardSprite = new FlxSprite();
			cardSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
			cardSprite.scrollFactor.set();
			cardSprite.frames = Paths.getSparrowAtlas('tvorog/credit/creditChar');
			cardSprite.animation.addByPrefix('meow', label, 1, false);
			cardSprite.scale.set(0.25,0.25);
			cardSprite.updateHitbox();
			cardSprite.animation.play('meow');
			cardSprite.alpha = 1;
			cardSprite.color = FlxColor.WHITE;
			cardSprite.acceleration.x = FlxG.random.int(-45, 45);
			cardSprite.acceleration.y = 300;
			cardSprite.velocity.x = FlxG.random.int(-250, 250);
			cardSprite.velocity.y = FlxG.random.int(-300, -100);
			cardSprite.elasticity = 1;
			cardSprite.angularDrag = 200;
			cardSprite.screenCenter();
			grpCards.add(cardSprite);
		}
	}

	override function destroy()
	{
		super.destroy();
	}
}
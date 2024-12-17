package states;

import backend.Spray;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import flixel.animation.FlxAnimationController;
import lime.utils.Assets;

import openfl.Assets;
import openfl.utils.Assets as OpenFlAssets;

import states.ChooseState;
import backend.ClientPrefs;

class SprayState extends MusicBeatState
{
    public var allShapes:Array<String> = [];

    public var delaySpray:Float = 0.0001; // через сколько будет ставиться каждая точка
    public var sprayColorMain:String = 'ONE'; // цвет
    public var spraySize:Float = 0.05;
    public static var spraySizeMAX:Float = 0.1;
    public static var spraySizeMIN:Float = 0.01;
    public static var colorSpray:Array<String> = [];
    public var sprayShape:String;
    public var sprayShapeValue:Int = 0;
    public var sprayColorSprite:FlxSprite;
    public var spraySizeText:FlxText;

    public var sprayCTRLz:Int = 0;
    public var sprayCount:Int;
    public var sprayFirst:Bool;
    public var sprayOper:Array<Int> = [];

    public var sprayGroup:FlxSpriteGroup; // спрей
    public var backGfGroup:FlxSpriteGroup;

    public var camFollow:FlxObject;

    public var sound:FlxSound = null; // звук

    var bg:FlxSprite;


    override function create()
    {
        bg = new FlxSprite(-80).loadGraphic(Paths.image('tvorog/choose/placeholder'));
        bg.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
        bg.scrollFactor.set(0, 0);
        bg.setGraphicSize(Std.int(bg.width * 1.175));
        bg.updateHitbox();
        bg.screenCenter();
        bg.color = 0xff59565f;
        add(bg);
    
        backGfGroup = new FlxSpriteGroup();
        add(backGfGroup);

        sprayGroup = new FlxSpriteGroup();
		add(sprayGroup);
    
        camFollow = new FlxObject(0, 0, 1, 1);
        add(camFollow);
    
        super.create();

        var sprayData:SprayFile = SprayData.getPresetFile();
		for (i in 0...sprayData.Sprays.length){
			allShapes[i] = sprayData.Sprays[i];
		}
		for (i in 0...sprayData.SprColors.length){
			colorSpray[i] = sprayData.SprColors[i];
		}
		sprayShape = allShapes[0];

        sprayPart();

        camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(bg.width/2, bg.height/2);
        add(camFollow);
    
        FlxG.camera.follow(camFollow, null, 9);
        FlxG.camera.snapToTarget();

        //FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
    
        if (controls.BACK){ // back
            MusicBeatState.switchState(new ChooseState());
            FlxG.sound.playMusic(Paths.music('tvorogMenu'));
        }
    
        spraySizeText.text = 'SIZE : '+spraySize+' [ d: 0.05 ]';
        if (FlxG.mouse.wheel!=0){ // размер кисти
            var future1:Float = spraySize += (FlxG.mouse.wheel / 100);
            if (future1>spraySizeMAX){ //future1>spraySizeMIN
                spraySize = future1;
            }
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
    
        if (FlxG.mouse.justPressed && sprayFirst==false){
            sprayFirst = true;
        }
        if (FlxG.mouse.pressed){
            if (delaySpray>0){
                delaySpray-=elapsed;
            }
            else{
                var tvorog:FlxSprite = new FlxSprite(0,0).loadGraphic(Paths.image('tvorog/sprayPart/Presets/brushTextures/'+sprayShape));
                tvorog.color = FlxColor.fromString('0x'+sprayColorMain);
                tvorog.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
                tvorog.x = FlxG.mouse.x;//screenX + (36 * FlxG.camera.zoom) + 3;
                tvorog.y = FlxG.mouse.y;//screenY + (215 * FlxG.camera.zoom))-293;
                tvorog.scale.set(spraySize,spraySize);
                tvorog.scrollFactor.set();
                if (sprayFirst == true){
                    sprayFirst=false;
                    sprayCTRLz = sprayCount;
                    sprayOper.push(sprayCTRLz);
                }
                sprayCount++;
                delaySpray = 0.0001;
                backGfGroup.add(tvorog);
            }			
        }
        if (FlxG.mouse.justReleased){
            if (sprayFirst==false){
                sprayFirst=true;
            }
        }
    }

    public function sprayPart() // творог спрей
    {
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

			sprayGroup.add(spriteColor);	
		}
		sprayColorSprite = new FlxSprite(0,0).loadGraphic(Paths.image('tvorog/sprayPart/Presets/brushTextures/'+sprayShape));
		sprayColorSprite.color = FlxColor.fromString('0x'+colorSpray[0]);
		sprayColorSprite.antialiasing = ClientPrefs.tvorogSet['antialiasing'];
		sprayColorSprite.scale.set(0.45,0.45);
		sprayColorSprite.screenCenter(X);
		sprayColorSprite.x = FlxG.width-sprayColorSprite.width-25;
		sprayColorSprite.y = 0+Std.int(FlxG.height/10)-45;
		sprayColorSprite.scrollFactor.set();
		sprayColorSprite.alpha = 0;
		sprayGroup.add(sprayColorSprite);
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
		sprayGroup.add(sprayShapeSprite);
		FlxTween.tween(sprayShapeSprite, {alpha: 1}, 2, {ease: FlxEase.quadIn});

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
            keyText.alpha = 0.5;
			sprayGroup.add(keyText);
		}

		spraySizeText = new FlxText(12, FlxG.height - 58, 0, "", 24);
		spraySizeText.scrollFactor.set();
		spraySizeText.setFormat("AppleLi.ttf", 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		spraySizeText.alpha = 0;
		spraySizeText.x = FlxG.width - 325;
		spraySizeText.y = FlxG.height-58;
        spraySizeText.alpha = 0.5;
		sprayGroup.add(spraySizeText);
	
		FlxG.sound.playMusic(Paths.music('spray'), 0);
		FlxG.sound.music.fadeIn(4, 0, 0.4);

        sprayChangeColor('ONE');
        FlxG.mouse.visible = true;
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
        sprayColorSprite.loadGraphic(Paths.image('tvorog/sprayPart/Presets/brushTextures/'+sprayShape));
    }

    public function sprayBack(){// CTRL Z
        if (sprayCTRLz>-1 && sprayCount>0){
            var minSpray:Int = sprayOper.pop();
            var meow:Int = backGfGroup.members.length;

            while (meow>minSpray){
                for (i in minSpray...meow){ //sprayCount
                    if (backGfGroup.members[i]!=null){
                        backGfGroup.members[i].destroy();
                        backGfGroup.members.remove(backGfGroup.members[i]);
                        meow-=1;
                    }
                    
                }				
            }

            sprayCount = meow;
            sprayCTRLz = meow;
        }
    }
}

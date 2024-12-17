function onCreate() 
	
	makeLuaSprite('bgg','tvorog/bgs/metro/bgg', -890,-1250)
	addLuaSprite('bgg', false)
	scaleObject('bgg', 1.6, 1.6)

	makeLuaSprite('lights','tvorog/bgs/metro/lights', -890,-720)
	addLuaSprite('lights', true)
	setBlendMode('lights','add')
	scaleObject('lights', 1.6, 1.6)

end
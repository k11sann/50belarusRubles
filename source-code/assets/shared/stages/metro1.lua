function onCreate() 
	
	makeLuaSprite('bgg','tvorog/bgs/metro1/bgg', -900,-400)
	addLuaSprite('bgg', false)
	scaleObject('bgg', 0.82, 0.82)

	makeLuaSprite('lights','tvorog/bgs/metro1/lights', -1200,-200)
	addLuaSprite('lights', true)
	setBlendMode('lights','add')
	scaleObject('lights', 1, 1)

end
function onCreate() 
	
	makeLuaSprite('bgg','tvorog/bgs/city2/city2', -1271,-290)
	addLuaSprite('bgg', false)
	scaleObject('bgg', 0.95, 0.95)

	makeLuaSprite('lights','tvorog/bgs/city2/lights', -1271,-290)
	addLuaSprite('lights', true)
	setBlendMode('lights','add')
	scaleObject('lights', 0.95, 0.95)
	

end
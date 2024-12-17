function onCreate() 
	
	makeLuaSprite('bgg','tvorog/bgs/city/city', -1091,-400)
	addLuaSprite('bgg', false)
	scaleObject('bgg', 1, 1)

	makeLuaSprite('lights','tvorog/bgs/city/lights', -1200,-500)
	addLuaSprite('lights', true)
	setBlendMode('lights','add')
	scaleObject('lights', 2, 2)
	

end
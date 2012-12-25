--[[
****
* This example is not modified for performance or other issues
* It only shows simple mechanism of TiledAsWorldEditor.lua
* Please see: https://github.com/1dot44mb/gideros/tree/master/tools/TiledAsWorldEditor
****
]]--

-- Set orientation to landscape
application:setOrientation(Application.LANDSCAPE_LEFT)

sceneManager = SceneManager.new({
	--simple scene
	["start"] = StartScene
})

--add manager to stage
stage:addChild(sceneManager)

--start start scene
sceneManager:changeScene("start", 1, SceneManager.crossFade, easing.outBack)
--[[
****
* This example is not modified for performance or other issues
* It only shows simple mechanism of TiledAsWorldEditor.lua
* Please see: https://github.com/1dot44mb/gideros/tree/master/tools/TiledAsWorldEditor
****
]]--

-- Set orientation to landscape
application:setOrientation(Application.LANDSCAPE_LEFT)

-- Load the level in the scene
local level = TiledAsWorldEditor.new("prototypeLevel.lua")

-- Add it to stage
stage:addChild(level)

-- Update function
function Update() 
	level.world:step(1/60, 8, 3)	-- edit the step values if required. These are good defaults!
	for i = 1, level:getNumChildren() do
		local sprite = level:getChildAt(i)
		local body = sprite.body
		-- if it has a body (ie, it's a physical object directly on the stage) update sprite based on physical body
		if body then
			local bodyX, bodyY = body:getPosition()
			sprite:setPosition(bodyX, bodyY)
			sprite:setRotation(body:getAngle() * 180 / math.pi)
		end
	end
end

-- Creates and adds a simple ball object along with its sprite
function addBall(x, y)

	-- Create ball bitmap object from ball graphic
	local ball = Bitmap.new(Texture.new("ball.png"))
	
	-- Reference center of the ball for positioning
	ball:setAnchorPoint(0.5,0.5)
	
	ball:setPosition(x,y)
	
	-- Get radius
	local radius = ball:getWidth()/2
	
	-- Create box2d physical object
	local body = level.world:createBody{type = b2.DYNAMIC_BODY}
	body:setPosition(ball:getX(), ball:getY())
	body:setAngle(ball:getRotation() * math.pi/180)
	local circle = b2.CircleShape.new(0, 0, radius)
	local fixture = body:createFixture{shape = circle, density = 5.0, friction = 0.1, restitution = 0}
	ball.body = body
	ball.body.type = "ball"
	
	-- Add to stage (in front)
	level:addChildAt(ball, 1)
	
	-- Return created object
	return ball
end

-- Create a simple ball
addBall(400, 20)

-- Enable debug drawing to see the Box2D bodies
local debugDraw = b2.DebugDraw.new()
level.world:setDebugDraw(debugDraw)
stage:addChild(debugDraw)
	
-- Bind event listener for update function
stage:addEventListener(Event.ENTER_FRAME, Update)
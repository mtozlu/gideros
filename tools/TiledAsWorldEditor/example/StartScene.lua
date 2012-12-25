StartScene = gideros.class(Sprite)

local vPad

local Xeon

local Level

local function is32bit()
	return string.dump(is32bit):byte(9) == 4
end

--check if 32bit and use corresponding vpad library
if is32bit() then
	require("Helper/tntvpad32")
else
	require("Helper/tntvpad64")
end


local function leftJoy(e)
if not Level.paused then
	if e.data.power > 0.7 then
		local direction = 1
		if (math.cos(e.data.angle) < 0) then
			direction = -1
			Xeon.anim:setAnimation("RUN-LEFT")
		else
			Xeon.anim:setAnimation("RUN-RIGHT")
		end
		Xeon.body:setLinearVelocity(direction * 100 * e.data.deltaTime, 0)
	elseif e.data.power == 0 then
		Xeon.body:setLinearVelocity(0, 0)
		if (math.cos(e.data.angle) < 0) then
			Xeon.anim:setAnimation("WAIT-LEFT")
		else
			Xeon.anim:setAnimation("WAIT-RIGHT")
		end
	else

	end
end
end
local function fire(e)
	if e.data.state == PAD.STATE_BEGIN then
		Xeon.body:applyLinearImpulse(0, -10, Xeon.body:getPosition())
	end
end
local function fire2(e)
	if e.data.state == PAD.STATE_BEGIN then
		if(Level.paused) then Level:UnPause()
		else Level:Pause() end
	end
end
local function fire3(e)
	if e.data.state == PAD.STATE_BEGIN then
		Level:EnableDebugDrawing()
	end
end
local function fire4(e)
	if e.data.state == PAD.STATE_BEGIN then
		Level:DisableDebugDrawing()
	end
end

local function onBeginContact(event)
	
	local fixtureA = event.fixtureA
	local fixtureB = event.fixtureB
	local bodyA = fixtureA:getBody()
	local bodyB = fixtureB:getBody()

	if(bodyA.Name == "Xeon") and (bodyB.Name == "Coin") then
		print(bodyA.Name, " picks ", bodyB.Name)
		print(bodyB._Points, " points!")
	end
end

function StartScene:init()

	vPad = CTNTVirtualPad.new(stage, "Assets/vpad",  PAD.STICK_SINGLE, PAD.BUTTONS_FOUR, 20, 2)
	
	vPad:setJoyStyle(PAD.COMPO_LEFTPAD, PAD.STYLE_MOVABLE)
	vPad:setPosition(PAD.COMPO_LEFTPAD, 100, 120)
	vPad:start()
	
	--add event VPAD event listeners to your game...
	vPad:addEventListener(PAD.LEFTPAD_EVENT, leftJoy, main)
	vPad:addEventListener(PAD.BUTTON1_EVENT, fire, main)
	vPad:addEventListener(PAD.BUTTON2_EVENT, fire2, main)
	vPad:addEventListener(PAD.BUTTON3_EVENT, fire3, main)
	vPad:addEventListener(PAD.BUTTON4_EVENT, fire4, main)

	--remove event on exiting scene
	self:addEventListener("exitBegin", self.onExitBegin, self)
	
	-- Load the level in the scene
	Level = TiledAsWorldEditor.new("Level.lua")

	-- Get main character so we can move and set animations
	Xeon = Level.Sprites["Xeon"]
	
	-- Listen for collisions in default world
	Level.B2_Worlds[1]:addEventListener(Event.BEGIN_CONTACT, onBeginContact)
	
	-- Add it to stage
	self:addChild(Level)

end

function StartScene:onExitBegin()
  vPad = vPad:free()
end
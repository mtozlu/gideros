--[[
	Author:	1.44mb
	Date:	December 25, 2012
	Version: 2
   
	Lua class that allows Tiled Editor (http://mapeditor.org)
	to be used as a world and physics editor for Gideros Studio.
   
	This class is heavily based on @atilim's TileMap example.
	But modified and extended.
	Also displayLib's update physical world code is used in this class (displayLib by Shark Soup Studios)

	Please see https://github.com/1dot44mb/gideros/tree/master/tools/TiledAsWorldEditor
	for further detail, usage instructions, video tutorial and examples.
   
	Arguments:
		filename is the path to .lua file exported from Tiled.

	Needs 'bit' plugin to work properly.
   
	License:
		MIT
--]]

TiledAsWorldEditor = Core.class(Sprite)

-- Reference for variables to be used among different functions when creating world
local Self
local map
local tilemap

-- Physics properties to be applied to objects when no property is set in Tiled
local Density_default = 1.0
local Friction_default = 0.1
local Restitution_default = 0.8

-- Physics properties to be applied to world when no property is set in Tiled
local GravityX_default = 0
local GravityY_default = 9.81

-- Bits on the far end of the 32-bit global tile ID are used for tile flags (flip, rotate)
local FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
local FLIPPED_VERTICALLY_FLAG   = 0x40000000;
local FLIPPED_DIAGONALLY_FLAG   = 0x20000000;

local Is_B2D_Included = false
local Is_BitOp_Included = false
local Is_TNTAnimator_Included = false

-- Path to dependencies
-- Write path to TNTAnimator here. It will automatically include 32bit or 64bit version depending on the system. So dont put 32 or 64 to the tail.
local Path_to_TNTAnimator = "Animation/tntanimator"

-- Gets tileset from exported map
local function getTileset(name)
	-- if we have a name parameter and it's a string
	if name and type(name) == 'string' then
		-- search for name
		for index = 1, #map.tilesets do
			-- if found
			if map.tilesets[index].name == name then
				-- return it
				return map.tilesets[index]
			end
		end
	end
	
	-- Warning if no tileset
	print("\n", "ERROR", "Tileset not found:", name, "\n")
	
end

-- Gets layer from exported map
local function getLayer(name)

	-- if we have a name parameter and it's a string
	if name and type(name) == 'string' then
		-- search for name
		for index = 1, #map.layers do
			-- if found
			if map.layers[index].name == name then
				-- return it
				return map.layers[index]
			end
		end		
	end
	
	-- Warning if no layer
	print("\n", "ERROR", "Layer not found:", name, "\n")

end

-- Gets property of item
local function getProperty(item, name)
	
	-- if we have an item and 
	if item and name and type(item) == 'table' and type(name) == 'string' then
		for k, v in pairs(item.properties) do 
			if k == name then  
				return v
			end	
		end
	end
	
end

local function IncludeBox2D()
	if Is_B2D_Included == false then
		require "box2d"
		Is_B2D_Included = true
	end
end

local function IncludeBitOp()
	if Is_BitOp_Included == false then
		require "bit"
		Is_BitOp_Included = true
	end
end

local function is32bit()
	return string.dump(is32bit):byte(9) == 4
end

local function IncludeTNTAnimator()
	if Is_TNTAnimator_Included == false then
		if is32bit() then
			require(Path_to_TNTAnimator .. "32")
		else
			require(Path_to_TNTAnimator .. "64")
		end
		Is_TNTAnimator_Included = true
	end
end


-- Not yet implemented
local function createBoundingObject(obj, bounding_layer)
	
	if bounding_layer.properties.TilesetName == nil then return end
	
	-- Get tileset information and texture
	local tileset = getTileset(bounding_layer.properties.TilesetName)
	tileset.sizex = math.floor((tileset.imagewidth - tileset.margin + tileset.spacing) / (tileset.tilewidth + tileset.spacing))
	tileset.sizey = math.floor((tileset.imageheight - tileset.margin + tileset.spacing) / (tileset.tileheight + tileset.spacing))	
	tileset.texture = Texture.new(tileset.image)
	
	local bitmap
	-- get texture region
	
	--[[
	Bounding_Sprite_Layer_Name: no need to indicate this by default unless you need a specific behaviour (see notes)
	(if following properties are set, the corresponding tile will be this bodies sprite)
		(if SpriteWidth and SpriteHeight is not set, a single tile will be selected starting from SpriteX and SpriteY(top-left) as the sprite of this body)
		(if SpriteWidth and SpriteHeight are set, starting from SpriteX, SpriteY(top-left) + SpriteWidth and SpriteHeight will be this bodies sprite)
	(if they are not set the tiles that this object collapses will be this bodies sprite)
	SpriteX = x index of the tile (enable grid, and count the tiles starting from 1 to sprites left) (not position, index is position / map.tilewidth)
	SpriteY = y index of the tile (enable grid, and count the tiles starting from 1 to sprites top) (not position, index is position / map.tilewidth)
	SpriteWidth = width of desired sprite in map.tilewidths (not pixels) 
	SpriteHeight = height of desired sprite in map.tileheights (not pixels) 
	--]]
	
	--obj.x and obj.y are in pixels, convert them to indexes to get each tile from tileset
	--concatenate each tile in its own place using TextureRegion, put them in one Bitmap
	
	-- Variables to let us know if the tile is flipped or rotated
	local flipHor, flipVer, flipDia = 0, 0, 0
	
	local i = x + (y - 1) * layer.width
			
	-- Get Global_index_ID of tile which holds all information
	local gid = layer.data[i]
	
	-- If not empty tile
	if gid ~= 0 then
		-- Read flipping flags
		flipHor = bit.band(gid, FLIPPED_HORIZONTALLY_FLAG)
		flipVer = bit.band(gid, FLIPPED_VERTICALLY_FLAG)
		flipDia = bit.band(gid, FLIPPED_DIAGONALLY_FLAG)
		
		-- Convert flags to gideros style
		if(flipHor ~= 0) then flipHor = TileMap.FLIP_HORIZONTAL end
		if(flipVer ~= 0) then flipVer = TileMap.FLIP_VERTICAL end
		if(flipDia ~= 0) then flipDia = TileMap.FLIP_DIAGONAL end

		-- Clear the flags from gid so other information is healthy
		gid = bit.band(gid, bit.bnot(bit.bor(FLIPPED_HORIZONTALLY_FLAG, FLIPPED_VERTICALLY_FLAG, FLIPPED_DIAGONALLY_FLAG)))
		
		-- Find corresponding texture
		local tx = (gid - tileset.firstgid) % tileset.sizex
		local ty = math.floor((gid - tileset.firstgid) / tileset.sizex)
		
		-- Set the tile with flip info
		--tilemap:setTile(x, y, tx, ty, bit.bor(flipHor, flipVer, flipDia))
		
		-- Get the tile and create seperate sprite
		local bitmap = Bitmap.new(TextureRegion.new(
					tileset.texture, 
					tileset.margin + tx * (tileset.tilewidth + tileset.spacing), 
					tileset.margin + ty * (tileset.tileheight + tileset.spacing), 
					tileset.tilewidth, tileset.tileheight))
		
		--print(gid)
		--print(tileset.sizex, tileset.sizey, tileset.tilewidth, tileset.tileheight, tileset.spacing, tileset.margin)
		--print(map.tilewidth, map.tileheight)
		--print(x, y)
		--print(tx, ty)
		
		createSpriteFromBitmap(bitmap, layer, x, y)

		-- Reset vars, so they dont confuse us in the next iteration
		flipHor, flipVer, flipDia = 0, 0, 0
	end
			
			
	bitmap.object = obj
	
	createSpriteFromBitmap(bitmap, bounding_layer, obj.x, obj.y)

end

local function createBodyFromObject(obj)

	local world_id = obj.properties.World_ID or 1

	if Self.B2_Worlds[world_id] == nil then
		local doSleep = true
		if obj.properties.Do_Sleep == "false" then doSleep = false end
		Self.B2_Worlds[world_id] = b2.World.new(obj.properties.GravityX or GravityX_default,
												obj.properties.GravityY or GravityY_default,
												doSleep)
	end
	
	
	-- get Box2D properties
	local B2_BodyType = b2.STATIC_BODY
	local B2_Shape	
	local B2_Density = obj.properties.Density or Density_default
	local B2_Friction = obj.properties.Friction or Friction_default
	local B2_Restitution = obj.properties.Restitution or Restitution_default
	local B2_IsSensor = false
	local B2_Angle = obj.properties.Angle or 0
	local B2_LinearVelocity = { x = obj.properties.LinearVelocityX or 0, y = obj.properties.LinearVelocityY or 0}
	local B2_AngularVelocity = obj.properties.AngularVelocity or 0
	local B2_LinearDamping = obj.properties.LinearDamping or 0
	local B2_AngularDamping = obj.properties.AngularDamping or 0
	local B2_AllowSleep = true
	local B2_Awake = true
	local B2_FixedRotation = false
	local B2_Bullet = false
	local B2_Active = true
	local B2_GravityScale = obj.properties.GravityScale or 1

	B2_Angle = B2_Angle * 0.0174532925

	--Set bool properties and override if set in obj
	if obj.properties.Active == "true" then B2_Active = true elseif obj.properties.Active == "false" then B2_Active = false end
	
	if obj.properties.Bullet == "true" then B2_Bullet = true elseif obj.properties.Bullet == "false" then B2_Bullet = false end
	
	if obj.properties.FixedRotation == "true" then B2_FixedRotation = true elseif obj.properties.FixedRotation == "false" then B2_FixedRotation = false end
	
	if obj.properties.Awake == "true" then B2_Awake = true elseif obj.properties.Awake == "false" then B2_Awake = false end
	
	if obj.properties.AllowSleep == "true" then B2_AllowSleep = true elseif obj.properties.AllowSleep == "false" then B2_AllowSleep = false end
	
	if obj.properties.IsSensor == "true" then B2_IsSensor = true elseif obj.properties.IsSensor == "false" then B2_IsSensor = false end
	
	-- Body Type //considered static by default
	if obj.properties.BodyType == "dynamic" then
		B2_BodyType = b2.DYNAMIC_BODY
	elseif obj.properties.BodyType == "kinematic" then
		B2_BodyType = b2.KINEMATIC_BODY
	end
	
	-- Get the actual shape of object set in Tiled and create Box2D object based on that
	if obj.shape == "rectangle" then
		B2_Shape = b2.PolygonShape.new()
		B2_Shape:setAsBox(obj.width / 2, obj.height / 2)
	elseif obj.shape == "ellipse" then
		B2_Shape = b2.CircleShape.new(0, 0, obj.width / 2)
		-- For now, all ellipses are considered perfect circles
		-- Because Box2D does not let you create ellipses
		-- if obj.width ~= obj.height, than this is an ellipse
		-- In the future we will add a polygon approximation of ellipse, see upcoming features on github readme
	elseif obj.shape == "polygon" then
		B2_Shape = b2.PolygonShape.new()
		-- Get vertices of polygon and create the same Box2D polygon
		vertices = {}
		-- We are reverse iterating because Tiled exports counter clokwise drawn polygons in reverse order
		-- and Box2D needs polygons in counter clockwise order
		-- So we reverse the nodes in order to give them to Box2D in proper order.
		local count = #obj.polygon
		for i = count, 1, -1 do
			vertices[(count - i)*2 + 1] = obj.polygon[i].x
			vertices[(count - i)*2 + 2] = obj.polygon[i].y
		end
		B2_Shape:set(unpack(vertices))
		
		-- Some of you may say why don't you let the user draw in clockwise order in Tiled
		-- and make a normal iteration.
		-- While this is true, i personally never like to tend to change the user behaviours
		-- Google about polygons and box2d, you will see that it is a standart to create polygons in ccw order
		-- So i just don't want to change that.
		
	elseif obj.shape == "polyline" then
		-- Create polyline
		B2_Shape = b2.ChainShape.new()
		vertices = {}
		for i = 1, #obj.polyline do
			vertices[i * 2 - 1] = obj.polyline[i].x
			vertices[i * 2] = obj.polyline[i].y
		end
		B2_Shape:createChain(unpack(vertices))
	end
	
	
	-- Create box2d physical object
	local body = Self.B2_Worlds[world_id]:createBody{
		type = B2_BodyType, 
		position = {x = obj.x + obj.width / 2, y = obj.y + obj.height / 2},
		angle = B2_Angle,
		linearVelocity = B2_LinearVelocity,
		angularVelocity = B2_AngularVelocity,
		linearDamping = B2_LinearDamping,
		angularDamping = B2_AngularDamping,
		allowSleep = B2_AllowSleep,
		awake = B2_Awake,
		fixedRotation = B2_FixedRotation,
		bullet = B2_Bullet,
		active = B2_Active,
		gravityScale = B2_GravityScale
		}

	-- Create Box2D fixture based on properties
	local fixture = body:createFixture{
		shape = B2_Shape, 
		density = B2_Density, 
		friction = B2_Friction, 
		restitution = B2_Restitution,
		isSensor = B2_IsSensor}

	body.world_id = world_id
	
	-- Add Custom Properties
	-- iterate properties and add those to body who are starting with underscore _
	for k, v in pairs(obj.properties) do 
		if string.sub(k, 1, 1) == "_" then  
			body[k] = v
		end	
	end
	
	if obj.properties.NAME ~= nil then body.Name = obj.properties.NAME end
	
	return body

end

local function createSpriteFromBitmap(bitmap, layer, x, y)

	bitmap:setAnchorPoint(0.5, 0.5)
	
	local TempSprite = Sprite.new()
	
	TempSprite:setAlpha(layer.opacity)
	TempSprite:setPosition(((x - 1) * map.tilewidth) + bitmap:getWidth() / 2, 
							(y * map.tileheight) - bitmap:getHeight() / 2)

	local obj = bitmap.object

	if obj == nil then
		-- Create a new obj and get the body to assign it to bitmap
		obj = {}
		obj.properties = layer.properties
		obj.width = bitmap:getWidth()
		obj.height = bitmap:getHeight()
		obj.x = TempSprite:getX() - obj.width / 2
		obj.y = TempSprite:getY() - obj.height / 2
		obj.shape = "rectangle"
		if obj.properties.BodyShape == "circle" then obj.shape = "ellipse" end
		obj.properties.Angle = bitmap:getRotation()
		bitmap:setRotation(0)
	end
	
	
	--animation
	if obj.properties.TNTAnimation == "true" then
		IncludeTNTAnimator()
		local TNTAnimTexturePack = TexturePack.new(obj.properties.TNTAnimationFiles .. ".txt", obj.properties.TNTAnimationFiles .. ".png")
		local TNTAnimLoader = CTNTAnimatorLoader.new()
		TNTAnimLoader:loadAnimations(obj.properties.TNTAnimationFiles .. ".tan", TNTAnimTexturePack, obj.properties.TNTAnimationMidHandler or true)
		TempSprite.anim = CTNTAnimator.new(TNTAnimLoader)
		if obj.properties.TNTInitialAnimation ~= nil then TempSprite.anim:setAnimation(obj.properties.TNTInitialAnimation) end
		TempSprite.anim:playAnimation()
		TempSprite.anim:addToParent(TempSprite)
		
		-- To be able to free these later
		Self.TNTAnimations[#Self.TNTAnimations + 1] = TempSprite.anim
		Self.TNTAnimationLoaders[#Self.TNTAnimationLoaders + 1] = TNTAnimLoader
	else
		TempSprite:addChild(bitmap)
	end


	if layer.properties.NoPhysicsBody == nil then
		IncludeBox2D()		
		TempSprite.body = createBodyFromObject(obj)
	end
	
	-- Add Custom Properties
	-- iterate properties and implement those starting with underscore _
	for k, v in pairs(obj.properties) do 
		if string.sub(k, 1, 1) == "_" then  
			TempSprite[k] = v
		end	
	end
	
	Self:addChild(TempSprite)
	
	Self.Sprites[obj.properties.NAME or #Self.Sprites + 1] = TempSprite

end

-- Gets image information and sets as background
-- Not implemented yet, see file comments above
local function createBackground(layer)
	local bgImg = Bitmap.new(Texture.new(layer.image))
	
	bgImg:setPosition(0, 0)
	
	Self:addChild(bgImg)
	
	Self.Images[layer.properties.NAME or #Self.Images + 1] = bgImg
end

-- Create tiles and add to self
local function createTiles(layer)

	if layer.properties.TilesetName == nil then return end
		
	IncludeBitOp()
	
	-- Get tileset information and texture
	local tileset = getTileset(layer.properties.TilesetName)
	tileset.sizex = math.floor((tileset.imagewidth - tileset.margin + tileset.spacing) / (tileset.tilewidth + tileset.spacing))
	tileset.sizey = math.floor((tileset.imageheight - tileset.margin + tileset.spacing) / (tileset.tileheight + tileset.spacing))	
	tileset.texture = Texture.new(tileset.image)
	
	-- Create TileMap instance (a very useful class that comes with Gideros)
	tilemap = TileMap.new(layer.width, layer.height,
							tileset.texture, tileset.tilewidth, tileset.tileheight,
							tileset.spacing, tileset.spacing, tileset.margin, tileset.margin,
							map.tilewidth, map.tileheight)
	
	-- Variables to let us know if the tile is flipped or rotated
	local flipHor, flipVer, flipDia = 0, 0, 0

	-- Iterate all tiles and draw to sprite
	for y=1,layer.height do
		for x=1,layer.width do
			local i = x + (y - 1) * layer.width
			
			-- Get Global_index_ID of tile which holds all information
			local gid = layer.data[i]
			
			-- If not empty tile
			if gid ~= 0 then
				-- Read flipping flags
				flipHor = bit.band(gid, FLIPPED_HORIZONTALLY_FLAG)
				flipVer = bit.band(gid, FLIPPED_VERTICALLY_FLAG)
				flipDia = bit.band(gid, FLIPPED_DIAGONALLY_FLAG)
				
				-- Convert flags to gideros style
				if(flipHor ~= 0) then flipHor = TileMap.FLIP_HORIZONTAL end
				if(flipVer ~= 0) then flipVer = TileMap.FLIP_VERTICAL end
				if(flipDia ~= 0) then flipDia = TileMap.FLIP_DIAGONAL end

				-- Clear the flags from gid so other information is healthy
				gid = bit.band(gid, bit.bnot(bit.bor(FLIPPED_HORIZONTALLY_FLAG, FLIPPED_VERTICALLY_FLAG, FLIPPED_DIAGONALLY_FLAG)))
				
				-- Find corresponding texture
				local tx = (gid - tileset.firstgid) % tileset.sizex + 1
				local ty = math.floor((gid - tileset.firstgid) / tileset.sizex) + 1
				
				-- Set the tile with flip info
				tilemap:setTile(x, y, tx, ty, bit.bor(flipHor, flipVer, flipDia))
				
				-- Reset vars, so they dont confuse us in the next iteration
				flipHor, flipVer, flipDia = 0, 0, 0
			end
		end
	end
	
	-- Set opacity (can be defined in Tiled)
	tilemap:setAlpha(layer.opacity)

	-- Add to sprite
	Self:addChild(tilemap)
	
	Self.Tilemaps[layer.properties.NAME or #Self.Tilemaps + 1] = tilemap
end

-- Create physical Box2D world
local function createWorld(layer)

	IncludeBox2D()
	
	-- If no bounding sprite, create object only (STATIC_BODY)
	-- if any bounding sprites (first obj, then layer) create those along with body
	for i = 1, #layer.objects do
		
		-- copy layer properties to object properties (if it is not already set in object properties)
		for k, v in pairs(layer.properties) do 
			if layer.objects[i].properties[k] == nil then  
				layer.objects[i].properties[k] = v
			end
		end
		
		-- Cut out region from TileMap is not implemented yet
		-- Or concat tiles to make a new sprite is not implemented yet
		-- So only create object, (no bounding property yet)
		--if layer.objects[i].properties.Bounding_Sprite_Layer_Name ~= nil then
		--	local bounding_layer = getLayer(layer.objects[i].properties.Bounding_Sprite_Layer_Name)
		--	createBoundingObject(layer.objects[i], bounding_layer)
		--else
			--Create each world object based on properties
			createBodyFromObject(layer.objects[i])
		--end
	end

end

local function createSprites(layer)

	IncludeBitOp()

	if layer.properties.TilesetName == nil then return end

	-- Get tileset information and texture
	local tileset = getTileset(layer.properties.TilesetName)
	tileset.sizex = math.floor((tileset.imagewidth - tileset.margin + tileset.spacing) / (tileset.tilewidth + tileset.spacing))
	tileset.sizey = math.floor((tileset.imageheight - tileset.margin + tileset.spacing) / (tileset.tileheight + tileset.spacing))	
	tileset.texture = Texture.new(tileset.image)

	-- Variables to let us know if the tile is flipped or rotated
	local flipHor, flipVer, flipDia = 0, 0, 0

	local m11, m12, m21, m22, dx, dy = 1,0,0,1,0,0
	-- Iterate all tiles and draw to sprite
	for y=1,layer.height do
		for x=1,layer.width do
			local i = x + (y - 1) * layer.width
			
			-- Get Global_index_ID of tile which holds all information
			local gid = layer.data[i]
			
			-- If not empty tile
			if gid ~= 0 then
				-- Read flipping flags
				flipHor = bit.band(gid, FLIPPED_HORIZONTALLY_FLAG)
				flipVer = bit.band(gid, FLIPPED_VERTICALLY_FLAG)
				flipDia = bit.band(gid, FLIPPED_DIAGONALLY_FLAG)
				
				-- Clear the flags from gid so other information is healthy
				gid = bit.band(gid, bit.bnot(bit.bor(FLIPPED_HORIZONTALLY_FLAG, FLIPPED_VERTICALLY_FLAG, FLIPPED_DIAGONALLY_FLAG)))
				
				-- Convert flags to gideros style
				if(flipHor ~= 0) then flipHor = TileMap.FLIP_HORIZONTAL end
				if(flipVer ~= 0) then flipVer = TileMap.FLIP_VERTICAL end
				if(flipDia ~= 0) then flipDia = TileMap.FLIP_DIAGONAL end
				
				-- Find corresponding texture
				local tx = (gid - tileset.firstgid) % tileset.sizex
				local ty = math.floor((gid - tileset.firstgid) / tileset.sizex)
				
				-- Get the tile and create seperate sprite
				local bitmap = Bitmap.new(TextureRegion.new(
					tileset.texture, 
					tileset.margin + tx * (tileset.tilewidth + tileset.spacing), 
					tileset.margin + ty * (tileset.tileheight + tileset.spacing), 
					tileset.tilewidth, tileset.tileheight))
				
				--print(gid)
				--print(tileset.sizex, tileset.sizey, tileset.tilewidth, tileset.tileheight, tileset.spacing, tileset.margin)
				--print(map.tilewidth, map.tileheight)
				--print(x, y, flipHor, flipVer, flipDia)
				
				if flipHor == TileMap.FLIP_HORIZONTAL then
					m11 = -m11
					m21 = -m21
					--tx = tx + bitmap:getWidth()
				end
				
				if flipVer == TileMap.FLIP_VERTICAL then
					m12 = -m12
					m22 = -m22
					--ty = ty + bitmap:getHeight()
				end
				
				if flipDia == TileMap.FLIP_DIAGONAL then 
					m11, m12 = m12, m11
					m21, m22 = m22, m21
				end
				
				bitmap:setMatrix(Matrix.new(m11, m12, m21, m22, dx, dy))
				
				createSpriteFromBitmap(bitmap, layer, x, y)
				
				-- Reset vars, so they dont confuse us in the next iteration
				flipHor, flipVer, flipDia = 0, 0, 0
				m11, m12, m21, m22, dx, dy = 1,0,0,1,0,0
			end
		end
	end
	
end


local function drawLayers()

	for index = 1, #map.layers do
		if map.layers[index].visible ~= false then
			if map.layers[index].properties.NoDraw == nil then
				if map.layers[index].properties.DrawType == "Tile" then
					createTiles(map.layers[index])
				elseif map.layers[index].properties.DrawType == "Sprite" then
					createSprites(map.layers[index])
				elseif map.layers[index].properties.DrawType == "Background" then
					-- Not yet implemented, see notes on github readme
					createBackground(map.layers[index])
				elseif map.layers[index].properties.DrawType == "Object" then
					-- Create physics world
					createWorld(map.layers[index])
				else
					print ('Unknown layer type', map.layers[index].properties.DrawType)
				end
			end
		end
	end		

end

-- Constructor
function TiledAsWorldEditor:init(filename)

	Self = self;
	
	-- Make self a display group so, all child objects are updated in physics step
	Self.group = true
	
	-- Assign all created worlds (if any) to a 'worlds' property, images, tilemaps, sprites (they may be needed in scene)
	Self.B2_Worlds = {}
	Self.Images = {}
	Self.Tilemaps = {}
	Self.Sprites = {}
	Self.TNTAnimations = {}
	Self.TNTAnimationLoaders = {}
	
	Self.paused = false;
	
	map = loadfile(filename)()
	
	-- Iterate and create layer based on type
	drawLayers()
	
	-- Add Update and Exit functions
	--run world
	Self:addEventListener(Event.ENTER_FRAME, Self.onEnterFrame, Self)
	
	--remove event on exiting scene
	Self:addEventListener("exitBegin", Self.onExitBegin, Self)
end

function TiledAsWorldEditor:FreeResources()

	for k, v in pairs(Self.TNTAnimations) do 
		v:free()
	end

	for k, v in pairs(Self.TNTAnimationLoaders) do 
		v:Free()
	end

end

function TiledAsWorldEditor:Pause()

	Self.paused = true
	
	for k, v in pairs(Self.TNTAnimations) do 
		v:stopAnimation()
	end
	
end

function TiledAsWorldEditor:UnPause()

	Self.paused = false
	
	for k, v in pairs(Self.TNTAnimations) do 
		v:playAnimation()
	end

end


-- ***
-- Debug Drawing
-- ***

function TiledAsWorldEditor:EnableDebugDrawing(world_id)

	if world_id == nil then
		for k,v in pairs(Self.B2_Worlds) do
			local debugDraw = b2.DebugDraw.new()
			v:setDebugDraw(debugDraw)
			Self:addChild(debugDraw)
			v.DebugDraw = debugDraw
		end
	else
		local debugDraw = b2.DebugDraw.new()
		Self.B2_Worlds[world_id]:setDebugDraw(debugDraw)
		Self:addChild(debugDraw)
		Self.B2_Worlds[world_id].DebugDraw = debugDraw
	end

end

function TiledAsWorldEditor:DisableDebugDrawing(world_id)

	if world_id == nil then
		for k,v in pairs(Self.B2_Worlds) do
			v:setDebugDraw(nil)
			if v.DebugDraw ~= nil then 
				Self:removeChild(v.DebugDraw) 
				v.DebugDraw = nil
			end
		end
	else
		Self.B2_Worlds[world_id]:setDebugDraw(nil)
		if Self.B2_Worlds[world_id].DebugDraw ~= nil then
			Self:removeChild(Self.B2_Worlds[world_id].DebugDraw)
			Self.B2_Worlds[world_id].DebugDraw = nil
		end
	end
	
end


-- ***
-- Physics
-- ***

local function updatePosition(object)
	local body = object.body
	local bodyX, bodyY = body:getPosition()
	object:setPosition(bodyX, bodyY)
	object:setRotation(body:getAngle() * 57.2957795131)
	-- 180 / math.pi = 57.2957795131
end
 
local function updatePhysicsObjects(physWorld, scope)
	physWorld:step(1/60, 8, 3)	-- edit the step values if required. These are good defaults!
	for i = 1, scope:getNumChildren() do
		local sprite = scope:getChildAt(i)
		-- determine if this is a sprite, or a group
		if sprite.group == nil then
			local body = sprite.body
			-- if it's not a group, but HAS a body (ie, it's a physical object directly on the stage)
			if body then
				updatePosition(sprite)
			else 
 
			end
		elseif sprite.group == true then
			-- if it IS a group, then iterate through the groups children
			for j = 1, sprite:getNumChildren() do
				local childSprite = sprite:getChildAt(j)
				local body = childSprite.body
				if body then
					updatePosition(childSprite)
				end				
			end
		end
	end
end


-- ***
-- Events
-- ***

function TiledAsWorldEditor:onEnterFrame()
	if not Self.paused then
		for k,v in pairs(Self.B2_Worlds) do
			updatePhysicsObjects(v, Self)
		end
	end
end

--removing event on exiting scene
function TiledAsWorldEditor:onExitBegin()
  Self:removeEventListener(Event.ENTER_FRAME, Self.onEnterFrame, Self)
  Self:FreeResources()
end
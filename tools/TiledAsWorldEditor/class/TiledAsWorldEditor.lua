--[[
   Author:	1.44mb
   Date:	December 19, 2012
   
   Lua class that allows Tiled Editor (http://mapeditor.org)
   to be used as a world and physics editor for Gideros Studio.
   
   This class is heavily based on @atilim's TileMap example.
   But modified and extended.

   Please see https://github.com/1dot44mb/gideros/tree/master/tools/TiledAsWorldEditor
   for further detail, usage instructions, video tutorial and examples.
   
   Arguments:
      filename is the path to .lua file exported from Tiled.
	  
   Needs 'bit' plugin to work properly.
   
   Additional Information:
	  Flipping and rotation code example (C++): https://github.com/bjorn/tiled/wiki/TMX-Map-Format (look at <layer> -> <data>)
--]]

-- Get plugins
require "box2d"
require "bit"

TiledAsWorldEditor = Core.class(Sprite)

-- Reference for variables to be used among different functions when creating world
local map
local tilemap

-- Variables that defines corresponding names
-- These must be the same with corresponding name in Tiled
local Name_of_layer_for_background = "Level-Background"
local Name_of_layer_for_collision_bodies = "Level-B2Bodies"
local Name_of_layer_for_level = "Level-Tiles"
local Name_of_tileset_for_level = "Level-Tileset"

-- Physics properties to be applied to objects when no property is set in Tiled
local Density_default = 1.0
local Friction_default = 0.1
local Restitution_default = 0.8

-- Physics properties to be applied to world when no property is set in Tiled
local GravityX_default = 0
local GravityY_default = 10

-- Constructor
function TiledAsWorldEditor:init(filename)

	map = loadfile(filename)()
	
	-- Not yet implemented, see notes on github readme
	--self:createBackground()
	
	-- Create tiles (very explanatory comment)
	self:createTiles(map)
	
	-- Create world (i did it again) (OK, create physics world)
	self:createWorld()
	
end

-- Gets tileset from exported map
function TiledAsWorldEditor:getTileset(name)
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
function TiledAsWorldEditor:getLayer(name)

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
function TiledAsWorldEditor:getProperty(item, name)
	
	-- if we have an item and 
	if item and name and type(item) == 'table' and type(name) == 'string' then
		
		for k, v in pairs(item.properties) do 
			
			if k == name then  
				
				return v
				
			end	
			
		end
		
	end
	
end

-- Gets image information and sets as background
-- Not implemented yet, see file comments above
function TiledAsWorldEditor:createBackground()
	local bgLayer = self:getLayer(Name_of_layer_for_background)
	
	local bgImg = Bitmap.new(Texture.new(bgLayer.image))
	
	bgImg:setPosition(0, 0)
	
	self:addChild(bgImg)
end

-- Create tiles and add to self
function TiledAsWorldEditor:createTiles(map)

	-- Get tileset information and texture
	local tileset = self:getTileset(Name_of_tileset_for_level)
	tileset.sizex = math.floor((tileset.imagewidth - tileset.margin + tileset.spacing) / (tileset.tilewidth + tileset.spacing))
	tileset.sizey = math.floor((tileset.imageheight - tileset.margin + tileset.spacing) / (tileset.tileheight + tileset.spacing))	
	tileset.texture = Texture.new(tileset.image)

	-- Get tile layer
	local layer = self:getLayer(Name_of_layer_for_level)
	
	-- Create TileMap instance (a very useful class that comes with Gideros)
	tilemap = TileMap.new(layer.width, layer.height,
							tileset.texture, tileset.tilewidth, tileset.tileheight,
							tileset.spacing, tileset.spacing, tileset.margin, tileset.margin,
							map.tilewidth, map.tileheight)
	
	-- Bits on the far end of the 32-bit global tile ID are used for tile flags
	local FLIPPED_HORIZONTALLY_FLAG = 0x80000000;
	local FLIPPED_VERTICALLY_FLAG   = 0x40000000;
	local FLIPPED_DIAGONALLY_FLAG   = 0x20000000;
	
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
	self:addChild(tilemap)
end

-- Create physical Box2D world
function TiledAsWorldEditor:createWorld()
	
	-- Create a world variable with defined properties
	self.world = b2.World.new(map.properties.GravityX or GravityX_default, map.properties.GravityY or GravityY_default, true)
	
	-- Get the object layer
	local layer = self:getLayer(Name_of_layer_for_collision_bodies)
	
	-- Create the objects from the tilemap objects layer
	for i = 1, #layer.objects do
		--Create each world object based on properties
		self:createObject(layer.objects[i])
	end

end

-- Creates objects based on their properties
function TiledAsWorldEditor:createObject(obj)
	
	-- Create Box2D physical object
	local body = self.world:createBody{type = b2.STATIC_BODY}
	
	-- Set Box2D objects position same as object's position from Tiled
	body:setPosition(obj.x + obj.width / 2, obj.y + obj.height / 2)
	
	-- Angle is set to 0 for now as all objects are STATIC bodies
	-- Will be able to change angle when KINEMATIC and DYNAMIC body support is added
	body:setAngle(0)
	
	-- Create a generic shape variable
	local shape

	-- Get the actual shape of object set in Tiled and create Box2D object based on that
	if obj.shape == "rectangle" then
		shape = b2.PolygonShape.new()
		shape:setAsBox(obj.width / 2, obj.height / 2)
	elseif obj.shape == "ellipse" then
		shape = b2.CircleShape.new(0, 0, obj.width / 2)
		-- For now, all ellipses are considered perfect circles
		-- Because Box2D does not let you create ellipses
		-- if obj.width ~= obj.height, than this is an ellipse
		-- In the future we will add a polygon approximation of ellipse, see upcoming features on github readme
	elseif obj.shape == "polygon" then
		shape = b2.PolygonShape.new()
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
		shape:set(unpack(vertices))
		
		-- Some of you may say why don't you let the user draw in clockwise order in Tiled
		-- and make a normal iteration.
		-- While this is true, i personally never like to tend to change the user behaviours
		-- Google about polygons and box2d, you will see that it is a standart to create polygons in ccw order
		-- So i just don't want to change that.
		
	elseif obj.shape == "polyline" then
		-- Create polyline
		shape = b2.ChainShape.new()
		vertices = {}
		for i = 1, #obj.polyline do
			vertices[i * 2 - 1] = obj.polyline[i].x
			vertices[i * 2] = obj.polyline[i].y
		end
		shape:createChain(unpack(vertices))
	end
	
	-- Get physical properties and create Box2D object based on them
	local fixture = body:createFixture{
						shape = shape, 
						density = obj.properties.Density or Density_default ,
						friction = obj.properties.Friction or Friction_default ,
						restitution = obj.properties.Restitution or Restitution_default}	
end
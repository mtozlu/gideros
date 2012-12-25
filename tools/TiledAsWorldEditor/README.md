# *Tiled* As World Editor v2

## Use *Tiled* (http://mapeditor.org) as a world editor.

You can use *Tiled* to create worlds and levels for your *Gideros* game.

### Watch video showcase:  http://youtu.be/vaYyq4WUAjw

## Features
- Add actors from Tiled
- Attach Dynamic, Kinematic or Static bodies to actors and object from Tiled with fixture and body properties
- Create sprites with physical body, not only tiles
- Add animations (TNT Animations)
- You can include box2d physics properties right in the Tiled Editor and **TiledAsWorldEditor** will recognise all kinds of shapes (circle, polygon, polyline, rectangle) and create your world as described in Tiled Editor.
- Create multiple worlds if necessary. Just assign WorldID to any layer or object with world creation parameters
- Tile rotations (by pressing *Z* button) and flippings (by pressing *X* and *Y* buttons for horizontal and vertical respectively) from *Tiled* are supported too.
- Enable / Disable debug drawing
- Physics body angle from tile flippings and rotations
- Physics run automatically
- Pause / Unpause
- Custom properties from Tiled will be added to your sprites and objects
- All body, fixture and world creation parameters are supported (see Gideros Reference Manual for all parameters)
- Library inclusions are not done if not needed. They will be included lazily in any need. For performance.
- Add NoPhysicsBody property if you want a sprite not to have physics body
- Supports layer transparency
- If the layer is not visible in Tiled, it will not be drawn
- Assign any name to your layer, just indicate DrawType property as Tile or Sprite, etc(you had to enter specific names for layers before)
- Supports multiple tilesets

  
  
**There are some rules to obey when creating world**
* Box2D assumes polygons' vertices are in counter clockwise order, so make sure to create them in counter clockwise order in Tiled Editor.
* Box2D polygon vertices count must be between 3 and 8. Box2D throws exception otherwise. Combine polygons for bigger or more detailed shapes.
* Polylines will not collide properly if there are self-intersections.
* Right now only perfect circles can be created as ellipses are not supported in Box2D. You can create a perfect circle by holding Shift (with circle tool selected) in *Tiled*. You can create an ellipse too if you want, but this class will assume all ellipses are perfect circles (it gets *obj.width / 2* as radius, so height does not matter. This is a limitation of Box2D, in the future, ellipse shapes will be supported in this class by converting them to approximated polygons.
* If draw type is *Tile* for a layer; you can not assign DYNAMIC or KINEMATIC physics behaviour. It is STATIC by default.
* If a sprite has body property (sprite.body ~= nil) then it has a body in physical world. The world_id that the body belongs to is in body.world_id property.
* You must assing *TilesetName* property with the corresponding tileset's name for each layer or they will not be drawn.
* Angle property must be set in degrees.

## Usage

    Download example project or follow these steps:
	
1. You must enable *bit* plugin because this class makes use of bitwise operations for tile rotatins and flippings. *Bit* plugin comes with *Gideros Studio* however it is not enabled by default. To enable it: (taken from @atilim's post here: http://www.giderosmobile.com/forum/discussion/2106/bitwise-operations-on-gideros-mobile#Item_5)
	* For MacOS: copy "/Applications/Gideros Studio/All Plugins/BitOp/bin/Mac OS/bitop.dylib" to "/Applications/Gideros Studio/Plugins" and restart the desktop player.
	* For Windows: copy "/Program Files/Gideros/All Plugins/BitOp/bin/Windows/bitop.dll" to "/Program Files/Gideros/Plugins" and restart the desktop player.
	* For iOS, add bit.c and bit_stub.cpp in the folder "/Applications/Gideros Studio/All Plugins/BitOp/source" to the Xcode project and redeploy the iOS player.
2. Include *TiledAsWorldEditor.lua* in your project
3. Go to Tiled and draw your world (see rules above)
4. Assign properties to your objects and layers.
5. Save your level and export to lua.
6. In your scene

  ```
  -- Load the level in the scene
  local level = TiledAsWorldEditor.new("Assets/Level/prototypeLevel.lua")
  
  --Add it to scene
  self:addChild(level)
  ```
	
*See example game to see actor attached to the world*

## Upcoming features
* A property on *Tiled* object called *IsBoundToTile* along with KINEMATIC and DYNAMIC body support will be added which enables physical behaviour of tiles that the object includes.
* Background Layers and their parallax, repetition, etc properties, once it is implemented in *Tiled* (see below, *Notes on current version*)
* Assign collision categories. Generation of events when actors collide with each other (eg: Player vs Enemy, Bullet vs Enemy, Player vs Cactus :) )
* Add Scene Manager support
* Create menus using buttons that change scenes


### Notes on current version
* Tiled 0.8.1.168 (Daily build dated: 2012.12.17) was used for testing this class. The reason for using a daily build is; latest stable release does not let you draw circle shapes in objects layer, but latest daily build lets. (You can see the list of daily builds at the bottom of the downloads section on http://mapeditor.org)
* Background images are not implemented because *Tiled Editor* does not include image layer info in exported file (you can track issue here (https://github.com/bjorn/tiled/issues/320), when it is implemented, this class will support background images as well as their parallax, repetition, etc.)
* In Tiled, you can not assign properties to Tiles in scene (not in tileset). So to have specific properties for tiles, you must set those properties in Layer Properties. If there are multiple tiles in a layer, all will inherit its properties from Layer Properties. So if you want to have unique properties for an object, you must create a new Layer, put that Tile only (so it is the only Tile in that layer) than assign properties to that Layer.

* You can set NAME property in Tiled layers or objects and they will be assigned to corresponding Sprite or Object.
	- The NAME property will also be applied to Sprite.body.Name, so you can get them in Collision Events

* To enable or disable debug drawing, use: TiledAsWorldEditorInstance:EnableDebugDrawing() or TiledAsWorldEditorInstance:DisableDebugDrawing()
	- Alternatively you can send world id parameter to these functions which will enablr or disable debug drawing for only that world

* If you want to add your custom sprite after the world is created, you can add TiledAsWorldEditorInstance:addChild(your sprite)
	- If your sprite has a body property defined (a box2d body) it will be calculated in physics operations

* EnterFrame and ExitBegin events are run inside the class

* Use TiledAsWorldEditorInstance:Pause() or TiledAsWorldEditorInstance:Unpause() to pause / unpause game

* Animations
	- If set in layer properties, all sprites in that layer will be animated
	- Don't forget to set Path_to_TNTAnimator in defaults, (without 32 or 64, class will decide that)
	
* Add custom properties with underscore in Tiled (like _CoinType) and they will be added to your object, sprite, etc
	- You can get them later like TiledAsWorldEditorInstance.Sprites[MyCustomName]._CustomProperty
	- Same custom properties are added to body object too if the sprite has a physical body. This way you can access same custom properties in Collision events (body._MyCustomProp)
	
* If you don't want a sprite to have physics body, just add NoPhysicsBody property to that layer, so all sprite in that layer won't have physics body

* If you make the Layer invisible in Tiled, it will not be drawn. (By clicking checkbox near layer name in Tiled)

* If you want to create multiple worlds; assign World_ID property to object or layer. To set GravityX, GravityY and DoSleep property, just indicate them too.
	
## Manual
### Defaults
*These are the default values for some properties which you can set in TiledAsWorldEditor.lua file.*
```
Density_default = 1.0
Friction_default = 0.1
Restitution_default = 0.8

GravityX_default = 0
GravityY_default = 9.81

-- Write path to TNTAnimator here. It will automatically include 32bit or 64bit version depending on the system. So dont put 32 or 64 to the tail.
Path_to_TNTAnimator = "tntanimator"
```

### Variables
*These are the variables which you can use later in your scene. They give access to specific objects in your worlds.*
*You can get the thing you need by TiledAsWorldEditorInstance.Sprites[SpriteName]*
*The name property is applied to body of sprite too (to get in collision events) (Sprites[MyName].body.Name will be MyName too)*
*If NAME property is not specified in Tiled, then increasing numbers are used like Sprites[1], Sprites[2], etc*
```
B2_Worlds = {} -- Box2d worlds
Images = {} -- Images (no image yet as image layer export is not supported yet in Tiled)
Tilemaps = {} -- Tilemaps (those who have DrawType property set to Tile)
Sprites = {} -- Sprites (those who have DrawType property set to Sprite)
TNTAnimations = {} -- (by default, all animation are held in *anim* property of its own sprite, but all of the animations will be put in this table too)
TNTAnimationLoaders = {} --this is for self reference to free resources later
```
```	
-- Get worlds and others like
-- (because they are dictionary tables, not arrays)
for k,v in pairs(TiledAsWorldEditorInstance.B2_Worlds) do 
	print(k,v) 
end
```

### Properties
```
-- The name of this particular object or image or sprite to be held in TiledAsWorldEditor.Sprites, Images, Tilemaps
NAME

-- to create new world
	World_ID : if not set, a single world will be created, if a world alredy exists, the sprite or object will be assigned to that world
	GravityX : taken from defaults if not set
	GravityY : taken from defaults if not set
	Do_Sleep : improve performance by not simulating inactive bodies (true, if not set)
	
DrawType = {Tile, Sprite, Background, Object}
NoDraw : if set, this layer will not be drawn, useful when you have seperate object layer for collisions of this layer
NoPhysicsBody : if set, objects physical body won't be added (so it is only a sprite)
TilesetName : this must be set, or the layer will not be drawn because it is not clear which tileset is used for that layer (that means, for now you can not use multiple tilesets to draw a layer. Use seperate layer for each tileset to achieve that)
World_ID = The id of the world this sprite belongs (if not set default world will be used) (this can be set in layer props or object props for objects) (object props>layer props>default always)

--Body Definitions (see gideros manual for more info on these properties)
BodyType = {static, dynamic, kinematic} (considered static if not set)
Angle = number (in degrees) (considered 0 if not set) (if this is not set, the body angle and sprite angle will be determined from tile rotation and flippings)
LinearVelocityX = number (considered 0 if not set)
LinearVelocityY = number (considered 0 if not set)
AngularVelocity = number (considered 0 if not set)
LinearDamping = number (considered 0 if not set) (can exceed 1.0 but it is better that it is between 0.0 and 1.0)
AngularDamping = number (considered 0 if not set) (can exceed 1.0 but it is better that it is between 0.0 and 1.0)
AllowSleep = {true, false} (considered true if not set)
Awake = {true, false} (considered true if not set)
FixedRotation = {true, false} (considered false if not set)
Bullet = {true, false} (considered false if not set)
Active = {true, false} (considered true if not set)
GravityScale = number (considered 1 if not set which does not have any effect)

--Fixture Definitions
BodyShape = {rectangle, circle} (considered rectangle with texture width, height if not set)
	(if rectangle; width and height are calculated from sprite)
	(if circle; width / 2 is taken as radius)
Density (taken from default values if not set)
Friction (taken from default values if not set)
Restitution (taken from default values if not set)
IsSensor (considered false if not set)

--Animation (in layer props. So if you want to animate a sprite, it must be the only tile in layer, otherwise these properties are applied to all tiles in layer)
TNTAnimation : if true, TNT animation will be created
TNTAnimationFiles: Only the first name of the file for Texture, TextureInfo and Animator Project (all of them must be same name)(only one variable because of too much assignments)
TNTInitialAnimation: Initial animation to be set (must be all uppercase, as TNTAnimator suggests)
TNTAnimationMidHandler: If set to false, animations anchor points will be top-left, it left blank, anchor will be middle (considered true if not set)
```

### Methods
```
TiledAsWorldEditorInstance:FreeResources() -- by default, the resources are freed on scene exit (in exitBegin). But maybe you want to use this elsewhere.
TiledAsWorldEditorInstance:Pause() -- Pauses the world
TiledAsWorldEditorInstance:Unpause() -- Unpauses the world
TiledAsWorldEditorInstance:EnableDebugDrawing(world_id) (if no world_id specified then all worlds are set)
TiledAsWorldEditorInstance:DisableDebugDrawing(world_id) (if no world_id specified then all worlds are set)
```


#### Please help the tool improve by creating issues and suggesting features

## License
*TiledAsWorldEditor* is licensed under the MIT license. This means do not change license and owner info, other than that, do whatever you want. You may even print out the code and make paper planes out of it. But don't forget to recycle the paper.

All 3rd party libraries and tools used are distributed under their respective license terms.

```
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
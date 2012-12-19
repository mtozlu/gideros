# *Tiled* As World Editor
  *The main objective of this tool is to use Tiled Editor as a complete (tiles, physics, actors, behaviours, etc) game editor for Gideros Studio*

## Use *Tiled* (http://mapeditor.org) as a world editor.

You can use *Tiled* to create worlds and levels for your *Gideros* game.

You can include box2d physics properties right in the Tiled Editor and **TiledAsWorldEditor** will recognise all kinds of shapes (circle, polygon, polyline, rectangle) and create your world as described in Tiled Editor.

Tile rotations (by pressing *Z* button) and flippings (by pressing *X* and *Y* buttons for horizontal and vertical respectively) from *Tiled* are supported too.

Watch video tutorial: http://youtu.be/G1AHvqAY4U0

**There are some rules to obey when creating world**
* Your layer names must be the same as defined in *TiledAsWorldEditor.lua* file. The default layer names are (however you can change them as long as they are the same in lua file and tiled editor):
  * Collisions Layer Name: *Level-B2Bodies* (This must be an *object* layer)
  * World Layer Name: *Level-Tiles* (This must be a *tile* layer)
  * World Tileset Name: *Level-Tileset* (You can use multiple tilesets in *Tiled*, that is why, this class has to know which one to use when drawing tiles)
* Box2D assumes polygons' vertices are in counter clockwise order, so make sure to create them in counter clockwise order in Tiled Editor.
* Box2D polygon vertices count must be between 3 and 8. Box2D throws exception otherwise. Combine polygons for bigger or more detailed shapes.
* Polylines will not collide properly if there are self-intersections.
* Right now only perfect circles can be created as ellipses are not supported in Box2D. You can create a perfect circle by holding Shift (with circle tool selected) in *Tiled*. You can create an ellipse too if you want, but this class will assume all ellipses are perfect circles (it gets *obj.width / 2* as radius, so height does not matter. This is a limitation of Box2D, in the future, ellipse shapes will be supported in this class by converting them to approximated polygons.
  
## Usage

    Watch video tutorial here: http://youtu.be/G1AHvqAY4U0 or follow these steps:
	
1. You must enable *bit* plugin because this class makes use of bitwise operations for tile rotatins and flippings. *Bit* plugin comes with *Gideros Studio* however it is not enabled by default. To enable it: (taken from @atilim's post here: http://www.giderosmobile.com/forum/discussion/2106/bitwise-operations-on-gideros-mobile#Item_5)
	* For MacOS: copy "/Applications/Gideros Studio/All Plugins/BitOp/bin/Mac OS/bitop.dylib" to "/Applications/Gideros Studio/Plugins" and restart the desktop player.
	* For Windows: copy "/Program Files/Gideros/All Plugins/BitOp/bin/Windows/bitop.dll" to "/Program Files/Gideros/Plugins" and restart the desktop player.
	* For iOS, add bit.c and bit_stub.cpp in the folder "/Applications/Gideros Studio/All Plugins/BitOp/source" to the Xcode project and redeploy the iOS player.
2. Include *TiledAsWorldEditor.lua* in your project
3. Go to Tiled and draw your world with corresponding layer names (see rules above)
	* Go to Map->Map properties and set *GravityX* and *GravityY* as numbers, these will be used for world's gravity (if not set, default values will be used, which can be set in *TiledAsWorldEditor.lua*)
	* Draw tiles in a Tile layer
	* Draw objects in an Object layer (let them be circles, polygons, as you wish)
	* You may set opacity of your Tile layer, which will be properly drawn too
4. Assign *Box2D* fixture properties to your objects which are Density, Friction and Restitution (see documentation here: http://www.giderosmobile.com/documentation/reference_manual.html#b2.Body:createFixture ) (Note that body type is considered as STATIC even if you define otherwise, see Upcoming features) (If no properties are added, deafult values will be used, which can be set in *TiledAsWorldEditor.lua*)
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
* Right now, all objects are considered as STATIC_BODY in Box2D. KINEMATIC and DYNAMIC bodies are to be added.
* A property on *Tiled* object called *IsBoundToTile* along with KINEMATIC and DYNAMIC body support will be added which enables physical behaviour of tiles that the object includes.
* Background Layers and their parallax, repetition, etc properties, once it is implemented in *Tiled* (see below, *Notes on current version*)
* Usage of *displayImage* and *displayGroup* libraries (see: http://www.giderosmobile.com/forum/discussion/373/display-object-physics-helper-library#Item_1) because its abstraction is perfect and code can be migrated to any other sdk ( don't do that :) )
* Actor layers
* Trigger areas (as object layers in *Tiled*) that generates events when certain kind of actors step inside
* Generation of events when actors collide with each other (eg: Player vs Enemy, Bullet vs Enemy, Player vs Cactus :) )

### Notes on current version
* Tiled 0.8.1.168 (Daily build dated: 2012.12.17) was used for testing this class. The reason for using a daily build is; latest stable release does not let you draw circle shapes in objects layer, but latest daily build lets. (You can see the list of daily builds at the bottom of the downloads section on http://mapeditor.org)
* Background images are not implemented because *Tiled Editor* does not include image layer info in exported file (you can track issue here (https://github.com/bjorn/tiled/issues/320), when it is implemented, this class will support background images as well as their parallax, repetition, etc.)
* Right now, all objects are considered as STATIC_BODY in Box2D.

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

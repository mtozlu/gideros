Xeon tileset downloaded from http://opengameart.org/forumtopic/xeon-as-he-is-sprited

TiledAsWorldEditor's some features are showcased in this Example
They are:

+ Project creation (you see the project files in example)
+ Include TiledAsWorldEditor and check defaults (see TiledAsWorldEditor.lua defaults)
+ Create level in Tiled (see Level.tmx and check each layers properties to learn them)
+ Circle BodyShape for collectibles (Bodies for sprites are rectangle by default, we can set this to circle if we want)
+ Transparency (Stone From Other World has transparency in Tiled, so it has the same transparency in the scene too)
+ Visible / Not visible (A layer in Tiled is set to bi invisible by unchecking the visible checkbox, so you dont see it in the scene)
+ Different Worlds (see Stone From Other World layer's properties. We define a new world with differen gravity. You can see that it does not collide with objects in default world)
+ Fixture creation (see some layers properties, collectibles are kinematic so they dont fall down, they are sensor, meaning they generate collision events but they dont respond physically to collisions)
	+ Dynamic Body
	+ Kinematic and IsSensor (collectible)
+ Custom Properties (see that Collectibles layer has custom properties "_Points", you can see in Gideros Output window that we can easily get custom properties in collision events or at other times)
+ Collision Events (StartScene.lua has a very basic implementation of collision events. Watch for Gideros Output window for debug output of Collision Events)
+ Animations (Xeon character has animations. We prepared animations in TNT Animation Studio, and we set properties in Tiled and animated it)
+ Get Character from Sprites[] and assign movement (You can see that we get character by name, Sprites[Xeon] and we later assign movement and change animations easily. Try moving the joystick to move character around)
+ Pause / Unpause (Press Green button to pause unpause game)
+ Tile Rotations (You can see that rotated and flipped tiles are drawn correctly in game. The rotation angle is also correctly implemented if the sprite has a body too)
+ Debug Drawing (Press Blue button to enable debug and Yellow button to disable debug)

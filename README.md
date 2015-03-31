# ADHQ

### What is this repository for?

This repository contains the source code of the [Ancient Domain HQ R1](http://www.roblox.com/games/15947100/view?rbxp=1021552). This is released in the hope that someone may find a part of this project useful.

### How do I get set up?

Firstly, this project heavily depends on the class system located at https://github.com/Zytharian/LuaLibs 

So how do you get set up? In two words, you don't. While you may find parts of this project useful, it is unlikely that you will find all of it similarly. 

Additionally, the in-game hierarchy is as follows, leaving the workspace and model hierarchy to your imaginations and what can be gleamed from the source.

* Game.ServerScriptService
    * AD-Moderation
    * Server/ClassLoader
        * Everything in ServerClasses
    * Server/NetworkInitializer
    * Modules (Container)
        * Everything in ServerModules
        * From my LuaLibs repository: ClassSystem, StandardClasses, ModuleEnvUnpack
* Game.ReplicatedStorage
    * Everything in LocalModules
        * A Gui named ConsoleGui in the LocalModules/Gui
    * A SurfaceGui named TransporterSurfaceGui 
* Game.StarterGui
    * Everything in Local

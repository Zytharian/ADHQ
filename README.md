# ADHQ - Anquietas Videum

### What is this repository for?

This repository contains the source code of the final outpost, [Anquietas Videum](http://www.roblox.com/games/15947100/Anquietas-Videum), of the original [Ancient Domain](http://www.roblox.com/Groups/Group.aspx?gid=1092) roblox group. This is released in the hope that someone may find a part of this project useful. It additionally contains a mirror of the final version of the place.

### How do I get set up?

Firstly, this project heavily depends on the class system located in [this repository](https://github.com/Zytharian/LuaLibs). 

So how do you get set up? The easiest way is to open the place in edit mode to get a setup of the HQ's network that is already functional and work off of that. 

As a quick overview, the in-game hierarchy is as follows, leaving the workspace and model hierarchy to what you will find by opening the place in edit mode.

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
    * Everything in Local excluding subdirectories
* Game.ReplicatedStorage.StunnerModels["AD Stunner"]
	* Local/StunnerTool/L_StunnerHandler.lua
# Half-Life 2 Campaign for Garry's Mod
Play the original Half-Life 2 campaign in co-op mode with your friends online.

## Installation
Extract the zip to the following directory on your hard-drive:

`<Steam-directory>/steamapps/<Username>/garrysmod/garrysmod/gamemodes/`

## Running a Listen Server
Browse to the below directory and edit the sh_config.lua file to your liking.

`<Steam-directory>/steamapps/<Username>/garrysmod/garrysmod/gamemodes/half-life_2_campaign
/gamemode`

Next, start up Garry’s Mod and click Create Multiplayer at the main menu. Select the HL2 map of your choice and then click the Options tab. Set the Default Gamemode option to “half-life-2-campaign”. Set any other options you’d like and then click Start Game.

## Running a Dedicated Server
Note: Start with a fresh installation of SRCDS with just Garry's Mod installed.
Browse to the below directory and edit the sh_config.lua file to your liking. It will be assumed for the rest of these instructions that PLAY_EPISODE_1 and PLAY_EPISODE_2 are both set to 0.

`<Steam-directory>/steamapps/<Username>/garrysmod/garrysmod/gamemodes/`

Once your done, upload the entire half-life-2-campaign folder to the following location on your server.
`<SRCDS directory>/orangebox/garrysmod/gamemodes/`

Using GCF Scape extract the following folders to a temporary directory on your computer:
- “maps” and “scenes” folders from half-life 2 content.gcf
- “scripts” folder from source engine.gcf
- “materials” folder from source materials.gcf
- “models” folder from source models.gcf
- “sounds” folder from source sounds.gcf

Next extract the following folders to the same directory on your computer overwriting the existing files.
- “materials” folder from source 2007 materials.gcf
- “models” folder from source 2007 models.gcf
- “sounds” folder from source 2007 sounds.gcf

Then move/upload all the extracted folders to the following directory on your server overwriting any existing files.

`<SRCDS directory>/orangebox/hl2/`

Your directory tree should now look something like this:

``` 
<SRCDS directory>
  hl2
    <Shared Server Models, Materials, Sounds installed by SRCDS>
  orangebox
    bin
    garrysmod
      <GMod Folders>
    hl2
      maps
      materials
      models
      resource
      scenes
      scripts
      sounds
    platform
      <Platform Folders>
    relists
```

Lastly, you’ll need to set the default gamemode to run when your server starts up. Browse to the following directory and open up the game.cfg file with NotePad.

`<SRCDS directory>/orangebox/garrysmod/cfg/`

Add the following console command to the cfg file:
`sv_defaultgamemode "half-life_2_campaign"`

Alternatively, you can leave the default gamemode as sandbox and switch to HL2 Campaign on the fly with this console command:
`rcon changegamemode [map] half-life_2_campaign`

You can switch back to sandbox anytime with this command:
`rcon changegamemode [map] sandbox`

You’ll need to restart your server before the above commands/changes will work. Don’t forget to run “scriptenforce_createmanifest” and “sv_scriptenforcerenabled 1? to prevent against Lua cheats/hacks.'

## Console Commands
- `hl2c_admin_noclip [0, 1]` - If set to 1 admins will be allowed to noclip.
- `hl2c_admin_physgun [0, 1]` - If set to 1 admins will get the physgun when they spawn.
- `hl2c_next_map` - Goes to the next map.
- `hl2c_restart_map` - Restarts the map.

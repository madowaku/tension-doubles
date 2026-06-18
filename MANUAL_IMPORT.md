# Manual Import Guide for Roblox Studio

Use this if you do not want to use Rojo.

## 1. Create a new place

Open Roblox Studio → New → Baseplate.

Open:

- View → Explorer
- View → Properties

## 2. ReplicatedStorage

In `ReplicatedStorage`, create a Folder:

```text
TDShared
```

Inside `TDShared`, create two ModuleScripts:

```text
GameConfig
MathUtil
```

Paste the contents from:

```text
src/ReplicatedStorage/TDShared/GameConfig.lua
src/ReplicatedStorage/TDShared/MathUtil.lua
```

## 3. ServerScriptService

In `ServerScriptService`, create one Script:

```text
TDServer
```

Paste the contents from:

```text
src/ServerScriptService/TDServer.server.lua
```

If the screen is blank in Play mode, check this first: `ServerScriptService` must contain `TDServer`. Without `TDServer`, the lobby and `TensionDoublesRemotes` are never created, so the client HUD can only show the fallback warning.

Create one more Script:

```text
TDArenaBuilder
```

Paste the contents from:

```text
scripts/roblox/build_tile_field_64_arena.server.lua
```

When Play starts, this creates the reusable arena models:

```text
ServerStorage
├─ Arenas
│  ├─ Arena_Grass
│  ├─ Arena_Rooftop
│  ├─ Arena_School
│  ├─ Arena_Festival
│  └─ Arena_Space
└─ TDArena_TileField64
```

The playable arena models are kept in `ServerStorage/Arenas` so the selected court can be cloned into `Workspace` without mixing it into the lobby. `TDArena_TileField64` remains as the legacy Grass alias.

## 4. StarterPlayerScripts

Open:

```text
StarterPlayer
└─ StarterPlayerScripts
```

Create three LocalScripts:

```text
TDInputClient
TDCameraClient
TDUIClient
```

Paste the contents from:

```text
src/StarterPlayer/StarterPlayerScripts/TDInputClient.client.lua
src/StarterPlayer/StarterPlayerScripts/TDCameraClient.client.lua
src/StarterPlayer/StarterPlayerScripts/TDUIClient.client.lua
```

## 5. Test

Press Play.

Default testing mode allows solo play with ghost partners.

For real 2v2 play, edit `GameConfig.lua`:

```lua
AllowGhostPartners = false
MinPlayersToAutoStart = 4
```

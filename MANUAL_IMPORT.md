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


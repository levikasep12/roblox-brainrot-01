[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/levikasep12/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/levikasep12/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**[Brainrot Rush on make.fun →](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)**

# Brainrot Rush

A 3D Steal-a-Brainrot game for Roblox, written entirely in Luau and built with
Rojo. Meme characters walk a conveyor across a market square; you buy one, it
starts earning money on your base plot, and rival bases can be raided until
their owner buys a lock. Every so often a neon hazard wave sweeps the map and
you had better be standing on your own base.

## The loop

1. **Grab** — a brainrot walks the central conveyor. Walk up to it and press
   the prompt (or press **B** for the shop panel) to buy it. Money is deducted
   and the character flies to the first free pad on your base.
2. **Earn** — each housed brainrot pays its own `$`/second. Your HUD counts up
   continuously; the base's total rate is shown on the steal board.
3. **Climb** — eleven characters across five rarities, Common to Mythic. Buying
   a higher tier costs more and pays much more. Golden and Diamond mutations
   spawn rarely and multiply a character's rate.
4. **Steal** — walk onto another plot, hold the **Steal** prompt, and the
   brainrot moves to your pad. Fifteen seconds of cooldown between steals.
5. **Defend** — **LOCK BASE** buys 45 seconds of immunity. That is the only
   thing that stops a thief.
6. **Dash home** — a hazard wave announces itself eight seconds ahead, then
   sweeps altar-to-spawn. Off-base players are thrown home, damaged and lose a
   slice of their money. Your own base is safe ground.
7. **Rebirth** — reset money and every brainrot for a permanent income
   multiplier that carries across runs.

## Controls

| Input | Action |
| --- | --- |
| WASD / arrows | move (default Roblox camera and character) |
| Space | jump |
| Mouse wheel / right-drag | zoom and orbit the 3D camera |
| E / click | activate the nearby ProximityPrompt |
| B | open or close the shop |
| R | rebirth |
| L | buy a base lock |
| Escape | close the shop |

## Project layout

```
default.project.json        Rojo tree: services, Remotes, Workspace world
src/
  shared/                   ReplicatedStorage.Shared — pure data and definitions
    Config.luau             tuning: prices, plot layout, wave timing
    BrainrotDefs.luau       the eleven-character cast, rarities, mutations
    BrainrotModel.luau      builds a character Model from parts + BillboardGui
    Format.luau             money / rate / time formatting
  server/                   ServerScriptService.Server
    Store.luau              the single source of truth for all state
    WorldBuilder.luau       builds the whole 3D map in code
    Economy.luau            income, purchases, rebirth, the lock
    BaseService.luau        slot placement, plot signs, rival seeds
    Spawner.luau            the conveyor walkers and mutations
    Steal.luau              steal rules and the fly-home animation
    Events.luau             the hazard wave
    init.server.luau        wiring: remotes, prompts, player lifecycle
  client/                   StarterPlayer.StarterPlayerScripts.Client
    Hud.luau                money, multiplier, rebirth/lock, steal board
    Shop.luau               the buy panel
    init.client.luau        remotes, keys, sounds, feedback
```

State lives only on the server, in `Store.luau`. The client renders snapshots it
is sent and never decides a price, a rate or a steal.

## Build

```
rojo build default.project.json --output game.rbxl
```

## Submit

```
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` into the
output directory and writes `dossier.json` with the vendored make.fun library.
`PLAY.json` names the published place; fill it in after publishing from Studio.

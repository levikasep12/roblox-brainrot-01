[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/levikasep12/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/levikasep12/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

[Play Brainrot Rush on Roblox](https://www.roblox.com/games/0) - an entry for make.fun's "Make the best AI Roblox brainrot game" bounty.

# Brainrot Rush

A 3D steal-a-brainrot game. Six player base plots and two rival bases ring a conveyor belt where
absurd meme characters walk past. Buy one before it leaves the belt, park it on a slot, and it
pays you money every second. Climb the Common -> Rare -> Epic -> Legendary -> Mythic ladder, lock
your base against thieves, steal from the rival crews, and rebirth for a permanent multiplier
while a neon hazard wave periodically forces everyone to dash home.

Everything is built in code from plain Parts. No meshes, no uploaded assets, no asset IDs that
could fail to load.

## The world

- 360x300 grass island with a tiled plaza, path network, lamps, trees, bushes, fences and a
  spawn podium, all assembled by `src/shared/WorldBuilder.luau`.
- A 16-stud-wide conveyor belt with rails, chevrons, a spawn arch and an exit gate, spanning x =
  -80..84 through the middle of the map.
- Six player plots (`PlotLayout.Plots`, indexes 1-6) each with a floor, trim, back wall, side
  rails, six slot pads, an owner sign and a force-field base lock barrier.
- Two rival bases (indexes 7-8) that restock themselves with random brainrots, so a solo player
  always has somebody to steal from.
- A shop building with canopy, counter, three pedestals holding showcase brainrots, plus a
  rebirth altar with pillars, a neon orb and balloons.

## The brainrot cast

Eleven original characters, each modelled from Parts in `src/shared/BrainrotModel.luau`:

| Brainrot | Rarity | $/sec | Price |
| --- | --- | --- | --- |
| Capybara Chef | Common | 2 | 60 |
| Durian DJ | Common | 3.5 | 115 |
| Skibidi Toaster | Common | 5 | 180 |
| Cucumber Cowboy | Rare | 12 | 540 |
| Flamingo Accountant | Rare | 18 | 820 |
| Croissant Cactus | Epic | 45 | 2,900 |
| Raccoon Lawyer | Epic | 65 | 4,200 |
| Toilet Wizard | Legendary | 160 | 13,500 |
| Pigeon Overlord | Legendary | 230 | 19,500 |
| Mango Mafia Don | Mythic | 700 | 72,000 |
| Banana Bureaucrat | Mythic | 1,000 | 110,000 |

Every character carries a BillboardGui with its name, rarity, and money-per-second rate.

## Systems

- `Store.luau` - the single server-side state table: players, belt, rivals, hazard.
- `Economy.luau` - passive income, rebirth cost/payout, sell prices.
- `Spawner.luau` - belt spawning, walking, bobbing, buying and despawn at the gate.
- `Bases.luau` - builds and refreshes every 3D brainrot on every base, paints the lock.
- `Steal.luau` - range- and lock-checked stealing, plus buying a base lock.
- `Events.luau` - the hazard wave (warning -> sweeping wall -> x2 income cooldown) and rival restock.
- `PlayerService.luau` - join/leave, plot claims, dash-home, wave safety checks.
- Client: `Hud.luau`, `ShopUi.luau`, `CameraRig.luau`, `UiKit.luau`, `Main.client.luau`.

## Controls

- `E` - buy the nearest belt brainrot, sell from your own base, steal from a rival base (proximity
  prompts also do all three).
- `F` - steal the nearest brainrot in reach.
- `Q` - dash home (with a cooldown) - the answer to the hazard wave.
- `L` - buy/activate the base lock.
- `R` - rebirth.
- `B` - toggle the shop.
- Arrow keys / right-drag - orbit the third-person camera, wheel to zoom.

## Build

    PATH="$HOME/workspace/tools/bin:$PATH" rojo build default.project.json --output game.rbxl

Hand it in as the grader does:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

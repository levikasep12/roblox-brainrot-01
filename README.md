[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/levikasep12/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/levikasep12/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[Play it on Roblox](https://www.roblox.com/games/100535318232718)

# Brainrot Rush

A 3D steal-a-brainrot game for Roblox, built with Rojo. Sixteen handmade meme characters
(a Capybara Chef, a Durian DJ, a Tax Evasion Goose, an Ohio Final Boss ...) walk down a
central conveyor; you grab them onto your base plot where they earn money per second,
climb the rarity ladder, buy rebirths for a permanent multiplier, lock your base against
thieves, and dash home when the hazard wave sweeps the map.

Every player starts with a free starter brainrot already on their plot, so the base is
earning from the first second and the first purchase happens within seconds. The HUD
leads with a big money and `$/s` readout plus a `slots used` counter and a progress bar
toward the next brainrot tier, and the plaza is dressed with a giant brainrot statue,
entrance arches, planters, lamps and signs.

## How it is built

`src/` is the Rojo project, mounted into the DataModel by `default.project.json`:

- `src/shared/` — `Config` (world layout, economy and wave tuning), `BrainrotDefs` (the
  16-character cast, five-rung rarity ladder, prices and rates), `BrainrotModel` (builds
  each character from parts and its small BillboardGui label), `Remotes` (the remote-event
  protocol) and `Feedback` (particle bursts and built-in sounds).
- `src/server/` — `init.server.luau` boots the world and wires everything. `Store` is the
  single place server state lives; `WorldBuilder` builds the baseplate, conveyor, six plots,
  shop, statue centerpiece, arches and decorations in code; `Economy` ticks income and runs
  rebirths; `Bases` claims plots, grants the free starter, places brainrots and sells base
  locks; `Spawner` rolls, mutates and walks runway brainrots; `Steal` implements stealing;
  `Events` runs the hazard wave cycle.
- `src/client/` — `Game.client.luau` renders the server's state snapshot, culls distant
  labels and sends every action back; `HUD.luau` builds the money/income/slots card, the
  next-tier progress bar, the persistent `x2` badge, the small hazard banner, the shop
  panel, rebirth/lock buttons and the toast stack.

## Build

    PATH="$HOME/workspace/tools/bin:$PATH" rojo build default.project.json --output game.rbxl

## Hand in

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` into the output
directory and writes `dossier.json` with the vendored make.fun library.

## Controls

- Walk with WASD; the camera is Roblox's default third-person camera.
- Walk up to a brainrot on the runway and press `E` to grab it (it must be within reach and
  you must have the money). Your base already holds a free starter, so income is ticking
  before your first grab.
- `B` opens the shop; order a brainrot straight onto a free base slot for a 20% markup.
- `R` rebirths (spends money for a permanent income multiplier); `L` buys a 90s base lock.
- Press `E` on another player's brainrot to steal it — unless their base is locked.
- When the banner warns of a hazard wave, get back on your own plot before the wall passes.
  Survive it and income doubles for 20 seconds.

-- Roster: the leaderboard-ish public view. It collects each player's visible
-- stats (money, income, rebirths, brainrot count) and pushes them to every
-- client on a heartbeat, throttled, so the client's sidebar renders one table.

local Players = game:GetService("Players")

local Store = require(script.Parent.Store)
local BrainrotDefs = require(game:GetService("ReplicatedStorage").Shared.BrainrotDefs)

local Roster = {}

local remote: RemoteEvent

function Roster.init(deps: any)
	remote = deps.net.get("ProfileUpdated")
end

local function rowFor(player: Player)
	local profile = Store.get(player)
	if not profile then
		return nil
	end
	local count = 0
	local bestRarity = 0
	for _, slot in pairs(profile.slots) do
		count += 1
		local def = BrainrotDefs.get(slot.defId)
		if def then
			bestRarity = math.max(bestRarity, BrainrotDefs.rarityRank(def.rarity))
		end
	end
	return {
		name = player.DisplayName,
		money = math.floor(profile.money),
		income = Store.income(player),
		rebirths = profile.rebirths,
		count = count,
		bestRarity = bestRarity,
		plot = profile.plotIndex,
	}
end

--- Pushes fresh state to one player (their own profile) plus the roster.
function Roster.send(player: Player)
	local snapshot = Store.snapshot(player)
	if not snapshot or not remote then
		return
	end
	local rows = {}
	for _, other in ipairs(Players:GetPlayers()) do
		local row = rowFor(other)
		if row then
			table.insert(rows, row)
		end
	end
	remote:FireClient(player, {
		self = snapshot,
		roster = rows,
	})
end

function Roster.broadcast()
	for _, player in ipairs(Players:GetPlayers()) do
		Roster.send(player)
	end
end

function Roster.start()
	task.spawn(function()
		while true do
			task.wait(0.25)
			Roster.broadcast()
		end
	end)
end

return Roster

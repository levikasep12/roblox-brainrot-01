-- Income ticking and the rebirth ladder. Reads and writes money only through Store,
-- so the HUD, shop and rebirth all agree on one number.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Store = require(script.Parent.Store)

local Economy = {}

function Economy.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(Store.Config.Economy.incomeTickSeconds)
			local waveRunning = Store.isWaveDouble()
			for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
				local record = Store.players[player.UserId]
				if record and record.plotIndex then
					local perSecond = Store.incomePerSecond(player)
					if waveRunning then
						perSecond *= 2
					end
					if perSecond > 0 then
						Store.award(player, perSecond * Store.Config.Economy.incomeTickSeconds)
					end
				end
			end
		end
	end)
end

-- Rebirth: spend the current money, gain a permanent +rebirthBonus multiplier and
-- clear the plot. Returns ok, message.
function Economy.rebirth(player)
	local record = Store.record(player)
	local cost = Store.rebirthCost(player)
	if record.money < cost then
		return false, string.format("Rebirth needs $%d", cost)
	end
	if #Store.ownedBrainrots(player) > 0 and record.plotIndex then
		local slot = Store.slots[record.plotIndex]
		for _, entry in ipairs(slot.models) do
			if entry.model then
				entry.model:Destroy()
			end
		end
		slot.models = {}
	end
	record.money = 0
	record.rebirths += 1
	record.multiplier = 1 + record.rebirths * Store.Config.Economy.rebirthBonus
	return true, string.format("Rebirth %d! Income x%.2f", record.rebirths, record.multiplier)
end

function Economy.summarize(player)
	local record = Store.record(player)
	return {
		money = record.money,
		multiplier = record.multiplier,
		rebirths = record.rebirths,
		income = Store.incomePerSecond(player),
	}
end

return Economy

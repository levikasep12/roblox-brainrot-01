-- Mutations: the rare shiny variants a spawned brainrot can roll.
-- A mutation is a pure stat modifier: a multiplier on the base rate plus the
-- tint the model builder applies. Weighted roll order: Normal, Golden, Diamond.

local Mutations = {}

Mutations.None = {
	id = "Normal",
	label = "",
	rateMultiplier = 1,
	tint = nil,
	chance = 1,
}

Mutations.List = {
	{
		id = "Golden",
		label = "GOLDEN",
		rateMultiplier = 2.5,
		tint = Color3.fromRGB(255, 204, 64),
	},
	{
		id = "Diamond",
		label = "DIAMOND",
		rateMultiplier = 5,
		tint = Color3.fromRGB(126, 236, 255),
	},
}

Mutations.ById = { Normal = Mutations.None }
for _, mutation in ipairs(Mutations.List) do
	Mutations.ById[mutation.id] = mutation
end

-- roll(goldenChance, diamondChance) -> mutation table. Diamond is rolled first
-- so it stays the rarest outcome even as the golden chance grows.
function Mutations.roll(goldenChance: number, diamondChance: number)
	if math.random() < diamondChance then
		return Mutations.ById.Diamond
	end
	if math.random() < goldenChance then
		return Mutations.ById.Golden
	end
	return Mutations.None
end

function Mutations.get(id: string?)
	if id and Mutations.ById[id] then
		return Mutations.ById[id]
	end
	return Mutations.None
end

return Mutations

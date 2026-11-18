-- Number formatting shared by the HUD, the shop and the 3D labels.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.short(amount: number): string
	if amount ~= amount or amount == math.huge then
		return "0"
	end
	local value = math.max(0, amount)
	if value < 1000 then
		return tostring(math.floor(value))
	end
	local index = 1
	while value >= 1000 and index < #SUFFIXES do
		value /= 1000
		index += 1
	end
	local decimals = if value >= 100 then 0 else 1
	return string.format("%." .. decimals .. "f%s", value, SUFFIXES[index])
end

function Format.money(amount: number): string
	return "$" .. Format.short(amount)
end

function Format.rate(amount: number): string
	return "+" .. Format.money(amount) .. "/s"
end

function Format.clock(seconds: number): string
	local total = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", total // 60, total % 60)
end

return Format

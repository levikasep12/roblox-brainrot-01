-- Shared number and text formatting. Used by the HUD, the shop and the
-- billboards above every brainrot so they all read the same.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.Abbreviate(value)
	value = tonumber(value) or 0
	local negative = value < 0
	value = math.abs(value)
	if value < 1000 then
		return (negative and "-" or "") .. tostring(math.floor(value + 0.5))
	end
	-- SUFFIXES[1] is "", so a tier of 1 (thousands) names SUFFIXES[2].
	local tier = math.floor(math.log(value, 1000))
	tier = math.clamp(tier, 1, #SUFFIXES - 1)
	local scaled = value / (1000 ^ tier)
	local text
	if scaled >= 100 then
		text = string.format("%d", math.floor(scaled + 0.5))
	elseif scaled >= 10 then
		text = string.format("%.1f", scaled)
	else
		text = string.format("%.2f", scaled)
	end
	text = text:gsub("%.?0+$", "")
	if text == "" then
		text = "0"
	end
	return (negative and "-" or "") .. text .. SUFFIXES[tier + 1]
end

function Format.Money(value)
	return "$" .. Format.Abbreviate(value)
end

function Format.Rate(value)
	return "$" .. Format.Abbreviate(value) .. "/s"
end

function Format.Time(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 60 then
		return string.format("%dm %02ds", math.floor(seconds / 60), seconds % 60)
	end
	return tostring(seconds) .. "s"
end

function Format.Percent(fraction)
	return string.format("%d%%", math.floor(fraction * 100 + 0.5))
end

return Format

function clamp(v, min, max)
	return (v < min and min) or (v > max and max) or v
end

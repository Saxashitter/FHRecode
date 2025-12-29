---@diagnostic disable: param-type-mismatch
local libVers = 1

if SSL
and SSL.version >= libVers then
	return
end

local strFind = string.find
local strSub = string.sub
local strLen = string.len
local strGmatch = string.gmatch
local strSub = string.sub
local strByte = string.byte
local strFormat = string.format
local strLower = string.lower
local tblInsert = table.insert
local tblRemove = table.remove
local tonumber = tonumber
local cos = cos
local FixedAngle = FixedAngle
local FU = FU -- :money_mouth:

local tofixedCache = {}
local tofixed = function(str)
	if tofixedCache[str] then return tofixedCache[str] end

	local dec_offset = strFind(str,'%.')
	if dec_offset == nil then
		return (tonumber(str) or 0)*FU
	end

	local whole = tonumber(strSub(str,0,dec_offset-1)) or 0
	local decstr = strSub(str,dec_offset+1)
	local decimal = tonumber(decstr) or 0

	if decimal == 0 then
		decstr = "0"
	end

	local dec_len = strLen(decstr)

	whole = $ * FU
	decimal = $ * FU / (10^dec_len)

	tofixedCache[str] = whole + decimal
	return whole + decimal
end -- :money_mouth: 2
local colors = {
	magenta = V_MAGENTAMAP,
	yellow = V_YELLOWMAP,
	green = V_GREENMAP,
	blue = V_BLUEMAP,
	red = V_REDMAP,
	gray = V_GRAYMAP,
	orange = V_ORANGEMAP,
	sky = V_SKYMAP,
	purple = V_PURPLEMAP,
	aqua = V_AQUAMAP,
	peridot = V_PERIDOTMAP,
	azure = V_AZUREMAP,
	brown = V_BROWNMAP,
	rosy = V_ROSYMAP,
	invert = V_INVERTMAP
}

local stringWidths = {}
local stringPatches = {}
local splitCache = {}
local tokenCache = {}
local tokenWidthCache = {}
local tokenHeightCache = {}
local fonts = {
	["TNYFN%03d"] = {
		spacing = 4,
		vspacing = 7,
		height = 7
	},
	["STCFN%03d"] = {
		spacing = 4,
		vspacing = 8,
		height = 8
	},
	["LTFNT%03d"] = {
		spacing = 8,
		vspacing = 16,
		height = 16
	}
}
local curWave = 0
local waveSpeed = 35

rawset(_G, "SSL", {version = libVers})

local function splitLines(str)
	if splitCache[str] then
		return splitCache[str]
	end

	local t = {}

	for line in strGmatch(str, "([^\n]*)\n?") do
		tblInsert(t, line)
	end

	if t[#t] == "" then tblRemove(t, #t) end

	splitCache[str] = t
	return t
end

local function tokenize(str)
	if tokenCache[str] then
		return tokenCache[str]
	end

    local tokens = {}
    local pos = 1

    while true do
        -- find next tag of the form [tag:value]
        local s, e, tag, val = strFind(str, "%[([%w_]+):([^%]]+)%]", pos)

        if not s then
            -- add remaining text
            if pos <= #str then
                tblInsert(tokens, {type="text", value=strSub(str,pos)})
            end
            break
        end

        -- add text before tag
        if s > pos then
            tblInsert(tokens, {
                type="text",
                value=strSub(str, pos, s-1)
            })
        end

        -- add tag
        tblInsert(tokens, {
            type=tag,
            value=val
        })

        pos = e + 1
    end

	tokenCache[str] = tokens
    return tokens
end

local function getStringWidth(v, string, font)
	if not fonts[font] then
		return 0
	end
	if not stringWidths[font] then
		stringWidths[font] = {}
	end
	if not stringPatches[font] then
		stringPatches[font] = {}
	end

	local width = stringWidths[font][string]

	if not width then
		width = 0

		for i = 1, #string do
			local str = strSub(string, i, i)
			local byte = strByte(str)
			local patch = stringPatches[font][byte]

			if byte == 32 then
				width = $ + fonts[font].spacing
				continue
			end

			if not (patch and patch.valid) then
				stringPatches[font][byte] = v.cachePatch(strFormat(font, byte))
				patch = stringPatches[font][byte]
			end

			width = $ + patch.width
		end

		stringWidths[font][string] = width
	end

	return width
end

local function getTaggedStringWidth(v, string, font, scale)
	scale = $ or FU
	
	if not fonts[font] then return 0 end
	
	-- split into lines
	local lines = splitLines(string)
	local maxWidth = 0
	
	for _, line in ipairs(lines) do
		local tokens = tokenize(line)
		local cx = 0          -- measured width
		
		for _, t in ipairs(tokens) do
			local _font = font
			if not tokenWidthCache[font] then
				tokenWidthCache[font] = {}
			end
			if tokenWidthCache[font][line] then
				cx = tokenWidthCache[font][line]
				break
			end

			if t.type == "text" then
				-- plain text width
				cx = $ + getStringWidth(v, t.value, font)*scale
			elseif t.type == "font" and fonts[t.value] then
				-- change font
				font = t.value
			elseif t.type == "graphic" then
				-- graphic patch width
				local patch = v.cachePatch(t.value)
				if patch and patch.valid then
					-- scale graphic to match font height
					local gscale = FixedDiv(fonts[font].height, patch.height)
					cx = $ + patch.width * gscale
				end
			end
		end

		tokenWidthCache[font][line] = cx
		if cx > maxWidth then
			maxWidth = cx
		end
	end
	
	return FixedMul(maxWidth, scale)
end

local function drawString(v, x, y, scale, string, font, flags, align, valign, color, shake, wave, _splitStr, _resetWave)
	local _curWave = curWave

	x = $ or 0
	y = $ or 0
	scale = $ or FU
	string = $ or ""
	font = $ or "STCFN%03d"
	flags = $ or 0 
	align = $ or 0
	valign = $ or 0
	color = $ or 0
	shake = $ or 0
	wave = $ or 0

	if _splitStr == nil then _splitStr = true end
	if _resetWave == nil then _resetWave = true end

	if not fonts[font] then return end

	local ox = x
	local oy = y
	local tbl = _splitStr and splitLines(string) or {string}

	y = $ - FixedMul((fonts[font].vspacing*#tbl)*scale, valign)

	for k, string in ipairs(tbl) do
		local width = getStringWidth(v, string, font)
		x = ox - FixedMul(width*align, scale)

		if k > 1 then
			curWave = 0
		end

		for i = 1, #string do
			local str = strSub(string, i, i)
			local byte = strByte(str)
			local patch = stringPatches[font][byte]
			if byte == 32 then
				x = $ + fonts[font].spacing * scale
				continue
			end

			if not (patch and patch.valid) then
				stringPatches[font][byte] = v.cachePatch(strFormat(font, byte))
				patch = stringPatches[font][byte]
			end

			local dx = 0
			local dy = 0
	
			if shake then
				local shake = FixedMul(shake, scale)
				dx = v.RandomRange(-shake, shake)
				dy = v.RandomRange(-shake, shake)
			end

			if wave then
				dy = $ + FixedMul(
					wave,
					FixedMul(
						cos(
							FixedAngle(
								360 * FixedDiv(
									(leveltime+curWave) % waveSpeed,
									waveSpeed
								)
							)
						),
						scale
					)
				)
			end
			curWave = $+2

			local colormap
			if color then
				colormap = v.getStringColormap(color)
			end

			v.drawScaled(x+dx, y+dy, scale, patch, flags, colormap)
			x = $ + patch.width*scale
		end

		y = $ + fonts[font].vspacing*scale
	end

	if _resetWave then
		curWave = 0
	end
end

local function drawTaggedString(v, x, y, scale, string, font, flags, align, valign, color, shake, wave)
	x = $ or 0
	y = $ or 0
	scale = $ or FU
	string = $ or ""
	font = $ or "STCFN%03d"
	flags = $ or 0 
	align = $ or 0
	valign = $ or 0
	color = $ or 0
	shake = $ or 0
	wave = $ or 0

	if not fonts[font] then return end

	local tbl = splitLines(string)
	local totalHeight = 0
	if not tokenHeightCache[font] then
		tokenHeightCache[font] = {}
	end

	local _font = font
	for _, line in ipairs(tbl) do
		curWave = 0

		local tokens = tokenize(line)
		local height = tokenHeightCache[font][line]

		if height == nil then
			local _strfont = _font
			height = 0

			for _, t in ipairs(tokens) do
				if t.type == "text" then
					height = max($, fonts[_font].vspacing)
				elseif t.type == "font"
				and fonts[t.value] then
					_font = t.value
				end
			end

			if not tokenHeightCache[_strfont] then
				tokenHeightCache[_strfont] = {}
			end
			tokenHeightCache[_strfont][line] = height
		end

		totalHeight = $ + height
	end

	y = $ - FixedMul(totalHeight * scale, valign)

	for _, line in ipairs(tbl) do
		if not tokenWidthCache[font] then
			tokenWidthCache[font] = {}
		end

		local cx = x
		local tokens = tokenize(line)
		local width = tokenWidthCache[font][line]
		local height = tokenHeightCache[font][line]
		local curFont = font
		local curColor = color
		local curShake = shake

		-- WIDTH CALC
		if width == nil then
			width = 0

			for _, t in ipairs(tokens) do
				if t.type == "text" then
					width = $ + getStringWidth(v, t.value, curFont) * FU
				elseif t.type == "font"
				and fonts[t.value] then
					curFont = t.value
				elseif t.type == "graphic" then
					local patch = v.cachePatch(t.value)
					if patch and patch.valid then
						-- scale graphic to match font height
						local gscale = FixedDiv(fonts[font].height, patch.height)
						cx = $ + patch.width * gscale
					end
				end
			end

			tokenWidthCache[font][line] = width
		end

		cx = $ - FixedMul(FixedMul(width, scale), align)

		for _, t in ipairs(tokens) do
			if t.type == "text" then
				drawString(v, cx, y, scale, t.value, font, flags, 0, 0, color, shake, wave, true, true)
				cx = $ + getStringWidth(v, t.value, font) * scale
			elseif t.type == "graphic" then
				local dx = 0
				local dy = 0
		
				if shake then
					local shake = FixedMul(shake, scale)
					dx = v.RandomRange(-shake, shake)
					dy = v.RandomRange(-shake, shake)
				end
	
				if wave then
					dy = $ + FixedMul(
						wave,
						FixedMul(
							cos(
								FixedAngle(
									360 * FixedDiv(
										(leveltime+curWave) % waveSpeed,
										waveSpeed
									)
								)
							),
							scale
						)
					)
					curWave = $+2
				end
				local patch = v.cachePatch(t.value)
				local gscale = FixedMul(FixedDiv(fonts[font].height, patch.height), scale)

				v.drawScaled(cx+dx, y+dy, gscale, patch, flags)
				cx = $+patch.width*gscale
			elseif t.type == "color" then
				color = colors[strLower(t.value)]
			elseif t.type == "font"
			and fonts[t.value] then
				font = t.value
			elseif t.type == "shake" then
				shake = tofixed(t.value)
			elseif t.type == "wave" then
				wave = tofixed(t.value)
			end
		end

		y = $ + height * scale
	end
end

-- expose stuff lul
function SSL.getFont(name)
	return fonts[name]
end
function SSL.addFont(name, spacing, vspacing, height)
	fonts[name] = {
		spacing = spacing or 0,
		vspacing = vspacing or 0,
		height = height or vspacing or 0
	}
	return fonts[name]
end
function SSL.drawString(v, x, y, string, font, flags, align, valign, color, shake, wave)
	drawString(v, x*FU, y*FU, FU, string, font, flags, align, valign, color, shake, wave)
end
function SSL.drawFixedString(v, x, y, scale, string, font, flags, align, valign, color, shake, wave)
	drawString(v, x, y, scale, string, font, flags, align, valign, color, shake, wave)
end
function SSL.drawTaggedString(v, x, y, scale, string, font, flags, align, valign, color, shake, wave)
	drawTaggedString(v, x, y, scale, string, font, flags, align, valign, color, shake, wave)
end
function SSL.getStringWidth(v, string, font)
	return getStringWidth(v, string, font)
end
function SSL.getTaggedStringWidth(v, string, font, scale)
	return getTaggedStringWidth(v, string, font, scale)
end

-- example usage
--[[local testStr = "hiya! [font:STCFN%03d]gays\n[color:white]HOW WELL DOES THIS [color:yellow]WORK\n[wave:4][color:blue]Child eater. [graphic:RACEGO] die."
addHook("HUD", function(v)
	SSL.drawTaggedString(v, 160*FU, 100*FU, FU,
		testStr,
	"TNYFN%03d", 0, FU/2, FU/2, V_REDMAP, 0, 0)

	SSL.drawString(v, 160*FU, 100*FU, FU, "testing...", "STCFN%03d", 0, FU/2, FU/2, V_REDMAP, 0, 4*FU)
end)]]
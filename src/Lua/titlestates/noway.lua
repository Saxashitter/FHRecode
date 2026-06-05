local state = {}

function state:load()
	S_ChangeMusic("FH_NOW", true)
end

function state:draw(v)
	local characters = v.cachePatch("FH_NOWAY_0")
	local logo = v.cachePatch("FH_NOWAY_1")

	v.draw(0, 0, characters, V_SNAPTOBOTTOM)
	v.draw(160 - 90 / 2, 16, logo, V_SNAPTOTOP)

	SSL.drawFixedString(v, 160 * FU, 16 * FU + logo.height * FU / 2, FU, "this isn't in yet lol get fucked", "STCFN%03d", V_SNAPTOTOP, FU / 2, FU / 2)
end

function state:pressed()
	FH:changeTitlescreenState("mainmenu", true)
end

FH.titleStates.noway = state
--- @type heistModifier_t
local modifier = setmetatable({}, FH:returnModifierMetatable())

sfxinfo[freeslot("sfx_fh_fox")].caption = "AAAAAAAAAAAAAAAAAAH!"

modifier.name = "top cinco jumpscares"
modifier.description = "scary"
modifier.type = "side"

function modifier:init()
	FHR.foxyJumpscareTics = P_RandomRange(5 * TICRATE, 45 * TICRATE)
	FHR.foxyJumpscareTime = -1
end

function modifier:update()
	FHR.foxyJumpscareTics = $ - 1

	if not FHR.foxyJumpscareTics then
		self:doJumpscare()
		FHR.foxyJumpscareTics = P_RandomRange(5 * TICRATE, 45 * TICRATE)
	end
end

function modifier:doJumpscare()
	S_StartSound(nil, sfx_fh_fox)
	FHR.foxyJumpscareTime = leveltime
end

return FH:registerModifier(modifier)
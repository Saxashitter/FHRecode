local quizTime = {}

--- @param v videolib
--- @param player player_t
--- @param camera camera_t
function quizTime:draw(v, player, camera)
	if FHR.currentState ~= "quiztime" then return end

	v.drawFill()

	SSL.drawString(v, 160, 100,      FHR.quizQuestion.question,                                     "STCFN%03d", 0,              FU / 2, FU/2, V_YELLOWMAP, 0, FU)
	SSL.drawString(v, 160, 200 - 12, FHR.quizQuestion.answers[player.hr.quizTimeSelection], "TNYFN%03d", V_SNAPTOBOTTOM, FU / 2, 0,    player.hr.quizTimeSelected and V_GREENMAP or 0)
end

return quizTime, "quizTime", 1, "menu"
local state = {}
state.__index = state

state.items = {}
-- item: {name = string, desc = string, selected = function(return true to open srb2 menu)}

function state:load()
	self.selection = 1
end

function state:draw(v)
	local textHeight = 8 * FU
	local textPadding = 2 * FU
	local height = (textHeight * #self.items) + (textPadding * (#self.items - 1))
	local y = 100 * FU - height / 2

	for i, item in ipairs(self.items) do
		SSL.drawFixedString(v, 160*FU, y, FU, item.name, "STCFN%03d", 0, FU/2, 0, self.selection == i and V_YELLOWMAP or 0)
		y = $ + textHeight + textPadding
	end
end

function state:select(direction)
	self.selection = $ + direction

	if self.selection < 1 then
		self.selection = #self.items
	elseif self.selection > #self.items then
		self.selection = 1
	end
end

function state:confirm()
	local item = self.items[self.selection]

	if item and item.selected then
		return item:selected()
	end
end

function state:pressed(keyName)
	local direction = 0

	if keyName == "up" then
		self:select(-1)
	elseif keyName == "down" then
		self:select(1)
	elseif keyName == "back" then
		FH:changeTitlescreenState("intro")
	elseif keyName == "accept" then
		return self:confirm()
	end
end

FH.titleStates.menubase = state
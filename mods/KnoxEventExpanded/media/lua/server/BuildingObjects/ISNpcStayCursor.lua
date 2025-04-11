ISNpcStayCursor = ISBuildingObject:derive("ISNpcStayCursor")


function ISNpcStayCursor:create(x, y, z, north, sprite)
	local square = getWorld():getCell():getGridSquare(x, y, z)
	tellNpcStay(self.npc, x, y, z);
end

function ISNpcStayCursor:isValid(square)
	return square:TreatAsSolidFloor()
end

function ISNpcStayCursor:render(x, y, z, square)
	if not ISNpcStayCursor.floorSprite then
		ISNpcStayCursor.floorSprite = IsoSprite.new()
		ISNpcStayCursor.floorSprite:LoadFramesNoDirPageSimple('media/ui/FloorTileCursor.png')
	end

	local hc = getCore():getGoodHighlitedColor()
	if not self:isValid(square) then
		hc = getCore():getBadHighlitedColor()
	end
	ISNpcStayCursor.floorSprite:RenderGhostTileColor(x, y, z, hc:getR(), hc:getG(), hc:getB(), 0.8)
end

function ISNpcStayCursor:new(sprite, northSprite, npc, player)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o:init()
	o:setSprite(sprite)
	o:setNorthSprite(northSprite)
	o.npc = npc
	o.player = player:getPlayerNum()
	o.noNeedHammer = true
	o.skipBuildAction = true
	return o
end
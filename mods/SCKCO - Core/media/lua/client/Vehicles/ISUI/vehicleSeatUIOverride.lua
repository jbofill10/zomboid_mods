require "Vehicles/ISUI/ISVehicleSeatUI"

local FONT_HGT_LARGE = getTextManager():getFontHeight(UIFont.Large)

SeatOffsetY["Base.SC_M35A1"] = -110

local function seatUIAdaptiveRendering(tbl, x, y, x2, y2)
    if tbl[x] then
        for _,tXY in pairs(tbl[x]) do
            local tX, tY = tXY[1], tXY[2]
            --if x > seatX and x < seatX+sizeX then x = seatX+sizeX+2 end
            if y >= tY and y <= tY+y2 then y = math.max(y, tY+y2) end
        end
    end
    tbl[x] = tbl[x] or {}
    table.insert(tbl[x], {x, y})

    return x, y
end


function ISVehicleSeatUI:render()
    ISPanelJoypad.render(self)

    self.mouseOverSeat = nil
    self.mouseOverExit = nil

    if not self.vehicle then return end

    local script = self.vehicle:getScript()
    local scriptName = self.vehicle:getScriptName()

    local extents = script:getExtents()
    local ratio = extents:x() / extents:z() + 0.0
    local height = self.height * 0.7
    local width = height * ratio
    local ex = (self.width - width) / 2
    local ey = (self.height - height) / 2
    local props = ISCarMechanicsOverlay.CarList[scriptName]
    if props and props.imgPrefix then
        local tex = getTexture("media/ui/vehicles/seatui/" .. props.imgPrefix .. "base_small.png")
        if tex then
            local imageScale = ImageScale[props.imgPrefix] or 1.0
            self:drawTextureScaledUniform(tex,
                    (self.width - tex:getWidthOrig() * imageScale) / 2,
                    (self.height - tex:getHeightOrig() * imageScale) / 2,
                    imageScale, 1,1,1,1)
        else
            self:drawRect(ex, ey, width, height, 0.8, 0.0, 0.0, 0.0)
            self:drawRectBorder(ex, ey, width, height, 1.0, 1.0, 1.0, 1.0)
        end
    else
        self:drawRect(ex, ey, width, height, 0.8, 0.0, 0.0, 0.0)
        self:drawRectBorder(ex, ey, width, height, 1.0, 1.0, 1.0, 1.0)
    end

    local playerSeat = self.vehicle:getSeat(self.character)

    local shiftKey = isKeyDown(Keyboard.KEY_LSHIFT) or isKeyDown(Keyboard.KEY_RSHIFT)

    local scale = height / extents:z()
    local sizeX,sizeY = 41,59
    local origSizeX, origSizeY = sizeX, sizeY

    local driver = script:getPassenger(0)
    local driverPos = driver:getPositionById("inside")
    if driverPos then
        local offset = driverPos:getOffset()
        local x = self:getWidth() / 2 - offset:get(0) * scale - sizeX / 2
        local y = self:getHeight() / 2 - offset:get(2) * scale - sizeY / 2
        y = y + (SeatOffsetY[scriptName] or 0.0)
        x = x + (SeatOffsetX[scriptName] or 0.0)
        sizeY = math.min(sizeY, ((height-y)/(self.vehicle:getMaxPassengers()/2)))
    end

    local aspect = math.min(1, sizeX/origSizeX, sizeY/origSizeY)
    sizeX = origSizeX*aspect
    sizeY = origSizeY*aspect
    
    local previousSeats = {}

    for seat=1,self.vehicle:getMaxPassengers() do
        local pngr = script:getPassenger(seat-1)
        local posn = pngr:getPositionById("inside")
        if posn then
            local offset = posn:getOffset()
            local x = self:getWidth() / 2 - offset:get(0) * scale - sizeX / 2
            local y = self:getHeight() / 2 - offset:get(2) * scale - sizeY / 2
            y = y + (SeatOffsetY[scriptName] or 0.0)
            x = x + (SeatOffsetX[scriptName] or 0.0)
            x, y = seatUIAdaptiveRendering(previousSeats, x, y, sizeX, sizeY)

            local mouseOver = (self:getMouseX() >= x and self:getMouseX() < x + sizeX and
                    self:getMouseY() >= y and self:getMouseY() < y + sizeY) or
                    (self.joyfocus and self.joypadSeat == seat)
            if mouseOver then
                self.mouseOverSeat = seat - 1
            end

            local fillR, fillG, fillB = 0.0, 0.0, 0.0
            local outlineR, outlineG, outlineB = 0.0, 1.0, 0.0
            local texName = "icon_vehicle_empty.png"
            local textRGB = 1.0
            local canSwitch = false
            if self.vehicle:isSeatOccupied(seat-1) then
                if self.vehicle:getCharacter(seat-1) then
                    texName = "icon_vehicle_person.png"
                    fillR = 0.0
                    fillG = 0.0
                    fillB = 1.0
                else
                    fillR, fillG, fillB = 1.0, 1.0, 1.0
                    textRGB = 0.0 -- black text on white background
                    texName = "icon_vehicle_stuff.png"
                    if ISVehicleMenu.moveItemsFromSeat(self.character, self.vehicle, seat-1, false, false) then
                        canSwitch = true
                    else

                    end
                end
                if mouseOver then
                    outlineR = 1.0
                    outlineG = 0.0
                    outlineB = 0.0
                end
            elseif self.vehicle:getPartForSeatContainer(seat-1) and
                    not self.vehicle:getPartForSeatContainer(seat-1):getInventoryItem() then
                texName = "icon_vehicle_uninstalled.png"
                fillR = 0.5
                fillG = 0.5
                fillB = 0.5
                if mouseOver then
                    outlineR = 1.0
                    outlineG = 0.0
                    outlineB = 0.0
                end
            else
                canSwitch = true
            end

            local seatRGB = 1.0
            if (playerSeat ~= -1) and (playerSeat ~= seat-1) and not self.vehicle:canSwitchSeat(playerSeat, seat - 1) then
                seatRGB = 0.5
                textRGB = textRGB * 0.5
            end

            local tex = getTexture("media/ui/vehicles/seatui/" .. texName)

            if tex then
                self:drawTextureScaled(tex, x, y, sizeX, sizeY, 1.0, seatRGB, seatRGB, seatRGB)
            else
                self:drawRect(x, y, sizeX, sizeY, 1.0, fillR, fillG, fillB)
                self:drawRectBorder(x, y, sizeX, sizeY, 1.0, 1.0, 1.0, 1.0)
            end

            if not shiftKey and canSwitch and not self.joyfocus then
                self:drawTextCentre(tostring(seat), x + sizeX / 2, y + sizeY / 2 - FONT_HGT_LARGE / 2, textRGB, textRGB, textRGB, 1, UIFont.Large)
            end

            if mouseOver then
                self:drawRectBorder(x - 2, y - 2, sizeX + 4, sizeY + 4, 1.0, outlineR, outlineG, outlineB)
            end

            if canSwitch and self.joyfocus and self.joypadSeat == seat then
                local texBtn = Joypad.Texture.AButton
                local texWBtn,texHBtn = tex:getWidthOrig()*aspect,tex:getHeightOrig()*aspect
                local xBtn = self:getWidth() / 2 - offset:get(0) * scale - texWBtn / 2
                local yBtn = self:getHeight() / 2 - offset:get(2) * scale - texHBtn / 2
                xBtn = xBtn + (SeatOffsetX[scriptName] or 0.0)
                yBtn = yBtn + (SeatOffsetY[scriptName] or 0.0)
                self:drawTextureScaledUniform(texBtn, xBtn, yBtn, aspect, 1,1,1,1)
            end
        end

        -- Display available exits when inside.
        if playerSeat ~= -1 then
            local canSwitch = self.vehicle:canSwitchSeat(playerSeat, seat - 1)
            if self.vehicle:isSeatOccupied(seat - 1) then
                canSwitch = false
                -- if you can't switch because of item we check you can still move them
                if not self.vehicle:getCharacter(seat-1) then
                    canSwitch = ISVehicleMenu.moveItemsFromSeat(self.character, self.vehicle, seat-1, false, false)
                end
            end
            if playerSeat == seat - 1 then canSwitch = true end
            self.vehicle:updateHasExtendOffsetForExit(self.character)
            if self.vehicle:isExitBlocked(self.character, seat - 1) then canSwitch = false end
            self.vehicle:updateHasExtendOffsetForExitEnd(self.character)
            posn = pngr:getPositionById("outside")
            if canSwitch and posn then
                local offset = posn:getOffset()
                if self.joyfocus and seat == self.joypadSeat then
                    local tex = Joypad.Texture.XButton
                    local texW,texH = tex:getWidthOrig()*aspect,tex:getHeightOrig()*aspect
                    local x = self:getWidth() / 2 - offset:get(0) * scale - texW / 2
                    local y = self:getHeight() / 2 - offset:get(2) * scale - texH / 2
                    y = y + (SeatOffsetY[scriptName] or 0.0)
                    x = x + (SeatOffsetX[scriptName] or 0.0)
                    x, y = seatUIAdaptiveRendering(previousSeats, x, y, texW, texH)
                    self:drawTextureScaledUniform(tex, x, y, aspect, 1,1,1,1)
                end

                if not self.joyfocus then
                    local tex = getTexture("media/ui/vehicles/vehicle_exit.png")
                    local texW,texH = tex:getWidthOrig()*aspect,tex:getHeightOrig()*aspect
                    local x = self:getWidth() / 2 - offset:get(0) * scale - texW / 2
                    local y = self:getHeight() / 2 - offset:get(2) * scale - texH / 2
                    y = y + (SeatOffsetY[scriptName] or 0.0)
                    x = x + (SeatOffsetX[scriptName] or 0.0)

                    if x > ex and x < (ex+width)-(texW/4) then
                        if y < ey+height and y > self:getHeight()/2 then y = ey+height+1 end
                        if y > ey and y < self:getHeight()/2 then y = y-(ey-y)-1 end
                    end

                    x, y = seatUIAdaptiveRendering(previousSeats, x, y, texW, texH)

                    local mouseOver = (self:getMouseX() >= x and self:getMouseX() < x + texW and
                            self:getMouseY() >= y and self:getMouseY() < y + texH) or
                            (self.joyfocus and self.joypadSeat == seat)
                    if mouseOver then self.mouseOverExit = seat - 1 end

                    if mouseOver or shiftKey then self:drawTextureScaledUniform(tex, x, y, aspect, 1,1,1,1)
                    else self:drawTextureScaledUniform(tex, x, y, aspect, 0.2,1,1,1) end

                    if shiftKey then
                        self:drawRect(x + texW / 2 - 8, y + texH / 2 - FONT_HGT_LARGE / 2, 16, FONT_HGT_LARGE, 1, 0.1, 0.1, 0.1)
                        self:drawTextCentre(tostring(seat), x + texW / 2, y + texH / 2 - FONT_HGT_LARGE / 2, 1, 1, 1, 1, UIFont.Large)
                    end
                end

            end
        end
    end
end
local utils = require("utils")
local vec2 = require("lib/vec2")
local assets = require("scripts/assets")
local coreFuncs = require("scripts.coreFuncs")

local zerpgui = {
    canvases = {};
    version = "1.1";
}

local function calculateAlign(position, align, canvas)
    local x = position.x
    local y = position.y

    return vec2.new(x + canvas.position.x, y + canvas.position.y)
    --[[ Find x position
    -- X Aligning
    if align:sub(1, 1) == "-" then
        -- Left align
        x = x - (SC_WIDTH-960)
    elseif align:sub(1, 1) == "+" then
        -- Right align
        x = x + (SC_WIDTH-960)
    elseif align:sub(1, 1) == "0" then
        -- Center align
        x = x + (SC_WIDTH-960)/2
    end
    -- Y Aligning
    if align:sub(2, 2) == "-" then
        -- Up align
        y = y - (SC_HEIGHT-540)
    elseif align:sub(2, 2) == "+" then
        -- Down align
        y = y + (SC_HEIGHT-540)
    elseif align:sub(2, 2) == "0" then
        -- Center align
        y = y + (SC_HEIGHT-540)/2
    end

    return vec2.new(x + canvas.position.x, y + canvas.position.y)
    ]]--
end

-- Thanks to @pgimeno at https://love2d.org/forums/viewtopic.php?f=4&t=93768&p=250899#p250899
function SetFont(fontname, size)
    local key = fontname .. "\0" .. size
    local font = assets.fonts[key]
    if font then
      love.graphics.setFont(font)
    else
      font = love.graphics.setNewFont(fontname, size)
      assets.fonts[key] = font
    end
    return font
end

-- Zerpgui functions
function zerpgui:newCanvas(pos)
    local canvas = {
        position = pos or vec2.new();
        elements = {};
        enabled = true;
        alpha = 1;
    }

    -- Elements
    function canvas:newTextLabel(name, position, text, size, align, begin, font, color)
        local textLabel = {
            parent = nil;
            position = position or vec2.new();
            text = text or "Sample";
            size = size or 24;
            align = align or "--"; -- "- -" means it will get aligned in bottom left of screen
            begin = begin or "left";
            font = font or "Minecraftia";
            color = color or {1, 1, 1, 1};
        }

        function textLabel:draw()
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4]*self.parent.alpha)
            SetFont("fonts/" .. self.font .. ".ttf", self.size)

            local p = calculateAlign(self.position, self.align, canvas)
            
            love.graphics.printf(self.text, p.x, p.y, 1000, self.begin)
            love.graphics.setColor(1, 1, 1, 1)
        end

        textLabel.parent = self
        self[name] = textLabel
        self.elements[#self.elements+1] = textLabel
    end

    function canvas:newImage(name, position, rotation, source, scale, color, align)
        local image = {
            parent = nil;
            position = position or vec2.new();
            rotation = rotation or 0;
            source = source or nil;
            scale = scale or 1;
            align = align or "--";
            color = color or {1, 1, 1, 1};
        }

        function image:draw()
            if not self.source then return end
            local p = calculateAlign(self.position, self.align, canvas)
            local width = self.source:getWidth()
            local height = self.source:getHeight()
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4]*self.parent.alpha)
            love.graphics.draw(
                self.source, p.x, p.y, self.rotation,
                self.scale, self.scale, width/2, height/2
            )
            love.graphics.setColor(1, 1, 1, 1)
        end

        image.parent = self
        self[name] = image
        self.elements[#self.elements+1] = image
    end

    function canvas:newButton(name, position, size, style, text, textSize, hoverEvent, clickEvent, align)
        local button = {
            parent = nil;
            position = position or vec2.new();
            style = style or 1;
            text = text or "Button";
            font = "Minecraftia";
            align = align or "--";
            mouseHover = false;
            size = size or vec2.new(45, 150);
            textSize = textSize or 24;
            hoverEvent = hoverEvent;
            clickEvent = clickEvent;
            mouseClick = false;
            lineWidth = 3;
        }

        function button:update(delta)
            -- Click event
            if not love.mouse.isDown(1) and self.mouseHover and self.mouseClick and self.clickEvent then
                if Save.settings[utils.indexOf(SettingNames, "Sounds")] then
                    assets.sounds.buttonClick:play()
                end
                self.clickEvent()
            end
            local p = calculateAlign(self.position, self.align, canvas)
            local mx, my = coreFuncs.getRelativeMousePosition()
            if self.style == 1 then
                -- Check for hover
                if my > p.y and my < p.y + self.textSize then
                    self.mouseHover = true
                    self.mouseClick = love.mouse.isDown(1)
                else
                    self.mouseHover = false
                    self.mouseClick = false
                end
            else
                if mx > p.x and mx < p.x + self.size.x and my > p.y and my< p.y + self.size.y then
                    self.lineWidth = self.lineWidth + (8-self.lineWidth) * (8.25 * delta)
                    self.mouseHover = true
                    self.mouseClick = love.mouse.isDown(1)
                else
                    self.lineWidth = self.lineWidth + (3-self.lineWidth) * (8.25 * delta)
                    self.mouseHover = false
                    self.mouseClick = false
                end
            end
        end

        function button:draw()
            love.graphics.setColor(1, 1, 1, self.parent.alpha)
            local p = calculateAlign(self.position, self.align, canvas)
            if self.style == 1 then
                -- Draw text
                local t = ""
                if self.mouseHover then
                    t = "> "
                end
                t = t .. self.text
                
                SetFont("fonts/" .. self.font .. ".ttf", self.textSize)
                love.graphics.printf(t, p.x, p.y, 1000, "left")
            else
                -- Draw base
                love.graphics.setLineWidth(self.lineWidth)
                love.graphics.rectangle("line", p.x, p.y, self.size.x, self.size.y)

                -- Draw text
                SetFont("fonts/" .. self.font .. ".ttf", self.textSize)
                local w = #self.text*self.textSize
                love.graphics.print(self.text, p.x + 32, p.y+self.size.y/4)
            end
        end

        button.parent = self
        self[name] = button
        self.elements[#self.elements+1] = button
    end

    function canvas:newRectangle(name, position, size, type, color, lineWidth, align)
        local rectangle = {
            parent = nil;
            position = position or vec2.new();
            size = size or vec2.new(50, 50);
            type = type or "fill";
            color = color or {1, 1, 1, 1};
            lineWidth = lineWidth or 1;
            align = align or "--";
        }

        function rectangle:draw()
            love.graphics.setColor(1, 1, 1, self.parent.alpha*self.color[4])
            local p = calculateAlign(self.position, self.align, canvas)
            love.graphics.setColor(self.color[1], self.color[2], self.color[3], self.color[4])
            love.graphics.setLineWidth(self.lineWidth)
            love.graphics.rectangle(self.type, p.x, p.y, self.size.x, self.size.y)
        end

        rectangle.parent = self
        self[name] = rectangle
        self.elements[#self.elements+1] = rectangle
    end

    function canvas:newCheckbox(name, position, size, value, align)
        local checkbox = {
            parent = nil;
            position = position or vec2.new();
            value = value;
            align = align or "--";
            size = size or 50;
            mouseHover = false;
            mouseClick = false;
        }

        function checkbox:update(delta)
            -- Click event
            if not love.mouse.isDown(1) and self.mouseHover and self.mouseClick then
                if Save.settings[utils.indexOf(SettingNames, "Sounds")] then
                    assets.sounds.buttonClick:play()
                end
                self.value = not self.value
            end
            -- Hover anim & check for click
            local p = calculateAlign(self.position, self.align, canvas)
            p.x = p.x - self.size/2
            p.y = p.y - self.size/2

            local mx, my = coreFuncs.getRelativeMousePosition()
            if mx > p.x and mx < p.x + self.realSize and my > p.y and my < p.y + self.realSize then
                self.mouseHover = true
                self.mouseClick = love.mouse.isDown(1)
                self.size = self.size + (self.realSize+5-self.size) * (8.25 * delta)
            else
                self.mouseHover = false
                self.mouseClick = false
                self.size = self.size + (self.realSize-self.size) * (8.25 * delta)
            end
        end

        function checkbox:draw()
            love.graphics.setColor(1, 1, 1, self.parent.alpha)
            local p = calculateAlign(self.position, self.align, canvas)
            p.x = p.x - self.size/2
            p.y = p.y - self.size/2
            -- Draw line
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", p.x, p.y, self.size, self.size)
            -- Fill inside if value is true
            if self.value then
                love.graphics.rectangle("fill", p.x, p.y, self.size, self.size)
            end
        end

        checkbox.parent = self
        checkbox.realSize = checkbox.size
        self[name] = checkbox
        self.elements[#self.elements+1] = checkbox
    end

    -- Canvas events
    function canvas:update(delta)
        -- Update elements
        for _, v in ipairs(self.elements) do
            if v.update then v:update(delta) end
        end
    end

    function canvas:draw()
        --love.graphics.setColor(1, 1, 1, self.alpha)
        -- Draw elements
        for _, v in ipairs(self.elements) do
            v:draw()
        end
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Add to table
    self.canvases[#self.canvases+1] = canvas
    return canvas
end

-- Zerpgui events
function zerpgui:update(delta)
    -- Update canvases
    for _, v in ipairs(self.canvases) do
        if v.enabled then v:update(delta) end
    end
end

function zerpgui:draw()
    -- Draw canvases
    for _, v in ipairs(self.canvases) do
        if v.enabled then v:draw() end
    end
end

return zerpgui
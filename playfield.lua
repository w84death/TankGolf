local Playfield = {}
Playfield.__index = Playfield

function Playfield.new()
    local self = setmetatable({}, Playfield)
    self.x = 20
    self.y = 40
    self.width = 600
    self.height = 420
    
    -- Create walls (outer boundary)
    self.walls = {
        -- Outer walls {x, y, width, height}
        {self.x, self.y, self.width, 10},  -- Top
        {self.x, self.y + self.height - 10, self.width, 10},  -- Bottom
        {self.x, self.y, 10, self.height},  -- Left
        {self.x + self.width - 10, self.y, 10, self.height},  -- Right
    }
    
    -- Grid configuration
    local blockSize = 30  -- Size of wall blocks
    local spacing = 60    -- Space between blocks
    local rows = 5       -- Number of rows in grid
    local cols = 8       -- Number of columns in grid
    
    -- Calculate grid offset to center it
    local gridWidth = cols * spacing
    local gridHeight = rows * spacing
    local startX = self.x + (self.width - gridWidth) / 2
    local startY = self.y + (self.height - gridHeight) / 2
    
    -- Create grid of small blocks
    for row = 1, rows do
        for col = 1, cols do
            -- Add random variation to position (within spacing constraints)
            local variation = 10
            local offsetX = love.math.random(-variation, variation)
            local offsetY = love.math.random(-variation, variation)
            
            -- Only place block with 70% probability
            if love.math.random() < 0.7 then
                local wallX = startX + (col-1) * spacing + offsetX
                local wallY = startY + (row-1) * spacing + offsetY
                table.insert(self.walls, {
                    wallX, wallY, 
                    blockSize, blockSize
                })
            end
        end
    end
    
    return self
end

function Playfield:draw()
    -- Draw sand background
    love.graphics.setColor(0.93, 0.79, 0.69)  -- Light sand color
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw stone walls
    love.graphics.setColor(0.6, 0.6, 0.5)  -- Stone color
    for _, wall in ipairs(self.walls) do
        love.graphics.rectangle("fill", wall[1], wall[2], wall[3], wall[4])
    end
end

function Playfield:removeWall(wallIndex)
    if wallIndex > 4 then  -- Don't remove boundary walls (first 4 walls)
        table.remove(self.walls, wallIndex)
        return true
    end
    return false
end

function Playfield:checkCollision(x, y, width, height)
    for i, wall in ipairs(self.walls) do
        if x + width > wall[1] and
           x < wall[1] + wall[3] and
           y + height > wall[2] and
           y < wall[2] + wall[4] then
            return true, wall, i  -- Added index to return values
        end
    end
    return false, nil, nil
end

return Playfield

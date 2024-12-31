local Ball = {}
Ball.__index = Ball

function Ball.new(x, y, angle, power, color)
    local self = setmetatable({}, Ball)
    -- Keep only essential properties
    self.x = x
    self.y = y
    self.radius = 4
    self.angle = angle
    self.color = color
    self.active = true
    self.speed = power * 5
    self.distance = 0
    self.totalDistance = power * 10
    return self
end

function Ball:update(dt)
    if not self.active then return end
    
    -- Simple linear movement
    local moveDistance = self.speed * dt
    self.distance = self.distance + moveDistance
    
    -- Update position
    self.x = self.x + math.cos(self.angle) * moveDistance
    self.y = self.y + math.sin(self.angle) * moveDistance
    
    -- Deactivate if traveled full distance
    if self.distance >= self.totalDistance then
        self:deactivate()
        return
    end
    
    -- Check wall collisions
    local collision, wall, wallIndex = game.playfield:checkCollision(
        self.x - self.radius, 
        self.y - self.radius, 
        self.radius * 2, 
        self.radius * 2
    )
    
    if collision then
        -- First bounce
        if wall[3] < wall[4] then  -- Vertical wall
            self.angle = math.pi - self.angle
        else  -- Horizontal wall
            self.angle = -self.angle
        end
        self.totalDistance = self.totalDistance * 0.7
        
        -- Then try to remove wall if it's not a boundary
        if wallIndex > 4 then  -- Not a boundary wall
            game.playfield:removeWall(wallIndex)
            game:addExplosion(self.x, self.y)
        end
        
        -- Check if should deactivate due to low energy
        if self.totalDistance < 50 then
            self:deactivate()
        end
    end
end

function Ball:deactivate()
    self.active = false
    game:addExplosion(self.x, self.y)
end

function Ball:draw()
    if not self.active then return end
    love.graphics.setColor(self.color)
    love.graphics.circle("fill", self.x, self.y, self.radius)
end

return Ball

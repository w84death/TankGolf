local Explosion = {}
Explosion.__index = Explosion

function Explosion.new(x, y)
    local self = setmetatable({}, Explosion)
    self.x = x
    self.y = y
    self.radius = 0
    self.maxRadius = 20
    self.speed = 100
    self.alpha = 1
    self.active = true
    return self
end

function Explosion:update(dt)
    self.radius = self.radius + self.speed * dt
    self.alpha = 1 - (self.radius / self.maxRadius)
    
    if self.radius >= self.maxRadius then
        self.active = false
    end
end

function Explosion:draw()
    love.graphics.setColor(0, 0, 0, self.alpha)
    love.graphics.circle("line", self.x, self.y, self.radius)
end

return Explosion

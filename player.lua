local Player = {}
Player.__index = Player

function Player.new(x, y, color)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.width = 20
    self.height = 20
    self.color = color
    self.angle = 0
    self.power = 0
    self.turretLength = 30  -- Length of the turret line
    self.isCharging = false
    self.maxPower = 100
    self.charging_speed = 200  -- Increased from 50 to 200
    -- Add movement properties
    self.isMoving = false
    self.isChargingMove = false
    self.moveDistance = 0
    self.maxMoveDistance = 200
    self.moveSpeed = 200  -- Increased from 100 to 200
    self.targetX = x
    self.targetY = y
    self.movePower = 0
    self.recoilVx = 0
    self.recoilVy = 0
    self.recoilDamping = 5  -- How quickly recoil slows down
    self.tracks = {}  -- Store track marks
    self.trackTimer = 0  -- Timer for creating new tracks
    self.trackInterval = 0.1  -- How often to create tracks
    self.lives = 3
    self.startX = x  -- Store initial position for respawn
    self.startY = y
    self.canShoot = true  -- Add shooting cooldown flag
    return self
end

function Player:startCharging()
    if not self.canShoot then return end
    self.isCharging = true
    self.power = 0
end

function Player:stopCharging()
    self.isCharging = false
    -- Return current power for shooting
    local shootPower = self.power
    self.power = 0
    return shootPower
end

function Player:startChargingMove()
    if not self.isMoving then
        self.isChargingMove = true
        self.movePower = 0
    end
end

function Player:stopChargingMove()
    if self.isChargingMove then
        self.isChargingMove = false
        local power = self.movePower
        self.movePower = 0
        -- Calculate target position
        local centerX = self.x + self.width/2
        local centerY = self.y + self.height/2
        self.targetX = centerX + math.cos(self.angle) * power
        self.targetY = centerY + math.sin(self.angle) * power
        self.isMoving = true
        return power
    end
    return 0  -- Return 0 if we weren't charging movement
end

function Player:getTurretEndpoint()
    local centerX = self.x + self.width/2
    local centerY = self.y + self.height/2
    local endX = centerX + math.cos(self.angle) * self.turretLength
    local endY = centerY + math.sin(self.angle) * self.turretLength
    return centerX, centerY, endX, endY
end

function Player:draw()
    -- Draw tracks first
    love.graphics.setColor(0.3, 0.3, 0.3, 0.5)  -- Dark gray tracks
    for _, track in ipairs(self.tracks) do
        love.graphics.setColor(0.3, 0.3, 0.3, track.alpha)
        love.graphics.rectangle("fill", track.x, track.y, track.width, track.height)
    end

    -- Draw tank body
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Draw turret
    love.graphics.setColor(1, 1, 1)  -- White turret
    local startX, startY, endX, endY = self:getTurretEndpoint()
    love.graphics.line(startX, startY, endX, endY)
    
    -- Draw power meter when charging
    if self.isCharging then
        love.graphics.setColor(1, 1, 0)  -- Yellow power bar
        love.graphics.rectangle("fill", self.x, self.y - 10, 
            (self.width * self.power/self.maxPower), 5)
    end
    
    -- Draw move power meter when charging movement
    if self.isChargingMove then
        love.graphics.setColor(0, 1, 1)  -- Cyan move bar
        love.graphics.rectangle("fill", self.x, self.y + self.height + 5, 
            (self.width * self.movePower/self.maxMoveDistance), 5)
    end

    -- Draw lives indicators
    love.graphics.setColor(self.color)
    for i = 1, self.lives do
        love.graphics.rectangle("fill", 
            self.startX + (i-1)*15 - 5, 
            self.startY - 30, 
            10, 10)
    end
end

function Player:update(dt)
    -- Update track timer if moving
    if self.isMoving or math.abs(self.recoilVx) > 0.1 or math.abs(self.recoilVy) > 0.1 then
        self.trackTimer = self.trackTimer + dt
        if self.trackTimer >= self.trackInterval then
            self:addTrack()
            self.trackTimer = 0
        end
    end
    
    -- Fade out tracks
    for i = #self.tracks, 1, -1 do
        local track = self.tracks[i]
        track.alpha = track.alpha - 0.2 * dt  -- Fade speed
        if track.alpha <= 0 then
            table.remove(self.tracks, i)
        end
    end

    if self.isCharging then
        self.power = math.min(self.power + self.charging_speed * dt, self.maxPower)
    end
    
    if self.isChargingMove then
        self.movePower = math.min(self.movePower + self.charging_speed * dt, self.maxMoveDistance)
    end
    
    if self.isMoving then
        local dx = self.targetX - (self.x + self.width/2)
        local dy = self.targetY - (self.y + self.height/2)
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance < 1 then
            self.isMoving = false
        else
            local moveStep = self.moveSpeed * dt
            local ratio = moveStep / distance
            local nextX = self.x + dx * ratio
            local nextY = self.y + dy * ratio
            
            -- Check collision before moving
            local collision = game.playfield:checkCollision(
                nextX, nextY, self.width, self.height
            )
            
            if not collision then
                self.x = nextX
                self.y = nextY
            else
                self.isMoving = false
            end
        end
    end

    -- Apply recoil movement
    if math.abs(self.recoilVx) > 0.1 or math.abs(self.recoilVy) > 0.1 then
        local nextX = self.x + self.recoilVx * dt
        local nextY = self.y + self.recoilVy * dt
        
        -- Check collision before applying recoil movement
        local collision = game.playfield:checkCollision(
            nextX, nextY, self.width, self.height
        )
        
        if not collision then
            self.x = nextX
            self.y = nextY
        end
        
        -- Dampen recoil velocity
        self.recoilVx = self.recoilVx * math.exp(-self.recoilDamping * dt)
        self.recoilVy = self.recoilVy * math.exp(-self.recoilDamping * dt)
    else
        self.recoilVx = 0
        self.recoilVy = 0
    end
end

function Player:addTrack()
    -- Add two tracks for left and right caterpillar
    local trackWidth = 4
    local trackLength = 8
    
    -- Left track
    table.insert(self.tracks, {
        x = self.x - 1,
        y = self.y + self.height/4,
        width = trackWidth,
        height = trackLength,
        alpha = 1.0  -- Track opacity
    })
    
    -- Right track
    table.insert(self.tracks, {
        x = self.x + self.width - 3,
        y = self.y + self.height/4,
        width = trackWidth,
        height = trackLength,
        alpha = 1.0
    })
    
    -- Limit number of tracks
    while #self.tracks > 40 do  -- Keep last 40 track marks
        table.remove(self.tracks, 1)
    end
end

function Player:shoot()
    local centerX, centerY = self.x + self.width/2, self.y + self.height/2
    return {
        x = centerX,
        y = centerY,
        angle = self.angle,
        power = self.power
    }
end

function Player:applyRecoil(power)
    local recoilPower = power * 0.2  -- 20% of shot power becomes recoil
    -- Set initial recoil velocity
    self.recoilVx = -math.cos(self.angle) * recoilPower * 10
    self.recoilVy = -math.sin(self.angle) * recoilPower * 10
end

function Player:respawn()
    self.x = self.startX
    self.y = self.startY
    self.angle = 0
    self.isMoving = false
    self.isCharging = false
    self.isChargingMove = false
    self.recoilVx = 0
    self.recoilVy = 0
end

return Player

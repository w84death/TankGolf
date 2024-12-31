local Player = require('player')
local Playfield = require('playfield')
local Ball = require('ball')
local Explosion = require('explosion')  -- Add this line at the top

local Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    self:reset()
    game = self
    self.explosions = {}  -- Add this line
    return self
end

function Game:reset()
    self.playfield = Playfield.new()
    self.player1 = Player.new(40, 200, {1, 0, 0})  -- Changed to normalized RGB
    self.player2 = Player.new(580, 200, {0, 0, 1})
    self.balls = {}
    self.gameOver = false
    self.winner = nil
    self.roundOver = false
    self.roundTransitionTimer = 0
    self.roundTransitionDuration = 2  -- 2 seconds between rounds
    self.explosions = {}
end

function Game:startNewRound()
    self.roundOver = false
    self.roundTransitionTimer = 0
    self.balls = {}  -- Clear all balls
    self.player1:respawn()
    self.player2:respawn()
    self.player1.canShoot = true
    self.player2.canShoot = true
end

function Game:checkBallCollisions()
    for i = #self.balls, 1, -1 do
        local ball = self.balls[i]
        
        -- Check collision with opposite player
        if ball.color == self.player1.color then
            if self:checkTankHit(ball.x, ball.y, self.player2) then
                self.player2.lives = self.player2.lives - 1
                if self.player2.lives <= 0 then
                    self.gameOver = true
                    self.winner = self.player1
                else
                    self.roundOver = true
                    self.roundTransitionTimer = 0
                end
                table.remove(self.balls, i)
            end
        else
            if self:checkTankHit(shadowX, shadowY, self.player1) then
                self.player1.lives = self.player1.lives - 1
                if self.player1.lives <= 0 then
                    self.gameOver = true
                    self.winner = self.player2
                else
                    self.roundOver = true
                    self.roundTransitionTimer = 0
                end
                table.remove(self.balls, i)
            end
        end
    end
end

function Game:checkTankHit(ballX, ballY, tank)
    return ballX > tank.x and ballX < tank.x + tank.width and
           ballY > tank.y and ballY < tank.y + tank.height
end

function Game:update(dt)
    if self.gameOver then return end
    
    if self.roundOver then
        self.roundTransitionTimer = self.roundTransitionTimer + dt
        if self.roundTransitionTimer >= self.roundTransitionDuration then
            self:startNewRound()
        end
        return
    end
    
    -- Player 1 controls
    if love.keyboard.isDown('left') then
        self.player1.angle = self.player1.angle - 2 * dt
    elseif love.keyboard.isDown('right') then
        self.player1.angle = self.player1.angle + 2 * dt
    end
    
    -- Player 2 controls
    if love.keyboard.isDown('z') then
        self.player2.angle = self.player2.angle - 2 * dt
    elseif love.keyboard.isDown('x') then
        self.player2.angle = self.player2.angle + 2 * dt
    end
    
    self.player1:update(dt)
    self.player2:update(dt)
    
    -- Update balls
    for i = #self.balls, 1, -1 do
        local ball = self.balls[i]
        ball:update(dt)
        if not ball.active then
            table.remove(self.balls, i)
        end
    end

    -- Check if all balls are gone to re-enable shooting
    if #self.balls == 0 then
        self.player1.canShoot = true
        self.player2.canShoot = true
    end

    self:checkBallCollisions()

    -- Update explosions
    for i = #self.explosions, 1, -1 do
        local explosion = self.explosions[i]
        explosion:update(dt)
        if not explosion.active then
            table.remove(self.explosions, i)
        end
    end
end

function Game:addExplosion(x, y)
    table.insert(self.explosions, Explosion.new(x, y))
end

function Game:keypressed(key)
    if self.gameOver then
        if key == 'space' then
            self:reset()
            return
        end
    end
    
    if key == 'rctrl' then
        self.player1:startCharging()
    elseif key == 'c' then
        self.player2:startCharging()
    end
    if key == 'ralt' then
        self.player1:startChargingMove()
    elseif key == 'v' then
        self.player2:startChargingMove()
    end
end

function Game:keyreleased(key)
    if self.gameOver then return end
    
    if key == 'rctrl' and self.player1.canShoot then
        local power = self.player1:stopCharging() or 0
        local shot = self.player1:shoot()
        self.player1.canShoot = false  -- Disable shooting
        table.insert(self.balls, Ball.new(shot.x, shot.y, shot.angle, power, self.player1.color))
        self.player1:applyRecoil(power)
    elseif key == 'c' and self.player2.canShoot then
        local power = self.player2:stopCharging() or 0
        local shot = self.player2:shoot()
        self.player2.canShoot = false  -- Disable shooting
        table.insert(self.balls, Ball.new(shot.x, shot.y, shot.angle, power, self.player2.color))
        self.player2:applyRecoil(power)
    end
    if key == 'ralt' then
        local power = self.player1:stopChargingMove() or 0
        print("Player 1 moving with power: " .. power)
    elseif key == 'v' then
        local power = self.player2:stopChargingMove() or 0
        print("Player 2 moving with power: " .. power)
    end
end

function Game:draw()
    self.playfield:draw()
    self.player1:draw()
    self.player2:draw()
    
    -- Draw balls
    for _, ball in ipairs(self.balls) do
        ball:draw()
    end
    
    -- Draw explosions after everything else
    for _, explosion in ipairs(self.explosions) do
        explosion:draw()
    end
    
    -- Draw game over screen
    if self.gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Game Over! " .. (self.winner == self.player1 and "Red" or "Blue") .. " player wins!", 
            220, 200, 0, 2, 2)
        love.graphics.print("Press SPACE to restart", 250, 250)
    end
    
    if self.roundOver and not self.gameOver then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Hit! Next round in " .. 
            math.ceil(self.roundTransitionDuration - self.roundTransitionTimer) .. "...", 
            220, 200, 0, 2, 2)
    end
    
    -- Draw UI
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Welcome to Tank Golf", 10, 10)
end

return Game

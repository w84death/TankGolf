local Game = require('game')

local game

function love.load()
    love.window.setMode(640, 480, {resizable=false})
    love.window.setTitle("TankGolf")
    game = Game.new()
end

function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

function love.keypressed(key)
    game:keypressed(key)
end

function love.keyreleased(key)
    game:keyreleased(key)
end
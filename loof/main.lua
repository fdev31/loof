loof = require('game')
objects = require('objects')
cfg = require('config')

function love.load()
    game = loof.Game:clone():init()
end

persisting = 0
function love.update(dt)
    game:update(dt)
end

function love.draw()
    game:draw()
end

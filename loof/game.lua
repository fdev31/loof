objects = require('objects')
cfg = require('config')
require('gameboard')
ai = require('ai')
key_funcs = require('key_handlers')
ok, see = pcall(function() return require('inspect').inspect end)
require('menu')

if not ok then
    function see(...)
        print(arg)
    end
end

function dprint(txt)
    if cfg.DEBUG then
        print(txt)
    end
end

Game = objects.object:clone()
function Game:new()
    love.physics.setMeter(cfg.DISTANCE) -- How many pixels for 1 meter
    local self = objects.object.new(self)
    self.board = Board:new()
    love.physics.setMeter(cfg.DISTANCE) --the height of a meter our worlds
    -- set mode
--    cfg.modes = love.window.getFullscreenModes()
--    table.sort(cfg.modes, function(a, b) return a.width*a.height < b.width*b.height end)   -- sort from smallest to largest

    cfg.width = love.graphics.getWidth()
    cfg.height = love.graphics.getHeight()

    self.score = {0, 0}
    self.goal_imgs = {
        objects.Sprite:new('goal1', {0,0} ),
        objects.Sprite:new('goal2', {0,0} )
    }
    self.bar_img = objects.Sprite:new('bar')

    self.cached_menu = MainMenu:new()
    self:reset()
    self.menu = self.cached_menu -- start with MainMenu
    cfg.scale = 1
    cfg.translate = {0,0}
    local os = love.system.getOS()
    self.touchbased = (os == "Android" or os == "iOS")
    return self
end

function Game:update(dt)
    gameInputs:update(dt)
    local maxx, maxy = 0, 0
    local minx, miny = 2000, 2000
    if self.menu == nil then -- no menu (in game)
        -- update main game states
        self.board:update(dt)
        -- update opponents
        ai.step(dt)
        for i, g in ipairs(self.board.opponents) do
            ai.manage(g, dt)
            maxx = math.max(maxx, g.x)
            maxy = math.max(maxy, g.y)
            minx = math.min(minx, g.x)
            miny = math.min(miny, g.y)
        end
        -- take user input
        for i, plr in ipairs(self.board.players) do
            if gameInputs:ispressed(plr.input, 2) then -- escape
                self.menu = self.cached_menu
                return
            end
            if gameInputs:ispressed(plr.input, 1) then -- ok / boost
                plr:boost(dt)
            end
            local x, y = gameInputs:getAxis(plr.input) -- direction keys
            plr:push(x, y, dt)
            maxx = math.max(maxx, plr.x)
            maxy = math.max(maxy, plr.y)
            minx = math.min(minx, plr.x)
            miny = math.min(miny, plr.y)
        end
        if cfg.autozoom then
            maxx = math.max(maxx, self.board.ball.x) + cfg.autozoom_margin
            maxy = math.max(maxy, self.board.ball.y) + cfg.autozoom_margin
            minx = math.min(minx, self.board.ball.x) - cfg.autozoom_margin
            miny = math.min(miny, self.board.ball.y) - cfg.autozoom_margin

            if maxx - minx < cfg.width then
                local mid = minx + (maxx-minx)/2
                minx = mid - (cfg.width / 2)
                maxx = mid + (cfg.width / 2)
            end
            if maxy - miny < cfg.width then
                local mid = miny + (maxy-miny)/2
                miny = mid - (cfg.height / 2)
                maxy = mid + (cfg.height / 2)
            end

            cfg.scale = (math.min(cfg.width/(maxx-minx), cfg.height/(maxy-miny)) + cfg.scale)/2
            if cfg.scale > 1 then
                cfg.scale = 1
            end
            cfg.translate[1] = (cfg.translate[1]*0.9 + (-cfg.scale*minx)*0.1)
            cfg.translate[2] = (cfg.translate[2]*0.9 + (-cfg.scale*miny) *0.1)
        end
    else
        self.menu:update(dt)
    end
end

function Game:drawbars(num, color, m, y_offset, right)
    local y_offset = y_offset or 0
    local lines = 10
    local w = 20 -- width
    local h = 40 -- height
    local m = m or 5 -- margin (x)
    if right then -- align right
        for i=1,self.score[1] do
            y_offset = math.floor((i-1)/lines) 
            self.bar_img:draw(cfg.width - (w+m)*i + ((w+m)*y_offset*lines),  (h+m)*y_offset+(w+m))
        end
    else
        for i=1,num do
            y_offset = math.floor((i-1)/lines) 
            self.bar_img:draw((w+m)*i - (y_offset*(w+m)*lines), (h+m)*y_offset + (w+m), w, h)
        end
    end
end

function Game:draw()
    love.graphics.push()
    love.graphics.translate(unpack(cfg.translate))
    love.graphics.scale(cfg.scale, cfg.scale)
    self.board:draw()
    love.graphics.pop()
    -- SCORE display
    self:drawbars(self.score[2], cfg.colors[1], nil, nil, false)
    self:drawbars(self.score[1], cfg.colors[2], nil, nil, true)
    -- overlays, reference resolution is 1080p
    love.graphics.scale(
        cfg.width/1920,
        cfg.height/1080
    )
    -- goal
    if self.board.goal_marked then
        self.goal_imgs[self.board.goal_team]:draw(0, 0)
    end
    -- menu
    if self.menu ~= nil then
        self.menu:draw()
    end
end

function Game:reset()
    love.graphics.origin()
    self.score = {0, 0}
    if self.board then
        self.board:reset_state() -- resets guy, ball & opponents states
    end
    self.board = Board:new()
    local p1 = objects.Sprite:new('p1')
    for name in pairs(gameInputs.list) do
        self.board:add_player(p1, 'noname', name)
    end
end

return {
    Game = Game
}

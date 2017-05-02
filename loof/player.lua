local baseobj = require('baseobj')

local Dude = baseobj.DrawableInterface:clone()
Dude.head = baseobj.Sprite:new('pawn')

function Dude:new(body, opts)
    local radius = opts and opts.radius or 20
    local self = baseobj.DrawableInterface.new(self, body, love.physics.newCircleShape(radius)) 
    self.side = opts and opts.side or -1
    self.color = opts and opts.color or {0, 0, 0}
    self.radius = radius
    self.boosted = nil
    -- bounce settings
    self.body:setMass(2)
    self.body:setBullet(true)
    self.body:setLinearDamping(0.9)
    self.fixture:setRestitution(0.4)
    self.fixture:setFriction(0.3)
    self.fixture:setUserData('Dude')
    self.feet = {0, 0}
    self.x = 0
    self.y = 0
    return self
end

function Dude:destroy()
    self.fixture:destroy()
    self.body:destroy()
    self.body = nil
    self.fixture = nil
end

function Dude:reset()
    baseobj.DrawableInterface.reset(self)
    self.shot        = nil
    self.pushed      = nil
    self.boosted     = nil
    self.slowed_down = nil
end

function Dude:draw()
    baseobj.DrawableInterface.draw(self)
    if self.img ~= nil then
        self.img:draw(self.body:getX(), self.body:getY())
    else
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius)
        love.graphics.setColor(unpack(self.color))
        love.graphics.circle("fill", self.body:getX(), self.body:getY(), self.radius-5)
    end
    if self.targetting then
        love.graphics.setColor(0, 255, 0)
    else
        love.graphics.setColor(0, 0, 0)
    end

    self.head:draw(unpack(self.feet))

    local sx, sy = self.body:getLinearVelocity()
    local s = normalVelocity(sx, sy)
    local x = self.body:getX()+(self.radius*s[1])
    local y = self.body:getY()+(self.radius*s[2])

    self.feet = {x, y}
end

function Dude:hit() -- dude is pushed by someone
    self.pushed = 1
end

function Dude:update(dt)
    local x, y = self.body:getLinearVelocity()
    if self.last_boost ~= nil then
        self.last_boost = self.last_boost - dt
        if self.last_boost < 0 then
            self.last_boost = nil
        end
    end
    if self.pushed ~= nil then
        if self.pushed == 1 then
            dprint("PUSHED, SHOOTING !!!")
            self:boost(dt)
        end
        self.pushed = self.pushed + dt
    end
    if self.pushed and self.pushed >= 0.3 then
        self.pushed = nil
    end
    if self.shot ~= nil then
        self.shot = self.shot + dt
        if self.shot > 1.5 then
            self.shot = nil
            dprint("shot = nil")
        end
    end

    if self.boosted ~= nil then
        self.boosted = dt + self.boosted
        if self.boosted >= 0.1 then
            if self.slowed_down == nil then
                self.body:setLinearVelocity(0, 0)
            end
        end
        if self.boosted >= 0.2 then
            if self.pushed then
                self.pushed = nil
            else
                self.slowed_down = self.boosted
                self.last_boost = 2
            end
            self.boosted = nil
        end
    end
    if self.slowed_down ~= nil then
        self.slowed_down = self.slowed_down + dt
        x = x/2
        y = y/2
        if self.slowed_down > 0.5 then
            self.slowed_down = nil
            dprint("reset")
        end
    end
    self.body:setLinearVelocity(x, y)
end

function Dude:push(x, y, dt) -- make the dude move
    if x ~= 0 or y ~= 0 and not self.boosted and not self.slowed_down then
        local coef = 1/math.sqrt( math.abs(x)^2 + math.abs(y)^2)
        self.body:applyForce(x*cfg.POWER*dt*coef, y*cfg.POWER*dt*coef)
    end
end

function Dude:boost(dt) -- boost button pressed
    local sx, sy = self.body:getLinearVelocity()
    s = normalVelocity(sx, sy)
    if s[1] == s[1] then
        if self.ball then
            local ball = self.ball
            self.shot = 1
            dprint("shot = 1")
            ball:attach(nil)
            ball.body:setPosition(self.feet[1]+s[1]*self.radius, self.feet[2]+s[2]*self.radius)
            ball.body:setLinearVelocity(s[1] * cfg.BALL_SPEED, s[2]*cfg.BALL_SPEED) 
        elseif not self.shot and self.boosted == nil and self.slowed_down == nil then
            dprint("boost !")
            if self.last_boost == nil then
                self.boosted = 0.0001
                local asx = math.abs(sx)
                local asy = math.abs(sy)
                coef = 1/math.sqrt( asx^2 + asy^2)
                self.body:setLinearVelocity(sx*2 + s[1]*cfg.POWER/100, sy*2 + s[2]*cfg.POWER/100)
            end
        end
    end
end

return {
    Dude = Dude
}

key_funcs = require('key_handlers')

local Entry = objects.object:clone()

function Entry:handle(menu, key)
    return self.handler(menu, self, key)
end

local SimpleEntry = Entry:clone()

function SimpleEntry:new(name, handler)
    local self = Entry.new(self)
    self.handler = handler
    self.selected = objects.Sprite:new('menu_' .. name .. '_sel', {0,0})
    self.unselected = objects.Sprite:new('menu_' .. name , {0,0})
    return self
end

function SimpleEntry:draw(x, y, selected)
    if selected then
        self.selected:draw(x,y)
    else
        self.unselected:draw(x,y)
    end
end

local LeftRightEntry = Entry:clone()

function LeftRightEntry:new(name)
    local self = Entry.new(self)
    self.position = 0
    self.offset = 200
    self.label = SimpleEntry:new(name)
    self.movable = {
        objects.Sprite:new('menu_movable_left', {0,0}),
        objects.Sprite:new('menu_movable', {0,0}),
        objects.Sprite:new('menu_movable_right', {0,0}),
    }
    return self
end
function LeftRightEntry:handle(menu, key)
    print(self, menu, key)
    if key == 'left' then
        self:move_left()
    elseif key == 'right' then
        self:move_right()
    end
end

function LeftRightEntry:draw(x, y, selected)
    self.label:draw(x, y, selected)
    self.movable[2+self.position]:draw(
    x + self.label.selected.width + 20 + self.offset + (self.position*self.offset),
    y + self.label.selected.height/2
    )
end

function LeftRightEntry:move_left()
    if self.position > -1 then
        self.position = self.position - 1
    end
end
function LeftRightEntry:move_right()
    if self.position < 1 then
        self.position = self.position + 1
    end
end

local Menu = objects.object:clone()

function Menu:new(background, choices)
    local self = objects.object.new(self)
    self.background = objects.Sprite:new(background, {0,0} )
    self.choices = choices
    self.selected = 1
    self.last_ts = 0
    self.ts = 0
    self.repeat_max = 0.2
    self.entries = choices

    return self
end

function Menu:update(dt)
    self.ts = self.ts + dt
    if self.last_ts + self.repeat_max > self.ts then
        return
    end
        
    if gameInputs:ispressed('*', 'down') then
        if self.selected < #self.choices then
            self.last_ts = self.ts
            self.selected = self.selected + 1
        end
    elseif gameInputs:ispressed('*', 'up') then
        if self.selected > 1 then
            self.last_ts = self.ts
            self.selected = self.selected - 1
        end
    elseif gameInputs:ispressed('*', 2) then
        self.last_ts = self.ts
        key_funcs.pop_one_level()
    elseif gameInputs:ispressed('*', 1) then
        self.last_ts = self.ts
        self.choices[self.selected]:handle(self, 'return')
    elseif gameInputs:ispressed('*', 'left') then
        self.last_ts = self.ts
        self.choices[self.selected]:handle(self, 'left')
    elseif gameInputs:ispressed('*', 'right') then
        self.last_ts = self.ts
        self.choices[self.selected]:handle(self, 'right')
    end
end

function Menu:draw()
    self.background:draw(0, 0)
    for i, entry in ipairs(self.entries) do
        entry:draw(300, i*100, self.selected == i)
    end
end

MainMenu = Menu:clone()

function MainMenu:new()
    local self = Menu.new(self, 'menu', {
        SimpleEntry:new('NewGame', MainMenu.handle_NewGame),
        SimpleEntry:new('Enemies', MainMenu.handle_Enemies),
        SimpleEntry:new('Quit',    MainMenu.handle_Quit),
--        LeftRightEntry:new('Enemies'),
    })
    return self
end

function MainMenu:draw()
    Menu.draw(self)
    for i=1,#game.board.opponents do
        game.board.opponents_img:draw(640 + 50*i, 250)
    end
end

MainMenu.handle_Quit = love.event.quit
MainMenu.handle_Resume = key_funcs.pop_one_level

function MainMenu:handle_NewGame(entry, key)
    game:reset()
    key_funcs.pop_one_level()
end

function MainMenu:handle_Enemies(entry, key)
    if key == 'right' then
        game.board:add_opponent()
    elseif key == 'left' then
        game.board:remove_opponent()
    end
end


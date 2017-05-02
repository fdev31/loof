function love.conf(t)
    t.window.title = "Loof!"
    t.window.width = 0
    t.window.height = 0
    t.window.vsync = true
    t.window.fullscreen = true
    t.window.fullscreentype = "exclusive"
    t.modules.joystick = true
    t.modules.physics = true
end

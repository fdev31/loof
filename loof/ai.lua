
local managed = {}

local function step(dt)
    managed.have_ball = false
    managed.toball_cnt = 0
    managed.agressive_cnt = 0
    managed.tofront_cnt = 0
    managed.togoal_cnt = 0
    for dude in pairs(managed) do
        if dude.ball then
            managed.have_ball = true
            break
        end
    end
end

local function manage(dude, dt)
    if managed[dude] == nil then
        managed[dude] = {
            mode = 'toball',
            lastmode_ts = 0,
        }
    end
    local infos = managed[dude]
    local mode_duration = 3 -- duration of one mode, in seconds

    local g = game.board.goals[1]
    -- find out what mode to apply (kinda state machine)
    if dude.ball then -- this dude have the ball !!
        if dude.y > g[2] and dude.y < g[4] and dude.x - g[1] < 600 then -- when near the goal
            infos.mode = 'togoal'
            managed.togoal_cnt = managed.togoal_cnt + 1
        else
            infos.mode = 'tofrontgoal'
            managed.tofront_cnt = managed.tofront_cnt + 1
        end
    else
        -- shuffle time !
        if cfg.difficulty > 1 and managed.have_ball then -- one team guy owns the ball, let's go to the ennemy !
            infos.mode = 'agressive'
            managed.agressive_cnt = managed.agressive_cnt + 1
        elseif infos.lastmode == nil or infos.lastmode_ts  > mode_duration then -- we don't have ball :'(
            infos.lastmode_ts = 0
            if cfg.difficulty > 1 and managed.toball_cnt > 0 and (math.random() < 0.5 or managed.toball_cnt == 0) then -- ensureone agressive, then one to ball
                infos.mode = 'agressive' -- make one agressive, then random
                managed.agressive_cnt = managed.agressive_cnt + 1
            else
                infos.mode = 'toball' -- if one agressive then one here, then random
                managed.toball_cnt = managed.toball_cnt + 1
            end
            infos.lastmode = infos.mode
        else -- repeat last mode if not elapsed (no shuffle)
            infos.lastmode_ts = infos.lastmode_ts + dt
            infos.mode = infos.lastmode
        end
    end

    -- now apply the behavior according to the chosen mode
    local x, y = nil, nil

    if infos.mode == 'agressive' then
        local tgt, dist
        -- TODO: check all players instead of random one
        local some_dude = game.board.players[math.random(1, #game.board.players)]
        tgt, dist, x, y = dude:targets(some_dude)
        if not dude.boosted and tgt and dist < 100 then
            dude:boost(dt)
        end
    elseif infos.mode == 'toball' then
        x, y = dude:distance(game.board.ball)
    else
        local tgt, dist
        tgt, dist, x, y = dude:targets( g[3], game.board.background.height / 2, 0.2)
        if cfg.difficulty > 0 and tgt and  dist < 600 then
            dude:boost(dt) -- shoot
        end
    end

    if x then
        local s = normalVelocity(x, y)
        if s and s[1] == s[1] then
            dude:push(s[1], s[2], dt)
        end
    end
end


local function clear()
    managed = {}
end

return {
    manage = manage,
    step = step,
    clear = clear,
}

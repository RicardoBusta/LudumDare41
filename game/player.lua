local player = {}

-- Constant Parameters
local twopi = math.pi * 2
local size2 = 32
local size = size2 / 2
local tileship2 = (size * math.sqrt(2) + size) ^ 2 -- max distance to the center of the tile to the center of the ship
local tacc = 200 -- thruster acceleration
local grav = 80 -- gravity
local deadlyspeed = 50
local minangle = math.pi / 9
local maxangle = twopi - minangle

-- Player State
local px, py = 0, 0 -- position x, y
local sx, sy = 0, 0 -- speed x, y
local rot = 0 -- rotation
local accrot = 0 -- rotation acceleration
local srot = 0 -- rotation speed
local sl, sr = 0, 0 -- speed from thrusters
local tx, ty = 0, 0 -- player in tile coordinates
local speed = 0
local dead = false
local landed = false
local win = false

local diebyspeed = false
local diebyrotation = false

-- References
local lg = love.graphics
local sprite = nil
local sprx = 0
local spry = 0

local spawnx, spawny = 0, 0

function player.init()
    sprite = sprites.player
    sprx = sprite:getWidth() / 2
    spry = sprite:getHeight() / 2
end

function player.thrust(l, r)
    sl = l
    sr = r
    accrot = 10 * (l - r)
end

function player.update(dt)
    if landed then
        return
    end
    local acc = tacc * (sl + sr) -- acceleration is the sum of both thrusters

    -- Accelerate the ship
    sx = sx + acc * math.sin(rot) * dt
    sy = sy + -acc * math.cos(rot) * dt + grav * dt
    srot = srot + accrot * dt

    -- Move the ship
    px = px + sx * dt
    py = py + sy * dt
    rot = rot + srot * dt
    rot = rot % twopi

    -- Update coords
    tx = math.floor((px - 16) / 32)
    ty = math.floor((py - 16) / 32)
    speed = math.sqrt(sx ^ 2 + sy ^ 2)

    diebyspeed = speed >= deadlyspeed
    diebyrotation = (rot <= maxangle and rot >= minangle)
end

function player.draw()
    lg.draw(sprite, px, py, rot, nil, nil, sprx, spry)

    lg.push()
    love.graphics.translate(px,py)
    love.graphics.rotate(rot)
    lg.draw(sprites.fire, -17, 17, 0, 1,sl)
    lg.draw(sprites.fire, 7, 17, 0, 1,sr)
    lg.pop()
end

function player.getinfo()
    return speed, srot
end

function player.detectcollision(tiles)
    local mx, my = (tx + 1), (ty + 1) -- center in tile coord
    local cx, cy = tx * size2 + size, ty * size2 + size -- center in pixel coord

    dead = false
    win = false
    local collide = false

    collide =
        collidewithtile(tiles, tx, ty) or collidewithtile(tiles, tx + 1, ty) or collidewithtile(tiles, tx + 1, ty + 1) or
        collidewithtile(tiles, tx, ty + 1)

    return collide
end

function collidewithtile(tiles, x, y)
    local mx, my = (x + 1), (y + 1) -- center in tile coord
    local cx, cy = x * size2 + size, y * size2 + size -- center in pixel coord

    if tiles[my] and tiles[my][mx] then
        local tid = tiles[my][mx].id
        if math.abs(px - cx) <= size or math.abs(py - cy) <= size or distanceto2(cx, cy, px, py) <= tileship2 then
            if tid < 12 or player.dieconditions() then
                dead = true
            elseif tid == 14 or tid == 15 then
                win = true
            end
            return true
        end
    end
    return false
end

function player.dieconditions()
    return diebyrotation or diebyspeed
end

function player.debugcollision(tiles)
    player.debugcollisiontile(tiles, 0, 0)
    player.debugcollisiontile(tiles, 1, 0)
    player.debugcollisiontile(tiles, 0, 1)
    player.debugcollisiontile(tiles, 1, 1)

    lg.circle("line", px, py, 16)
end

function player.debugcollisiontile(tiles, ox, oy)
    local x, y = tx + ox, ty + oy
    local mx, my = x + 1, y + 1
    if tiles[my] and tiles[my][mx] then
        lg.print(tiles[my][mx].id, x * 32, y * 32)
    end

    lg.rectangle("line", x * 32, y * 32, 32, 32)
end

function player.land()
    landed = true
    player.reset()
    py = math.floor((py + 16) / 32) * 32 + 16
end

function player.reset()
    sx, sy, rot, srot = 0, 0, 0, 0
    px, py = spawnx, spawny
end

function player.fly()
    landed = false
end

function player.islanded()
    return landed
end

function player.isdead()
    return dead
end

function player.iswin()
    return win
end

function setspawn(x, y)
    spawnx, spawny = x, y
end

return player

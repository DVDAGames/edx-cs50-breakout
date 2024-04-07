--[[
    GD50
    Breakout Remake

    -- PowerUp Class --

    Author: DVDA Games
    hello@dvdagames.com

    Represents a powerUp that can be spawned in the game.
    When the Paddle collides with the powerUp, the powerUp
    applies to the player's Paddle.
]]

PowerUp = Class{}

function PowerUp:init(x, y, type)
    self.x = x
    self.y = y
    self.width = 16
    self.height = 16
    self.type = type
    self.dy = -50
    self.dx = math.random(-50, 50)
    self.inPlay = true
end

function PowerUp:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    if self.y > VIRTUAL_HEIGHT then
        self.inPlay = false
    end

    if self.x <= 0 then
        self.x = 0
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.x >= VIRTUAL_WIDTH - 8 then
        self.x = VIRTUAL_WIDTH - 8
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.y <= 0 then
        self.y = 0
        self.dy = -self.dy
        gSounds['wall-hit']:play()
    end
end

function PowerUp:collides(target)
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    return true
end

function PowerUp:render()
    if self.inPlay then
        local spriteIndex = 10
        if self.type == 'key' then
            spriteIndex = 10
        elseif self.type == 'doubleBall' then
            spriteIndex = 9
        end

        love.graphics.draw(gTextures['main'], gFrames['powerUps'][spriteIndex],
            self.x, self.y)
    end
end

function PowerUp:activate(paddle)
    if self.type == 'doubleBall' then
        paddle:powerUp('doubleBall')
    elseif self.type == 'key' then
        paddle:powerUp('key')
    end
end

function PowerUp:deactivate(paddle)
    if self.type == 'doubleBall' then
        paddle:removePowerUp('doubleBall')
    elseif self.type == 'key' then
        paddle:removePowerUp('key')
    end
end

function PowerUp:hit()
    self.inPlay = false
end

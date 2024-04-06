--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: DVDA Games
    hello@dvdagames.com

    Represents a powerup that can be spawned in the game.
    When the Paddle collides with the powerup, the powerup
    applies to the player's Paddle.
]]

Powerup = Class{}

function Powerup:init(x, y, type)
    self.x = x
    self.y = y
    self.width = 16
    self.height = 16
    self.type = type
    self.dy = 50
    self.inPlay = true
end

function Powerup:update(dt)
    self.y = self.y + self.dy * dt

    if self.y > VIRTUAL_HEIGHT then
        self.inPlay = false
    end
end

function Powerup:collides(target)
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end

    return true
end

function Powerup:render()
    if self.inPlay then
      -- TODO: figure out why the powerup sprite doesn't use the right type
        local spriteIndex = 10

        if self.type == 'key' then
            spriteIndex = 10
        elseif self.type == 'double' then
            spriteIndex = 9
        end

        love.graphics.draw(gTextures['main'], gFrames['powerups'][spriteIndex],
            self.x, self.y)
    end
end

function Powerup:activate(paddle)
    if self.type == 'double' then
        paddle:powerup('double')
    elseif self.type == 'key' then
        paddle:powerup('key')
    end
end

function Powerup:deactivate(paddle)
    if self.type == 'double' then
        paddle:removePowerup('double')
    elseif self.type == 'key' then
        paddle:removePowerup('key')
    end
end

function Powerup:hit()
    self.inPlay = false
end

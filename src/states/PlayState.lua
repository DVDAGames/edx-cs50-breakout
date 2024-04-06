--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    self.locks = params.locks == nil and 0 or params.locks

    self.recoverPoints = 5000
    self.paddleResizePoints = 3500
    self.resizeScore = 0

    self.powerUpTimer = 0
    self.powerUpScore = 0
    self.powerUpSpawnTime = 25
    self.powerUpSpawnScore = 7500

    self.powerup = nil

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    local bricksLeft = 0

    self.powerUpTimer = self.powerUpTimer + dt

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)

    if self.powerup then
        self.powerup:update(dt)
    end

    if self.ball:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        self.ball.y = self.paddle.y - 8
        self.ball.dy = -self.ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if self.ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
        end

        gSounds['paddle-hit']:play()
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        if brick.inPlay then
            bricksLeft = bricksLeft + 1
        end

        -- only check collision if we're in play
        if brick.inPlay and self.ball:collides(brick) then

            -- trigger the brick's hit function
            local hit = brick:hit(self.paddle.powerups, self.unlock)

            if hit then
                -- add to score
                self.score = self.score + brick.points

                self.resizeScore = self.resizeScore + brick.points

                self.powerUpScore = self.powerUpScore + brick.points
            end

            -- if we have enough points, shrink the paddle
            if self.resizeScore > self.paddleResizePoints then
                -- can't go below 1 size
                self.paddle:setSize(self.paddle.size - 1)

                -- increase paddle resize points by 25%
                self.paddleResizePoints = self.paddleResizePoints + math.min(100000, self.paddleResizePoints * 1.25)

                -- reset resize score
                self.resizeScore = 0

                -- play shrink sound effect
                gSounds['shrink']:play()
            end

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.ball.x + 2 < brick.x and self.ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.ball.x + 6 > brick.x + brick.width and self.ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball.dy) < 150 then
                self.ball.dy = self.ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT then
        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            self.paddle:setSize(self.paddle.size + 1)
            self.resizeScore = 0
            self.paddleResizePoints = 3500

            -- play grow sound effect
            gSounds['grow']:play()

            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    else
        

        -- spawn a key powerup if the player only has locked bricks left
        if bricksLeft == self.locks and self.paddle.powerups['key'] == 0 then
            self.powerUpTimer = 0
            self.powerUpScore = 0

            self.powerup = Powerup(
                VIRTUAL_WIDTH / 2,
                VIRTUAL_HEIGHT / 3,
                'key'
            )

        -- spawn a power up if the powerup timer or score has been reached
        elseif self.powerUpTimer > self.powerUpSpawnTime or self.powerUpScore > self.powerUpSpawnScore then
            self.powerUpTimer = 0
            self.powerUpScore = 0

            -- generate a powerup
            if self.paddle.powerups['key'] == 0 and self.locks > 0 then
                -- we need a key
                self.powerup = Powerup(
                    VIRTUAL_WIDTH / 2,
                    VIRTUAL_HEIGHT / 3,
                    'key'
                )
            elseif self.paddle.powerups['doubleBall'] == 0 then
                -- we need a double ball
                self.powerup = Powerup(
                    VIRTUAL_WIDTH / 2,
                    VIRTUAL_HEIGHT / 3,
                    'doubleBall'
                )
            end
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()

    self.paddle:renderParticles()

    if self.powerup then
        self.powerup:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end

function PlayState:unlock()
    self.locks = clamp(0, self.locks - 1, self.locks)
end
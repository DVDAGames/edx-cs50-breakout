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
    self.balls = params.balls
    self.level = params.level
    self.locks = params.locks == nil and 0 or params.locks

    self.recoverPoints = params.recoverPoints == nil and 5000 or params.recoverPoints
    self.paddleResizePoints = params.paddleResizePoints == nil and 3500 or params.paddleResizePoints
    self.resizeScore = params.resizeScore == nil and 0 or params.resizeScore

    self.powerUpTimer = params.powerUpTimer == nil and 0 or params.powerUpTimer
    self.powerUpScore = params.powerUpScore == nil and 0 or params.powerUpScore
    self.powerUpSpawnTime = params.powerUpSpawnTime == nil and math.random(20, 30) or params.powerUpSpawnTime
    self.powerUpSpawnScore = params.powerUpSpawnScore == nil and math.random(2500, 7500) or params.powerUpSpawnScore
    self.powerUpCooldownTime = params.powerUpCooldownTime == nil and self.powerUpSpawnTime * 3 or params.powerUpCooldownTime
    self.powerUpCooldownTimer = params.powerUpCooldownTimer == nil and 0 or params.powerUpCooldownTimer

    self.powerUp = nil

    if DEBUG_MODE then
        self.recoverPoints = 500
        self.paddleResizePoints = 350
        self.powerUpSpawnTime = 5
        self.powerUpSpawnScore = 100
    end

    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)
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

    self.powerUpTimer = self.powerUpTimer + dt

    if not self.powerUp and (self.paddle.powerUps['key'] == 0 and self.locks > 0 or self.paddle.powerUps['doubleBall'] == 0) then
        self.powerUpCooldownTimer = self.powerUpCooldownTimer + dt
    end

    -- update positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)

        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy
    
            --
            -- tweak angle of bounce based on where it hits the paddle
            --
    
            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end
    
            gSounds['paddle-hit']:play()
        end

        -- handle ball on ball collision
        for k2, ball2 in pairs(self.balls) do
            if not k2 == k then
                if ball:collides(ball2) then
                    -- flip velocities
                    local tempDx = ball.dx
                    local tempDy = ball.dy

                    ball.dx = ball2.dx
                    ball.dy = ball2.dy

                    ball2.dx = tempDx
                    ball2.dy = tempDy

                    -- make sure they don't get stuck together
                    ball.x = ball.x + ball.dx * dt
                    ball.y = ball.y + ball.dy * dt

                    ball2.x = ball2.x + ball2.dx * dt
                    ball2.y = ball2.y + ball2.dy * dt
                end
            end
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do
        -- only check collision if we're in play
        if brick.inPlay then

            -- make power up bounce around like the ball
            if self.powerUp then
                if self.powerUp:collides(brick) then
                    brick:hit(self.paddle.powerUps, true)

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
                    if self.powerUp.x + 8 < brick.x and self.powerUp.dx > 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        self.powerUp.dx = -self.powerUp.dx
                        self.powerUp.x = brick.x - 16
                    
                    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                    -- so that flush corner hits register as Y flips, not X flips
                    elseif self.powerUp.x + 8 > brick.x + brick.width and self.powerUp.dx < 0 then
                        
                        -- flip x velocity and reset position outside of brick
                        self.powerUp.dx = -self.powerUp.dx
                        self.powerUp.x = brick.x + 32
                    
                    -- top edge if no X collisions, always check
                    elseif self.powerUp.y < brick.y then
                        
                        -- flip y velocity and reset position outside of brick
                        self.powerUp.dy = -self.powerUp.dy
                        self.powerUp.y = brick.y - 16
                    
                    -- bottom edge if no X collisions or top collision, last possibility
                    else
                        
                        -- flip y velocity and reset position outside of brick
                        self.powerUp.dy = -self.powerUp.dy
                        self.powerUp.y = brick.y + 32
                    end

                    -- only allow colliding with one brick, for corners
                    break
                end
            end

            for k, ball in pairs(self.balls) do
                if ball.inPlay then
                    -- if ball goes below bounds, revert to serve state and decrease health
                    if ball.y >= VIRTUAL_HEIGHT then
                        ball.inPlay = false

                        self.paddle:removePowerUp('doubleBall')

                        -- if we were on our last ball, reduce health
                        if self:ballsInPlay() < 1 then
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
                                self.powerUp = nil

                                -- play grow sound effect
                                gSounds['grow']:play()

                                gStateMachine:change('serve', {
                                    paddle = self.paddle,
                                    bricks = self.bricks,
                                    locks = self.locks,
                                    health = self.health,
                                    score = self.score,
                                    highScores = self.highScores,
                                    level = self.level,
                                    recoverPoints = self.recoverPoints,
                                    resizeScore = self.resizeScore,
                                    powerUpTimer = self.powerUpTimer,
                                    powerUpScore = self.powerUpScore,
                                    powerUpSpawnTime = self.powerUpSpawnTime,
                                    powerUpSpawnScore = self.powerUpSpawnScore,
                                    powerUpCooldownTimer = self.powerUpCooldownTimer
                                })
                            end
                        end

                        -- if the player has run out of health
                        
                    else

                        if ball:collides(brick) then
                            -- trigger the brick's hit function
                            local hit = brick:hit(self.paddle.powerUps)

                            if hit then
                                -- add to score
                                self.score = self.score + brick.points

                                self.resizeScore = self.resizeScore + brick.points

                                self.powerUpScore = self.powerUpScore + brick.points
                                
                                if brick.isLocked then
                                    self:unlock()
                                end
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

                                -- if the player was working with an extra ball and 0 hearts
                                -- trigger the game over state when the level is cleared
                                if #self.balls == 0 and self.health == 0 then
                                    gStateMachine:change('game-over', {
                                        score = self.score,
                                        highScores = self.highScores
                                    })
                                else
                                    gStateMachine:change('victory', {
                                        level = self.level,
                                        paddle = self.paddle,
                                        health = self.health,
                                        score = self.score,
                                        highScores = self.highScores,
                                        ball = self.balls[1],
                                        recoverPoints = self.recoverPoints,
                                        resizeScore = self.resizeScore,
                                        powerUpTimer = self.powerUpTimer,
                                        powerUpScore = self.powerUpScore,
                                        powerUpSpawnTime = self.powerUpSpawnTime,
                                        powerUpSpawnScore = self.powerUpSpawnScore,
                                        powerUpCooldownTimer = self.powerUpCooldownTimer
                                    })
                                end
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
                            if ball.x + 2 < brick.x and ball.dx > 0 then
                                
                                -- flip x velocity and reset position outside of brick
                                ball.dx = -ball.dx
                                ball.x = brick.x - 8
                            
                            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                            -- so that flush corner hits register as Y flips, not X flips
                            elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                                
                                -- flip x velocity and reset position outside of brick
                                ball.dx = -ball.dx
                                ball.x = brick.x + 32
                            
                            -- top edge if no X collisions, always check
                            elseif ball.y < brick.y then
                                
                                -- flip y velocity and reset position outside of brick
                                ball.dy = -ball.dy
                                ball.y = brick.y - 8
                            
                            -- bottom edge if no X collisions or top collision, last possibility
                            else
                                
                                -- flip y velocity and reset position outside of brick
                                ball.dy = -ball.dy
                                ball.y = brick.y + 16
                            end

                            -- slightly scale the y velocity to speed up the game, capping at +- 150
                            if math.abs(ball.dy) < 150 then
                                ball.dy = ball.dy * 1.02
                            end

                            -- only allow colliding with one brick, for corners
                            break
                        end
                    end
                else
                    -- remove the ball from play if it goes below the screen
                    table.remove(self.balls, k)
                end
            end
        end
    end

    -- don't respawn a powerUp if one is already in play
    if self.powerUp then
        self.powerUp:update(dt)
    
        if self.powerUp.inPlay then
            if self.powerUp:collides(self.paddle) then
                self.powerUp:activate(self.paddle)
                self.powerUp = nil

                gSounds['powerUp']:stop()
                gSounds['powerUp']:play()
            end
        else
            self.powerUp = nil
        end
    else

        -- spawn a key powerUp if the player only has locked bricks left
        -- and doesn't already have the key
        if self:onlyLocksLeft() and self.paddle.powerUps['key'] == 0 and self.powerUpCooldownTimer >= self.powerUpCooldownTime / 2 then
            self.powerUpTimer = 0
            self.powerUpScore = 0
            self.powerUpCooldownTimer = 0
            self.powerUpSpawnScore = math.min(self.powerUpSpawnScore * 1.25, 150000)

            self.powerUp = PowerUp(
                clamp(VIRTUAL_WIDTH * 0.1, self.paddle.x, VIRTUAL_WIDTH * 0.9),
                self.paddle.y - 32,
                'key'
            )

        -- possibly spawn a power up if the powerUp timer or score has been reached
        elseif (self.powerUpTimer > self.powerUpSpawnTime or self.powerUpScore > self.powerUpSpawnScore) and self.powerUpCooldownTimer >= self.powerUpCooldownTime then
            self.powerUpTimer = 0
            self.powerUpScore = 0
            self.powerUpCooldownTimer = 0

            -- generate a powerUp
            if self.paddle.powerUps['key'] == 0 and self.locks > 0 then
                -- we need a key
                self.powerUp = PowerUp(
                    clamp(VIRTUAL_WIDTH * 0.1, self.paddle.x, VIRTUAL_WIDTH * 0.9),
                    self.paddle.y - 32,
                    'key'
                )
            elseif self.paddle.powerUps['doubleBall'] == 0 and #self.balls == 1 then
                -- we need a double ball
                self.powerUp = PowerUp(
                    clamp(VIRTUAL_WIDTH * 0.1, self.paddle.x, VIRTUAL_WIDTH * 0.9),
                    self.paddle.y - 32,
                    'doubleBall'
                )
            end
        end
    end

    -- if we have the double ball powerUp, but only one ball is in play
    if self.paddle.powerUps['doubleBall'] == 1 and #self.balls == 1 then
        -- create a new ball
        local ball = Ball()
        ball.skin = math.random(7)

        ball.x = self.paddle.x + (self.paddle.width / 2) - 4
        ball.y = self.paddle.y - 8

        ball.dx = math.random(-200, 200)
        ball.dy = math.random(-50, -60)

        table.insert(self.balls, ball)
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:ballsInPlay()
    local ballsInPlay = 0

    for k, ball in pairs(self.balls) do
        if ball.inPlay then
            ballsInPlay = ballsInPlay + 1
        end
    end

    return ballsInPlay
end

function PlayState:onlyLocksLeft()
    local bricksLeft = 0

    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            bricksLeft = bricksLeft + 1
        end
    end

    if self.locks == bricksLeft then
        return true
    end

    return false
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
    
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    self.paddle:renderParticles()

    if self.powerUp then
        self.powerUp:render()
    end

    renderScore(self.score)
    renderHealth(self.health)
    renderPowerUps(self.paddle)

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
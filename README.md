# edX CS50 Introduction to Game Development: Breakout

This is `Project 2` for [CS50's Introduction to Game Development](https://cs50.harvard.edu/games/2018/).

The game is a clone of the classic Atari game Breakout, where the player must use a paddle to bounce a ball upwards, towards a wall of bricks. The ball will bounce off the walls and the bricks, and if it hits the bottom of the screen, the player will lose a life. The player wins a level once all the bricks are destroyed.

The goal of this project is to take the provided [Love2D]() project and add several features to it:

- [x] PowerUp Class and spawning PowerUps
- [x] Double Ball PowerUp
- [x] Key PowerUp
- [x] Locked bricks that require key PowerUp to break
- [x] Dynamic paddle size based on score and losing a life

## Dynamic Paddle Size

The project description said to shrink the paddle when the user loses a heart and increase it as the score increases, but I intend to use the reverse logic in order to make it easier for players that are having trouble and harder for players who are already excelling.

However, in order to make the game a little more forgiving for less skilled players and a little more challenging for more skilled players, I implemented a dynamic paddle system that reverses the project description's logic:

**The paddle shrinks as the players score increases and grows each time the player loses a heart.**

Punishing a player for failing by making the game feel harder is a mechanic best suited for more hardcore games, like a Souls-like, and not quite appropriate for something like Breakout.

I believe that the mechanic that I implemented leads to a more fun and engaging experience for players across the spectrum of skill levels.

This was easy to implement by adding a `Paddle:setSize()` method that allows the developer to set the paddle's size to:

- `1`: `16px`
- `2`: `32px` (the default size)
- `3`: `64px`
- `4`: `128px`

And then calling that method when the player loses a heart or reaches a certain score threshold.

The growth and shrink events both trigger a new sound effect.

### Assistive Paddle Growth

![paddle growing](./assets/breakout-paddle-help.gif)

The paddle will increment in size, up to size `4`, each time the player loses a heart.

### Reactive Paddle Shrinkage 

![paddle shrinking](./assets/breakout-paddle-shrink.gif)

When the player reaches `3500` points since the last time they lost a heart - or the start of the game - the paddle will shrink one size, to a minimum of size `1` (which is `16px` wide).

This counter resets every time the player loses a heart and also increases by 25% each time the player encounters a paddle shrink, so a player with a paddle of size `3` will need to score `3500` points to reach the default of size `2` and then another `4375` points to reach the smallest size of `1`. If they lose a heart, the paddle size will grow and the counter will reset to `3500` points for a shrink event.

### Clamping Paddle Size

In order to make it easier to just set the size to the current size minus 1 or plus 1 without worrying about over/under flowing the `PADDLE_SIZE` table, I borrowed the [`clamp()` function from the Love2D Wiki](https://love2d.org/wiki/Clamping):

```lua
---
-- Clamps a value to a certain range.
-- @param min - The minimum value.
-- @param val - The value to clamp.
-- @param max - The maximum value.
--
function clamp(min, val, max)
    return math.max(min, math.min(val, max));
end
```

I'm used to a clamp where the value is the first parameter and the min and max follow, but this one from the Wiki uses `min`, `val`, and `max` which took some getting used to.

Learn more about [clamping](https://en.wikipedia.org/wiki/Clamping_(graphics)).

### Paddle Particle Effects

![paddle particles](./assets/breakout-paddle-particles.gif)

To give the paddle growth and shrinking effects a little more "oomph" and make them more visible, I duplicated the particle effect from the brick hit event to give the paddle a nice particle transition effect.

To make this appear as expected, the `Paddle:renderParticles()` method needs to be called in the `ServeState:render()` method, after the `self.paddle:render()` call to make sure the particles render on top of the paddle.

## Locked Bricks

Adding locked bricks in a way that feels fair was an interesting challenge. Ultimately I settled on a random system that increases in likelihood as the player progresses and also allows for more locked bricks as the player progresses.

## PowerUps

Adding PowerUps makes the game more interesting, but it's hard to tune the respawn timing and cooldown timing to make the game feel fun and not boring when you don't have the double ball PowerUp.

I decided to have powerups spawn in front of the player's paddle and then move towards the top of the screen. They have similar collision and bounce physics to the ball, so they will bounce off the walls and the the bricks until hitting the player's paddle or passing through the bottom of the screen.

### Key PowerUp

The first PowerUp I implemented was the Key, because I already had [locked bricks](#locked-bricks) figured out and needed to be able to break them.

This PowerUp just makes it possible to unlock Locked Bricks by hitting them with the ball, and when you acquire it, the UI updates to have a little key sprite next to the health meter.

The Key PowerUp will only spawn in levels with Locked Bricks and only if the player still has Locked Bricks remaining on the screen.

If there are only Locked Bricks, after a short period of time, the Key PowerUp will spawn even if the player hasn't reached the score or timing threshold for powerups to spawn.

### Double Ball PowerUp

This one was more complicated, but turning the `ball` parameter for the PlayState into a `balls` table allowed me to add another ball to the game and also only trigger a health loss or game loss when all of the balls have passed through the bottom of the screen.

This means that a clever player can trade out a ball that is going to be too hard to reach for the Double Ball PowerUp to launch a new ball and keep the game going.

Each ball has collision detection with the walls, the paddle, the bricks, and each other ball - though a ball to ball collision is fairly rare in my playtesting, so it's not quite as well-tuned.

## Other Quality of Life Improvements

I added the [lovebird](https://github.com/rxi/lovebird) dependency to make it easier to debug the project and see what's going on in the game's current state and also added a `DEBUG_MODE` flag that makes it easy to toggle this on and off.

When `DEBUG_MODE` is `true`, in addition to `lovebird` being enabled, the various score and timing thresholds are all decreased dramatically to allow for quicker testing and the background music is disabled because it's just too much when you're stopping and starting the game a bunch during development.

## Issues with the Current Implementation

These issues exist in the base game project that was provided, and I did not address them while I was adding the required features for this project.

Given more time, I would go back and address these to make the game feel much tighter, more refined, and much more fun to play.

![janky phsyics](./assets/breakout-janky.gif)

- "Floaty" ball physics: the initial serve can be very slow and make the game feel boring and unresponsive
- Naive collision detection: the collision detection algorithm does not seem to take into account things like the paddle direction (which should be able to influence the direction of the ball when it leaves the paddle) or properly handle corner hits - which sometimes make the ball suddenly pop out of the top of the paddle
- Inconsistent ball acceleration: the ball occasionally gets bursts of speed or slows down for no apparent reason which makes the game physics feel confusing and inconsistent


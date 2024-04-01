# edX CS50 Introduction to Game Development: Breakout

This is `Project 2` for [CS50's Introduction to Game Development](https://cs50.harvard.edu/games/2018/).

The game is a clone of the classic Atari game Breakout, where the player must use a paddle to bounce a ball upwards, towards a wall of bricks. The ball will bounce off the walls and the bricks, and if it hits the bottom of the screen, the player will lose a life. The player wins a level once all the bricks are destroyed.

The goal of this project is to take the provided [Love2D]() project and add several features to it:

- [ ] Double Ball Powerup
- [ ] Locked brick with Key Powerup
- [ ] Dynamic paddle size based on score and losing a life
    **Note**: The project description says to shrink the paddle when the user loses a heart and increase it as the score increases, but I intend to use the reverse logic in order to make it easier for players that are having trouble and harder for players who are already excelling.


## Issues with the Current Implementation

- "Floaty" ball physics: the initial serve can be very slow and make the game feel boring and unresponsive
- Naive collision detection: the collision detection algorithm does not seem to take into account things like the paddle direction (which should be able to influence the direction of the ball when it leaves the paddle) or properly handle corner hits - which sometimes make the ball suddenly pop out of the top of the paddle
- Inconsistent ball acceleration: the ball occasionally gets bursts of speed or slows down for no apparent reason which makes the game physics feel confusing


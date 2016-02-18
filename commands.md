#SwiftBot Commands

###Built-in Functions
+ **!g**: Calculate gravity for a planet. 
    * usage: `!g <Earth masses> <radius (km)>`
    * formula: `g = G * (mass / radius²)`
        - `G = 6.67e-11`
+ **!id**: Return Discord ID for the user, or all @mentioned users
    * usage: `!id [@user1 @user2 ...]`
+ **!kly/hr**: Calculate max distance travelled per hour. 
    * usage: `!kly/hr <jump range (LY)> [time per jump (sec) | default: 45]`
+ **!ping**: Sends a pong message back to you.
    * usage: `!ping`
+ **!pingme**: Pongs you in a personal message.
    * usage: `!pingme`
+ **!pong**: Pings you back delightfully.
    * usage: `!pong`
+ **!random**: Show image of random animal. Supports cat, dog, corgi and kitten. Space between random and animal is optional.
    * usage: `!random <cat|dog|corgi|kitten>` or `!random<cat|dog|corgi|kitten>`
+ **!route**: Calculate optimal core routing distance. 
    * usage: `!route <jump range> <distance to Sgr A* (KLY)> [max route length (LY)]`
    * formula: `route = M - ((N / 4) + (DistanceToSgrA * 2))`
        - `N = floor(1000 / JumpRange)`
        - `M = JumpRange * N`
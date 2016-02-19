# SwiftBot Commands

<!-- YAML File Command Structure
commands:
  command_name:
    content:
      extended_help: this is a long/detailed description of the content. It is either sent via private message 
                     or ignored completely, depending on the option set later in the command definition.
      short_help: this is a 1-sentence short_help of the content.
      text: this is the link to wherever the content is hosted (forums, google drive, github, etc.)
    options:
      detailed_pm: true or false - determines if the `extended_help` text is automatically sent as a PM or in-chat.
      category: this sets the command's category for the SwiftBot
categories:
  category_name: Short help for the category (note categories are created automatically for commands, this just adds
                 optional help). Categories are only created if there's command for them.
-->

### Bot Management
+ **!help**: displays brief help message in your PMs (optionally displays in-channel)
    * usage: `!help [here]`

### Programmed Functions
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
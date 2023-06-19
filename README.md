# FiveM-NPC-Controller

This script allows FiveM players to create and control Non-Player Characters (NPCs). With the provided commands and menus, players can dictate the actions and behaviors of the NPCs.

## Features

1. **NPC Creation**: Players can create and name up to two NPCs.
2. **NPC Control**: Players can command NPCs to follow, get in and out of vehicles, and change their levels of aggression.

## Installation

1. Clone the repository into your `resources` folder.
2. Add `start FiveM-NPC-Controller` to your `server.cfg` file.
3. Restart your server or reload the resource.

## Usage

In-game, a player can open the NPC menu and select the desired action.

## Commands

- `/createnpc [NPC Name] [Number]`: Creates one or more NPCs.
- `/followme`: Commands all of a player's NPCs to follow the player.
- `/unfollow`: Stops all of a player's NPCs from following the player.
- `/npcenter`: Commands all of a player's NPCs to get into the vehicle the player is driving.
- `/npcexit`: Commands all of a player's NPCs to exit the vehicle.
- `/npcaggressive`: Commands all of a player's NPCs to be hostile towards other players.
- `/npcpassive`: Commands all of a player's NPCs to be passive towards other players.

## Contributing

Contributions from the community are welcome. You can fork the project and send pull requests if you want to add improvements or features.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

# Fatebound

A Roblox game featuring advanced combat mechanics, character movement systems, and inventory management.

## 🎮 Features

### Combat System
- **State-based combat**: Light attacks, heavy attacks, and blocking mechanics
- **Combat state machine**: Smooth transitions between different combat states
- **Anti-exploit protection**: Server-side validation for all combat actions
- **Damage system**: Configurable damage values with stun effects

### Movement System
- **Advanced movement states**: Idle, walk, run, jump, and dash mechanics
- **Movement state machine**: Responsive character movement with state transitions
- **Back dash mechanics**: Special backward movement with visual effects
- **Smooth animations**: Integrated animation handling for all movement states

### Inventory System
- **Comprehensive item system**: Support for weapons, consumables, materials, equipment, quest items, and currency
- **Rarity system**: Common, Uncommon, Rare, Epic, Legendary, and Mythic items with color coding
- **Durability system**: Equipment degradation and repair mechanics
- **Stacking system**: Automatic item stacking with configurable limits
- **Slot-based inventory**: Flexible inventory management with drag-and-drop support

## 🏗️ Architecture

### Project Structure
```
src/
├── client/           # Client-side scripts
│   ├── character/    # Character-specific systems
│   │   ├── Combat/   # Combat state machine
│   │   └── Movement/ # Movement state machine
│   └── player/       # Player-specific client logic
├── server/           # Server-side scripts
│   └── Handlers/     # Server-side event handlers
└── shared/           # Shared code between client and server
    ├── BaseClasses/  # Base classes and interfaces
    ├── Controller/   # State machine controllers
    ├── External/     # External libraries (Spring, Wind, Ragdoll)
    ├── Inventory/    # Inventory system classes
    ├── Movement/     # Movement utilities
    ├── Remotes/      # Remote events for client-server communication
    └── Utilities/    # Utility functions and handlers
```

### Key Systems

#### Combat System
The combat system uses a state machine pattern to manage different combat states:
- **IdleState**: Default combat state, ready for input
- **LightAttackState**: Quick, low-damage attacks
- **HeavyAttackState**: Powerful, slower attacks
- **BlockState**: Defensive stance that reduces damage

#### Movement System
Character movement is handled through a dedicated state machine:
- **IdleState**: Standing still
- **WalkState**: Slow movement
- **RunState**: Fast movement
- **JumpState**: Vertical movement
- **DashState**: Quick directional movement

#### Inventory System
The inventory system provides a robust item management solution:
- **Item Class**: Represents individual items with properties like rarity, durability, and effects
- **Inventory Class**: Manages item storage, stacking, and slot operations
- **Type Safety**: Full Luau typing support for better development experience

## 🚀 Getting Started

### Prerequisites
- [Rojo](https://github.com/rojo-rbx/rojo) 7.5.1 or later
- [Roblox Studio](https://www.roblox.com/develop)

### Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fatebound
   ```

2. **Build the project**
   ```bash
   rojo build -o "fatebound.rbxlx"
   ```

3. **Open in Roblox Studio**
   - Open `fatebound.rbxlx` in Roblox Studio
   - Start the Rojo server for live development:
   ```bash
   rojo serve
   ```

4. **Connect to Rojo**
   - In Roblox Studio, install the Rojo plugin
   - Connect to the Rojo server for live code synchronization

## 📚 Documentation

### Combat System Usage

```lua
-- Server-side combat handling
local CombatHandler = require(game.ServerScriptService.CombatHandler)

-- Handle hit events from clients
CombatHandler.HandleHitEvent(player, "LightAttack", {targetCharacter})
```

### Movement System Usage

```lua
-- Client-side movement
local MovementMachine = require(game.ReplicatedStorage.Movement.MovementMachine)

-- Initialize movement for a character
local movement = MovementMachine.new(character)
movement:SetState("RunState")
```

### Inventory System Usage

```lua
-- Create an item
local Item = require(game.ReplicatedStorage.Inventory.Item)
local sword = Item.new({
    id = "iron_sword",
    name = "Iron Sword",
    description = "A sharp iron sword",
    itemType = "Weapon",
    rarity = "Uncommon",
    maxStackSize = 1,
    damage = 25
})

-- Create and manage inventory
local Inventory = require(game.ReplicatedStorage.Inventory.Inventory)
local inventory = Inventory.new({
    maxSlots = 20,
    owner = player
})

-- Add items to inventory
inventory:AddItem(sword, 1)
```

## 🔧 Configuration

### Combat Settings
- **Damage Values**: Configure in `CombatHandler.luau`
- **Stun Duration**: Adjust stun effects for different attacks
- **Attack Cooldowns**: Prevent spam attacks
- **Range Limits**: Maximum attack distance validation

### Movement Settings
- **Movement Speeds**: Configure walk, run, and dash speeds
- **Jump Height**: Adjust vertical movement
- **Animation Transitions**: Smooth state transitions

### Inventory Settings
- **Slot Limits**: Configure maximum inventory size
- **Stack Limits**: Set maximum stack sizes for different items
- **Rarity Colors**: Customize rarity color schemes

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Convention
This project follows [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` New features
- `fix:` Bug fixes
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Adding or updating tests
- `chore:` Maintenance tasks

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Check the documentation in the code comments
- Review the example usage in the documentation

---

Generated by [Rojo](https://github.com/rojo-rbx/rojo) 7.5.1.
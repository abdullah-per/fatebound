# Fatebound

Welcome to **Fatebound** – a modular Roblox action RPG framework designed for rapid prototyping and robust gameplay. This project features a modern, state-driven architecture for combat, movement, and inventory, with a focus on extensibility, security, and smooth player experience.

---

## 🚀 Features

### ⚔️ Combat System
- **State-based combat:** Light attacks, heavy attacks, blocking, and combos
- **Server-side validation:** Anti-exploit, cooldowns, range checks, and DPS limits
- **Stun & effects:** Configurable stun durations and damage values
- **Smooth transitions:** State machine ensures fluid combat flow

### 🏃 Movement System
- **Advanced states:** Idle, walk, run, jump, dash, and backdash (with visuals)
- **Responsive controls:** State machine for seamless movement transitions
- **Animation integration:** All movement and combat states play appropriate animations

### 🎒 Inventory System
- **Slot-based inventory:** Stackable items, drag-and-drop, and slot management
- **Item types & rarity:** Weapons, consumables, materials, equipment, quest items, currency
- **Durability & stacking:** Equipment wear and automatic stacking
- **Type safety:** Full Luau typing for reliability

### 🌱 Extensible Architecture
- **Modular codebase:** Shared, client, and server modules for easy expansion
- **External libraries:** Spring, Ragdoll, Wind, and more
- **Remote events:** Secure client-server communication

---

## 🏗️ Project Structure

```
src/
├── client/           # Client-side scripts (character, player, UI)
│   ├── character/    # State machines for movement & combat
│   └── player/       # Player-specific logic
├── server/           # Server-side event handlers & logic
├── shared/           # Shared modules (base classes, utilities, inventory, movement)
```

---

## 🛠️ Getting Started

1. **Clone the repo:**
   ```bash
   git clone <repository-url>
   cd fatebound
   ```
2. **Build the project:**
   ```bash
   rojo build -o "fatebound.rbxlx"
   ```
3. **Open in Roblox Studio:**
   - Open `fatebound.rbxlx`
   - Start Rojo for live sync:
     ```bash
     rojo serve
     ```
   - Connect via the Rojo plugin in Studio

---

## 🧩 Key Systems

### Combat
- **Client:** Handles input, state transitions, hit detection, and animation
- **Server:** Validates attacks, applies damage, enforces cooldowns, and prevents exploits
- **States:** Idle, LightAttack, HeavyAttack, Block (with context-aware transitions)

### Movement
- **States:** Idle, Walk, Run, Jump, Dash, BackDash (with visual effects)
- **State machine:** Handles input, animation, and FOV changes

### Inventory
- **Item class:** All item data, rarity, durability, and effects
- **Inventory class:** Add, remove, move, and stack items; serialization support

---

## ⚙️ Configuration
- **Combat:** Damage, stun, cooldowns, and range in `CombatHandler.luau`
- **Movement:** Speeds, dash distances, and animation transitions in `PlayerConfig.luau`
- **Inventory:** Slot and stack limits, rarity colors in `Inventory.luau` and `Item.luau`

---

## 🤝 Contributing

1. Fork & branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m 'docs: update readme'`
3. Push and open a Pull Request

**Commit style:** Conventional Commits (`feat:`, `fix:`, `docs:`, etc.)

---

## 📄 License
MIT License – see [LICENSE](LICENSE)

---

## 🆘 Support
- Open an issue for help or questions
- Check code comments and in-file docs

---

Happy developing! ✨

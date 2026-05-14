# ⬡ HEXBOUND
**Outwit your enemies. Master the cards.**

A 2–4 player LAN couch co-op turn-based PvP card game built in **Godot 4.x**.
No internet required. Pure peer-to-peer over your local network.

---

## 🚀 Quick Start

### Requirements
- Godot 4.2+ (download at https://godotengine.org)
- 2–4 computers on the **same LAN / Wi-Fi network**

### Setup
1. Open Godot → **Import Project** → select this folder
2. Press **F5** (or the Play button) to run

---

## 🌐 How to Play Multiplayer

### Hosting
1. Launch the game
2. Enter your name
3. Leave the IP field blank
4. Click **HOST GAME**
5. Share your **LAN IP** shown on the Lobby screen with other players

### Joining
1. Launch the game on another machine on the same network
2. Enter your name
3. Type the host's LAN IP (e.g. `192.168.1.49`)
4. Click **JOIN GAME**

### Starting
- Once 2–4 players are in the Lobby, the **Host** clicks **START GAME**

---

## 🃏 Card Types

| Type    | Color  | Effect                        |
|---------|--------|-------------------------------|
| Attack  | Red    | Deal damage to a target       |
| Defend  | Blue   | Gain Block this turn          |
| Spell   | Purple | Powerful effects, costs 2 energy |
| Curse   | Dark   | Debuffs: poison, energy drain |
| Heal    | Green  | Restore your HP               |

### Card List
- **Strike** — Deal 6 damage (×4)
- **Heavy Blow** — Deal 12 damage, costs 2 energy (×2)
- **Cleave** — Deal 4 damage to ALL enemies
- **Twin Strike** — Deal 5 damage twice
- **Defend** — Gain 5 Block (×4)
- **Iron Wave** — Deal 5 damage + gain 5 Block
- **Fireball** — Deal 18 damage, costs 2 energy
- **Arcane Bolt** — Deal 8 damage + draw 1 card
- **Slow** — Target skips next draw phase
- **Hex** — Deal 5 damage + target loses 1 energy next turn
- **Wither** — Apply 3 poison stacks (3 dmg/turn, fades)
- **Healing Potion** — Restore 8 HP (×2)
- **Second Wind** — Restore 5 HP + draw 1 card

---

## ⚙️ Architecture (matches brochure)

| Component            | File                          | Role |
|---------------------|-------------------------------|------|
| Connection Manager  | `NetworkManager.gd`           | Peer discovery, connect/disconnect over LAN |
| Game State Manager  | `GameManager.gd`              | Board state, hands, turn order across peers |
| Turn Handler        | `GameManager._process_end_turn` | Locks input to active player, broadcasts result |
| Card Engine         | `CardData.gd` + `GameManager` | Deck logic, card effects, win detection |

### P2P Design
- **Host** creates an ENet server on port `5286`
- **Clients** join via local IP
- All actions (card plays, end turn) are broadcast from host to all peers
- Each peer maintains its own full copy of game state
- No central server required

---

## 🗂️ File Structure

```
hexbound/
├── project.godot
├── scenes/
│   ├── MainMenu.tscn
│   ├── Lobby.tscn
│   └── Game.tscn
└── scripts/
    ├── CardData.gd        — Card definitions & deck generation
    ├── PlayerState.gd     — Per-player HP, hand, energy, effects
    ├── NetworkManager.gd  — P2P LAN autoload singleton
    ├── GameManager.gd     — Turn logic, card resolution, win detection
    ├── MainMenu.gd        — Host/join screen
    ├── Lobby.gd           — Player waiting room
    └── Game.gd            — Battle board UI
```

---

## 👥 Team — Hexbound

| Name | Role |
|------|------|
| Kynehl Scott Misajon | Team Leader |
| Alfred Samuya | Programmer |
| Julian Marabe | Programmer |
| Emmanuel Songquipal | Designer / Programmer |
| Kim Ryan Joseph Orencia | Artist |

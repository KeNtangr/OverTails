# Project

This is a Godot 4.x local multiplayer bullet-hell duel game.

Core loop:

Preparation Phase
→ players buy/equip weapons
→ Attack Phase
→ each player's weapons generate attack patterns
  inside the opponent's arena
→ players dodge
→ HP/economy results
→ repeat until one player dies.

# Architecture Rules

- Keep Player 1 and Player 2 systems symmetric.
- Each player owns an Arena.
- A player's weapons attack the opponent's Arena.
- Maximum active loadout is 3 weapons.
- Weapon definitions should be data-driven using Resources.
- Attack scenes should be modular and reusable.
- Do not hardcode weapon-specific logic into GameManager.
- GameManager controls match state only.
- PhaseManager controls Preparation/Attack transitions.
- Arena handles attacks occurring inside itself.
- Player handles movement, HP, hit detection, and graze detection.

# Prototype Priorities

Gameplay first.
Placeholder graphics are expected.
Do not add unnecessary animations, menus, save systems,
online multiplayer, procedural systems, or polish.

# Coding Rules

- Godot 4.x / GDScript.
- Prefer small scripts with clear responsibilities.
- Use typed GDScript where practical.
- Prefer signals over tightly coupling unrelated nodes.
- Do not refactor working unrelated systems without a reason.
- Inspect existing project architecture before making changes.
- Preserve existing functionality.

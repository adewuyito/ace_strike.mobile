# Ace Strike

[![Flutter Game](https://img.shields.io/badge/Made%20with-Flutter%20%7C%20Flame-blue.svg)](https://flutter.dev)
[![LICENSE](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

**Ace Strike** is a high-octane, arcade-style 2D aerial evasion and shoot-'em-up (shmup) game built using the **Flutter** framework and the **Flame** game engine. Fly modern combat jets, outmaneuver waves of complex guided missiles, collect powerful upgrades, and rack up multiplier points through high-risk near-miss dodges!

---

## 🚀 Key Features & "Game Feel" Overhaul

The game has been designed with a heavy emphasis on visceral visual, tactile, and auditory feedback loops to maximize gameplay satisfaction:

*   **Momentum-Based Flight:** Control the aircraft with smooth, responsive, inertia-driven steering physics that simulate high-speed atmospheric flight, complete with fading visual trailing afterimages when turning tightly.
*   **Intelligent Missile Steering & Overshooting:** Missiles don't follow you forever. They feature custom steering rates and a **predictive overshoot check**. If you execute a sharp turn at the last second, the missile will overshoot your flight path, immediately lose its target lock, and fly off-screen.
*   **Visceral Proximity Danger Ring:** A clean, neon circular aura expands and shrinks around your aircraft, dynamically transitioning from calm cyan to vivid pulsing red as a missile gets closer, adding a constant layer of tension.
*   **Hit-Stop Frame Freezing:** Colliding with a missile triggers a micro-freeze (hit-stop) of about `4` frames to give massive visual weight and impact to getting hit before detonating.
*   **Oscillating Screen Shake:** Different events trigger customized screen shakes (near-misses get a subtle vibration, direct hits shake violently, and game over registers a heavy shudder).
*   **Combo Streak HUD & near-miss scoring:** Dodging missiles closely without taking damage registers a "Near-Miss". Each near-miss adds to your multiplier streak (e.g. `x1.5`, `x2.0` up to `x4.0`) and drops cyan spark particles. The HUD displays a glowing combo badge that flashes gold at milestones (10, 25, 50 dodges).
*   **Tactile Haptics Engine:** Forward-looking haptic feedback maps selection clicks to powerup pickups, light impacts to near-misses, medium impact to player hits, and heavy shudders to Game Over (designed for mobile devices).

---

## 📁 Codebase Directory Structure

```markdown
lib/
├── core/
│   └── constants.dart         # Core physics, z-indexes, multipliers, and game feel settings.
├── game/
│   ├── ace_strike_game.dart   # Main game engine, manages frame-skipping (hit-stop) and rendering (shake).
│   ├── components/            # Game entities and rendering components.
│   │   ├── effects/
│   │   │   └── danger_ring.dart # Centered visual aura scaling in red intensity by danger.
│   │   ├── missile/
│   │   │   ├── missile_component.dart # Guided missile logic (homing, predictive, cluster, torpedoes).
│   │   │   └── missile_type.dart      # Missile type categorizations.
│   │   ├── plane/
│   │   ├── powerup/
│   │   │   └── powerup_component.dart # Glow items (shield, extra life, boost refuel).
│   │   └── world/
│   │       ├── background_component.dart # Parallax background terrain.
│   │       ├── explosion_component.dart  # Animated particle detonations.
│   │       └── star_field.dart           # Space/atmospheric scrolling particles.
│   ├── managers/              # State and gameplay managers.
│   │   ├── difficulty_manager.dart # Dynamic scaling of missile speeds and frequencies.
│   │   ├── game_manager.dart       # State machine, score multiplier tracking, and streak combos.
│   │   ├── haptics_manager.dart    # Singleton wrapper for mobile tactile feedback.
│   │   └── spawn_manager.dart      # Staggered wave patterns, spawn weights, and powerup spawners.
│   ├── overlays/              # Widget-based menus and overlays.
│   │   ├── game_over_overlay.dart  # End-game details and statistics.
│   │   ├── hud_overlay.dart        # Combo badges, shield icons, level trackers, and scores.
│   │   ├── main_menu_overlay.dart  # Startup animations and ship selection.
│   │   └── pause_overlay.dart      # Standard gameplay pause controls.
│   └── providers/
│       └── game_providers.dart    # Riverpod state management for safe widget/game synchronization.
└── main.dart                  # App initialization, locks orientation, and mounts GameWidget.
```

---

## 🛠️ How to Run & Develop

### Prerequisites
Make sure you have Flutter installed and configured on your machine. We recommend using **FVM** (Flutter Version Manager) to ensure matching environments.

### 1. Fetch Dependencies
```bash
fvm flutter pub get
```

### 2. Run the App
To start the application on your local macOS desktop:
```bash
fvm flutter run -d macos
```
*(Or specify `-d chrome` for web testing, or `-d ios` / `-d android` for mobile verification).*

### 3. Running Tests
Verify your builds and mechanics against our widget and physics suite:
```bash
fvm flutter test
```

### 4. Code Quality & Analysis
Keep the codebase clean and conform to our analysis guidelines:
```bash
fvm flutter analyze
```

---

## 🎮 Game Controls

| Control | Keyboard Input | On-Screen Touch / Mouse |
| :--- | :--- | :--- |
| **Steer Left** | `A` or `Left Arrow` | Drag left anywhere, or hold Left steering button |
| **Steer Right** | `D` or `Right Arrow`| Drag right anywhere, or hold Right steering button |
| **Refuel Boost** | `Spacebar` (Double-tap) | Double-tap screen to toggle supercharge speed |
| **Pause Game** | `Escape` or `P` | Tap the Pause button in the top-right corner |

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

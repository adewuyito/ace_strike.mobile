const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, AlignmentType, HeadingLevel, BorderStyle, WidthType, ShadingType,
  LevelFormat, PageNumber, PageBreak, VerticalAlign, TabStopType, TabStopPosition
} = require('docx');
const fs = require('fs');

// ── Colour palette ────────────────────────────────────────────────────────────
const C = {
  navy:    '0D1B2A',
  blue:    '1565C0',
  sky:     '1E88E5',
  teal:    '00838F',
  accent:  '00B0FF',
  orange:  'E65100',
  green:   '2E7D32',
  white:   'FFFFFF',
  light:   'E3F2FD',
  mid:     'BBDEFB',
  dark:    '0A1929',
  grey:    '546E7A',
  text:    '1A1A2E',
  muted:   '78909C',
  codebg:  'F0F4F8',
  rowalt:  'F5F9FF',
};

// ── Border helpers ─────────────────────────────────────────────────────────────
const border = (color = C.mid, size = 4) => ({ style: BorderStyle.SINGLE, size, color });
const noBorder = () => ({ style: BorderStyle.NONE, size: 0, color: 'FFFFFF' });
const allBorders = (c, s) => ({ top: border(c,s), bottom: border(c,s), left: border(c,s), right: border(c,s) });
const noAllBorders = () => ({ top: noBorder(), bottom: noBorder(), left: noBorder(), right: noBorder() });

// ── Typography helpers ────────────────────────────────────────────────────────
const txt = (text, opts = {}) => new TextRun({
  text,
  font: opts.mono ? 'Courier New' : 'Calibri',
  size: opts.size || 22,
  bold: opts.bold || false,
  italics: opts.italic || false,
  color: opts.color || C.text,
  highlight: opts.highlight || undefined,
});

const h1 = (text) => new Paragraph({
  heading: HeadingLevel.HEADING_1,
  spacing: { before: 480, after: 160 },
  children: [txt(text, { bold: true, size: 36, color: C.white })],
  shading: { fill: C.navy, type: ShadingType.CLEAR },
  indent: { left: 360, right: 360 },
  border: { bottom: { style: BorderStyle.SINGLE, size: 8, color: C.accent } },
});

const h2 = (text) => new Paragraph({
  heading: HeadingLevel.HEADING_2,
  spacing: { before: 360, after: 120 },
  children: [txt(text, { bold: true, size: 28, color: C.navy })],
  border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: C.sky } },
});

const h3 = (text) => new Paragraph({
  heading: HeadingLevel.HEADING_3,
  spacing: { before: 240, after: 80 },
  children: [txt(text, { bold: true, size: 24, color: C.blue })],
});

const h4 = (text) => new Paragraph({
  spacing: { before: 200, after: 60 },
  children: [txt(text, { bold: true, size: 22, color: C.teal })],
});

const p = (text, opts = {}) => new Paragraph({
  spacing: { before: 60, after: 100 },
  alignment: opts.center ? AlignmentType.CENTER : AlignmentType.LEFT,
  children: [txt(text, { size: opts.size || 22, color: opts.color || C.text, italic: opts.italic })],
});

const note = (text) => new Paragraph({
  spacing: { before: 80, after: 80 },
  indent: { left: 360, right: 360 },
  shading: { fill: 'FFF8E1', type: ShadingType.CLEAR },
  border: { left: { style: BorderStyle.SINGLE, size: 12, color: 'FFA000' } },
  children: [
    txt('⚠ NOTE: ', { bold: true, color: 'E65100', size: 20 }),
    txt(text, { size: 20, color: '4A3728' }),
  ],
});

const info = (text) => new Paragraph({
  spacing: { before: 80, after: 80 },
  indent: { left: 360, right: 360 },
  shading: { fill: 'E3F2FD', type: ShadingType.CLEAR },
  border: { left: { style: BorderStyle.SINGLE, size: 12, color: C.sky } },
  children: [
    txt('ℹ  ', { bold: true, color: C.sky, size: 20 }),
    txt(text, { size: 20, color: C.navy }),
  ],
});

const code = (text) => new Paragraph({
  spacing: { before: 60, after: 60 },
  indent: { left: 360, right: 360 },
  shading: { fill: C.codebg, type: ShadingType.CLEAR },
  border: { left: { style: BorderStyle.SINGLE, size: 8, color: C.teal } },
  children: [txt(text, { mono: true, size: 18, color: '1A237E' })],
});

const bullet = (text, level = 0, opts = {}) => new Paragraph({
  numbering: { reference: 'bullets', level },
  spacing: { before: 40, after: 40 },
  indent: { left: 360 + level * 360, hanging: 360 },
  children: [txt(text, { size: opts.size || 21, color: opts.color || C.text, bold: opts.bold })],
});

const numbered = (text, level = 0) => new Paragraph({
  numbering: { reference: 'numbers', level },
  spacing: { before: 40, after: 40 },
  children: [txt(text, { size: 21 })],
});

const divider = () => new Paragraph({
  spacing: { before: 200, after: 200 },
  border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: C.mid } },
  children: [],
});

const spacer = (n = 1) => Array.from({ length: n }, () =>
  new Paragraph({ spacing: { before: 20, after: 20 }, children: [] })
);

// ── Table helpers ──────────────────────────────────────────────────────────────
function headerCell(text, width, bg = C.navy) {
  return new TableCell({
    width: { size: width, type: WidthType.DXA },
    shading: { fill: bg, type: ShadingType.CLEAR },
    borders: allBorders(C.sky, 4),
    margins: { top: 100, bottom: 100, left: 160, right: 160 },
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [txt(text, { bold: true, size: 20, color: C.white })],
    })],
  });
}

function dataCell(text, width, bg = C.white, textColor = C.text, mono = false) {
  return new TableCell({
    width: { size: width, type: WidthType.DXA },
    shading: { fill: bg, type: ShadingType.CLEAR },
    borders: allBorders(C.mid, 2),
    margins: { top: 80, bottom: 80, left: 160, right: 160 },
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      children: [txt(text, { size: 19, color: textColor, mono })],
    })],
  });
}

function makeTable(headers, rows, widths, altRow = true) {
  const totalW = widths.reduce((a, b) => a + b, 0);
  return new Table({
    width: { size: totalW, type: WidthType.DXA },
    columnWidths: widths,
    rows: [
      new TableRow({
        tableHeader: true,
        children: headers.map((h, i) => headerCell(h, widths[i])),
      }),
      ...rows.map((row, ri) =>
        new TableRow({
          children: row.map((cell, ci) => {
            const bg = altRow && ri % 2 === 1 ? C.rowalt : C.white;
            if (typeof cell === 'object') {
              return dataCell(cell.text, widths[ci], cell.bg || bg, cell.color || C.text, cell.mono || false);
            }
            return dataCell(cell, widths[ci], bg);
          }),
        })
      ),
    ],
  });
}

// ── Cover page ────────────────────────────────────────────────────────────────
function coverPage() {
  return [
    new Paragraph({
      spacing: { before: 1440, after: 40 },
      alignment: AlignmentType.CENTER,
      shading: { fill: C.dark, type: ShadingType.CLEAR },
      children: [txt('🛩', { size: 96 })],
    }),
    new Paragraph({
      spacing: { before: 40, after: 20 },
      alignment: AlignmentType.CENTER,
      shading: { fill: C.dark, type: ShadingType.CLEAR },
      children: [txt('ACE STRIKE', { bold: true, size: 72, color: C.accent })],
    }),
    new Paragraph({
      spacing: { before: 0, after: 40 },
      alignment: AlignmentType.CENTER,
      shading: { fill: C.dark, type: ShadingType.CLEAR },
      children: [txt('MISSILE DODGE', { bold: true, size: 48, color: C.white })],
    }),
    new Paragraph({
      spacing: { before: 40, after: 80 },
      alignment: AlignmentType.CENTER,
      shading: { fill: C.dark, type: ShadingType.CLEAR },
      children: [txt('Flutter + Flame Game Architecture & Agent Guidelines', { size: 24, color: C.muted, italic: true })],
    }),
    divider(),
    new Paragraph({
      spacing: { before: 60, after: 40 },
      alignment: AlignmentType.CENTER,
      children: [txt('v1.0.0  ·  2025  ·  Confidential', { size: 20, color: C.muted })],
    }),
    new Paragraph({ children: [new PageBreak()] }),
  ];
}

// ── Main document ─────────────────────────────────────────────────────────────
const doc = new Document({
  numbering: {
    config: [
      {
        reference: 'bullets',
        levels: [
          { level: 0, format: LevelFormat.BULLET, text: '•', alignment: AlignmentType.LEFT,
            style: { run: { font: 'Calibri', color: C.sky }, paragraph: { indent: { left: 360, hanging: 360 } } } },
          { level: 1, format: LevelFormat.BULLET, text: '◦', alignment: AlignmentType.LEFT,
            style: { run: { font: 'Calibri', color: C.teal }, paragraph: { indent: { left: 720, hanging: 360 } } } },
          { level: 2, format: LevelFormat.BULLET, text: '▪', alignment: AlignmentType.LEFT,
            style: { run: { font: 'Calibri', color: C.grey }, paragraph: { indent: { left: 1080, hanging: 360 } } } },
        ],
      },
      {
        reference: 'numbers',
        levels: [
          { level: 0, format: LevelFormat.DECIMAL, text: '%1.', alignment: AlignmentType.LEFT,
            style: { paragraph: { indent: { left: 360, hanging: 360 } } } },
        ],
      },
    ],
  },
  styles: {
    default: { document: { run: { font: 'Calibri', size: 22 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 36, bold: true, font: 'Calibri', color: C.white },
        paragraph: { spacing: { before: 480, after: 160 }, outlineLevel: 0 } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 28, bold: true, font: 'Calibri', color: C.navy },
        paragraph: { spacing: { before: 360, after: 120 }, outlineLevel: 1 } },
      { id: 'Heading3', name: 'Heading 3', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 24, bold: true, font: 'Calibri', color: C.blue },
        paragraph: { spacing: { before: 240, after: 80 }, outlineLevel: 2 } },
    ],
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1300, bottom: 1440, left: 1300 },
      },
    },
    headers: {
      default: new Header({
        children: [
          new Paragraph({
            alignment: AlignmentType.RIGHT,
            border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: C.sky } },
            spacing: { after: 160 },
            children: [
              txt('ACE STRIKE — Flutter + Flame Architecture', { size: 18, color: C.muted }),
            ],
          }),
        ],
      }),
    },
    children: [

      // ── Cover ──────────────────────────────────────────────────────────────
      ...coverPage(),

      // ══════════════════════════════════════════════════════════════════════
      // 1. DOCUMENT PURPOSE
      // ══════════════════════════════════════════════════════════════════════
      h1('1. Document Purpose & Agent Instructions'),
      p('This document is the single source of truth for building Ace Strike: Missile Dodge using Flutter and the Flame game engine. Every Claude Code agent that receives this document should read it in full before writing a single line of code. It defines the project structure, component contracts, state machine, rendering pipeline, input handling, audio, and CI/CD pipeline.'),
      ...spacer(),
      info('Each section is addressed directly to the agent building that layer. Sections marked AGENT TASK contain the exact scope an agent must implement without deviation. Follow the architecture as written; do not refactor into patterns not described here.'),
      ...spacer(),
      h3('How Agents Should Use This Document'),
      numbered('Read Sections 1–4 fully before touching any file.'),
      numbered('Implement only the section assigned. Do not reach into other sections.'),
      numbered('Follow naming conventions exactly — other agents depend on the same contracts.'),
      numbered('Write tests for every public method in your component before marking the task done.'),
      numbered('Leave TODO comments for integration points; never guess at another agent\'s interface.'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 2. TECH STACK
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('2. Technology Stack'),
      makeTable(
        ['Category', 'Package / Tool', 'Version', 'Purpose'],
        [
          ['Runtime', 'Flutter', '3.24.x (FVM)', 'Cross-platform framework'],
          ['Game Engine', 'flame', '^1.18.0', 'Sprite, collision, camera, game loop'],
          ['Audio', 'flame_audio', '^2.10.0', 'BGM + SFX via AudioPool'],
          ['State (App)', 'flutter_riverpod', '^2.5.0', 'App-level state (scores, settings)'],
          ['State (Game)', 'Flame FSM', 'Built-in', 'In-game state via ComponentFSM'],
          ['Storage', 'shared_preferences', '^2.3.0', 'Hi-score, settings persistence'],
          ['Input', 'flame (built-in)', '^1.18.0', 'DragCallbacks, TapCallbacks, KeyboardCallbacks'],
          ['Particles', 'flame (built-in)', '^1.18.0', 'ParticleSystemComponent'],
          ['Collision', 'flame (built-in)', '^1.18.0', 'HasCollisionDetection + ShapeHitbox'],
          ['Routing', 'flame (RouterComponent)', '^1.18.0', 'Scene routing inside game'],
          ['CI/CD', 'Codemagic', 'YAML config', 'Build, test, TestFlight'],
          ['Project Setup', 'Very Good CLI', '^0.21.0', 'Project scaffold + flavors'],
          ['Code Gen', 'build_runner + riverpod_generator', '^2.4.0', 'Provider code generation'],
          ['Lint', 'very_good_analysis', '^6.0.0', 'Strict lint rules'],
        ],
        [2200, 2400, 1600, 3160],
      ),
      ...spacer(),
      note('Always use FVM (Flutter Version Management) to lock to Flutter 3.24.x. Never run flutter commands directly; always prefix with fvm flutter or fvm dart.'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 3. PROJECT STRUCTURE
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('3. Project Structure'),
      p('The project follows a feature-first Clean Architecture folder layout, the same pattern used in the Sayles platform. Game-specific code lives under lib/game/ while Flutter UI scaffolding (menus, HUD overlays using Flutter widgets) lives under lib/features/.'),
      ...spacer(),
      code('ace_strike/'),
      code('├── lib/'),
      code('│   ├── main.dart                    # App entry, ProviderScope'),
      code('│   ├── app.dart                      # MaterialApp + RouterConfig'),
      code('│   ├── game/                         # ALL Flame game code'),
      code('│   │   ├── ace_strike_game.dart       # FlameGame root'),
      code('│   │   ├── components/               # Flame components (pure game objects)'),
      code('│   │   │   ├── plane/'),
      code('│   │   │   │   ├── plane_component.dart'),
      code('│   │   │   │   ├── plane_trail.dart'),
      code('│   │   │   │   └── plane_hitbox.dart'),
      code('│   │   │   ├── missile/'),
      code('│   │   │   │   ├── missile_component.dart'),
      code('│   │   │   │   ├── missile_factory.dart'),
      code('│   │   │   │   └── missile_type.dart'),
      code('│   │   │   ├── world/'),
      code('│   │   │   │   ├── background_component.dart'),
      code('│   │   │   │   ├── star_field.dart'),
      code('│   │   │   │   ├── cloud_layer.dart'),
      code('│   │   │   │   └── ground_grid.dart'),
      code('│   │   │   ├── effects/'),
      code('│   │   │   │   ├── explosion_effect.dart'),
      code('│   │   │   │   ├── boost_flash.dart'),
      code('│   │   │   │   └── warning_indicator.dart'),
      code('│   │   │   └── powerup/'),
      code('│   │   │       ├── powerup_component.dart'),
      code('│   │   │       └── powerup_type.dart'),
      code('│   │   ├── managers/                 # Stateful game managers'),
      code('│   │   │   ├── game_manager.dart      # Score, lives, level'),
      code('│   │   │   ├── spawn_manager.dart     # Missile + powerup spawning'),
      code('│   │   │   ├── audio_manager.dart     # BGM + SFX orchestration'),
      code('│   │   │   └── difficulty_manager.dart'),
      code('│   │   ├── input/'),
      code('│   │   │   ├── touch_input_handler.dart'),
      code('│   │   │   └── keyboard_input_handler.dart'),
      code('│   │   ├── overlays/                 # Flutter widget overlays over Flame'),
      code('│   │   │   ├── hud_overlay.dart'),
      code('│   │   │   ├── pause_overlay.dart'),
      code('│   │   │   └── game_over_overlay.dart'),
      code('│   │   └── routes/'),
      code('│   │       ├── game_route.dart'),
      code('│   │       └── menu_route.dart'),
      code('│   ├── features/'),
      code('│   │   ├── home/                     # Main menu screen (Flutter)'),
      code('│   │   ├── settings/                 # Audio/vibration settings'),
      code('│   │   └── leaderboard/              # Hi-score screen'),
      code('│   └── core/'),
      code('│       ├── constants.dart            # Game constants (sizes, speeds, timings)'),
      code('│       ├── extensions.dart'),
      code('│       └── assets.dart               # Asset path constants'),
      code('├── assets/'),
      code('│   ├── images/                       # Sprite sheets, backgrounds'),
      code('│   ├── audio/bgm/                    # Background music loops'),
      code('│   └── audio/sfx/                    # Sound effects'),
      code('├── test/'),
      code('├── codemagic.yaml'),
      code('└── pubspec.yaml'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 4. GAME STATE MACHINE
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('4. Game State Machine'),
      p('The game has a top-level state machine with five states. All transitions are driven through GameManager, which notifies Riverpod providers consumed by Flutter overlay widgets.'),
      ...spacer(),
      makeTable(
        ['State', 'Description', 'Active Components', 'Allowed Transitions'],
        [
          ['menu', 'Main menu, animated plane orbits', 'MenuRoute, BackgroundComponent, StarField', '→ playing'],
          ['playing', 'Active gameplay', 'ALL components', '→ paused, → dead'],
          ['paused', 'Game frozen, PauseOverlay shown', 'HUDOverlay, PauseOverlay', '→ playing, → menu'],
          ['dead', 'Plane destroyed, GameOverOverlay', 'GameOverOverlay, explosions', '→ playing (retry), → menu'],
          ['levelUp', 'Brief flash between difficulty tiers', 'LevelUpEffect, HUDOverlay', '→ playing (auto)'],
        ],
        [1100, 2000, 2400, 2060],
      ),
      ...spacer(),
      h3('GameManager Contract'),
      code('class GameManager extends Component {'),
      code('  GameState state = GameState.menu;'),
      code('  int score = 0;'),
      code('  int hiScore = 0;'),
      code('  int lives = 3;'),
      code('  int level = 1;'),
      code('  double boostCharge = 1.0;'),
      code(''),
      code('  void transitionTo(GameState next);'),
      code('  void addScore(int delta);'),
      code('  void loseLife();'),
      code('  void collectPowerup(PowerupType type);'),
      code('}'),
      ...spacer(),
      info('GameManager is a Flame Component added to the game root. It emits Dart Streams that Riverpod StreamProviders listen to — this bridges Flame\'s game loop with Flutter\'s reactive widget tree for the HUD.'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 5. COMPONENT ARCHITECTURE
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('5. Component Architecture'),

      h2('5.1 PlaneComponent'),
      p('The player-controlled aircraft. Handles movement, banking physics, boost system, invincibility frames, and trail rendering.'),
      ...spacer(),
      h4('Mixins Required'),
      bullet('DragCallbacks — touch drag movement'),
      bullet('KeyboardHandler — WASD / arrow key movement'),
      bullet('CollisionCallbacks — collision detection with missiles'),
      bullet('HasGameRef<AceStrikeGame> — access to game root'),
      ...spacer(),
      h4('Key Properties'),
      makeTable(
        ['Property', 'Type', 'Default', 'Description'],
        [
          ['speed', 'double', '250.0', 'Base movement speed (pixels/sec)'],
          ['boostMultiplier', 'double', '2.0', 'Speed multiplier when boosting'],
          ['boostDrainRate', 'double', '0.8 / sec', 'Boost charge drain per second'],
          ['boostRegenRate', 'double', '0.3 / sec', 'Boost charge regen per second'],
          ['invincibilityDuration', 'double', '2.0 sec', 'Invincibility after hit'],
          ['rollSensitivity', 'double', '0.035', 'Banking angle from horizontal velocity'],
          ['trailLength', 'int', '20', 'Number of trail positions stored'],
        ],
        [1800, 1200, 1500, 3060],
      ),
      ...spacer(),
      h4('Update Loop Pseudocode'),
      code('void update(double dt) {'),
      code('  _processInput(dt);             // apply velocity from touch/keys'),
      code('  _clampToBounds();              // keep within game viewport'),
      code('  _updateBanking(dt);            // smooth roll interpolation'),
      code('  _updateBoost(dt);              // drain / regen boost charge'),
      code('  _updateTrail();                // push current pos to trail buffer'),
      code('  _updateInvincibility(dt);      // tick down invincibility timer'),
      code('}'),
      ...spacer(),
      note('PlaneComponent NEVER directly modifies GameManager. It calls game.gameManager.loseLife() only through its onCollisionStart callback. All other state changes go through GameManager.transitionTo().'),
      ...spacer(),

      h2('5.2 MissileComponent'),
      p('A single missile projectile. Missiles are pooled using Flame\'s ComponentPool to avoid GC pressure during intense spawning.'),
      ...spacer(),
      h4('MissileType Enum'),
      makeTable(
        ['Type', 'Speed (base)', 'Size', 'Homing?', 'Special Behaviour'],
        [
          ['rocket', '250 px/s', '10 px', 'No', 'Straight path from edge'],
          ['torpedo', '180 px/s', '14 px', 'No', 'Wide hitbox, slower'],
          ['homing', '200 px/s', '10 px', 'Yes (2s)', 'Tracks plane for 2s then ballistic'],
          ['cluster', '300 px/s', '12 px', 'No', 'Splits into 4 rockets on hit'],
        ],
        [1200, 1400, 900, 1400, 2660],
      ),
      ...spacer(),
      h4('Homing Logic'),
      code('// Applied each tick while homingTimer > 0'),
      code('final dir = (plane.position - position).normalized();'),
      code('velocity += dir * homingForce * dt;'),
      code('velocity = velocity.normalized() * velocity.length.clamp(0, maxSpeed);'),
      code('homingTimer -= dt;'),
      ...spacer(),
      h4('Component Pool Pattern'),
      code('// In SpawnManager'),
      code('final _pool = ComponentPool<MissileComponent>('),
      code('  minSize: 10,'),
      code('  factory: () => MissileComponent(),'),
      code(');'),
      code(''),
      code('void spawnMissile(MissileType type, Vector2 origin, Vector2 velocity) {'),
      code('  final missile = _pool.obtain()'),
      code('    ..configure(type: type, position: origin, velocity: velocity);'),
      code('  game.world.add(missile);'),
      code('}'),
      ...spacer(),

      h2('5.3 World / Background Components'),
      p('The background is composed of layered components, each scrolling at independent speeds to produce a parallax depth effect.'),
      ...spacer(),
      makeTable(
        ['Component', 'Layer Z', 'Scroll Speed', 'Render Method'],
        [
          ['StarField', '-3 (farthest)', '0.05x game speed', 'Canvas drawCircle with twinkle alpha animation'],
          ['CloudLayer', '-2', '0.15x game speed', 'Canvas drawPath with low opacity'],
          ['GroundGrid', '-1', '0.8x game speed', 'Canvas lines projected to vanishing point'],
          ['BackgroundComponent', 'base', 'Static', 'Gradient fill (navy → deep blue)'],
        ],
        [2200, 1400, 1800, 3160],
      ),
      ...spacer(),
      info('All background components use a single shared Canvas paint pass via a BatchedRenderComponent wrapper to reduce draw calls. Each layer implements RenderComponent and draws in order by z-index.'),
      ...spacer(),

      h2('5.4 Effects Components'),
      h4('ExplosionEffect'),
      bullet('Uses Flame\'s ParticleSystemComponent'),
      bullet('Particle count: 30 (small hit) / 60 (plane destroyed)'),
      bullet('Particles: AcceleratedParticle with color lerp from orange → red → transparent'),
      bullet('Duration: 0.8 seconds total'),
      bullet('Pooled: yes, returned to pool after animation completes'),
      ...spacer(),
      h4('WarningIndicator'),
      bullet('Spawned for every off-screen missile'),
      bullet('Position: clamped to a 30px inset border around the viewport'),
      bullet('Direction: arrow pointing from indicator toward missile world position'),
      bullet('Pulse: alpha oscillates at sin(time * 4.0) × 0.8'),
      bullet('Removed automatically when missile enters viewport or is destroyed'),
      ...spacer(),
      h4('BoostFlash'),
      bullet('Full-screen overlay component with very low opacity (0.04–0.07)'),
      bullet('Rendered only when PlaneComponent.isBoosting == true'),
      bullet('Color: accent blue (#00B0FF) with sin modulation'),
      ...spacer(),

      h2('5.5 PowerupComponent'),
      makeTable(
        ['Type', 'Visual', 'Spawn Rate', 'Effect'],
        [
          ['life', 'Red heart, pulsing scale', 'Every 400 frames if lives < 5', '+1 life (max 5)'],
          ['boost', 'Cyan star, spin animation', 'Every 300 frames if boost < 0.5', 'Full boost recharge'],
          ['shield', 'Blue hexagon, rotating', 'Every 600 frames', '5 seconds of invincibility'],
        ],
        [1200, 2200, 2200, 2960],
      ),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 6. SPAWN & DIFFICULTY
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('6. SpawnManager & Difficulty Curve'),

      h2('6.1 Difficulty Levels'),
      makeTable(
        ['Level', 'Score Range', 'Spawn Interval', 'Max Missiles', 'Homing %', 'Cluster %'],
        [
          ['1', '0 – 499', '90 frames', '8', '0%', '0%'],
          ['2', '500 – 1,199', '75 frames', '12', '15%', '0%'],
          ['3', '1,200 – 2,499', '60 frames', '18', '25%', '10%'],
          ['4', '2,500 – 4,499', '45 frames', '24', '35%', '15%'],
          ['5+', '4,500+', '30 frames', '35', '45%', '20%'],
        ],
        [900, 1600, 1600, 1500, 1300, 1300],
      ),
      ...spacer(),

      h2('6.2 SpawnManager Logic'),
      code('class SpawnManager extends Component with HasGameRef {'),
      code('  int _frameCount = 0;'),
      code(''),
      code('  @override'),
      code('  void update(double dt) {'),
      code('    _frameCount++;'),
      code('    final diff = game.difficultyManager.current;'),
      code('    if (_frameCount % diff.spawnInterval == 0) {'),
      code('      _spawnMissile(diff);'),
      code('    }'),
      code('    if (_frameCount % diff.powerupInterval == 0) {'),
      code('      _maybeSpawnPowerup();'),
      code('    }'),
      code('  }'),
      code(''),
      code('  MissileType _selectType(DifficultyConfig diff) {'),
      code('    final roll = Random().nextDouble();'),
      code('    if (roll < diff.clusterChance) return MissileType.cluster;'),
      code('    if (roll < diff.clusterChance + diff.homingChance) return MissileType.homing;'),
      code('    return roll < 0.4 ? MissileType.torpedo : MissileType.rocket;'),
      code('  }'),
      code('}'),
      ...spacer(),

      h2('6.3 Spawn Edge Logic'),
      p('Missiles spawn from the four viewport edges with weighted probability:'),
      makeTable(
        ['Edge', 'Weight', 'Velocity Direction'],
        [
          ['Top', '40%', 'Downward arc, random horizontal drift'],
          ['Left', '20%', 'Right-biased with slight vertical drift'],
          ['Right', '20%', 'Left-biased with slight vertical drift'],
          ['Top (homing)', '20%', 'Directly toward plane position at spawn time'],
        ],
        [1200, 1200, 6160],
      ),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 7. INPUT HANDLING
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('7. Input Handling'),

      h2('7.1 Touch (Primary — iOS)'),
      code('// PlaneComponent mixin: DragCallbacks'),
      code(''),
      code('@override'),
      code('void onDragUpdate(DragUpdateEvent event) {'),
      code('  _touchTarget = event.canvasPosition;'),
      code('}'),
      code(''),
      code('@override'),
      code('void onDragEnd(DragEndEvent event) {'),
      code('  _touchTarget = null;'),
      code('}'),
      code(''),
      code('// Double-tap for boost — handled via TapCallbacks'),
      code('@override'),
      code('void onDoubleTapDown(DoubleTapDownEvent event) {'),
      code('  _activateBoost();'),
      code('}'),
      ...spacer(),
      p('In update(), the plane smoothly moves toward _touchTarget using lerp:'),
      code('if (_touchTarget != null) {'),
      code('  final dir = (_touchTarget! - position).normalized();'),
      code('  final dist = (_touchTarget! - position).length;'),
      code('  if (dist > deadzone) {'),
      code('    velocity = dir * speed * (isBoosting ? boostMultiplier : 1.0);'),
      code('  }'),
      code('}'),
      code('position += velocity * dt;'),
      ...spacer(),

      h2('7.2 Keyboard (Desktop / Testing)'),
      makeTable(
        ['Key(s)', 'Action'],
        [
          ['Arrow keys / WASD', 'Directional movement'],
          ['Space / Shift', 'Hold to boost'],
          ['P / Escape', 'Pause / Resume'],
          ['R (on dead screen)', 'Retry'],
        ],
        [2400, 7160],
      ),
      ...spacer(),
      note('KeyboardHandler is a separate mixin from DragCallbacks. Both can be active simultaneously — useful for iPad with keyboard. Velocity is additive; whichever input provides the larger magnitude wins via clamp.'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 8. COLLISION DETECTION
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('8. Collision Detection'),
      p('All collision detection uses Flame\'s built-in HasCollisionDetection + ShapeHitbox system. Never implement manual distance checks — let Flame handle the broad/narrow phase.'),
      ...spacer(),
      h3('Hitbox Definitions'),
      makeTable(
        ['Component', 'Hitbox Shape', 'Size vs Sprite', 'Reasoning'],
        [
          ['PlaneComponent', 'RectangleHitbox', '70% of sprite', 'Forgiveness margin for near-misses'],
          ['MissileComponent (rocket)', 'CircleHitbox', 'radius = 8px', 'Fast, rotation-independent'],
          ['MissileComponent (torpedo)', 'RectangleHitbox', '80% of sprite', 'Elongated shape matters'],
          ['PowerupComponent', 'CircleHitbox', 'radius = 22px', 'Generous pickup radius'],
        ],
        [2200, 2000, 1800, 3560],
      ),
      ...spacer(),
      h3('Collision Callback Pattern'),
      code('// In PlaneComponent'),
      code('@override'),
      code('void onCollisionStart('),
      code('  Set<Vector2> intersectionPoints,'),
      code('  PositionComponent other,'),
      code(') {'),
      code('  super.onCollisionStart(intersectionPoints, other);'),
      code('  if (other is MissileComponent && !isInvincible) {'),
      code('    _handleMissileHit(other);'),
      code('  } else if (other is PowerupComponent) {'),
      code('    _handlePowerup(other);'),
      code('  }'),
      code('}'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 9. RENDERING & PSEUDO-3D
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('9. Rendering & Pseudo-3D Effect'),

      h2('9.1 Plane 3D Banking'),
      p('The 2.5D feel comes from dynamically adjusting the plane\'s vertical scale based on pitch and banking the sprite based on horizontal velocity. This is achieved in the render method — no actual 3D math.'),
      code('// In PlaneComponent.render(Canvas canvas)'),
      code('canvas.save();'),
      code('canvas.translate(size.x / 2, size.y / 2);'),
      code(''),
      code('// Banking: rotate proportional to horizontal velocity'),
      code('canvas.rotate(rollAngle);'),
      code(''),
      code('// Pitch: scale Y axis for 3D depth illusion'),
      code('final pitchScale = 0.85 + (velocity.y / maxSpeed) * 0.15;'),
      code('canvas.scale(1.0, pitchScale.clamp(0.7, 1.0));'),
      code(''),
      code('canvas.translate(-size.x / 2, -size.y / 2);'),
      code('_sprite.render(canvas, size: size);'),
      code('canvas.restore();'),
      ...spacer(),

      h2('9.2 Ground Grid Projection'),
      p('The perspective grid at the bottom of the screen is drawn with lines converging to a single vanishing point at the horizon. This is recalculated every frame as a Canvas draw operation.'),
      code('void render(Canvas canvas) {'),
      code('  final vp = Vector2(gameSize.x / 2, gameSize.y * 0.85); // vanishing point'),
      code('  final paint = Paint()..color = accentBlue.withOpacity(0.07)..strokeWidth = 0.8;'),
      code(''),
      code('  // Vertical lines'),
      code('  for (int xi = -10; xi <= 10; xi++) {'),
      code('    canvas.drawLine('),
      code('      Offset(vp.x + xi * 60, vp.y),'),
      code('      Offset(vp.x + xi * 300, gameSize.y + 100),'),
      code('      paint,'),
      code('    );'),
      code('  }'),
      code(''),
      code('  // Horizontal lines (perspective spacing)'),
      code('  for (int yi = 0; yi < 8; yi++) {'),
      code('    final t = (yi / 7);'),
      code('    final y = vp.y + (gameSize.y - vp.y + 100) * (t * t);'),
      code('    canvas.drawLine(Offset(0, y), Offset(gameSize.x, y), paint);'),
      code('  }'),
      code('}'),
      ...spacer(),

      h2('9.3 Render Order (Z-Index)'),
      makeTable(
        ['Z Priority', 'Component', 'Notes'],
        [
          ['0 (back)', 'BackgroundComponent', 'Solid gradient fill'],
          ['1', 'StarField', 'Parallax stars, slow scroll'],
          ['2', 'CloudLayer', 'Low opacity cloud blobs'],
          ['3', 'GroundGrid', 'Perspective lines, clipped to bottom 30%'],
          ['4', 'Powerups', 'World space objects'],
          ['5', 'MissileComponent (trail)', 'Rendered before missile body'],
          ['6', 'MissileComponent (body)', 'Main missile sprite'],
          ['7', 'PlaneComponent (trail)', 'Engine trail particles'],
          ['8', 'PlaneComponent (body)', 'Main plane sprite + glow'],
          ['9', 'ExplosionEffect', 'Particles above all world objects'],
          ['10', 'WarningIndicator', 'Screen-edge arrows, top of world layer'],
          ['11 (front)', 'HUDOverlay (Flutter)', 'Flutter widget tree, outside Flame canvas'],
        ],
        [1400, 2600, 5560],
      ),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 10. AUDIO
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('10. Audio Architecture'),

      h2('10.1 Audio Manager'),
      p('AudioManager is a singleton Flame Component that wraps flame_audio. It exposes a clean API consumed by all other components and respects the user\'s mute/volume settings stored in SharedPreferences.'),
      code('class AudioManager extends Component with HasGameRef {'),
      code('  static const _bgmPath = \'audio/bgm/combat_loop.mp3\';'),
      code(''),
      code('  late final AudioPool _explosionPool;'),
      code('  late final AudioPool _missilePool;'),
      code(''),
      code('  Future<void> playBGM() async =>'),
      code('    FlameAudio.bgm.play(_bgmPath, volume: _bgmVolume);'),
      code(''),
      code('  Future<void> playSFX(SFX sfx) async {'),
      code('    if (_sfxMuted) return;'),
      code('    switch (sfx) {'),
      code('      case SFX.explosion: _explosionPool.start(); break;'),
      code('      case SFX.missileWarning: _missilePool.start(); break;'),
      code('      case SFX.boost: FlameAudio.play(\'sfx/boost.wav\'); break;'),
      code('      case SFX.powerup: FlameAudio.play(\'sfx/powerup.wav\'); break;'),
      code('      case SFX.gameOver: FlameAudio.play(\'sfx/game_over.wav\'); break;'),
      code('    }'),
      code('  }'),
      code('}'),
      ...spacer(),

      h2('10.2 Required Audio Assets'),
      makeTable(
        ['File', 'Type', 'Duration', 'Trigger'],
        [
          ['audio/bgm/combat_loop.mp3', 'Looped BGM', '60–90s', 'Playing state start'],
          ['audio/sfx/explosion.wav', 'SFX', '0.6s', 'Missile hits plane'],
          ['audio/sfx/missile_warning.wav', 'SFX', '0.3s', 'Homing missile spawned'],
          ['audio/sfx/boost.wav', 'SFX', '0.4s', 'Boost activated'],
          ['audio/sfx/powerup.wav', 'SFX', '0.3s', 'Powerup collected'],
          ['audio/sfx/game_over.wav', 'SFX', '1.5s', 'Player dies (lives = 0)'],
          ['audio/sfx/level_up.wav', 'SFX', '0.8s', 'Level transition'],
        ],
        [2800, 900, 1000, 4860],
      ),
      ...spacer(),
      info('Use Suno or Udio to generate the combat BGM loop. Use jsfxr (https://sfxr.me) to generate all SFX — it produces clean WAV files for free. See Section 2 of the Game Design document for audio style references.'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 11. HUD & OVERLAYS
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('11. HUD & Flutter Overlays'),

      h2('11.1 Overlay Registration'),
      p('Flutter widget overlays are registered on the GameWidget and shown/hidden by GameManager calling game.overlays.add() / remove(). This keeps Flutter widgets reactive and avoids manual Canvas drawing for UI.'),
      code('// In AceStrikeGame.onLoad()'),
      code('// Overlays are registered in the GameWidget builder in app.dart'),
      code('// game.overlays.add(HUDOverlay.id) called when game starts'),
      code('// game.overlays.add(GameOverOverlay.id) called on game over'),
      ...spacer(),

      h2('11.2 HUD Layout'),
      makeTable(
        ['Element', 'Position', 'Data Source', 'Update Trigger'],
        [
          ['Score', 'Top-left', 'GameManager.scoreStream', 'Every frame (+1 or +2 when boosting)'],
          ['Level badge', 'Top-right', 'GameManager.levelStream', 'On level transition'],
          ['Lives (hearts)', 'Top-center', 'GameManager.livesStream', 'On hit'],
          ['Boost bar', 'Bottom-center', 'PlaneComponent.boostStream', 'Every frame'],
          ['Warning arrows', 'Screen edges (Flame layer)', 'SpawnManager', 'Per missile'],
        ],
        [1600, 1600, 2200, 4160],
      ),
      ...spacer(),

      h2('11.3 Bridging Flame → Flutter (StreamProvider)'),
      code('// In GameManager'),
      code('final _scoreController = StreamController<int>.broadcast();'),
      code('Stream<int> get scoreStream => _scoreController.stream;'),
      code(''),
      code('void addScore(int delta) {'),
      code('  score += delta;'),
      code('  _scoreController.add(score);'),
      code('}'),
      code(''),
      code('// In HUDOverlay (Flutter widget)'),
      code('final scoreAsync = ref.watch(scoreProvider);'),
      code('// scoreProvider is a StreamProvider listening to game.gameManager.scoreStream'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 12. PERSISTENCE
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('12. Data Persistence'),
      makeTable(
        ['Key', 'Type', 'Description', 'Read At'],
        [
          ['hi_score', 'int', 'All-time best score', 'App launch + Game Over screen'],
          ['sfx_enabled', 'bool', 'SFX on/off', 'AudioManager.init()'],
          ['bgm_enabled', 'bool', 'BGM on/off', 'AudioManager.init()'],
          ['bgm_volume', 'double', '0.0–1.0', 'AudioManager.init()'],
          ['haptics_enabled', 'bool', 'Haptic feedback on/off', 'Input handler init'],
        ],
        [2000, 1000, 2600, 3960],
      ),
      ...spacer(),
      code('// StorageService (core/storage_service.dart)'),
      code('class StorageService {'),
      code('  static const _hiScoreKey = \'hi_score\';'),
      code(''),
      code('  Future<int> getHiScore() async {'),
      code('    final prefs = await SharedPreferences.getInstance();'),
      code('    return prefs.getInt(_hiScoreKey) ?? 0;'),
      code('  }'),
      code(''),
      code('  Future<void> saveHiScore(int score) async {'),
      code('    final prefs = await SharedPreferences.getInstance();'),
      code('    await prefs.setInt(_hiScoreKey, score);'),
      code('  }'),
      code('}'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 13. AGENT TASK BREAKDOWN
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('13. Agent Task Breakdown'),
      p('Each agent is assigned a bounded scope. Agents must not implement functionality outside their assigned section. Integration is handled by the Lead Agent after all tasks are complete.'),
      ...spacer(),
      makeTable(
        ['Agent', 'Task', 'Files to Create', 'Depends On'],
        [
          ['Agent 1\n(Scaffold)', 'Project scaffold, pubspec, folder structure, constants, asset declarations', 'pubspec.yaml, core/constants.dart, core/assets.dart, ace_strike_game.dart (stub)', 'None — first agent'],
          ['Agent 2\n(World)', 'Background, star field, cloud layer, ground grid components', 'background_component.dart, star_field.dart, cloud_layer.dart, ground_grid.dart', 'Agent 1'],
          ['Agent 3\n(Plane)', 'PlaneComponent with physics, banking, boost, trail, hitbox', 'plane_component.dart, plane_trail.dart, plane_hitbox.dart', 'Agent 1'],
          ['Agent 4\n(Missiles)', 'MissileComponent, MissileFactory, ComponentPool, all 4 types', 'missile_component.dart, missile_factory.dart, missile_type.dart', 'Agent 1'],
          ['Agent 5\n(Effects)', 'ExplosionEffect, WarningIndicator, BoostFlash, PowerupComponent', 'explosion_effect.dart, warning_indicator.dart, boost_flash.dart, powerup_component.dart', 'Agent 1'],
          ['Agent 6\n(Managers)', 'GameManager, SpawnManager, DifficultyManager, AudioManager', 'game_manager.dart, spawn_manager.dart, difficulty_manager.dart, audio_manager.dart', 'Agents 3, 4, 5'],
          ['Agent 7\n(HUD)', 'HUDOverlay, PauseOverlay, GameOverOverlay, StreamProvider bridge', 'hud_overlay.dart, pause_overlay.dart, game_over_overlay.dart', 'Agent 6'],
          ['Agent 8\n(Integration)', 'Wire all components in AceStrikeGame, GameWidget, AppRouter, StorageService', 'ace_strike_game.dart (final), app.dart, core/storage_service.dart', 'Agents 1–7'],
          ['Agent 9\n(CI/CD)', 'Codemagic YAML, FVM config, build_runner step, TestFlight workflow', 'codemagic.yaml, .fvm/fvm_config.json', 'Agent 8'],
        ],
        [1400, 2200, 2400, 3560],
      ),
      ...spacer(),
      note('Agent 8 (Integration) is the most critical. It must read ALL previous agents\' output before writing. It resolves interface mismatches and performs the final wiring. Assign your most capable agent to this task.'),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 14. NAMING & CODING CONVENTIONS
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('14. Naming & Coding Conventions'),

      h2('14.1 File & Class Naming'),
      makeTable(
        ['Pattern', 'Example'],
        [
          ['Flame Component class', 'PlaneComponent, MissileComponent, StarField'],
          ['Manager class', 'GameManager, SpawnManager, AudioManager'],
          ['Enum', 'MissileType, GameState, PowerupType, SFX'],
          ['Extension', 'Vector2X, ColorX (in core/extensions.dart)'],
          ['Provider (Riverpod)', 'scoreProvider, livesProvider, settingsProvider'],
          ['File name', 'plane_component.dart, missile_factory.dart (snake_case)'],
          ['Asset path constant', 'Assets.planePng, Assets.bgmCombatLoop (in core/assets.dart)'],
        ],
        [2800, 6760],
      ),
      ...spacer(),

      h2('14.2 Code Rules'),
      bullet('All public APIs must have dartdoc comments.'),
      bullet('No magic numbers — all constants in core/constants.dart.'),
      bullet('Prefer composition over inheritance for Flame Components.'),
      bullet('Never call setState() or ChangeNotifier inside Flame Components — use streams.'),
      bullet('Use fpdart Either<Failure, T> for all async operations that can fail.'),
      bullet('Tests live in test/ mirroring lib/ structure: test/game/components/plane_component_test.dart.'),
      bullet('Run fvm flutter analyze --fatal-infos before committing. Zero warnings allowed.'),
      ...spacer(),

      h2('14.3 Git Conventions'),
      makeTable(
        ['Type', 'Format', 'Example'],
        [
          ['Feature', 'feat(scope): description', 'feat(missile): add cluster split behaviour'],
          ['Fix', 'fix(scope): description', 'fix(plane): clamp velocity to viewport bounds'],
          ['Refactor', 'refactor(scope): description', 'refactor(spawn): extract pool to factory'],
          ['Test', 'test(scope): description', 'test(manager): add game state transition tests'],
          ['Docs', 'docs(scope): description', 'docs(readme): add build instructions'],
          ['CI', 'ci: description', 'ci: add TestFlight upload step'],
        ],
        [1400, 2800, 5360],
      ),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 15. CI/CD
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('15. CI/CD Pipeline (Codemagic)'),
      p('The CI/CD pipeline is configured in codemagic.yaml and follows the same pattern as the Sayles platform. The build workflow runs on every push to main; the release workflow runs on git tags.'),
      ...spacer(),
      h3('Build Steps (in order)'),
      numbered('fvm use 3.24.x — pin Flutter version'),
      numbered('fvm flutter pub get'),
      numbered('fvm dart run build_runner build --delete-conflicting-outputs'),
      numbered('fvm flutter test — fail on any test failure'),
      numbered('fvm flutter analyze --fatal-infos — fail on any lint warning'),
      numbered('fvm flutter build ipa --release --flavor production'),
      numbered('Upload to TestFlight (App Store Connect API key via Codemagic env vars)'),
      ...spacer(),
      h3('Required Environment Variables'),
      makeTable(
        ['Variable', 'Description'],
        [
          ['APP_STORE_CONNECT_ISSUER_ID', 'App Store Connect API issuer ID'],
          ['APP_STORE_CONNECT_KEY_IDENTIFIER', 'API key identifier'],
          ['APP_STORE_CONNECT_PRIVATE_KEY', 'Private key PEM content'],
          ['CERTIFICATE_PRIVATE_KEY', 'iOS distribution certificate private key'],
        ],
        [3600, 5960],
      ),
      ...spacer(),

      // ══════════════════════════════════════════════════════════════════════
      // 16. GLOSSARY
      // ══════════════════════════════════════════════════════════════════════
      new Paragraph({ children: [new PageBreak()] }),
      h1('16. Glossary'),
      makeTable(
        ['Term', 'Definition'],
        [
          ['Flame', 'Flutter game engine built on Canvas; version 1.18.x used throughout'],
          ['Component', 'Base Flame class; anything added to the game tree extends Component'],
          ['HasGameRef<T>', 'Mixin giving a Component typed access to the root FlameGame instance'],
          ['DragCallbacks', 'Flame mixin providing onDragStart / onDragUpdate / onDragEnd'],
          ['ShapeHitbox', 'Flame collision shape attached to a Component for hit detection'],
          ['ComponentPool', 'Object pooling utility in Flame; reuses components to reduce GC'],
          ['PositionComponent', 'Component with position, size, angle, and anchor properties'],
          ['ParticleSystemComponent', 'Flame component managing particle animation lifecycle'],
          ['RouterComponent', 'Flame\'s built-in scene/route manager'],
          ['StreamProvider', 'Riverpod provider backed by a Dart Stream; used for HUD data'],
          ['FVM', 'Flutter Version Manager; locks project to a specific Flutter SDK version'],
          ['TestFlight', 'Apple\'s beta distribution platform; receives builds from Codemagic'],
          ['Pseudo-3D', 'Simulating depth without a 3D engine using scale, parallax, and canvas transforms'],
        ],
        [2400, 7160],
      ),
      ...spacer(),

      // ── Footer spacer ──────────────────────────────────────────────────────
      ...spacer(2),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        spacing: { before: 480 },
        border: { top: { style: BorderStyle.SINGLE, size: 4, color: C.mid } },
        children: [
          txt('Ace Strike: Missile Dodge — Architecture v1.0.0  ·  Flutter + Flame  ·  Confidential', { size: 18, color: C.muted, italic: true }),
        ],
      }),
    ],
  }],
});

Packer.toBuffer(doc).then(buf => {
  fs.writeFileSync('/mnt/user-data/outputs/AceStrike_GameArchitecture.docx', buf);
  console.log('Done');
}).catch(console.error);

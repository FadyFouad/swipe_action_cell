# Quickstart: Custom Painting & Decoration Hooks (F013)

**Branch**: `012-custom-painter` | **Date**: 2026-03-01

These test scenarios map directly to the acceptance criteria in `spec.md`.

---

## Scenario 1 — Background & Foreground Painter Hooks (US1)

### Setup
```dart
class _GradientPainter extends CustomPainter {
  _GradientPainter(this.ratio);
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.red.withOpacity(ratio), Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width * ratio, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * ratio, size.height), paint);
  }

  @override
  bool shouldRepaint(_GradientPainter old) => ratio != old.ratio;
}

class _BorderPainter extends CustomPainter {
  _BorderPainter(this.ratio);
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(ratio)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_BorderPainter old) => ratio != old.ratio;
}
```

### Widget
```dart
SwipeActionCell(
  paintingConfig: SwipePaintingConfig(
    backgroundPainter: (progress, state) => _GradientPainter(progress.ratio),
    foregroundPainter: (progress, state) => _BorderPainter(progress.ratio),
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.oneShot,
    onSwipeCompleted: (_) {},
  ),
  child: const ListTile(title: Text('Swipe to test painters')),
)
```

### What to verify
- [ ] Background: Red gradient strip grows proportionally as user drags left
- [ ] Foreground: Yellow border appears above ListTile content (not behind it)
- [ ] On release without threshold: both painters animate back to zero with no stale artifacts
- [ ] Tap on `ListTile` (title text area) while foreground painter is active → tap registers normally (hit test unaffected)
- [ ] Remove `paintingConfig` (set to null) → zero visual change, no artifacts

---

## Scenario 2 — Decoration Interpolation (US2)

### Widget
```dart
SwipeActionCell(
  paintingConfig: const SwipePaintingConfig(
    restingDecoration: BoxDecoration(
      color: Color(0xFFEEEEEE),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    activatedDecoration: BoxDecoration(
      color: Color(0xFFFFCDD2),
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.oneShot,
    onSwipeCompleted: (_) {},
  ),
  child: const ListTile(title: Text('Swipe to see decoration morph')),
)
```

### What to verify
- [ ] At rest: light grey background, heavily rounded corners (12dp)
- [ ] At 50% drag: background halfway between grey and pink; corners halfway between 12dp and 2dp
- [ ] At full activation (ratio ≥ 1.0): full pink background, nearly sharp corners — no glitch
- [ ] Release without completing: decoration smoothly returns to resting state
- [ ] Provide only `restingDecoration` (no `activatedDecoration`): resting decoration always applied, no crash

---

## Scenario 3 — `SwipeMorphIcon` in Background Builder (US3)

### Widget
```dart
SwipeActionCell(
  visualConfig: SwipeVisualConfig(
    leftBackground: (context, progress) {
      return ColoredBox(
        color: Colors.redAccent,
        child: Center(
          child: SwipeMorphIcon(
            startIcon: const Icon(Icons.delete_outline, color: Colors.white),
            endIcon: const Icon(Icons.delete, color: Colors.white),
            progress: progress.ratio,
            size: 28.0,
          ),
        ),
      );
    },
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.oneShot,
    onSwipeCompleted: (_) {},
  ),
  child: const ListTile(title: Text('Delete item')),
)
```

### What to verify
- [ ] At `progress.ratio = 0.0`: only `delete_outline` icon visible
- [ ] At `progress.ratio = 0.5`: both icons blended at equal weight — neither dominates
- [ ] At `progress.ratio = 1.0`: only `delete` (filled) icon visible
- [ ] Cross-fade is smooth — no jump between states

---

## Scenario 4 — Particle Burst on Action Completion (US4)

### Widget
```dart
SwipeActionCell(
  paintingConfig: const SwipePaintingConfig(
    particleConfig: ParticleConfig(
      count: 12,
      colors: [Colors.red, Colors.orange, Colors.yellow],
      spreadAngle: 360.0,
      duration: Duration(milliseconds: 500),
    ),
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.oneShot,
    onSwipeCompleted: (_) {},
    postActionBehavior: PostActionBehavior.snapBack,
  ),
  child: const ListTile(title: Text('Trigger particle burst')),
)
```

### What to verify
- [ ] Complete a left-swipe action → 12 particles appear at cell center and animate outward
- [ ] By 500 ms after action: all particles are gone, no rendering overhead
- [ ] Right-swipe action → no particles appear
- [ ] Complete action, then immediately dispose widget mid-animation → no particles persist, no exception
- [ ] Set `particleConfig: null` (or no `paintingConfig`) → no burst, no overhead

---

## Scenario 5 — Zero Overhead Baseline (FR-012-010)

### Widget
```dart
// Control: no painting config
SwipeActionCell(
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.oneShot,
    onSwipeCompleted: (_) {},
  ),
  child: const ListTile(title: Text('No painting')),
)

// Experimental: painting config with all-null fields
SwipeActionCell(
  paintingConfig: const SwipePaintingConfig(),  // All fields null
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.oneShot,
    onSwipeCompleted: (_) {},
  ),
  child: const ListTile(title: Text('Null painting config')),
)
```

### What to verify
- [ ] With `paintingConfig: null`: Stack in `build()` has no extra children (verify via `debugDumpRenderTree`)
- [ ] With `SwipePaintingConfig()` (all-null): same Stack child count as null case
- [ ] `flutter analyze` passes with zero warnings on both cells

---

## Scenario 6 — Edge Case: Incompatible Decoration Types

### Widget
```dart
SwipeActionCell(
  paintingConfig: SwipePaintingConfig(
    // BoxDecoration vs ShapeDecoration — lerp may return null
    restingDecoration: const BoxDecoration(color: Colors.grey),
    activatedDecoration: ShapeDecoration(
      color: Colors.red,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.oneShot,
    onSwipeCompleted: (_) {},
  ),
  child: const ListTile(title: Text('Mixed decoration types')),
)
```

### What to verify
- [ ] No crash during drag
- [ ] Resting decoration displayed at all progress values (graceful fallback)
- [ ] No stale frame artifacts

---

## Scenario 7 — Rapid Swipe Direction Reversal

### Widget
Same as Scenario 1 with background painter.

### What to verify
- [ ] Rapidly reverse swipe direction (left then right repeatedly)
- [ ] Painter and decoration values update correctly on every frame — no stale frame stuck at a previous ratio
- [ ] No exceptions or visual glitches

# Lab 1: Stateless Widgets
Author: Simone Corbo
---


# 1 · The Widget Model

A user interface in Flutter is not a set of objects you draw and then mutate. It is a *description* you produce, and produce again, every time something changes. The whole of the weather screen built here (the blue gradient, the frosted card, the temperature, the two little glass chips) is one big expression: a tree of lightweight objects that says *what* should be on screen, which the framework turns into actual pixels on your behalf. Nothing here changes after it is drawn; the screen is fixed. That constraint is the point. It lets every idea below be understood in isolation, before time and interaction enter the picture.


> A Flutter UI is a **tree of widgets**, and a widget is a plain, immutable value that describes a piece of the interface. You build the tree by nesting: a screen contains a column, the column contains a card, the card contains text. You never reach into a widget to change it, you describe the whole thing declaratively and let the framework do the reconciling. Master that one habit and the rest is vocabulary.

---
## 1.1 The Dart syntax
Before the widgets make sense, the language scaffolding around them has to stop being noise. Dart is an ordinary object-oriented language with a few features Flutter leans on heavily, and everything below appears in the code.
### `void main() => runApp(const WeatherApp());`
- **`main()`** is the program's entry point. Every Dart program starts by calling `main`; the runtime looks for it, calls it, and the app is whatever happens next.
- **`void`** is the return type: `main` returns nothing. A function's type is written before its name in Dart.
- **`=>`** is the arrow (expression-body) shorthand. `=> expr;` is exactly `{ return expr; }` — a body that is a single expression. Since `runApp(...)` itself returns nothing, no value is actually returned; the arrow just runs it.
- **`runApp(Widget)`** is the bridge from your code into the framework. It takes a single root widget, *inflates* it (walks the tree, creating the machinery behind each widget), and mounts it as the root of everything on screen. Whatever you pass becomes the entire app.
- **`const`** here means the `WeatherApp` value is a **compile-time constant**: fully determined before the program runs, so the compiler builds it once and reuses that identical instance forever. A widget can be `const` only when every input it receives is itself constant. This matters more than it looks — see the note on canonicalization below.
### Classes, constructors, and the `{ ... }` parameters

```dart
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;
  final Color? fill;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding = const EdgeInsets.all(20),
    this.fill,
  });
  ...
}
```

- **`class GlassCard extends StatelessWidget`** declares a class that *is a* `StatelessWidget` (inheritance). It inherits all of `StatelessWidget`'s behaviour — most importantly, the contract that it must have a `build` method — and adds its own fields.
- **`final`** fields are assigned exactly once, at construction, and can never be reassigned. Widgets store their inputs in `final` fields because a widget is meant to be an immutable description: once you have built a `GlassCard` with a radius of 22, that object *is* a card of radius 22, permanently. To get a different card you build a new one.
- **`Color?`**: the trailing **`?`** makes the type **nullable**. Under Dart's sound null safety, a plain `Color` can *never* hold `null`; only `Color?` can. The compiler enforces this, which is why `fill` (optional, may be absent) is `Color?` while `child` (always required) is a non-nullable `Widget`.
- **`const GlassCard({ ... })`** is the constructor. The **`{ }`** make these **named parameters**: callers pass them by name (`GlassCard(radius: 14, child: ...)`) in any order. Deeply nested widget trees are far more readable when every argument is labelled, which is why Flutter's whole API is built this way.
- **`required this.child`**: `required` forces the caller to supply the argument (omitting it is a compile error). **`this.child`** is an *initializing formal* — a shorthand that takes the incoming argument and assigns it straight into the field of the same name, sparing you a constructor body that just copies parameters into fields.
- **`this.radius = 22`** gives a default: omit `radius` and it is 22. Defaults let one widget serve many cases without overloads.
- **`this.padding = const EdgeInsets.all(20)`**: a default value must itself be a compile-time constant, hence the `const`. You cannot default a parameter to something computed at runtime.
- **`super.key`** forwards an optional `key` up to the `StatelessWidget` base class. A key is the framework's way of telling two otherwise-identical widgets apart when a list is reordered or items are inserted; you rarely set one by hand, but forwarding it keeps that door open for callers.
### `@override` and `build`
```dart
@override
Widget build(BuildContext context) { ... }
```

- **`@override`** is an annotation announcing "this method deliberately replaces one declared in a superclass." It changes nothing at runtime; its value is that the analyzer will flag a mistake — misspell `build` as `biuld` and, because nothing in the superclass matches, you get a warning instead of a silently-ignored method.
- **`build`** is the single method every widget must implement (see §1.3). It is the heart of the whole model.
### Static members and the private `_` namespace

```dart
class AppColors {
  AppColors._();
  static const skyTop = Color(0xFF5AA9F5);
  static final inkSecondary = Colors.white.withValues(alpha: 0.58);
}
```

- **`static`** members belong to the *class itself*, not to any instance. You reach them through the class name — `AppColors.skyTop` — and never construct the class. That is exactly what you want for a palette: a fixed, global lookup table of design values.
- **`AppColors._();`** is a **private, empty constructor**. A leading underscore makes any Dart name *library-private* (visible only within its own file), and an empty private constructor means no code outside can ever write `AppColors()`. The class becomes a pure namespace — a bag of constants that cannot be instantiated by accident.
- **`const` vs `final`, a distinction worth internalising:** `const` means *known at compile time* — `Color(0xFF5AA9F5)` is a literal the compiler can bake in. `final` means *assigned once, but possibly computed at runtime* — `Colors.white.withValues(...)` has to actually run a method to produce its result, so it cannot be `const`; it is `final`. Every value is one or the other, and reaching for `const` first (when possible) is a habit that pays off in performance.

### Expressions that appear inside `build`
These small operators recur throughout the tree:
- **Ternary `cond ? a : b`** evaluates to `a` when `cond` is true, else `b`. `saved ? Icons.favorite : Icons.favorite_border` picks the heart's glyph; it is an *expression*, so it slots directly into an argument where an `if` statement could not.
- **Null-coalescing `a ?? b`** evaluates to `a` unless `a` is null, in which case `b`. `fill ?? AppColors.glassFill` is how an optional `Color?` supplies its own fallback — the canonical way to give a nullable value a default at the point of use.
- **String interpolation** injects values into a string literal: `'$temp°'` splices in `temp`, `'$windKmh km/h'` splices in `windKmh`. Use `${expression}` with braces when it is more than a bare variable name.
- **List literal `[ ... ]`** builds a `List`. `children: [ ... ]` is a `List<Widget>`, and a `Column` or `Row` lays those children out in the order given.

### The `switch` in `WeatherIcon`

```dart
IconData glyph = Icons.cloud_rounded;
Color color = AppColors.ink;
switch (condition) {
  case 'Clear':
    glyph = Icons.wb_sunny_rounded;
    color = AppColors.sun;
  case 'Clouds':
    glyph = Icons.cloud_rounded;
  case 'Rain':
  case 'Drizzle':
    glyph = Icons.water_drop_rounded;
  ...
}
```

- A **`switch`** compares `condition` against each `case` label and runs the matching branch.
- **Dart 3 removed accidental fall-through:** a non-empty case does *not* leak into the next, and you never write `break`. `case 'Clear':` runs its own two lines and stops. This closes off one of the oldest bug sources in C-family languages.
- **Empty cases still share the next body:** `case 'Rain':` immediately followed by `case 'Drizzle':` means *both* strings run the `Drizzle` branch. That is the deliberate way to map several inputs to one outcome.
- **Why the defaults sit *above* the switch:** `glyph` and `color` are seeded with cloud/white *before* the switch. Any `condition` not listed simply falls through with those seed values still in place, so no `default:` clause is needed — the pre-seeded variables *are* the default.

---
## 1.2 How the app boots
The path from `main` to a painted screen is short but each step earns its place.
### `runApp(const WeatherApp())`
Covered above: it hands the root widget to the framework, which inflates and mounts it. Everything visible descends from this one call, so the tree literally has a single root.
### `MaterialApp`

The conventional root widget for a Material-Design app. Its real job is to install a great deal of shared machinery *above* your screens, so that everything below can simply assume it exists: a `Navigator` (the stack that routes between screens), theming, a text direction, a default `MediaQuery` carrying the screen's size and insets, localization plumbing, and the `Overlay` that dialogs and tooltips paint into. You rarely interact with most of it directly, but nearly every widget you write quietly depends on one piece of it.

```dart
MaterialApp(
  title: 'Weather',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
  home: const HomeScreen(),
)
```

Parameters used here:

| Parameter | Type | What it does (and the choice made) |
|---|---|---|
| `home` | `Widget` | The widget shown on the default route — the first screen. It points at `HomeScreen`. |
| `theme` | `ThemeData` | The app-wide light theme (colours, fonts, component defaults). See below. |
| `title` | `String` | A short description the operating system uses (e.g. the Android task-switcher label). Never shown inside the app itself. |
| `debugShowCheckedModeBanner` | `bool` | The red "DEBUG" ribbon in the corner of debug builds. Set to `false` so the screen matches the intended design. |

Other parameters worth knowing (unused here):

| Parameter | Why you would reach for it |
|---|---|
| `routes` / `initialRoute` / `onGenerateRoute` | Declarative navigation tables, once the app has more than one screen. |
| `darkTheme` / `themeMode` | Provide a dark theme and choose light/dark/system. |
| `locale` / `localizationsDelegates` / `supportedLocales` | Internationalisation. |
| `navigatorKey` / `navigatorObservers` | Programmatic navigation and analytics hooks. |
| `builder` | Wrap every screen in a common widget (e.g. a global banner). |

> There is also `MaterialApp.router(...)`, a variant wired for advanced routing packages such as go_router. It is not needed here.

### `ThemeData`
A bundle of styling defaults that descendant widgets read automatically. The mechanism behind "automatically" is *inherited widgets*: `MaterialApp` places the theme high in the tree, and any widget below can look it up through its `BuildContext` (`Theme.of(context)`). Setting styling once at the top and reading it far below is cheaper and less error-prone than passing colours and fonts down through every constructor.

| Parameter (used here) | What it does |
|---|---|
| `fontFamily` | The default font for all `Text` unless a widget overrides it. It names `'Inter'`; if `Inter` is not bundled as an asset, Flutter silently falls back to the system font. |
| `useMaterial3` | Opts into Material 3 component styling. **Note:** Material 3 is already the default on current Flutter, so this line is redundant now and may show as deprecated; it can safely be deleted. It is kept here only to make the intent explicit. |

Commonly-set `ThemeData` parameters seen elsewhere: `colorScheme` (the modern way to define a palette, usually via `ColorScheme.fromSeed(seedColor: ...)`), `scaffoldBackgroundColor`, `textTheme`, and per-component themes such as `appBarTheme`. This app instead overrides colours directly in its own widgets (through `AppColors`), because the design is very specific and exact pixel control is wanted rather than the theme's defaults.

---
## 1.3 The widget model itself
This is the conceptual centre of everything. Read it slowly.

### `StatelessWidget`

A widget whose appearance is a pure function of the inputs it was handed at construction. Give it the same inputs and it produces the same UI, every time, forever; it holds no internal data that can change. Every widget on this screen is stateless, which is precisely why the screen is static. (Widgets that *do* change over time use a different base class, `StatefulWidget`, which introduces mutable state and a lifecycle — a separate topic taken up once the screen needs to react to input.)
### `Widget build(BuildContext context)`

The one method every widget implements. The framework calls it to ask a single question — "given your current inputs, what should the interface look like?" — and your job is to return a subtree of other widgets answering it. You never call `build` yourself; the framework calls it, on first display and again whenever something upstream requires the widget to be redescribed.
- **Return type `Widget`**: `build` hands back *more widgets*. A screen is widgets nested inside widgets, all the way down to leaves like `Text` and `Icon`. This recursion is the whole structure of a Flutter UI.
- **`BuildContext context`** is a handle to *this widget's position in the tree*. Concretely it is the widget's `Element` (see the note below), and it is what you use to look things up that live *above* you — the theme, the navigator, the screen's dimensions. It is used only lightly on a static screen; it becomes central the moment a widget needs to reach shared state or trigger navigation.

> [!note] What is actually behind `build`: the three trees
> It looks as though your widgets *are* the UI, but the framework keeps **three** parallel trees, and understanding the split explains almost every performance rule you will ever meet:
> 1. The **widget tree** is what you write — cheap, immutable descriptions. Flutter creates and throws these away constantly; a rebuild produces a whole new widget tree.
> 2. The **element tree** is the framework's stable bookkeeping. Each element points at a current widget and *persists across rebuilds*. When you rebuild, Flutter walks the new widget tree against the existing elements and, where a widget's type and key still match, it simply updates the element in place instead of tearing anything down. `BuildContext` *is* an element.
> 3. The **render tree** holds the heavy `RenderObject`s that actually do layout and painting.
>
> So a "rebuild" is cheap because it only regenerates the featherweight top tree and reconciles it against the durable middle one; the expensive render objects are reused wherever possible. This is also why `const` widgets are worth chasing — an unchanged `const` subtree is skipped entirely during reconciliation.
### `Icons` and `IconData`
- **`IconData`** is the type that describes a single glyph: a font code point plus which icon font it lives in.
- **`Icons`** is a large class of predefined `IconData` constants drawn from the Material icon font — `Icons.search`, `Icons.favorite`, `Icons.settings_rounded`, and hundreds more. Many glyphs come in style variants: plain (`Icons.cloud`), `_rounded`, `_outlined`, `_sharp`. The rounded set is used throughout here to match the soft, glassy visual language.

---
## 1.4 Layout widgets (how things are positioned)
Flutter's layout follows one algorithm, and knowing it demystifies the whole section: **constraints go down, sizes come up, the parent sets position.** A parent passes each child a *constraint* (a min/max width and height it must fit within); the child chooses its own *size* within that constraint and reports it back up; the parent then decides *where* to place the child. Almost every layout surprise — an "unbounded height" error, a widget that fills too much or too little — is this conversation going wrong. Keep it in mind as each widget below appears.

### `Scaffold`
Implements the basic Material screen skeleton: a structured frame with optional slots for an app bar, body, floating action button, drawers, and bottom navigation. Only the **`body`** slot is used here; the top bar and tab bar are built by hand, deliberately, because the design calls for exact custom styling that Material's stock `AppBar` and `BottomNavigationBar` would not match. Using `Scaffold` anyway is still worthwhile: it gives correct full-screen sizing and a proper place to host content.

| Parameter (used here) | What it does |
|---|---|
| `body` | The main content area. It holds the gradient background plus everything else. |

Notable unused slots: `appBar`, `bottomNavigationBar`, `floatingActionButton`, `drawer`, `backgroundColor`, `resizeToAvoidBottomInset`.
### `SafeArea`
Insets its child so content avoids hardware intrusions — the notch or Dynamic Island at the top, the home-indicator gesture bar at the bottom. It reads the system-reported insets from `MediaQuery` and adds exactly that much padding. Without it, the title could slide under the notch on a modern phone.

| Parameter | What it does |
|---|---|
| `child` | The content to inset. |
| `top` / `bottom` / `left` / `right` (`bool`) | Turn padding on/off per edge (all default `true`). |
| `minimum` (`EdgeInsets`) | A floor on the padding even where the system reports none. |
### `Container`
A general-purpose box, and really a convenience that composes several simpler widgets: it can paint a background/decoration, add padding and margin, size itself, and hold one child. It is used here for the full-screen gradient background.

| Parameter (used here) | What it does |
|---|---|
| `decoration` | A `BoxDecoration` that paints the gradient (see §1.5). |
| `width` / `height` | Set to `double.infinity` to force the box to fill all space its parent offers, so the gradient covers the whole screen. |
| `padding` | Inner space between the box edge and its child (used inside `GlassCard`). |
| `child` | The single widget inside. |

> `Container` exposes *both* a `color` and a `decoration` parameter, and setting both at once is an error, because `decoration` already includes a `color` slot. For a background colour *and* a border or radius, put the colour *inside* the `BoxDecoration` (`BoxDecoration(color: ...)`) — exactly what `GlassCard` does.

Other `Container` parameters: `margin` (outer space), `alignment`, `constraints`, `transform`.
### `Padding` and `EdgeInsets`
- **`Padding`** wraps a child and adds empty space around it, shrinking the constraint it passes down by that amount. It provides the screen's horizontal margin here.
- **`EdgeInsets`** is the value describing *how much* space, on *which* sides:

| `EdgeInsets` form | Meaning |
|---|---|
| `EdgeInsets.all(20)` | 20 on all four sides (`GlassCard`'s default padding). |
| `EdgeInsets.symmetric(horizontal: 20)` | Left + right only (the screen margin). |
| `EdgeInsets.symmetric(horizontal: 13, vertical: 9)` | Different horizontal and vertical (the `InfoChip`). |
| `EdgeInsets.only(left: 8)` | One specific side. |
| `EdgeInsets.fromLTRB(l, t, r, b)` | All four given explicitly. |
| `EdgeInsets.zero` | No padding (so `GlassIconButton` can centre its icon in a fixed 34×34 box). |

### `Column` and `Row`, and the axis model
`Column` lays its children out vertically; `Row` lays them out horizontally. The one concept to hold onto is **main axis vs cross axis**:
- In a **Column**, the main axis is vertical and the cross axis is horizontal.
- In a **Row**, the main axis is horizontal and the cross axis is vertical.

Their alignment parameters are named against those axes, which is why the same property names work for both:

| Parameter | What it controls | Values used |
|---|---|---|
| `children` | The list of widgets to lay out, in order. | a `List<Widget>` |
| `mainAxisAlignment` | Position/spacing along the main axis. | `start`, `end`, `center`, `spaceBetween`, `spaceAround`, `spaceEvenly` |
| `crossAxisAlignment` | Alignment across the main axis. | `start`, `center`, `end`, `stretch`, `baseline` |
| `mainAxisSize` | How big the Row/Column tries to be along its main axis. | `max` (default — fill the available space) or `min` (shrink to fit the children) |

Where each appears here, and why:
- The **top bar** uses `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` to push the title to the left edge and the gear to the right edge.
- **`BottomTabBar`** uses `MainAxisAlignment.center` to centre its two tab items.
- The **`InfoChip`** rows and the city+heart row use `mainAxisSize: MainAxisSize.min` so they shrink to fit their contents instead of stretching to full width.
- The **`InfoChip`'s inner `Column`** uses `crossAxisAlignment: CrossAxisAlignment.start` so the value and label are left-aligned to each other.

> **A common beginner mistake:** a `Row` inside a centred `Column`, left at its default `mainAxisSize: MainAxisSize.max`, greedily fills the entire width — so two chips that should sit together are flung to opposite edges. The fix is `mainAxisSize: MainAxisSize.min`. This is the constraints-and-sizes rule from the top of this Part in miniature: `max` reports back the largest allowed size, `min` reports back only what the children need.

### `SizedBox`
A box of an exact size. It does two jobs here:

1. **As a spacer:** `SizedBox(width: 8)` or `SizedBox(height: 12)` inserts a fixed gap between siblings in a Row or Column. This is the idiomatic way to space items — cleaner than wrapping each in padding — and maps directly to a design's "gap 8", "gap 12", and so on.
2. **As a size enforcer:** `SizedBox(width: 34, height: 34, child: ...)` forces the glass icon button to be exactly 34×34 regardless of what its child would otherwise measure.

| Parameter | What it does |
|---|---|
| `width` / `height` | Exact dimensions (omit one to constrain only the other). |
| `child` | Optional widget to size. |

### `Spacer`
A flexible gap that consumes *all* the leftover space along the main axis, shoving its siblings apart. In `HomeScreen` a `Spacer()` sits above and below the `WeatherCard`, so the card floats in the vertical centre while the search bar stays pinned near the top and the tab bar near the bottom.

| Parameter | What it does |
|---|---|
| `flex` | Relative weight when several `Spacer`s share the free space (default `1`; two equal spacers split it evenly, which is what centres the card). |

> Why it works — and when it fails: `Spacer` fills the *free* main-axis space, so there has to *be* a measurable amount of it. Inside a `Column` with a definite height (here, the safe-area height), the free space is well defined. In an unbounded or scrolling context the main axis is effectively infinite, there is no "leftover" to compute, and Flutter throws. That error is the constraints rule again: `Spacer` needs a bounded constraint coming down.

### `Center`
Centres its single child within the space it is given. Used inside `GlassIconButton` to put the icon in the middle of the 34×34 box.

| Parameter | What it does |
|---|---|
| `child` | The widget to centre. |
| `widthFactor` / `heightFactor` | Optionally size `Center` to a multiple of the child instead of filling. |

(`Center` is just shorthand for `Align(alignment: Alignment.center)`.)
### `Opacity`
Makes its child partially transparent. `_TabItem` wraps its content in `Opacity(opacity: active ? 1.0 : 0.55, ...)` so the inactive tab dims to 55% while the active one stays fully visible.

| Parameter | What it does |
|---|---|
| `opacity` | `0.0` (invisible) to `1.0` (fully visible). |
| `child` | The widget to fade. |

> Performance note, and the reason behind it: `Opacity` is slightly expensive because uniform transparency cannot be applied glyph-by-glyph — the framework must render the whole subtree to an offscreen layer and then fade that layer as a unit. For two small tab items this cost is invisible; for large or animating subtrees, prefer `AnimatedOpacity` or bake the alpha directly into the colours, avoiding the extra layer.

---
## 1.5 Painting & decoration (how things look)
### `Color`, `Colors`, and `.withValues`
- **`Color(0xFF5AA9F5)`** is a colour written as a 32-bit hex value in **`0xAARRGGBB`** order: `FF` alpha (fully opaque), `5A` red, `A9` green, `F5` blue. That is why every solid token is `0xFF…` — opaque sky colours.
- **`Colors`** is a convenience palette of named `Color`s (`Colors.white`, `Colors.black`, `Colors.blue`, and so on).
- **`.withValues(alpha: 0.58)`** returns a *copy* of a colour with a new alpha channel (0.0 to 1.0). This is how the "white @ 58%" translucent tokens are derived from `Colors.white`. Because it produces a new value rather than mutating the original, it is `final`, not `const`. (On Flutter older than 3.27 this method does not exist — use the legacy `.withOpacity(0.58)` there; on current Flutter, `withOpacity` is the deprecated one.)
### `BoxDecoration`
The "how to paint this box" object handed to a `Container`'s `decoration`. It is painted *behind* the child.

| Parameter (used here) | What it does |
|---|---|
| `gradient` | Paint a gradient fill (the screen background uses this). |
| `color` | A solid fill (used inside `GlassCard`). |
| `border` | An outline (see `Border.all`). |
| `borderRadius` | Rounded corners. |

Other `BoxDecoration` parameters: `boxShadow`, `image`, `shape`. (Note: with `shape: BoxShape.circle`, `borderRadius` cannot also be set — a circle has no corners to round.)
### `LinearGradient`
A gradient that blends colours along a straight line. The sky fades top-to-bottom through three stops.

| Parameter | What it does (here) |
|---|---|
| `colors` | The list of colours to blend (`[skyTop, skyMid, skyBottom]`). Required. |
| `begin` / `end` | Where the line starts/ends. `Alignment.topCenter` to `Alignment.bottomCenter` gives a vertical gradient. |
| `stops` | Where along the line (0.0 to 1.0) each colour sits: `[0.0, 0.52, 1.0]` places the middle colour at 52% of the way down. The list length must match `colors`. |

Other parameters: `tileMode`, `transform`. Available `Alignment` values include `topLeft`, `topCenter`, `centerLeft`, `center`, `bottomRight`, and so on.
### `Border` and `BorderRadius`
- **`Border.all(color: AppColors.glassStroke)`** is a uniform 1-logical-pixel outline on all four sides (it also accepts `width:` and `style:`). For different sides, use the `Border(top: ..., bottom: ...)` constructor with `BorderSide`s.
- **`BorderRadius.circular(22)`** rounds all four corners by the same radius. Variants: `BorderRadius.all(Radius.circular(x))`, `.only(topLeft: ...)`, `.vertical(...)`, `.horizontal(...)`.
### `ClipRRect`
Clips its child to a rounded rectangle — anything the child paints outside that rounded shape is masked away. In `GlassCard` it is the outermost piece, so that *both* the blur and the fill are masked to the same rounded silhouette. Without it, the blur would spill past the corners as a hard square.

| Parameter | What it does |
|---|---|
| `borderRadius` | The corner radius to clip to (the card's own radius is passed in). |
| `child` | What gets clipped. |
| `clipBehavior` | How aggressively to anti-alias the clip edge (the default is fine). |

### `BackdropFilter` and `ImageFilter.blur`
This is what makes the glass look frosted, and the mechanism is worth understanding because it dictates the widget ordering.
- **`BackdropFilter`** applies an image filter to *everything already painted behind it* — not to its own child. So the effect only exists if there is content underneath to sample: here, the gradient. This is why the filter must sit *above* the gradient in the tree and why it is wrapped in `ClipRRect`, so the blurred region is confined to the card's rounded bounds.
- **`ImageFilter.blur(sigmaX: 14, sigmaY: 14)`** is the filter itself: a Gaussian blur of radius 14 on each axis.

| `BackdropFilter` parameter | What it does |
|---|---|
| `filter` | The `ImageFilter` to apply to the backdrop (required). |
| `child` | Painted on *top* of the blurred backdrop — here the translucent fill `Container`. |
| `blendMode` | How the filtered result composites (default fine). |

| `ImageFilter.blur` parameter | What it does |
|---|---|
| `sigmaX` / `sigmaY` | Blur strength on each axis. |
| `tileMode` | How edges are handled (default fine). |

> **The `GlassCard` stack, outermost to innermost:** `ClipRRect` (establish the rounded mask) → `BackdropFilter` (blur whatever shows through) → `Container` (paint the translucent fill and border, hold the child). The order is not stylistic; each layer depends on the one outside it.

---
## 1.6 Content widgets (the actual text & icons)
### `Text`
Displays a string.

| Parameter (used here) | What it does |
|---|---|
| `data` (the first, positional argument) | The string to show, e.g. `'Weather'`, `'$temp°'`. |
| `style` | A `TextStyle` controlling appearance (see below). These are pulled from `AppText`. |

Other useful `Text` parameters: `textAlign`, `maxLines`, `overflow` (e.g. `TextOverflow.ellipsis`), `softWrap`, `textScaler`.
### `TextStyle`
Describes how text looks. Each property here maps to a specific typographic decision.

| Parameter (used here) | What it does |
|---|---|
| `fontSize` | Size in logical pixels (equal to points on iOS). |
| `fontWeight` | Thickness, `FontWeight.w100` to `w900` (plus `.normal` = w400, `.bold` = w700). The hero temperature is `w200` (very thin); titles are `w600` (semi-bold). |
| `color` | Text colour, from `AppColors`. |
| `height` | Line height as a *multiple* of `fontSize`. `height: 1` makes the line box exactly the font size — no extra leading — which is why the huge temperature numeral does not get pushed around vertically by its own line spacing. |

Other useful `TextStyle` parameters: `letterSpacing` (small positive values loosen tracking on section labels), `fontStyle` (italic), `decoration` (underline/strikethrough), `shadows`, `fontFamily`.
### `Icon`
Renders one glyph.

| Parameter (used here) | What it does |
|---|---|
| the `IconData` (first, positional) | Which glyph, e.g. `Icons.search`, `Icons.favorite`. |
| `size` | Glyph size in logical pixels (96 for the big weather icon, 18 for the heart, and so on). |
| `color` | Glyph colour: `AppColors.sun` for a clear sky, white otherwise. |

Other useful parameter: `semanticLabel` (an accessibility description read aloud by screen readers).

---

## 1.7 Why each component is built the way it is
A pass connecting the pieces above to the design decisions behind them.
- **`AppColors` / `AppText` (token classes).** Centralising colour and type gives one place to hold the design's values and zero drift between widgets. They are `static` members on a non-instantiable class so they read like global constants.
- **`GlassCard` with overridable `radius` / `padding` / `fill`.** One reusable frosted container, parameterised so a small chip (radius 14, lighter fill) and a large card (radius 22, stronger fill) are the *same* widget with different arguments. This is composition over a pile of one-off containers — the recurring theme of the whole model.
- **`WeatherIcon` taking a `condition` string.** It owns the condition-to-glyph-to-colour mapping in a single place, so every screen that shows weather stays consistent, and live data can later feed an API's condition string straight in with no change to the widget.
- **`InfoChip` / `WeatherCard` taking plain data (`int temp`, `String description`).** Pure stateless widgets: data in through the constructor, UI out. The data is hard-coded for now; crucially, nothing about these widgets has to change when that data later becomes live — only where it *comes from* changes.
- **`SearchField` / `BottomTabBar` as visual-only stubs.** The scope here is appearance, not behaviour. Building them now, even inert, means adding real interaction later is purely additive — no redesign, just wiring.
- **Custom top bar + tab bar instead of `AppBar` / `BottomNavigationBar`.** The design specifies exact glass styling the stock Material components do not offer, so they are composed by hand from `Row`, `GlassCard`, `Icon`, and `Text`.
- **`Spacer` above and below `WeatherCard`.** This vertically centres the hero while keeping the search field near the top and the tab bar at the bottom — a layout that adapts to any screen height, rather than one pinned with hard-coded offsets.
---
## 1.8 Common pitfalls

| Pitfall | What happens | The fix |
|---|---|---|
| **`Container` `color` *and* `decoration` together** | Runtime assertion: "Cannot provide both a color and a decoration." | Put the colour *inside* the `BoxDecoration(color: …)`. That is why `GlassCard` never sets `Container.color`. |
| **`Row`/`Column` without `mainAxisSize.min`** | A `Row` in a centred `Column` fills the whole width and pushes its children to opposite edges (the two chips separate). | Add `mainAxisSize: MainAxisSize.min` so it shrinks to fit its content. `max` is the default. |
| **`Spacer` in an unbounded axis** | "RenderFlex children have non-zero flex but incoming height constraints are unbounded." | `Spacer` needs a definite main-axis size (the `SafeArea`-bounded `Column` is fine; a scrolling column is not). |
| **`BackdropFilter` with nothing behind it** | The "frost" looks like a flat translucent box, with no blur. | The filter blurs what is painted *behind* it, so the gradient must sit underneath. Order matters. |
| **`BackdropFilter` not clipped** | The blur bleeds past the rounded corners as a hard rectangle. | Wrap it in `ClipRRect` (as `GlassCard` does) so blur and fill share one rounded mask. |
| **Dropping `const`** | Widgets rebuild more often than they need to. | Mark widgets and values `const` wherever inputs are constant; `const` subtrees are skipped during reconciliation. |
| **`.withValues` on old Flutter** | Compile error on Flutter < 3.27. | Use `.withOpacity(0.58)` there; on current Flutter `.withValues(alpha:)` is the non-deprecated one. |
| **`Opacity` on large/animated subtrees** | Jank, because the subtree is composited to an offscreen layer every frame. | Fine for two tab items; for animation use `AnimatedOpacity` or bake alpha into the colour. |

---
## 1.9 The same idea in other toolkits

The central premise — *a UI is a tree of pure, stateless widgets composed from smaller ones* — is not a Flutter idiosyncrasy. It is the shared model of every modern declarative UI toolkit, so knowing one makes the others readable:

| Flutter | React Native | Jetpack Compose | SwiftUI |
|---|---|---|---|
| `StatelessWidget` + `build` | function component returning JSX | `@Composable fun` | `struct: View { var body }` |
| `Column` / `Row` | `<View>` with flexbox | `Column` / `Row` | `VStack` / `HStack` |
| `SizedBox` (gap) | `<View style={{height}}>` | `Spacer(Modifier.height())` | `Spacer()` / `.frame` |
| `Padding` / `EdgeInsets` | `style={{padding}}` | `Modifier.padding()` | `.padding()` |
| `Container` + `BoxDecoration` | `<View style={{…}}>` | `Box` + `Modifier.background()` | `.background()` / `.overlay()` |
| `LinearGradient` | `expo-linear-gradient` | `Brush.linearGradient` | `LinearGradient` |
| **Frosted glass** (`ClipRRect`+`BackdropFilter`) | `expo-blur` `<BlurView>` | `Modifier.blur()` / `RenderEffect` | `.background(.ultraThinMaterial)` |
| `Text` / `TextStyle` | `<Text style={…}>` | `Text(style=)` | `Text().font()` |
| `AppColors` / `AppText` tokens | a theme/constants module | `MaterialTheme` tokens | an `enum`/`Color` asset set |

The idea that carries across is **composition over configuration**: rather than one enormous "card component with forty props," build a small `GlassCard` and configure it by nesting. Every framework above rewards that same instinct.

---

## 1.10 Running it

On screen, the intended design should render:
- a **blue vertical gradient** filling the whole screen, clear of the notch and home indicator (that is `SafeArea` working);
- the **top bar**: "Weather" pinned left, a glass settings gear pinned right;
- a **frosted `SearchField`** below it (the blur picks up the gradient);
- the **`WeatherCard`** floating in the vertical centre: city + heart, the 96-px weather glyph, the large thin temperature, the description, and two glass `InfoChip`s;
- the **tab bar** at the bottom, Home fully opaque and Saved dimmed to 55%.

---
## 1.11 Quick reference — Widgets

| Widget                                | Job                                                             |
| ------------------------------------- | --------------------------------------------------------------- |
| `MaterialApp`                         | App root: theming, navigation, Material plumbing.               |
| `ThemeData`                           | App-wide style defaults (font here).                            |
| `Scaffold`                            | Material screen frame; only its `body` is used.                 |
| `SafeArea`                            | Keep content clear of notch/home-indicator.                     |
| `Container`                           | Box with decoration/size/padding (the gradient bg + card fill). |
| `BoxDecoration`                       | How a box is painted (gradient/colour/border/radius).           |
| `LinearGradient`                      | The top-to-bottom sky fade.                                     |
| `Padding` / `EdgeInsets`              | Space around content.                                           |
| `Column` / `Row`                      | Vertical / horizontal layout.                                   |
| `SizedBox`                            | Fixed gaps and fixed-size boxes.                                |
| `Spacer`                              | Flexible gap that centres the hero.                             |
| `Center`                              | Centre a child (icon in the glass square).                      |
| `Opacity`                             | Dim the inactive tab.                                           |
| `ClipRRect`                           | Round-corner clip for the glass.                                |
| `BackdropFilter` + `ImageFilter.blur` | The frosted blur.                                               |
| `Border` / `BorderRadius`             | Card outline and rounded corners.                               |
| `Text` / `TextStyle`                  | All on-screen text plus its styling.                            |
| `Icon` / `Icons` / `IconData`         | All glyphs.                                                     |
| `Color` / `Colors` / `withValues`     | The colour tokens.                                              |

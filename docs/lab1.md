# Lab 1: Stateless Widgets
Author: Simone Corbo
---


# 1. The Widget Model

In Flutter you don't draw objects and then change them. You write a description of the UI, and Flutter rebuilds that description whenever something changes. The weather screen in this lab (blue gradient, frosted card, temperature, the two small glass chips) is a single tree of lightweight objects that says what should be on screen, and the framework turns it into pixels. Nothing on this screen changes after it's drawn, which keeps things simple: we can look at each widget on its own before dealing with state and user input.


> A Flutter UI is a tree of widgets. A widget is an immutable object that describes part of the interface. You build the tree by nesting: the screen contains a column, the column contains a card, the card contains some text. You don't modify a widget after creating it; you describe the UI and Flutter handles the updates.

---
## 1.1 The Dart syntax
Some Dart basics first, since they show up everywhere in the code. Dart is a normal object-oriented language, but Flutter relies on a few of its features a lot.
### `void main() => runApp(const WeatherApp());`
- `main()` is the entry point. Every Dart program starts by running `main`.
- `void` is the return type, so `main` returns nothing. In Dart the return type goes before the function name.
- `=>` is the arrow syntax. `=> expr;` is the same as `{ return expr; }`, i.e. a function body made of a single expression. `runApp(...)` returns nothing, so here the arrow just calls it.
- `runApp(Widget)` connects our code to the framework. It takes the root widget, inflates it (goes through the tree and creates what each widget needs internally) and puts it on screen. Whatever widget we pass here is the whole app.
- `const` means `WeatherApp` is a compile-time constant. Its value is known before the program runs, so the compiler creates it once and reuses the same instance. A widget can only be `const` if all its inputs are constant too. This is more important than it seems (see the note on the three trees in 1.3).
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

- `class GlassCard extends StatelessWidget` defines a class that inherits from `StatelessWidget`. It gets all of its behaviour, including the requirement to implement a `build` method, and adds its own fields.
- `final` fields are set once in the constructor and can't be reassigned. Widgets store their inputs in `final` fields because they're supposed to be immutable: a `GlassCard` created with radius 22 stays that way. If you want a different card, you create a new one.
- `Color?`: the `?` makes the type nullable. With Dart's null safety a plain `Color` can never be `null`, only `Color?` can. That's why `fill` (optional) is `Color?` while `child` (required) is a normal `Widget`.
- `const GlassCard({ ... })` is the constructor. The curly braces make the parameters named, so you pass them by name and in any order, e.g. `GlassCard(radius: 14, child: ...)`. With deeply nested widgets this is a lot easier to read, and it's why the whole Flutter API works this way.
- `required this.child`: `required` means the caller has to pass this argument, otherwise it doesn't compile. `this.child` is an initializing formal, a shortcut that assigns the argument directly to the field with the same name, so you don't need a constructor body.
- `this.radius = 22` sets a default value. If `radius` isn't passed, it's 22. This way one widget covers several cases without needing overloads.
- `this.padding = const EdgeInsets.all(20)`: default values must be compile-time constants, hence the `const`.
- `super.key` passes an optional `key` to the `StatelessWidget` parent class. Keys help Flutter tell apart widgets that look the same, for example when a list is reordered. You rarely set one yourself, but forwarding it lets the caller do it if needed.
### `@override` and `build`
```dart
@override
Widget build(BuildContext context) { ... }
```

- `@override` marks a method that replaces one from the parent class. It does nothing at runtime, but the analyzer uses it to catch mistakes: if you write `biuld` instead of `build`, you get a warning because there's no such method to override.
- `build` is the method every widget has to implement (see 1.3).
### Static members and the private `_` constructor

```dart
class AppColors {
  AppColors._();
  static const skyTop = Color(0xFF5AA9F5);
  static final inkSecondary = Colors.white.withValues(alpha: 0.58);
}
```

- `static` members belong to the class, not to an instance. You access them through the class name (`AppColors.skyTop`) without creating an object. This works well for a color palette: a fixed set of global values.
- `AppColors._();` is a private empty constructor. In Dart, a name starting with an underscore is private to its file, so no other code can call `AppColors()`. The class is basically just a namespace for constants.
- `const` vs `final`: `const` means the value is known at compile time, like `Color(0xFF5AA9F5)`. `final` means it's assigned only once but can be computed at runtime. `Colors.white.withValues(...)` has to run a method to get its result, so it can't be `const` and is `final` instead. It's a good habit to use `const` whenever possible, since it helps performance.

### Expressions used inside `build`
- Ternary `cond ? a : b` returns `a` if `cond` is true, otherwise `b`. For example `saved ? Icons.favorite : Icons.favorite_border` picks the heart icon. Since it's an expression, you can put it directly in an argument, which you can't do with an `if` statement.
- Null-coalescing `a ?? b` returns `a` unless it's null, in which case it returns `b`. `fill ?? AppColors.glassFill` uses the default color when no `fill` was passed.
- String interpolation puts values inside a string: `'$temp°'` inserts `temp`, `'$windKmh km/h'` inserts `windKmh`. For anything more than a variable name you need braces: `${expression}`.
- List literal `[ ... ]` creates a `List`. `children: [ ... ]` is a `List<Widget>`, and a `Column` or `Row` shows the children in that order.

### The `switch` in `WeatherIcon`

```dart
IconData glyph = Icons.cloud_rounded;
Color color = AppColors.ink;
switch (condition) {
  case 'Clear':
    glyph = Icons.sunny;
    color = AppColors.sun;
    // no break
  case 'Clouds':
    glyph = Icons.cloud_rounded;
  case 'Rain':
  case 'Drizzle':
    glyph = Icons.water_drop_rounded;
    color = AppColors.ink;
  case 'Thunderstorm':
    glyph = Icons.bolt_rounded;
  case 'Snow':
    glyph = Icons.ac_unit_rounded;
}
return Icon(glyph, size: size, color: color);
```

- The `switch` compares `condition` with each `case` and runs the one that matches.
- Since Dart 3 there's no accidental fall-through: a case with code in it doesn't continue into the next one, and you don't need `break`. `case 'Clear':` runs its two lines and stops, which is what the `// no break` comment in the code is pointing out.
- Empty cases still share the next body: `case 'Rain':` followed directly by `case 'Drizzle':` means both run the same code. This is how you map multiple values to the same result.
- `glyph` and `color` are initialized to cloud/white (`Icons.cloud_rounded`, `AppColors.ink`) before the switch. If `condition` doesn't match any case, those values stay as they are, so there's no need for a `default:`.

---
## 1.2 How the app starts
### `runApp(const WeatherApp())`
As mentioned above, it passes the root widget to the framework. Everything on screen comes from this call, so the tree has one single root.
### `MaterialApp`

The usual root widget for a Material Design app. It sets up a lot of shared stuff above our screens: a `Navigator` (the stack used to move between screens), theming, text direction, a `MediaQuery` with the screen size and insets, localization, and the `Overlay` used by dialogs and tooltips. We don't use most of it directly, but almost every widget depends on some part of it.

```dart
MaterialApp(
  title: 'Weather',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
  home: const HomeScreen(),
)
```

Parameters used here:

| Parameter | Type | What it does |
|---|---|---|
| `home` | `Widget` | The first screen shown. Here it's `HomeScreen`. |
| `theme` | `ThemeData` | The app-wide theme (colors, fonts, component defaults). See below. |
| `title` | `String` | A short name used by the OS (e.g. in the Android recent apps list). It isn't shown in the app. |
| `debugShowCheckedModeBanner` | `bool` | The red "DEBUG" banner in the corner in debug builds. Set to `false` so the screen looks like the design. |

Other parameters (not used here):

| Parameter | When you'd use it |
|---|---|
| `routes` / `initialRoute` / `onGenerateRoute` | Navigation, once there's more than one screen. |
| `darkTheme` / `themeMode` | Adding a dark theme and choosing light/dark/system. |
| `locale` / `localizationsDelegates` / `supportedLocales` | Translations. |
| `navigatorKey` / `navigatorObservers` | Navigating from code, analytics. |
| `builder` | Wrapping every screen in a common widget (e.g. a global banner). |

> There's also `MaterialApp.router(...)`, used with routing packages like go_router. Not needed here.

### `ThemeData`
A set of style defaults that widgets further down the tree use automatically. This works through inherited widgets: `MaterialApp` puts the theme near the top of the tree, and any widget below can get it with `Theme.of(context)`. This is easier than passing colors and fonts through every constructor.

| Parameter (used here) | What it does |
|---|---|
| `fontFamily` | Default font for all `Text` widgets. Set to `'Inter'`; if the font isn't added as an asset, Flutter just uses the system font. |
| `useMaterial3` | Enables Material 3 styling. Material 3 is already the default in recent Flutter versions, so this line isn't needed anymore and may show as deprecated. It's kept in the code only to make it explicit. |

Other common `ThemeData` parameters: `colorScheme` (usually `ColorScheme.fromSeed(seedColor: ...)`), `scaffoldBackgroundColor`, `textTheme`, and component themes like `appBarTheme`. In this app the colors are set directly in the widgets through `AppColors`, because the design is very specific and needs exact values instead of the theme defaults.

---
## 1.3 The widget model

### `StatelessWidget`

A widget whose look depends only on the inputs it gets in the constructor. Same inputs, same UI, always. It has no internal data that can change. Every widget on this screen is stateless, which is why the screen is static. Widgets that need to change over time extend `StatefulWidget` instead, which adds mutable state and a lifecycle. That's for a later lab, when the screen needs to react to input.
### `Widget build(BuildContext context)`

The method every widget implements. Flutter calls it to ask "given your inputs, what should the UI look like?", and you return a tree of other widgets. You never call `build` yourself: Flutter calls it when the widget is first shown and again whenever it needs to be rebuilt.
- The return type is `Widget`, so `build` returns more widgets. A screen is widgets inside widgets, down to basic ones like `Text` and `Icon`.
- `BuildContext context` represents the widget's position in the tree. It's actually the widget's `Element` (see the note below), and you use it to find things higher up in the tree, like the theme, the navigator or the screen size. On a static screen it's barely used, but it becomes important once widgets need shared state or navigation.

> [!note] What's behind `build`: the three trees
> Flutter actually keeps three trees:
> 1. The widget tree is what we write: cheap, immutable descriptions. Flutter creates and throws them away all the time, and every rebuild makes a new widget tree.
> 2. The element tree is what Flutter uses to keep track of things. Each element points to its current widget and stays alive between rebuilds. On a rebuild, Flutter compares the new widgets with the existing elements, and if the type and key match it just updates the element instead of recreating it. `BuildContext` is an element.
> 3. The render tree contains the `RenderObject`s that do the actual layout and painting.
>
> Rebuilds are cheap because only the widget tree is recreated, while elements and render objects are reused when possible. This is also why `const` widgets help: a `const` subtree that hasn't changed is skipped completely.
### `Icons` and `IconData`
- `IconData` describes a single icon: a code point in a font, plus which font.
- `Icons` is a class with lots of predefined `IconData` constants from the Material icon font, like `Icons.search`, `Icons.favorite` or `Icons.settings_rounded`. Many icons have style variants: plain (`Icons.cloud`), `_rounded`, `_outlined`, `_sharp`. The code mostly uses the rounded ones to fit the soft glass look.

---
## 1.4 Layout widgets
Flutter layout follows one rule: constraints go down, sizes go up, the parent sets the position. The parent gives each child a constraint (min/max width and height), the child picks its size within that and reports it back, and then the parent decides where to place it. Most layout problems, like the "unbounded height" error or a widget that's too big or too small, come from this going wrong somewhere.

### `Scaffold`
The basic Material screen structure, with optional slots for an app bar, body, floating action button, drawers and bottom navigation. Here only `body` is used. The top bar and tab bar are built by hand because the design needs custom styling that the standard `AppBar` and `BottomNavigationBar` don't support. `Scaffold` is still useful because it handles full-screen sizing.

| Parameter (used here) | What it does |
|---|---|
| `body` | The main content. Contains the gradient background and everything else. |

Other slots: `appBar`, `bottomNavigationBar`, `floatingActionButton`, `drawer`, `backgroundColor`, `resizeToAvoidBottomInset`.
### `SafeArea`
Adds padding so the content doesn't end up under the notch or Dynamic Island at the top, or the home indicator at the bottom. It reads the insets from `MediaQuery` and pads by that amount. Without it the title could end up under the notch.

| Parameter | What it does |
|---|---|
| `child` | The content to pad. |
| `top` / `bottom` / `left` / `right` (`bool`) | Enable/disable padding for each side (all `true` by default). |
| `minimum` (`EdgeInsets`) | Minimum padding, even where the system reports none. |
### `Container`
A general box widget. It combines several simpler widgets: it can paint a background or decoration, add padding and margin, set its size, and hold one child. Here it's used for the full-screen gradient.

| Parameter (used here) | What it does |
|---|---|
| `decoration` | A `BoxDecoration` that paints the gradient (see 1.5). |
| `width` / `height` | Set to `double.infinity` so the box fills all available space and the gradient covers the whole screen. |
| `padding` | Space between the edge of the box and its child (used in `GlassCard`). |
| `child` | The widget inside. |

> `Container` has both a `color` and a `decoration` parameter, but you can't set both, since `BoxDecoration` already has a `color`. If you need a background color plus a border or radius, put the color inside the decoration (`BoxDecoration(color: ...)`), like `GlassCard` does.

Other `Container` parameters: `margin`, `alignment`, `constraints`, `transform`.
### `Padding` and `EdgeInsets`
- `Padding` adds empty space around its child. Here it's used for the horizontal margin of the screen.
- `EdgeInsets` says how much space and on which sides:

| `EdgeInsets` form | Meaning |
|---|---|
| `EdgeInsets.all(20)` | 20 on every side (default padding of `GlassCard`). |
| `EdgeInsets.symmetric(horizontal: 20)` | Left and right only (screen margin). |
| `EdgeInsets.symmetric(horizontal: 13, vertical: 9)` | Different horizontal and vertical values (`InfoChip`). |
| `EdgeInsets.only(left: 8)` | Just one side. |
| `EdgeInsets.fromLTRB(l, t, r, b)` | All four sides set separately. |
| `EdgeInsets.zero` | No padding (so `GlassIconButton` can center its icon in a fixed 34×34 box). |

### `Column` and `Row`
`Column` places its children vertically, `Row` horizontally. The important thing is the difference between main axis and cross axis:
- In a Column the main axis is vertical and the cross axis is horizontal.
- In a Row the main axis is horizontal and the cross axis is vertical.

The alignment parameters refer to these axes, so they have the same names in both:

| Parameter | What it controls | Values |
|---|---|---|
| `children` | The widgets to lay out, in order. | a `List<Widget>` |
| `mainAxisAlignment` | Position/spacing along the main axis. | `start`, `end`, `center`, `spaceBetween`, `spaceAround`, `spaceEvenly` |
| `crossAxisAlignment` | Alignment on the cross axis. | `start`, `center`, `end`, `stretch`, `baseline` |
| `mainAxisSize` | How much space the Row/Column takes on the main axis. | `max` (default, takes all available space) or `min` (only as much as the children need) |

Where they're used in this screen:
- The top bar uses `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` to put the title on the left and the gear on the right.
- `BottomTabBar` uses `MainAxisAlignment.center` to center the two tabs, with a `SizedBox(width: 48)` between them.
- The `InfoChip` rows and the city + heart row use `mainAxisSize: MainAxisSize.min` so they only take the space they need.
- The `Column` inside `InfoChip` doesn't set `crossAxisAlignment`, so it uses the default `center` and the value and label are centered on each other. `CrossAxisAlignment.start` would align them on the left instead.

> Common mistake: a `Row` inside a centered `Column` with the default `mainAxisSize: MainAxisSize.max` takes the full width, so two chips that should be next to each other end up on opposite sides. Setting `mainAxisSize: MainAxisSize.min` fixes it. It's the constraints rule again: `max` takes the biggest size allowed, `min` only what the children need.

### `SizedBox`
A box with a fixed size. In this code it has two jobs:

1. As a spacer: `SizedBox(width: 8)` or `SizedBox(height: 12)` adds a fixed gap between items in a Row or Column. It's simpler than wrapping everything in padding, and it matches the "gap 8", "gap 12" values in the design.
2. To force a size: `SizedBox(width: 34, height: 34, child: ...)` makes the glass icon button exactly 34×34 no matter what's inside.

| Parameter | What it does |
|---|---|
| `width` / `height` | Exact size (you can set only one of them). |
| `child` | Optional widget inside. |

### `Spacer`
A flexible gap that takes all the remaining space on the main axis and pushes the other children apart. In `HomeScreen` there's a `Spacer()` above and below the `WeatherCard`, so the card sits in the middle vertically, the search bar stays near the top and the tab bar at the bottom.

| Parameter | What it does |
|---|---|
| `flex` | How the free space is split when there are several `Spacer`s (default `1`; two spacers with the same flex split it in half, which centers the card). |

> `Spacer` only works if there's a known amount of free space. In a `Column` with a fixed height (here, the height of the safe area) that's fine. In a scrolling or unbounded layout the main axis is basically infinite, so there's no leftover space to calculate and Flutter throws an error.

### `Center`
Centers its child in the available space. Used in `GlassIconButton` to put the icon in the middle of the 34×34 box.

| Parameter | What it does |
|---|---|
| `child` | The widget to center. |
| `widthFactor` / `heightFactor` | Make `Center` a multiple of the child's size instead of filling the space. |

(`Center` is the same as `Align(alignment: Alignment.center)`.)
### `Opacity`
Makes its child partly transparent. `_TabItem` wraps its content in `Opacity(opacity: active ? 1.0 : 0.55, ...)`, so the inactive tab is at 55% and the active one is fully visible.

| Parameter | What it does |
|---|---|
| `opacity` | From `0.0` (invisible) to `1.0` (fully visible). |
| `child` | The widget to fade. |

> `Opacity` is a bit expensive: Flutter has to draw the whole subtree to an offscreen layer and then fade the layer. For two small tabs it doesn't matter, but for big or animated subtrees it's better to use `AnimatedOpacity` or put the alpha directly in the colors.

---
## 1.5 Painting and decoration
### `Color`, `Colors`, and `.withValues`
- `Color(0xFF5AA9F5)` is a color written as a 32-bit hex number in `0xAARRGGBB` format: `FF` alpha (fully opaque), `5A` red, `A9` green, `F5` blue. That's why all the solid colors start with `0xFF`.
- `Colors` is a set of named colors (`Colors.white`, `Colors.black`, `Colors.blue`, etc.).
- `.withValues(alpha: 0.58)` returns a copy of the color with a different alpha (0.0 to 1.0). This is how the "white at 58%" colors are made from `Colors.white`. Since it creates a new value at runtime, it's `final` and not `const`. On Flutter versions before 3.27 this method doesn't exist and you use `.withOpacity(0.58)` instead; on newer versions `withOpacity` is deprecated.
### `BoxDecoration`
Describes how to paint a box, passed to `Container`'s `decoration`. It's painted behind the child.

| Parameter (used here) | What it does |
|---|---|
| `gradient` | A gradient fill (used for the background). |
| `color` | A solid fill (used in `GlassCard`). |
| `border` | An outline (see `Border.all`). |
| `borderRadius` | Rounded corners. |

Other `BoxDecoration` parameters: `boxShadow`, `image`, `shape`. With `shape: BoxShape.circle` you can't also set `borderRadius`.
### `LinearGradient`
A gradient along a straight line. The sky goes from top to bottom through three colors. It's defined once in `design_tokens.dart` as a top-level constant, `skyGradient`, and used in `HomeScreen` as `const BoxDecoration(gradient: skyGradient)`. Since all its values are constants, the whole decoration can be `const`.

| Parameter | What it does |
|---|---|
| `colors` | The colors to blend (`[skyTop, skyMid, skyBottom]`). Required. |
| `begin` / `end` | Start and end of the line. `Alignment.topCenter` to `Alignment.bottomCenter` makes it vertical. |
| `stops` | Where each color is placed along the line (0.0 to 1.0). `[0.0, 0.52, 1.0]` puts the middle color at 52%. Must have the same length as `colors`. |

Other parameters: `tileMode`, `transform`. `Alignment` values include `topLeft`, `topCenter`, `centerLeft`, `center`, `bottomRight`, etc.
### `Border` and `BorderRadius`
- `Border.all(color: AppColors.glassStroke)` draws a 1 px outline on all sides (you can also pass `width:` and `style:`). For different sides, use `Border(top: ..., bottom: ...)` with `BorderSide`s.
- `BorderRadius.circular(22)` rounds all four corners with the same radius. Other options: `BorderRadius.all(Radius.circular(x))`, `.only(topLeft: ...)`, `.vertical(...)`, `.horizontal(...)`.
### `ClipRRect`
Clips its child to a rounded rectangle, so anything drawn outside the rounded shape is hidden. In `GlassCard` it's the outer widget, so both the blur and the fill get the same rounded shape. Without it the blur would show as a square past the corners.

| Parameter | What it does |
|---|---|
| `borderRadius` | The corner radius (same as the card's). |
| `child` | What gets clipped. |
| `clipBehavior` | Anti-aliasing of the clip edge (default is fine). |

### `BackdropFilter` and `ImageFilter.blur`
This is what gives the frosted glass effect. How it works also decides the order of the widgets.
- `BackdropFilter` applies a filter to what's already drawn behind it, not to its own child. So it only works if there's something underneath, in this case the gradient. That's why it has to be above the gradient in the tree and wrapped in `ClipRRect`, so the blur stays inside the card's rounded shape.
- `ImageFilter.blur(sigmaX: 14, sigmaY: 14)` is the filter: a Gaussian blur of 14 on each axis.

| `BackdropFilter` parameter | What it does |
|---|---|
| `filter` | The `ImageFilter` applied to the background (required). |
| `child` | Drawn on top of the blurred background; here it's the translucent `Container`. |
| `blendMode` | How the result is blended (default is fine). |

| `ImageFilter.blur` parameter | What it does |
|---|---|
| `sigmaX` / `sigmaY` | Blur strength on each axis. |
| `tileMode` | How edges are handled (default is fine). |

> Structure of `GlassCard`, from outside to inside: `ClipRRect` (rounded mask) → `BackdropFilter` (blur what's behind) → `Container` (translucent fill and border, holds the child). The order matters, each layer depends on the one around it.

---
## 1.6 Content widgets
### `Text`
Shows a string.

| Parameter (used here) | What it does |
|---|---|
| `data` (first positional argument) | The string, e.g. `'Weather'`, `'$temp°'`. |
| `style` | A `TextStyle` (see below), taken from `AppText`. |

Other useful parameters: `textAlign`, `maxLines`, `overflow` (e.g. `TextOverflow.ellipsis`), `softWrap`, `textScaler`.
### `TextStyle`
Describes how the text looks.

| Parameter (used here) | What it does |
|---|---|
| `fontSize` | Size in logical pixels (same as points on iOS). |
| `fontWeight` | From `FontWeight.w100` to `w900` (`.normal` = w400, `.bold` = w700). The big temperature is `w200` (very thin), titles are `w600` (semi-bold). |
| `color` | Text color, from `AppColors`. |
| `height` | Line height as a multiple of `fontSize`. With `height: 1` the line is exactly as tall as the font, so the big temperature number doesn't get extra space above and below. |

Other parameters: `letterSpacing` (slightly positive for section labels), `fontStyle` (italic), `decoration` (underline/strikethrough), `shadows`, `fontFamily`.
### `Icon`
Shows one icon.

| Parameter (used here) | What it does |
|---|---|
| the `IconData` (first positional argument) | Which icon, e.g. `Icons.search`, `Icons.favorite`. |
| `size` | Size in logical pixels (96 for the big weather icon, 18 for the heart, etc.). |
| `color` | Icon color: `AppColors.sun` when the sky is clear, white otherwise. |

Also useful: `semanticLabel` (description read by screen readers).

---

## 1.7 Design choices
- `AppColors` / `AppText` (in `design_tokens.dart`): keeping colors and text styles in one place means all widgets use the same values. They're `static` members of a class that can't be instantiated, so they work like global constants.
- `GlassCard` with optional `radius` / `padding` / `fill`: one reusable glass container. A small chip (radius 14, lighter fill) and the big card (radius 22, stronger fill) are the same widget with different arguments, instead of writing a separate container each time.
- `WeatherIcon` takes a `condition` string: the mapping from condition to icon and color is in one place, so every screen shows the weather the same way. Later, the condition string from the API can be passed in directly without changing the widget.
- `InfoChip` / `WeatherCard` take plain data (`int temp`, `String description`): data comes in through the constructor and the widget shows it. The data is hardcoded for now, but the widgets won't need to change when it comes from an API; only the source of the data will.
- `SearchField` / `BottomTabBar` are only visual for now (`BottomTabBar` already takes an `activeIndex`, default `0`, to choose which tab is highlighted). This lab is about the look, not the behaviour. Adding interaction later just means wiring them up, without redesigning them.
- Custom top bar and tab bar instead of `AppBar` / `BottomNavigationBar`: the design uses glass styling that the standard Material widgets don't have, so they're built from `Row`, `GlassCard`, `Icon` and `Text`.
- `Spacer` above and below `WeatherCard`: this centers the card vertically while the search field stays at the top and the tab bar at the bottom, and it works on any screen height without hardcoded offsets.
---
## 1.8 Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| `Container` with both `color` and `decoration` | Runtime error: "Cannot provide both a color and a decoration." | Put the color inside `BoxDecoration(color: …)`. That's why `GlassCard` never sets `Container.color`. |
| `Row`/`Column` without `mainAxisSize.min` | A `Row` in a centered `Column` takes the full width and pushes its children to the edges (the two chips separate). | Add `mainAxisSize: MainAxisSize.min`. The default is `max`. |
| `Spacer` in an unbounded axis | "RenderFlex children have non-zero flex but incoming height constraints are unbounded." | `Spacer` needs a fixed main-axis size (the `Column` inside `SafeArea` is fine, a scrolling one isn't). |
| `BackdropFilter` with nothing behind it | The glass looks like a flat translucent box with no blur. | The filter blurs what's behind it, so the gradient has to be underneath. |
| `BackdropFilter` not clipped | The blur goes past the rounded corners as a rectangle. | Wrap it in `ClipRRect` like `GlassCard` does. |
| Forgetting `const` | Widgets get rebuilt more than needed. | Use `const` wherever the inputs are constant; `const` subtrees are skipped on rebuild. |
| `.withValues` on old Flutter | Compile error on Flutter < 3.27. | Use `.withOpacity(0.58)` there; on current Flutter `.withValues(alpha:)` is the one to use. |
| `Opacity` on large or animated subtrees | Lag, because the subtree is drawn to an offscreen layer every frame. | Fine for two tabs; for animations use `AnimatedOpacity` or put the alpha in the color. |

---
## 1.9 Comparison with other frameworks

Building the UI as a tree of small stateless components isn't specific to Flutter. The other declarative UI frameworks work the same way, so the concepts mostly map one to one:

| Flutter | React Native | Jetpack Compose | SwiftUI |
|---|---|---|---|
| `StatelessWidget` + `build` | function component returning JSX | `@Composable fun` | `struct: View { var body }` |
| `Column` / `Row` | `<View>` with flexbox | `Column` / `Row` | `VStack` / `HStack` |
| `SizedBox` (gap) | `<View style={{height}}>` | `Spacer(Modifier.height())` | `Spacer()` / `.frame` |
| `Padding` / `EdgeInsets` | `style={{padding}}` | `Modifier.padding()` | `.padding()` |
| `Container` + `BoxDecoration` | `<View style={{…}}>` | `Box` + `Modifier.background()` | `.background()` / `.overlay()` |
| `LinearGradient` | `expo-linear-gradient` | `Brush.linearGradient` | `LinearGradient` |
| Frosted glass (`ClipRRect`+`BackdropFilter`) | `expo-blur` `<BlurView>` | `Modifier.blur()` / `RenderEffect` | `.background(.ultraThinMaterial)` |
| `Text` / `TextStyle` | `<Text style={…}>` | `Text(style=)` | `Text().font()` |
| `AppColors` / `AppText` tokens | a theme/constants module | `MaterialTheme` tokens | an `enum`/`Color` asset set |

In all of them it's better to build small components and combine them (like `GlassCard`) than to make one big component with a lot of parameters.

---

## 1.10 Running it

The screen should show:
- a blue vertical gradient covering the whole screen, with content kept away from the notch and home indicator (`SafeArea`);
- the top bar with "Weather" on the left and a glass settings button on the right;
- a frosted `SearchField` below it (the blur shows the gradient behind);
- the `WeatherCard` in the vertical center with the hardcoded data: "London" with a filled yellow heart (`saved: true`), the 96 px water drop icon (condition `'Rain'`), "12°" in thin 38 px text, "Light rain", and two glass `InfoChip`s showing "80%" humidity and "15 km/h" wind;
- the tab bar at the bottom, with Home fully visible and Saved dimmed to 55%.

---
## 1.11 Quick reference: widgets

| Widget                                | Job                                                             |
| ------------------------------------- | --------------------------------------------------------------- |
| `MaterialApp`                         | App root: theme, navigation, Material setup.                    |
| `ThemeData`                           | App-wide style defaults (here just the font).                   |
| `Scaffold`                            | Material screen structure; only `body` is used.                 |
| `SafeArea`                            | Keeps content away from the notch/home indicator.               |
| `Container`                           | Box with decoration/size/padding (background + card fill).      |
| `BoxDecoration`                       | How a box is painted (gradient/color/border/radius).            |
| `LinearGradient`                      | The top-to-bottom sky gradient.                                 |
| `Padding` / `EdgeInsets`              | Space around content.                                           |
| `Column` / `Row`                      | Vertical / horizontal layout.                                   |
| `SizedBox`                            | Fixed gaps and fixed-size boxes.                                |
| `Spacer`                              | Flexible gap that centers the card.                             |
| `Center`                              | Centers a child (icon in the glass button).                     |
| `Opacity`                             | Dims the inactive tab.                                          |
| `ClipRRect`                           | Rounded clip for the glass.                                     |
| `BackdropFilter` + `ImageFilter.blur` | The frosted blur.                                               |
| `Border` / `BorderRadius`             | Card outline and rounded corners.                               |
| `Text` / `TextStyle`                  | All text and its style.                                         |
| `Icon` / `Icons` / `IconData`         | All icons.                                                      |
| `Color` / `Colors` / `withValues`     | The colors.                                                     |

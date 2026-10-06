# Lab 2: Stateful Widgets
Author: Simone Corbo
---


# 2. State, Screens and Tabs

In Lab 1 the screen was static: same inputs, same pixels, every time. A real app doesn't work like that. The user taps the heart, picks a city on another screen, moves between tabs. All of these are data that changes while the app is running, and a `StatelessWidget` has nowhere to keep it, because it only knows the values it got in its constructor.

In this lab we start from the Lab 1 code and change as little as possible:
- `HomeScreen` becomes a `StatefulWidget` that remembers the selected tab, the city and the saved cities;
- the heart, the search box and the tabs react to taps;
- two new screens: a city picker that gives back the chosen city, and a detail screen for a saved city.

At the end we compare our hand-made tab bar with the two navigation widgets Flutter gives us ready-made: `NavigationBar` and `NavigationDrawer`.

The weather values are still a fixed sample: real data comes in the next lab.


> A widget that remembers something becomes a `StatefulWidget`, paired with a `State` object that lives as long as the widget is on screen. `setState` tells Flutter "the data changed, rebuild me". `Navigator` keeps the screens in a stack and can bring a value back when a screen closes, and a tab is just a number in the state.

---
## 2.1 Stateful widgets

### What is state?

State is any data that can change while the app runs and that changes what the user sees: the text the user is typing, data that arrives from a server, the choices the user made (which cities are saved), small UI details (which tab is selected). Something that never changes, like our colors, is not state: it's a constant.

| Data | State? | Why |
|---|---|---|
| The selected tab | Yes | Changes when a tab is tapped |
| The saved cities | Yes | Change when the heart is tapped |
| The city on Home | Yes | Changes when the user picks one |
| The weather values | No | A fixed sample until the next lab |
| The list of known cities | No | Fixed in the code |
| The sky gradient colors | No | A constant in `design_tokens.dart` |

> [!note] UI = f(state)
> In Flutter you never grab a widget on screen and change it: widgets are immutable. You change the state, and Flutter calls `build` again, which describes the new UI from the new data. The UI is a function of the state. Everything else in this lab is about where to keep the state and how to tell Flutter it changed.

### `StatelessWidget` vs `StatefulWidget`

A `StatelessWidget` is completely described by its constructor arguments. Its fields are `final`, and the only way to show something different is for the parent to create a new widget with different arguments.

A `StatefulWidget` is for the cases where the widget itself has to remember something that changes over time. It's made of two classes that work together:

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;                         // 0 = Home, 1 = Saved
  String _city = 'London';              // the city shown on Home
  final Set<String> _savedCities = {};  // the cities with the heart

  @override
  Widget build(BuildContext context) { ... }
}
```

- `HomeScreen` is the widget. It's still immutable (it even has a `const` constructor), exactly like a stateless widget. Its only job is to create the state object through `createState`.
- `_HomeScreenState` is the state. It extends `State<HomeScreen>`, holds the fields that change, and contains the `build` method that was in `HomeScreen` in Lab 1.
- The state class starts with `_`, so it's private to the file. Only Flutter creates it, by calling `createState`.

Tip: in VS Code or Android Studio, put the cursor on a `StatelessWidget`, open the quick actions and choose **Convert to StatefulWidget**. It writes the two classes for you.

> [!note] Why two classes?
> Remember the three trees from Lab 1: widgets are cheap descriptions that Flutter throws away and recreates on every rebuild, while elements stay alive between rebuilds. If the changing data were stored in a widget, it would be lost every time the widget is recreated. So Flutter attaches the `State` object to the element instead. Every `setState` creates new widgets (a new `WeatherCard`, a new `BottomTabBar`...), but `_HomeScreenState` and its fields stay the same.

### What must be overridden

| Class | Method | Required? | What it does |
|---|---|---|---|
| `StatefulWidget` | `createState()` | Yes | Creates the `State` object. |
| `State` | `build(BuildContext)` | Yes | Returns the UI, like in a stateless widget. Called many times. |
| `State` | `initState()` | No | One-time setup when the state is created. |
| `State` | `dispose()` | No | Cleanup when the state is removed for good. |
| `State` | `didUpdateWidget(oldWidget)` | No | The parent rebuilt and gave this state a new widget with different arguments. |
| `State` | `didChangeDependencies()` | No | An inherited widget it depends on (e.g. `Theme`) changed. |

`setState` is not overridden: it's a method of `State` that we call.

### The lifecycle

1. `createState()` is called on the widget, and the `State` object is created.
2. `initState()` runs once.
3. `build()` runs and the widget is drawn.
4. While the widget is on screen, `build()` runs again every time `setState` is called or the parent rebuilds.
5. When the widget is removed for good: `dispose()`. After that the state can't be used anymore.

`initState` is the place for one-time setup, `dispose` for cleaning up what you created there: controllers, timers, subscriptions. Always call `super.initState()` first and `super.dispose()` last. Today's app doesn't need them yet: they come back with text fields and network calls.

Since `build` can run very often (during an animation, at every frame), keep it cheap: read the state, return widgets, do small calculations. Don't start requests or timers, don't create controllers and don't call `setState` inside it.

### Hot reload and hot restart

| | What happens | When to use it |
|---|---|---|
| Hot reload (`r`, or save) | `build` runs again with the new code. The `State` is kept: fields keep their current values, `initState` doesn't run again. | Most changes to the UI. |
| Hot restart (`R`) | The app starts again from `main`. All the state is lost. | After changing `initState` or a field's starting value. |
| Stop and run | A full rebuild of the app. | After adding a package or changing native files. |

If you change the starting value of `_city` and nothing happens after saving, it's not a bug: hot reload kept the old `State`.

### `setState()`

```dart
void _toggleSaved(String city) {
  setState(() {
    if (!_savedCities.add(city)) {
      // add() returns false if it was already present -> it's a "remove".
      _savedCities.remove(city);
    }
  });
}
```

- `setState` takes a function. Flutter runs it immediately, then marks the element as dirty, which means "needs to be rebuilt". On the next frame `build` runs again with the new values.
- It's `setState` that causes the rebuild, not the change itself. If you change `_savedCities` without `setState`, the set changes but nothing tells Flutter, so the heart doesn't change.
- Keep only the changes to the state inside the function, and never call `setState` inside `build`.

`_savedCities` is `final` but its content changes. `final` only means the variable always points to the same `Set`; adding or removing elements is still allowed.

### A tap, step by step

What happens when the heart is tapped:

1. **Tap**: the `GestureDetector` in `WeatherCard` calls `onToggleSave`.
2. **Callback**: `() => _toggleSaved(_city)` runs in `_HomeScreenState`.
3. **setState**: the set changes, the element is marked dirty.
4. **Next frame**: `_HomeScreenState.build` runs again.
5. **New widgets**: a new `WeatherCard` with `saved: true`.
6. **Screen**: the heart fills. The Saved tab, built from the same set, will list the city.

Nobody changed a widget: the data changed in one place, and the UI was described again.

### Lifting state up

Take the heart. The saved cities live in `HomeScreen`, which is stateful: it owns the data and it's the only one that changes it. `WeatherCard` draws the heart, and it's stateless.

```dart
// in HomeScreen's build
WeatherCard(
  ...
  saved: _savedCities.contains(_city),       // data down
  onToggleSave: () => _toggleSaved(_city),   // event up
)
```

- **Data goes down**: `HomeScreen` passes `saved` in the constructor, and the card draws a filled or an empty heart.
- **Events go up**: when the heart is tapped, the card calls `onToggleSave`, the function `HomeScreen` gave it. The card never changes the data; it only says "I was tapped". `HomeScreen` decides, and calls `setState`.

This pattern is called lifting state up. The saved cities can't live inside the card, because the Saved tab needs them too. Rule of thumb:
- data that never changes isn't state, it's a constant;
- data used by one widget only stays in that widget's `State`;
- data used by several widgets goes up to their lowest common parent, here `HomeScreen`.

The tab bar works the same way: `activeIndex` goes down, `onTap(index)` comes up. The search box only sends an event up: `onTap`.

---
## 2.2 New Dart syntax

### `Set<String>`

A `Set` is a collection without duplicates and without order. It fits the saved cities well: a city is either saved or not. `.add` returns `false` if the value was already there; `.remove` and `.contains` do what they say.

### Callbacks

```dart
onToggleSave: () => _toggleSaved(_city),
onTap: (index) => setState(() => _tab = index),
SearchField(onTap: _pickCity),
```

- In Dart a function is a value: you can pass it to a widget, and the widget calls it later. That's a callback.
- `() => ...` is a function without a name, written inline. `(index) => ...` is one that takes an argument.
- `_pickCity` without parentheses passes the method itself. With parentheses, `_pickCity()`, you'd call it now and pass its result.
- Types: `VoidCallback` is `void Function()`; `ValueChanged<int>` is `void Function(int)`.
- Required or optional: `SearchField` and the tab bar always need their callback (`required this.onTap`). The heart's callback is optional, `VoidCallback? onToggleSave`, because the detail screen shows a `WeatherCard` without a working heart: `GestureDetector` simply ignores taps when `onTap` is `null`.

### `for` inside a list

```dart
ListView(
  children: [
    for (final city in _savedCities)
      ListTile(
        title: Text(city, style: AppText.cityName),
        onTap: () => _openCity(city),
      ),
  ],
)
```

A `for` inside a list literal adds one element per item: one `ListTile` per saved city.

### The ternary `? :`

```dart
child: _tab == 0 ? Center(...) : ListView(...),
```

The same ternary operator from Lab 1 (`saved ? Icons.favorite : Icons.favorite_border`), here choosing between two widgets: if the tab is 0 the first, otherwise the second.

---
## 2.3 Navigation

### The `Navigator` stack

In Flutter each screen is a route, and the `Navigator` (created by `MaterialApp`) keeps them in a stack:
- `push` puts a new screen on top. It slides in and covers the one below.
- `pop` removes the top screen, and the one below is visible again.

The screens below are not destroyed: their `State` stays alive while they're covered. That's why `HomeScreen` still has its city and its saved cities when you come back.

```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => CityDetailScreen(city: city)),
);
...
Navigator.of(context).pop();
```

| Piece | What it does |
|---|---|
| `Navigator.of(context)` | Finds the nearest `Navigator` going up the tree. Same `X.of(context)` pattern as `Theme.of(context)`. |
| `MaterialPageRoute` | A route with the platform's transition and back gesture. |
| `builder` | A function that creates the new screen. |
| `pop()` | Closes the current screen. The system back button and the iOS swipe do the same. |

### The new screens

Each pushed screen covers the whole screen, so it has its own `Scaffold`. For the background, one line: `backgroundColor: AppColors.skyMid`.

Instead of building a top bar by hand, the new screens use an `AppBar`:

```dart
appBar: AppBar(
  title: const Text('Choose a city'),
  backgroundColor: AppColors.skyMid,
  foregroundColor: AppColors.ink, // white title and arrow
),
```

When a screen was pushed, the `AppBar` adds a back arrow by itself, and tapping it calls `pop()`.

---
## 2.4 Data in and out of a screen

### Data in: the constructor

A screen is a widget, so data goes in the constructor:

```dart
void _openCity(String city) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => CityDetailScreen(city: city)),
  );
}
```

`CityDetailScreen` has nothing that changes, so it's stateless and reads `city` like any field. (If it were stateful, the state would read it as `widget.city`.)

### Data out: `pop(value)`

`pop` can take a value, and that value is what `push` gives back to the screen that opened it:

```dart
// HomeScreen
Future<void> _pickCity() async {
  final city = await Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (context) => const CityPickerScreen()),
  );
  if (city == null || city.isEmpty) return; // back without choosing, or empty text
  setState(() => _city = city);
}

// CityPickerScreen, on each row
onTap: () => Navigator.of(context).pop(city),

// CityPickerScreen, in the text box (2.5)
onSubmitted: (text) => Navigator.of(context).pop(text),
```

- `await` means "wait here until the picker is closed". The method that uses it must be marked `async` (and returns a `Future<void>`). How this works is the topic of the next lab: for now, `await push(...)` reads as "open the screen and wait for its answer".
- `push<String>` says the result is a `String`. The actual type is `String?`: if the user goes back with the arrow or the system gesture, `pop` is called without a value and the result is `null`. Always handle it. `city.isEmpty` covers the other case: enter pressed on an empty text box.
- The picker doesn't know who opened it or what will happen with the value. It only says "the user chose this", and the caller decides: the same idea as callbacks, for screens.

---
## 2.5 Lists and taps

### `ListView`

`ListView` is a scrolling column: use it when the content can be taller than the screen. A `Column` is exactly as tall as its children and never scrolls: if they don't fit, you get the yellow and black overflow stripes. The `ListView`'s `children` are built with a `for` inside the list (2.2). For long lists, `ListView.builder` creates only the rows that are visible.

- In the picker the `ListView` is in a `Column`, above the text box: it's wrapped in `Expanded`, so it takes the space left and the text box stays at the bottom.
- In the Saved tab it's inside the `Column`, between the search box and the tab bar. Without `Expanded` it wouldn't know how tall to be, and Flutter would throw an error about unbounded height. The `Expanded` of the tabs gives it exactly the space left.

Each city is a `ListTile`: a ready-made Material row with a `title` and an `onTap`. No need to build our own row widget.

### `TextField`

At the bottom of the picker, a text box lets the user type a city that isn't in the list:

```dart
Padding(
  padding: const EdgeInsets.all(20),
  child: TextField(
    style: AppText.cityName,
    decoration: InputDecoration(
      hintText: 'Or type a city',
      hintStyle: AppText.searchHint,
    ),
    onSubmitted: (text) => Navigator.of(context).pop(text),
  ),
)
```

| Parameter (used here) | What it does |
|---|---|
| `onSubmitted` | Called with the text when the user presses enter on the keyboard. |
| `decoration` | An `InputDecoration`: here only the hint shown when the field is empty. |
| `style` | The style of the typed text (white, like the city names). |

- `TextField` keeps the typed text by itself, so the picker can stay stateless: we only need the text when enter is pressed, and `onSubmitted` gives it to us.
- If the user presses enter with an empty box, the picker pops with `''`, and Home ignores it (`city.isEmpty`).
- Tapping the field opens the keyboard. By default the `Scaffold` shrinks its body to make room, so the text box moves up and stays visible above the keyboard. When the screen is popped, the keyboard closes by itself.
- To read or change the text from code (to clear it, or to filter the list while typing), you need a `TextEditingController`, created in `initState` and disposed in `dispose`. We'll use it in a later lab.

The typed city doesn't have to be in the list: Home just shows it, with the same sample values.

### `GestureDetector`

`GestureDetector` has no look of its own: it wraps a child and detects gestures on it. In this lab it makes the heart, the search box and the tabs tappable. (`ListTile` doesn't need it: it has its own `onTap`.)

| Parameter (used here) | What it does |
|---|---|
| `onTap` | Called when the child is tapped. If it's `null`, taps are ignored. |
| `child` | The widget that receives the gestures. |

Other gestures: `onDoubleTap`, `onLongPress`. If you want the Material ripple effect, use `InkWell`.

The heart shows the whole loop: tap → `WeatherCard` calls `onToggleSave` → `_toggleSaved(_city)` runs `setState` → `build` runs again → a new `WeatherCard` with `saved: true` → the heart is filled, and the city is in the Saved tab.

---
## 2.6 Tabs

Switching tab doesn't push or pop anything. A tab is a piece of state, the index of the selected tab, and `build` shows something different depending on it:

```dart
int _tab = 0;
...
Expanded(
  child: _tab == 0
      ? Center(child: WeatherCard(...))  // Home tab
      : ListView(...),                    // Saved tab
),
BottomTabBar(
  activeIndex: _tab,
  onTap: (index) => setState(() => _tab = index),
),
```

`BottomTabBar` stays stateless. It gets `activeIndex` to know which tab to highlight and calls `onTap` with the index of the tapped tab. Each `_TabItem` is wrapped in a `GestureDetector`.

`Expanded` takes all the space between the search box and the tab bar, and `Center` puts the card in the middle of it: the same result as the two `Spacer`s of Lab 1.

Switching tab doesn't lose anything, because all the state is in `_HomeScreenState`, which stays on screen. (When each tab becomes its own stateful widget, switching would destroy the hidden tab's state; that's what `IndexedStack` is for. We'll see it when we need it.)

---
## 2.7 Ready-made tabs and menus

Our tab bar is built by hand, from Lab 1. Flutter also has two ready-made widgets for switching screens: `NavigationBar` (tabs at the bottom) and `NavigationDrawer` (a menu that slides in from the side). They work exactly like our tabs: an `int` in the state, `setState` on tap, and the body shows the matching screen. Only the names change:

| | Weather app | Material 3 example |
|---|---|---|
| The int | `_tab` | `selectedIndex` |
| The bar | `BottomTabBar` (built by us) | `NavigationBar` (from Flutter) |
| Highlight | `activeIndex: _tab` | `selectedIndex: selectedIndex` |
| Tap | `onTap: (i) => setState(...)` | `onDestinationSelected: (i) => setState(...)` |
| What's shown | `_tab == 0 ? card : list` | `screens[selectedIndex]` |
| Where | at the bottom of our `Column` | `Scaffold(bottomNavigationBar: ...)` |

The two examples below are **separate small apps**, not the weather app. To try one, paste it in the `main.dart` of a new Flutter project.

### `NavigationBar`

```dart
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: HomeScreen()));

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    Center(child: Text("Home Screen")),
    Center(child: Text("Search Screen")),
    Center(child: Text("Profile Screen")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() { selectedIndex = index; });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Home",
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: "Search",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
```

| Piece | What it does |
|---|---|
| `screens` | The screens, as a `const` list of widgets. The body shows `screens[selectedIndex]`. |
| `bottomNavigationBar` | A slot of the `Scaffold`, at the bottom. |
| `selectedIndex` | Which destination is highlighted. |
| `onDestinationSelected` | Called with the index of the tapped destination. We call `setState`. |
| `destinations` | One `NavigationDestination` per screen, in the same order as `screens`. `selectedIcon` is shown when it's the active one; `label` is a `String`. |

Use it for 3 to 5 main screens, the ones the user switches between all the time.

### `NavigationDrawer`

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    Center(child: Text("Home Screen", style: TextStyle(fontSize: 24))),
    Center(child: Text("Profile Screen", style: TextStyle(fontSize: 24))),
    Center(child: Text("Settings Screen", style: TextStyle(fontSize: 24))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Simple Drawer")),
      drawer: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() { selectedIndex = index; });
          Navigator.pop(context); // close drawer
        },
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text('Menu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: Text('Home'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: Text('Profile'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: Text('Settings'),
          ),
        ],
      ),
      body: screens[selectedIndex],
    );
  }
}
```

- `drawer` is another slot of the `Scaffold`. When it's set, the `AppBar` adds the menu icon by itself (like the back arrow on a pushed screen). The user can also swipe from the left edge.
- `selectedIndex` and `onDestinationSelected` work exactly like in `NavigationBar`.
- `children` can hold any widget: here a "Menu" title, then one `NavigationDrawerDestination` per screen, in the same order as `screens`.
- Careful: in the drawer `label` is a widget, `Text('Home')`; in `NavigationBar` it's a `String`.
- `Navigator.pop(context)` closes the drawer: an open drawer sits on the navigator stack, like a pushed screen. Without it, the drawer would stay open over the new screen.

### Which one?

| | `NavigationBar` | `NavigationDrawer` |
|---|---|---|
| Where | at the bottom | a panel from the side |
| Always visible | yes | no: opens from the menu icon |
| How many screens | 3 to 5, used all the time | many, or used less often |
| `Scaffold` slot | `bottomNavigationBar` | `drawer` |
| `label` | a `String` | a widget: `Text(...)` |
| After a tap | `setState` | `setState` + `Navigator.pop` |

---
## 2.8 From Lab 1 to Lab 2, step by step

The concepts above turn the static Lab 1 screen into an app with state, screens and tabs. Nothing from Lab 1 is rewritten: a few lines change, and three small pieces are added at the end of the file. Each step ends with what the app should do at that point.

### Step 1: `HomeScreen` becomes stateful

1. Put the cursor on `HomeScreen`, open the quick actions (Cmd+. on macOS, Alt+Enter / Ctrl+. elsewhere) and choose **Convert to StatefulWidget**. `build` moves into `_HomeScreenState`.
2. At the top of `_HomeScreenState`, add the state:
   ```dart
   int _tab = 0;                         // 0 = Home, 1 = Saved
   String _city = 'London';              // the city shown on Home
   final Set<String> _savedCities = {};  // the cities with the heart
   ```
3. In `build`, the `WeatherCard` uses it: `city: _city,` and `saved: _savedCities.contains(_city),`.

Result: hot reload, the heart is now empty.

### Step 2: The heart

1. In `WeatherCard`, add an optional callback and put it in the constructor (`this.onToggleSave`):
   ```dart
   final VoidCallback? onToggleSave; // called when the heart is tapped
   ```
2. Wrap the heart `Icon` in a `GestureDetector` (quick actions → **Wrap with widget**):
   ```dart
   GestureDetector(
     onTap: onToggleSave,
     child: Icon(...),   // the heart, unchanged
   ),
   ```
3. In `_HomeScreenState`:
   ```dart
   void _toggleSaved(String city) {
     setState(() {
       if (!_savedCities.add(city)) {
         _savedCities.remove(city);
       }
     });
   }
   ```
   and in the `WeatherCard`: `onToggleSave: () => _toggleSaved(_city),`.

Result: tap the heart, it fills and empties.

> [!warning] Try it
> Remove `setState(() { ... })` and keep only the `if`, with a `print(_savedCities);`. The console shows the set changing, but the heart doesn't. Then put `setState` back.

### Step 3: Tabs

1. In `_TabItem`, add `final VoidCallback onTap;` (with `required this.onTap` in the constructor) and wrap the `Opacity` in `GestureDetector(onTap: onTap, child: ...)`.
2. In `BottomTabBar`, add:
   ```dart
   final ValueChanged<int> onTap; // called with the index of the tapped tab
   ```
   with `required this.onTap` in the constructor, and on the two items `onTap: () => onTap(0)` and `onTap: () => onTap(1)`.
3. In `HomeScreen`'s `build`, replace `const BottomTabBar()` with:
   ```dart
   BottomTabBar(
     activeIndex: _tab,
     onTap: (index) => setState(() => _tab = index),
   )
   ```
4. Show something different per tab: replace `const Spacer(), WeatherCard(...), const Spacer(),` with
   ```dart
   Expanded(
     child: _tab == 0
         ? Center(child: WeatherCard(...))   // the same card as before
         : ListView(
             children: [
               for (final city in _savedCities)
                 Text(city, style: AppText.cityName),
             ],
           ),
   ),
   ```

Result: save London, open the Saved tab, it's there. Back on Home, the card is still in the middle.

### Step 4: The city picker

1. At the end of the file, add the list of cities and the picker screen:
   ```dart
   const cities = ['London', 'Bergamo', 'Milano', 'Oslo', 'New York'];

   class CityPickerScreen extends StatelessWidget {
     const CityPickerScreen({super.key});

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         backgroundColor: AppColors.skyMid,
         appBar: AppBar(
           title: const Text('Choose a city'),
           backgroundColor: AppColors.skyMid,
           foregroundColor: AppColors.ink,
         ),
         body: ListView(
           children: [
             for (final city in cities)
               ListTile(
                 title: Text(city, style: AppText.cityName),
                 onTap: () => Navigator.of(context).pop(city),
               ),
           ],
         ),
       );
     }
   }
   ```
2. In `SearchField`, add `final VoidCallback onTap;` (with `required this.onTap`) and wrap the `GlassCard` in `GestureDetector(onTap: onTap, child: ...)`.
3. In `_HomeScreenState`:
   ```dart
   Future<void> _pickCity() async {
     final city = await Navigator.of(context).push<String>(
       MaterialPageRoute(builder: (context) => const CityPickerScreen()),
     );
     if (city == null || city.isEmpty) return;
     setState(() => _city = city);
   }
   ```
   and replace `const SearchField()` with `SearchField(onTap: _pickCity)`.

Result: tap the search box, tap Milano: Home shows Milano. Open the picker again and go back with the arrow: still Milano.

### Step 5: The text box under the cities

In `CityPickerScreen`, the body becomes a `Column`: the list in `Expanded`, so it takes the space left, and the text box below it. `SafeArea` keeps it away from the bottom edge of the phone.

```dart
body: SafeArea(
  child: Column(
    children: [
      Expanded(
        child: ListView(...),   // the same list as before
      ),
      Padding(
        padding: const EdgeInsets.all(20),
        child: TextField(
          style: AppText.cityName,
          decoration: InputDecoration(
            hintText: 'Or type a city',
            hintStyle: AppText.searchHint,
          ),
          onSubmitted: (text) => Navigator.of(context).pop(text),
        ),
      ),
    ],
  ),
),
```

Result: type "Paris" and press enter: Home shows Paris. Enter on an empty box: back on Home, nothing changes (the `city.isEmpty` check).

### Step 6: The detail screen

1. In the Saved tab, make the rows tappable: replace `Text(city, style: AppText.cityName)` with
   ```dart
   ListTile(
     title: Text(city, style: AppText.cityName),
     onTap: () => _openCity(city),
   )
   ```
2. In `_HomeScreenState`:
   ```dart
   void _openCity(String city) {
     Navigator.of(context).push(
       MaterialPageRoute(builder: (context) => CityDetailScreen(city: city)),
     );
   }
   ```
3. At the end of the file, the screen (same shape as the picker):
   ```dart
   class CityDetailScreen extends StatelessWidget {
     final String city;
     const CityDetailScreen({super.key, required this.city});

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         backgroundColor: AppColors.skyMid,
         appBar: AppBar(
           title: Text(city),
           backgroundColor: AppColors.skyMid,
           foregroundColor: AppColors.ink,
         ),
         body: Center(
           child: WeatherCard(
             city: city,
             condition: 'Rain',
             temp: 12,
             description: 'Light rain',
             humidity: 80,
             windKmh: 15,
             saved: true,
           ),
         ),
       );
     }
   }
   ```

Result: save two cities, open them from the Saved tab, go back with the arrow.

---
## 2.9 Common mistakes

| Mistake | What happens | Fix |
|---|---|---|
| Changing state without `setState` | The data changes but the screen doesn't. | Put the change inside `setState`. |
| Not handling `null` from `push` | A wrong value when the user just goes back. | The result is nullable: check for `null`. |
| `ListView` in a `Column` without `Expanded` | Error about unbounded height. | Wrap it in `Expanded`. |
| `onTap: _pickCity()` with parentheses | It runs while building, not on tap (and doesn't compile here). | Pass the function: `onTap: _pickCity`. |
| Hot reload after changing a field's starting value | Nothing changes. | Hot reload keeps the `State`: do a hot restart. |
| `label: "Home"` in a `NavigationDrawerDestination` | It doesn't compile. | In the drawer `label` is a widget: `label: Text('Home')`. |
| No `Navigator.pop(context)` after a drawer tap | The screen changes, but the drawer stays open over it. | Close it with `Navigator.pop(context)`. |

---
## 2.10 Running it

```bash
flutter run
```

The app should:
- at launch, show London on Home;
- tapping the heart: it fills, and London appears in the Saved tab;
- tapping the search box: open the list of cities; tapping one goes back to Home with that city;
- typing a city in the box at the bottom of the list and pressing enter: Home shows that city; enter on an empty box does nothing;
- going back from the list without choosing: nothing changes;
- switching tabs and back: Home still shows the same city;
- tapping a saved city: open its detail screen; the back arrow goes back.

---
## 2.11 Quick reference

| Construct | Job |
|---|---|
| `StatefulWidget` + `State<T>` | A widget with a long-lived object that holds changing data. |
| `createState()` / `build()` | The two required methods. |
| `initState()` / `dispose()` | One-time setup and cleanup. |
| `setState()` | Changes the state and schedules a rebuild. |
| `Navigator.of(context).push` / `pop` | Open and close a screen. |
| `MaterialPageRoute` | A route with the platform transition. |
| `AppBar` | A top bar with a title and, on pushed screens, a back arrow. |
| `push<T>` + `pop(value)` | Return a value from a screen (`T?`, `null` on back). |
| `await` (in an `async` method) | Wait for the screen to close and get its value. |
| `for` inside a list | One child per item. |
| `cond ? a : b` | Choose between two widgets (the tabs). |
| `ListView` | A scrolling list of widgets. |
| `ListTile` | A ready-made row with a title and an `onTap`. |
| `Expanded` | Fill the remaining space in a `Row` or `Column`. |
| `GestureDetector` | Make any widget tappable. |
| `TextField` + `onSubmitted` | Text input; get the text when enter is pressed. |
| `NavigationBar` | Ready-made tabs at the bottom (`Scaffold.bottomNavigationBar`). |
| `NavigationDrawer` | Ready-made side menu (`Scaffold.drawer`), closed with `Navigator.pop`. |

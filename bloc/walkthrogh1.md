# BLoC State Management — Reference Notes (Expense Tracker)

These notes collect everything covered in our BLoC session: the core idea, the complete code, a line-by-line explanation of every important line, the answers to the questions you asked, and a full trace of how one tap flows through the app.

---

## Table of Contents

1. [The Big Idea: What BLoC Is](#1-the-big-idea-what-bloc-is)
2. [Project Setup and File Structure](#2-project-setup-and-file-structure)
3. [The Complete Code](#3-the-complete-code)
4. [Line-by-Line: The Model (`Expense`)](#4-line-by-line-the-model-expense)
5. [Line-by-Line: The Events (`ExpenseEvent`)](#5-line-by-line-the-events-expenseevent)
6. [Line-by-Line: The State (`ExpenseState`)](#6-line-by-line-the-state-expensestate)
7. [Line-by-Line: The Bloc (`ExpenseBloc`)](#7-line-by-line-the-bloc-expensebloc)
8. [Line-by-Line: The UI](#8-line-by-line-the-ui)
9. [Your Question: Where Does `state.expenses` Come From?](#9-your-question-where-does-stateexpenses-come-from)
10. [Your Question: Why Make a New List? Isn't Every Emitted Object New?](#10-your-question-why-make-a-new-list-isnt-every-emitted-object-new)
11. [The Complete Flow: One Tap, Start to Finish](#11-the-complete-flow-one-tap-start-to-finish)
12. [Dart Concepts Used in This Code (Quick Reference)](#12-dart-concepts-used-in-this-code-quick-reference)
13. [Practice Questions and Task](#13-practice-questions-and-task)

---

## 1. The Big Idea: What BLoC Is

BLoC (Business Logic Component) is a pattern that keeps **what your app looks like** (widgets) separate from **what your app decides** (logic).

### The restaurant analogy

- The **customer** (your UI) does not walk into the kitchen. They give an **order** to the kitchen.
- The **kitchen** (the Bloc) receives the order, does the work, and sends out a **dish**.
- The customer only sees the dish that arrives and reacts to it.

### The three pieces

| Piece | What it is | Example in our app |
|---|---|---|
| **Event** | A message from the UI that says "something happened". The UI never changes data directly; it only reports what happened. | "The user added an expense." |
| **State** | A snapshot of the data the screen should show at one moment. | "Here is the list of expenses and the total." |
| **Bloc** | The class that receives events, runs the logic, and **emits** (sends out) a new state. | `ExpenseBloc` |

### Data flows in one direction only

```
┌────────┐   adds an Event    ┌────────┐   emits a new State   ┌────────────┐
│   UI   │ ─────────────────▶ │  Bloc  │ ────────────────────▶ │ UI rebuilds│
└────────┘                    └────────┘                       └────────────┘
     ▲                                                               │
     └───────────────────────────────────────────────────────────────┘
```

Because data only moves one way, you always know where a change came from. The button does not know how expenses are stored, and the Bloc does not know what a button is. Each side has exactly one job.

---

## 2. Project Setup and File Structure

Add the package by running this in your project folder:

```
flutter pub add flutter_bloc
```

A clean way to organise the files:

```
lib/
├── main.dart                  ← app entry point and UI
├── models/
│   └── expense.dart           ← the Expense data class
└── bloc/
    ├── expense_event.dart     ← all events (must be in ONE file because the parent is sealed)
    ├── expense_state.dart     ← the state class
    └── expense_bloc.dart      ← the Bloc with the logic
```

---

## 3. The Complete Code

### `lib/models/expense.dart`

```dart
class Expense {
  final String title;
  final double amount;

  const Expense({required this.title, required this.amount});
}
```

### `lib/bloc/expense_event.dart`

```dart
import '../models/expense.dart';

sealed class ExpenseEvent {}

final class ExpenseAdded extends ExpenseEvent {
  final Expense expense;
  ExpenseAdded(this.expense);
}

final class ExpenseRemoved extends ExpenseEvent {
  final int index;
  ExpenseRemoved(this.index);
}
```

### `lib/bloc/expense_state.dart`

```dart
import '../models/expense.dart';

class ExpenseState {
  final List<Expense> expenses;

  const ExpenseState({this.expenses = const []});

  double get total => expenses.fold(0.0, (sum, e) => sum + e.amount);
}
```

> Note: in the session we wrote `fold(0, ...)`. Dart treats that `0` as `0.0` because the getter returns a `double`, so both work. Writing `0.0` makes the intent clearer, so it is used here.

### `lib/bloc/expense_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc() : super(const ExpenseState()) {
    on<ExpenseAdded>(_onAdded);
    on<ExpenseRemoved>(_onRemoved);
  }

  void _onAdded(ExpenseAdded event, Emitter<ExpenseState> emit) {
    final updated = [...state.expenses, event.expense];
    emit(ExpenseState(expenses: updated));
  }

  void _onRemoved(ExpenseRemoved event, Emitter<ExpenseState> emit) {
    final updated = [...state.expenses]..removeAt(event.index);
    emit(ExpenseState(expenses: updated));
  }
}
```

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/expense_bloc.dart';
import 'bloc/expense_event.dart';
import 'bloc/expense_state.dart';
import 'models/expense.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => ExpenseBloc(),
      child: const MaterialApp(home: ExpenseScreen()),
    ),
  );
}

class ExpenseScreen extends StatelessWidget {
  const ExpenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          return Column(
            children: [
              Text('Total: ₹${state.total.toStringAsFixed(2)}'),
              Expanded(
                child: ListView.builder(
                  itemCount: state.expenses.length,
                  itemBuilder: (context, index) {
                    final expense = state.expenses[index];
                    return ListTile(
                      title: Text(expense.title),
                      trailing: Text('₹${expense.amount}'),
                      onLongPress: () => context
                          .read<ExpenseBloc>()
                          .add(ExpenseRemoved(index)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<ExpenseBloc>().add(
              ExpenseAdded(const Expense(title: 'Tea', amount: 20)),
            ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## 4. Line-by-Line: The Model (`Expense`)

```dart
class Expense {
  final String title;
  final double amount;

  const Expense({required this.title, required this.amount});
}
```

- `class Expense` defines what one expense is: a title and an amount.
- Both fields are `final`, which means that once an `Expense` object is created, its title and amount can never be reassigned. In BLoC we never edit old data; we create new data instead, so immutable models fit the pattern naturally.
- `required` means the caller **must** pass that named parameter. `Expense(title: 'Tea')` without an amount would not compile.
- `const` before the constructor allows creating the object at compile time when all values are known, for example `const Expense(title: 'Tea', amount: 20)`.

---

## 5. Line-by-Line: The Events (`ExpenseEvent`)

```dart
sealed class ExpenseEvent {}
```

- This creates a **parent type** for every event this Bloc understands.
- The keyword `sealed` tells Dart that every subclass must live in **this same file**. Because of that, Dart knows the complete list of possible events, and it can warn you if you forget to handle one inside a `switch`.

```dart
final class ExpenseAdded extends ExpenseEvent {
  final Expense expense;
  ExpenseAdded(this.expense);
}
```

- This is the event for "the user added an expense".
- It **carries** the new `Expense` object, because the Bloc needs to know *what* was added.
- `ExpenseAdded(this.expense)` is a constructor with a **positional** parameter (no curly braces), so you create it as `ExpenseAdded(myExpense)`.
- `final class` means no other class may extend `ExpenseAdded`. It is a closed, finished type.

```dart
final class ExpenseRemoved extends ExpenseEvent {
  final int index;
  ExpenseRemoved(this.index);
}
```

- This is the event for "the user removed an expense".
- It carries the `index`, meaning the position in the list, so the Bloc knows *which* expense to remove.

**Naming rule:** events are named in the **past tense** (Added, Removed) because they describe something that has already happened in the UI.

---

## 6. Line-by-Line: The State (`ExpenseState`)

```dart
class ExpenseState {
  final List<Expense> expenses;

  const ExpenseState({this.expenses = const []});

  double get total => expenses.fold(0.0, (sum, e) => sum + e.amount);
}
```

### Line: `final List<Expense> expenses;`

This declares a field called `expenses`.

- `List<Expense>` means "a list that is only allowed to hold `Expense` objects". The part in angle brackets is a **generic type**. If you tried to put a `String` or an `int` into this list, Dart would refuse at compile time, before the app even runs.
- `final` means this field can be assigned **once**, when the object is created, and never reassigned after that.

**Important subtlety:** `final` protects the **variable**, not the **contents** of the list. Think of the variable as a label stuck on a box. `final` glues the label to that one box, so you cannot move the label to a different box. But `final` alone does not stop someone from putting things into the box or taking things out.

```dart
final numbers = [1, 2, 3];
numbers.add(4);        // Allowed: we changed the contents of the same list.
numbers = [5, 6];      // Error: we tried to point the variable at a different list.
```

This is why, in the Bloc, we deliberately create new lists instead of editing the old one. `final` alone would not stop us from making that mistake.

### Line: `const ExpenseState({this.expenses = const []});`

This constructor packs four ideas into one line:

1. **`const` before the constructor name** allows Dart to create this object at compile time when all its values are known. This is only allowed because every field in the class is `final`. The benefit is that `const ExpenseState()` is created once and reused instead of being rebuilt every time.

2. **The curly braces `{ }`** make `expenses` a **named parameter**. When creating the object, you write the parameter's name, which makes the code easier to read:
   ```dart
   ExpenseState(expenses: myList);
   ```

3. **`this.expenses`** is a shorthand meaning "take whatever value is passed in and store it directly in the field called `expenses`". Without the shorthand you would write:
   ```dart
   ExpenseState({List<Expense> expenses = const []}) : this.expenses = expenses;
   ```

4. **`= const []`** is the **default value**. If no list is passed, `expenses` becomes an empty list. Default values in Dart must be compile-time constants, which is why it is `const []` and not `[]`. A `const` list is also **unmodifiable**: calling `.add()` on it throws an error at runtime.

Both of these work:

```dart
const ExpenseState();                     // expenses is an empty list
ExpenseState(expenses: [teaExpense]);     // expenses holds one item
```

### Line: `double get total => expenses.fold(0.0, (sum, e) => sum + e.amount);`

#### The getter part: `double get total =>`

- `get` makes `total` a **getter**. A getter looks like a field when you use it, but it runs code every time it is read. You write `state.total`, with no parentheses, exactly as if it were a stored value.
- `double` is the type of value the getter returns.
- `=>` is **arrow syntax**, a shorthand for a function body that only returns one expression. These two are identical:

```dart
double get total => expenses.fold(0.0, (sum, e) => sum + e.amount);

double get total {
  return expenses.fold(0.0, (sum, e) => sum + e.amount);
}
```

**Why calculate the total instead of storing it?** A stored total could get out of sync with the list (for example, you remove an expense but forget to update the total). A getter is recalculated from the list every time, so it can never be wrong.

#### The `fold` part

`fold` walks through a list and **combines all its items into a single value**. It takes two arguments:

1. **A starting value**: here `0.0`.
2. **A combining function**: here `(sum, e) => sum + e.amount`. This function is called once for every item. It receives `sum` (the result built up so far) and `e` (the current item). Whatever it returns becomes the new `sum` for the next item.

Trace with three expenses: Tea ₹20, Lunch ₹120, Bus ₹30.

| Step | `sum` coming in | `e` (current item) | `sum + e.amount` (goes out) |
|---|---|---|---|
| Start | — | — | 0.0 |
| 1 | 0.0 | Tea | 0 + 20 = **20** |
| 2 | 20 | Lunch | 20 + 120 = **140** |
| 3 | 140 | Bus | 140 + 30 = **170** |

After the last item, `fold` returns `170`. If the list is empty, the combining function is never called, and `fold` simply returns the starting value.

The same logic written as a plain loop, which is exactly what `fold` does for you:

```dart
double get total {
  double sum = 0.0;
  for (final e in expenses) {
    sum = sum + e.amount;
  }
  return sum;
}
```

---

## 7. Line-by-Line: The Bloc (`ExpenseBloc`)

### Line: `class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {`

- `extends` means `ExpenseBloc` **inherits** from the `Bloc` class provided by the flutter_bloc package.
- The parent `Bloc` already contains all the machinery: it stores the current `state`, accepts events through `add()`, and notifies listeners when you `emit`. Your class only adds the **rules**: what to do for each event.
- The two types in angle brackets fill in the parent's blanks: "this Bloc **receives** `ExpenseEvent`s and **produces** `ExpenseState`s".

### Line: `ExpenseBloc() : super(const ExpenseState()) {`

- `ExpenseBloc()` is the constructor of your class. It takes no parameters.
- The colon `:` starts an **initializer list**, code that runs **before** the constructor's body `{ ... }`.
- `super(...)` calls the constructor of the **parent** class, `Bloc`. The `Bloc` constructor requires one thing: the **initial state**. We give it `const ExpenseState()`, an empty expense list.

**Why does Bloc insist on an initial state?** The very first time the screen draws, `BlocBuilder` needs some state to show. Requiring it up front guarantees that `state` is never empty or `null`.

### Line: `on<ExpenseAdded>(_onAdded);`

This registers a rule: "when an event of type `ExpenseAdded` arrives, run the method `_onAdded`". There is one `on<...>` line for every event type.

Notice it is `_onAdded` **without parentheses**:

- `_onAdded()` with parentheses would **call** the method right now.
- `_onAdded` without parentheses **hands the method over** so the Bloc can call it later, whenever the event arrives. This is called a **tear-off**.

Analogy: calling someone on the phone right now, versus giving someone their phone number so they can call later. Here we give the Bloc the phone number.

The underscore at the start of `_onAdded` makes the method **private** to this file, so code in other files cannot call it directly. Only the Bloc itself should run it.

### Line: `void _onAdded(ExpenseAdded event, Emitter<ExpenseState> emit) {`

The Bloc calls this method with two arguments:

- `event` is the exact event object the UI sent. Because its type is `ExpenseAdded`, you can read `event.expense` to get the expense the user added.
- `emit` is the tool for sending out a new state. Calling `emit(someState)` replaces the Bloc's current state and tells every `BlocBuilder` to rebuild.

### Line: `final updated = [...state.expenses, event.expense];`

The `...` is the **spread operator**. Inside a list literal `[ ]`, it means "unpack every item from this other list into here".

```dart
final old = ['Tea', 'Lunch'];
final updated = [...old, 'Bus'];
// updated is ['Tea', 'Lunch', 'Bus']
// old is still ['Tea', 'Lunch'] — untouched
```

So this line builds a **brand-new list** containing all the old expenses plus the new one at the end. The old list is never changed.

### Line: `emit(ExpenseState(expenses: updated));`

This creates a **new** `ExpenseState` object holding the new list and sends it out. Because it is a different object from the previous state, Bloc recognises that something changed and rebuilds the UI.

### Line: `final updated = [...state.expenses]..removeAt(event.index);`

Two steps:

1. `[...state.expenses]` makes a **copy** of the current list.
2. `..removeAt(event.index)` removes the item at that position **from the copy**.

The `..` is the **cascade operator**. It is needed because `removeAt` returns **the item it removed**, not the list:

```dart
final a = ['Tea', 'Lunch', 'Bus'].removeAt(0);
// a is 'Tea'  — the removed item

final b = ['Tea', 'Lunch', 'Bus']..removeAt(0);
// b is ['Lunch', 'Bus']  — the list itself, after removal
```

- With a **single dot**, you get back whatever the method returns.
- With **two dots**, the method still runs, but you get back **the object you called it on**.

Since we want the shortened list stored in `updated`, we need `..`. This two-line version does exactly the same thing and is perfectly fine to use:

```dart
final updated = [...state.expenses];
updated.removeAt(event.index);
```

---

## 8. Line-by-Line: The UI

### `BlocProvider`

```dart
BlocProvider(
  create: (_) => ExpenseBloc(),
  child: const MaterialApp(home: ExpenseScreen()),
)
```

- `BlocProvider` creates the `ExpenseBloc` **once** and makes it available to every widget below it in the widget tree. Think of it as placing the kitchen in the building so every table can send orders to it.
- `create: (_) => ExpenseBloc()` is a function that builds the Bloc. The `_` is the `BuildContext` parameter, which we do not need here.
- `BlocProvider` also **closes** the Bloc automatically when it is no longer needed, so you do not leak resources.

### `BlocBuilder`

```dart
BlocBuilder<ExpenseBloc, ExpenseState>(
  builder: (context, state) {
    // return widgets built from state
  },
)
```

- `BlocBuilder` **listens** to the Bloc. Every time the Bloc emits a new state, the `builder` function runs again with that new `state`.
- Only the widgets inside the builder are rebuilt, not the whole screen.
- Notice that `ExpenseScreen` is a `StatelessWidget`. It does not need `setState`, because the Bloc holds the data.

### `context.read<ExpenseBloc>().add(...)`

```dart
onPressed: () => context.read<ExpenseBloc>().add(
      ExpenseAdded(const Expense(title: 'Tea', amount: 20)),
    ),
```

- `context.read<ExpenseBloc>()` finds the Bloc that `BlocProvider` created higher up in the tree.
- `.add(...)` sends an event to it.
- We use `read` (not `watch`) inside button callbacks because we only want to **send** something once. We do not want this widget to rebuild when the state changes; `BlocBuilder` already handles that.

| Method | Use it for | Rebuilds this widget on state change? |
|---|---|---|
| `context.read<T>()` | Sending events (inside callbacks like `onPressed`) | No |
| `context.watch<T>()` / `BlocBuilder` | Displaying state | Yes |

---

## 9. Your Question: Where Does `state.expenses` Come From?

`state` is never declared anywhere in `ExpenseBloc`. You never wrote `final ExpenseState state;`, yet you can use it. It comes from the **parent class**, `Bloc`.

### It has two parts

`state.expenses` is two steps joined by a dot:

1. **`state`** is the Bloc's **current `ExpenseState` object**, the latest snapshot of your data.
2. **`.expenses`** reads the `expenses` field **from that object**, which is the `List<Expense>` you declared in `ExpenseState`.

You wrote `.expenses` yourself in `ExpenseState`. The only mystery is `state`.

### Where `state` comes from: inheritance

```dart
class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState>
```

`extends` means your class **inherits** everything the `Bloc` class already has. The authors of flutter_bloc wrote a `state` property inside their class, so your class gets it automatically.

A heavily **simplified** sketch of what the parent class does internally (the real code is more complex, but the idea is the same):

```dart
class Bloc<Event, State> {
  State _state;                 // a private variable holding the current state

  Bloc(State initialState) : _state = initialState;

  State get state => _state;    // a getter, so you read it as "state"

  void emit(State newState) {
    _state = newState;          // replace the old state with the new one
    // ...then notify every BlocBuilder that is listening
  }
}
```

Two things to notice:

- `state` is a **getter** (the same idea as `total` in `ExpenseState`). It gives you the current value of a private variable that the parent class manages.
- The type is written as `State`, a **placeholder**. When you wrote `Bloc<ExpenseEvent, ExpenseState>`, you filled the placeholder with `ExpenseState`. That is why Dart knows `state` is an `ExpenseState` inside your Bloc, and lets you write `.expenses` after it.

### How `state` changes over time

| Moment | What happens | What `state` holds |
|---|---|---|
| Bloc is created | `super(const ExpenseState())` passes the initial state to the parent | `ExpenseState` with an empty list |
| User taps + (Tea ₹20) | `_onAdded` reads `state.expenses` (empty), builds `[Tea]`, calls `emit` | `ExpenseState` with `[Tea]` |
| User taps + again | `_onAdded` reads `state.expenses` (`[Tea]`), builds `[Tea, Tea]`, calls `emit` | `ExpenseState` with `[Tea, Tea]` |

The cycle: **read the current list through `state.expenses` → build a new list from it → `emit` a new state → `state` now points to that new object**, so the next event reads the updated list.

This is also why `super(const ExpenseState())` matters: it is the very first value `state` ever holds. Without it, the first `_onAdded` call would have nothing to read.

---

## 10. Your Question: Why Make a New List? Isn't Every Emitted Object New?

**Your reasoning:** "Every time Bloc emits, a new object is made, so how could it ever emit the same state? The object would definitely be different."

**Answer:** With the code we wrote, `emit(ExpenseState(expenses: updated))`, you are correct: a new object is created every time. The "same object" problem only happens when the code is written differently.

### The key point: `emit` does not create objects

`emit` never builds a new state for you. It only **delivers whatever object you hand it**. Think of `emit` as a postman: he delivers the envelope you give him; he does not write a new letter.

What creates a new object is the **constructor call**, `ExpenseState(...)`. So whether the object is new or old depends entirely on what you put inside `emit(...)`:

```dart
emit(ExpenseState(expenses: updated));  // Constructor called → a NEW object is delivered.
emit(state);                            // Existing object passed → the SAME object is delivered.
```

### When the "same object" problem happens

A very common beginner mistake:

```dart
void _onAdded(ExpenseAdded event, Emitter<ExpenseState> emit) {
  state.expenses.add(event.expense);   // edits the list inside the current state
  emit(state);                         // hands back the exact same object
}
```

(With our `const []` default, the `.add` line would actually crash first, because a `const` list is unmodifiable. Assume a modifiable list for this explanation.)

What Bloc does with this:

1. Before emitting, Bloc checks: is the new state `==` to the current state?
2. You passed `state` itself, so the two are **literally the same object in memory**. The check is true.
3. Bloc concludes "nothing changed" and **skips** the emit. `BlocBuilder` never rebuilds.
4. The data inside the list **did** change, but the screen still shows the old list: a **frozen screen**.

So the rule is not "Bloc sometimes reuses objects". The rule is: **you** must give Bloc a new object, because Bloc trusts the `==` check.

### Then why copy the list too?

You might ask: "If I always call `ExpenseState(...)`, I get a new object anyway. Why bother with `[...state.expenses]`?"

```dart
state.expenses.add(event.expense);                 // edit the old list
emit(ExpenseState(expenses: state.expenses));      // wrap it in a new state object
```

With our current code this would rebuild the screen, because the state object is new. But it is still wrong, for two reasons.

**Reason 1 — the old state gets damaged.** The old state and the new state now **share the same list**, and that list already contains the new item. The "before" snapshot no longer shows what things looked like before. Anything that compares old and new states (logging, undo, `BlocListener` conditions) sees two identical lists.

**Reason 2 — in real apps, `==` compares contents, not identity.** Right now `ExpenseState` uses Dart's default `==`, which only asks "are these the same object in memory?" In real Flutter apps you usually change `==` to compare the **values inside** the state (commonly with the `equatable` package, covered later). Then Bloc's check becomes "do these two states contain equal data?" With the shared list:

- Old state's list: `[Tea, Lunch]` (it was edited, so it already contains Lunch)
- New state's list: `[Tea, Lunch]` (the very same list)
- Bloc compares them → equal → emit skipped → **frozen screen again**.

Copying with `[...state.expenses]` avoids both problems:

- The old state keeps its own list, `[Tea]`, untouched.
- The new state gets a new list, `[Tea, Lunch]`.
- They are genuinely different, so any comparison, by identity or by contents, correctly sees the change.

### Summary

`emit` delivers whatever you give it, so you must give it a **new state object holding a new list**, and you must never edit the old list, because the old state should remain an accurate record of what things looked like before.

| Handler code | New state object? | New list? | Correct? |
|---|---|---|---|
| `emit(ExpenseState(expenses: [...state.expenses, e]))` | Yes | Yes | ✅ Always correct |
| `state.expenses.add(e); emit(state);` | No | No | ❌ Same object → emit skipped |
| `state.expenses.add(e); emit(ExpenseState(expenses: state.expenses));` | Yes | No | ❌ Damages old state; breaks with content-based `==` |

---

## 11. The Complete Flow: One Tap, Start to Finish

### App start

1. `main()` runs and calls `runApp(...)`.
2. `BlocProvider` runs `create`, which constructs `ExpenseBloc()`.
3. The `ExpenseBloc` constructor calls `super(const ExpenseState())`, so `state` now holds an empty list. The two `on<...>` lines register the handlers.
4. `MaterialApp` shows `ExpenseScreen`.
5. `BlocBuilder` reads the current `state` and calls `builder`. The screen shows "Total: ₹0.00" and an empty list.

### User taps the + button

```
[+ tapped]
    │
    ▼
onPressed → context.read<ExpenseBloc>()           (find the Bloc above in the tree)
    │
    ▼
.add(ExpenseAdded(Expense('Tea', 20)))             (UI only REPORTS what happened)
    │
    ▼
Bloc looks for a handler → finds on<ExpenseAdded> → runs _onAdded
    │
    ▼
_onAdded reads state.expenses  →  []               (current list, empty)
    │
    ▼
updated = [...[], Tea]  →  [Tea]                  (brand-new list; old one untouched)
    │
    ▼
emit(ExpenseState(expenses: [Tea]))                (brand-new state object)
    │
    ▼
Bloc checks: new state == old state?  → No         (different objects)
    │
    ▼
state now points to the new object; listeners are notified
    │
    ▼
BlocBuilder runs builder(context, newState)
    │
    ▼
Screen shows "Tea  ₹20.0" and "Total: ₹20.00"
```

### User long-presses the "Tea" row

1. `onLongPress` sends `ExpenseRemoved(0)`, because Tea is at position 0.
2. The Bloc finds `on<ExpenseRemoved>` and runs `_onRemoved`.
3. `[...state.expenses]` copies `[Tea]`, and `..removeAt(0)` removes Tea from the copy, giving `[]`.
4. `emit(ExpenseState(expenses: []))` sends a new state.
5. `BlocBuilder` rebuilds. The screen shows an empty list and "Total: ₹0.00".

---

## 12. Dart Concepts Used in This Code (Quick Reference)

| Concept | Syntax | Meaning |
|---|---|---|
| `final` field | `final String title;` | Assigned once, never reassigned. Protects the variable, not the contents of a list. |
| `const` constructor | `const Expense(...)` | Object can be created at compile time; all fields must be `final`. |
| Named parameters | `ExpenseState({this.expenses})` | Caller writes the name: `ExpenseState(expenses: x)`. |
| `required` | `{required this.title}` | The named parameter must be provided. |
| Default value | `{this.expenses = const []}` | Used when the caller passes nothing; must be a compile-time constant. |
| `this.` shorthand | `ExpenseAdded(this.expense)` | Stores the argument directly into the field. |
| Generic type | `List<Expense>`, `Bloc<E, S>` | Fills in a type placeholder so Dart knows exactly what goes in/out. |
| Getter | `double get total => ...` | Computed value read like a field: `state.total`. |
| Arrow syntax | `=> expression` | Shorthand for `{ return expression; }`. |
| `fold` | `list.fold(start, (acc, item) => ...)` | Combines all items into one value. |
| Spread | `[...list, item]` | Copies all items of `list` into a new list. |
| Cascade | `list..removeAt(0)` | Calls the method but returns the object itself. |
| Inheritance | `extends Bloc<...>` | Your class gets everything the parent has (`state`, `emit`, `add`). |
| `super(...)` | `: super(initialState)` | Calls the parent class's constructor. |
| Initializer list | `ExpenseBloc() : ...` | Code that runs before the constructor body. |
| Tear-off | `on<X>(_onAdded)` | Passes a method without calling it. |
| Private name | `_onAdded` | Underscore makes it private to the file. |
| `sealed class` | `sealed class ExpenseEvent {}` | All subclasses must be in the same file; Dart knows the full list. |
| `final class` | `final class ExpenseAdded` | No other class may extend it. |

---

## 13. Practice Questions and Task

Answer these in your own words and send them for review.

### Concept checks

1. If `expenses` is an empty list, what does `state.total` return, and why?
2. What are the values of `x` and `y`?
   ```dart
   final x = [10, 20, 30].removeAt(1);
   final y = [10, 20, 30]..removeAt(1);
   ```
3. In `on<ExpenseAdded>(_onAdded);`, what would go wrong if you wrote `_onAdded()` with parentheses?
4. On the very first tap of +, what does line A print and what does line B print? Why do they differ?
   ```dart
   void _onAdded(ExpenseAdded event, Emitter<ExpenseState> emit) {
     print(state.expenses.length);   // line A
     final updated = [...state.expenses, event.expense];
     emit(ExpenseState(expenses: updated));
     print(state.expenses.length);   // line B
   }
   ```
5. What **two** things go wrong with this handler? (Hint: the default value of `expenses`, and what Bloc does when you emit the same object.)
   ```dart
   void _onAdded(ExpenseAdded event, Emitter<ExpenseState> emit) {
     state.expenses.add(event.expense);
     emit(state);
   }
   ```
6. Assuming the default `==` (identity) and a modifiable list, does the screen update for A, B and C? Then: which would **stop** working if `==` compared list contents?
   ```dart
   // A
   final updated = [...state.expenses, event.expense];
   emit(ExpenseState(expenses: updated));

   // B
   state.expenses.add(event.expense);
   emit(state);

   // C
   state.expenses.add(event.expense);
   emit(ExpenseState(expenses: state.expenses));
   ```

### Coding task: "Clear all"

1. Create a new event class called `ExpensesCleared`.
2. Register a handler for it in `ExpenseBloc` that emits an empty state.
3. Add an `IconButton` to the `AppBar` (in its `actions` list) that sends this event.

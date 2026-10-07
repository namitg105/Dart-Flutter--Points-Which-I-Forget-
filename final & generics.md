# Understanding `final` Lists in Dart

## Key Concepts

* **`List<Expense>`**: A list that is only allowed to hold `Expense` objects.
* **Generic Type**: The part in angle brackets (`<Expense>`), which enforces type safety.
* **Compile-Time Check**: Dart prevents you from putting an invalid type (like a `String` or `int`) into this list before your app even runs.
* **`final` Field**: This field can be assigned exactly once, when the object is created, and cannot be reassigned afterward.

---

## The Subtle Point: Variables vs. Contents

A crucial detail to remember is that **`final` protects the variable itself, not the contents of the list**. 

### The Box & Label Analogy
* Think of the variable as a **label stuck on a box**.
* `final` **glues the label to that specific box**, meaning you cannot move the label to a different box.
* However, `final` alone **does not stop someone from putting things into the box or taking things out of it**.

### Code Example

```dart
final numbers = [1, 2, 3];

// Allowed: We changed the contents of the same list.
numbers.add(4); 

// Error: We tried to point the variable at a new list.
numbers = [5, 6]; 
```

---

## Why This Matters in BLoC

* Because `final` doesn't prevent mutating the contents of a list, it alone cannot stop accidental modifications to your state.
* This is why, in the **BLoC pattern**, we deliberately create **new lists** instead of editing the old one in place. 

sealed class ExpenseEvent {}

final class ExpenseAdded extends ExpenseEvent {
  final Expense expense;
  ExpenseAdded(this.expense);//carries the new expense object as Bloc needs to know what was added
}

final class ExpenseRemoved extends ExpenseEvent {
  final int index;//carries position in list so Bloc knows which one to remove 
  ExpenseRemoved(this.index);
}

/*sealed class ExpenseEvent {}
creates a parent type for every event this Bloc understands.
The keyword sealed tells Dart that every subclass must 
live in this same file.
Dart then knows the complete list of possible events, 
and it can warn you if you forget to handle one when you use a switch*/


//Event names are written in the past tense (Added, Removed) 
//because they describe something that has already happened in the UI.

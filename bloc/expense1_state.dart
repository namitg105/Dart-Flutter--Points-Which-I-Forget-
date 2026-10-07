class ExpenseState {
  final List<Expense> expenses;

  const ExpenseState({this.expenses = const []});

double get total {
  double sum = 0;
  for (final e in expenses) {
    sum = sum + e.amount;
  }
  return sum;
}}

//this.expenses = const [] means: if no list is passed in, 
//start with an empty list.
//This is our starting state when the app opens.

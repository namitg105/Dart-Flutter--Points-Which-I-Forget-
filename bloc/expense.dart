
//THIS IS A TUTORIAL FOR BLOC
// i understood  how to create folders in github with this commit (just add / in the end)
class Expense {
  final String title;
  final double amount;

  const Expense({required this.title, required this.amount});
}
//Both fields are final, which means that once an Expense object is created, its title and amount can never change. 
//This matters in BLoC: we never edit old data. We create new data instead.

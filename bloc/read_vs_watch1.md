import 'package:flutter_bloc/flutter_bloc.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc() : super(const ExpenseState()) {//sets the initial state,
  // the state that exists before any event has happened.
  // Here it is an empty expense list.
    on<ExpenseAdded>(_onAdded);
    on<ExpenseRemoved>(_onRemoved);
  }

  void _onAdded(ExpenseAdded event, Emitter<ExpenseState> emit) {
    final updated = [...state.expenses, event.expense];//creates a brand new list.
    emit(ExpenseState(expenses: updated));
  }

  void _onRemoved(ExpenseRemoved event, Emitter<ExpenseState> emit) {
    final updated = [...state.expenses]..removeAt(event.index);//makes a copy first, and removes the item from that copy
    emit(ExpenseState(expenses: updated));
  }
}


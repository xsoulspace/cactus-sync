import 'package:riverpod/riverpod.dart';

class TodosNotifier extends StateNotifier<List<Todo>> {
  TodosNotifier() : super([]);

  void add(Todo todo) {
    state = [...state, todo];
  }

  void remove(String todoId) {
    state = [
      for (final todo in state)
        if (todo.id != todoId) todo,
    ];
  }

  void toggle(String todoId) {
    state = [
      for (final todo in state)
        if (todo.id == todoId) todo.copyWith(completed: !todo.completed),
    ];
  }
}

class Todo {
  String id;
}

class RiverpodStateModel<TModel> extends StateNotifier<List<TModel>> {
  RiverpodStateModel() : super([]);
}

final riverpodStateModelProvider =
    <TModel>() => StateNotifierProvider((ref) => RiverpodStateModel<TModel>());

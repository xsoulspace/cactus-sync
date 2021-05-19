class GraphqlFindList<TModel> {
  final Map<String, dynamic> json;
  GraphqlFindList({required this.json});

  List<TModel?> get getItems =>
      (json.values.first['items'] ?? []) as List<TModel?>;
}

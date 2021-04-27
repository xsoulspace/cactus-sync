class GraphqlFindList<TModel> {
  final Map<String, dynamic> json;
  GraphqlFindList({required this.json});

  List<TModel?> get getValues => json.values.first['items'] ?? [];
}

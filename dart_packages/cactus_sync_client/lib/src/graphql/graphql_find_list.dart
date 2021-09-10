part of cactus_graphql;

class GraphqlFindList<TModel> {
  const GraphqlFindList({required final this.json});
  final Map<String, dynamic> json;

  List<TModel?> get getItems =>
      (json.values.first['items'] ?? []) as List<TModel?>;
}

part of cactus_client_abstract;

abstract class GraphbackResultList<TModel> extends JsonSerializable {
  final List<TModel?> items;
  GraphbackResultList({
    required this.items,
  });
}

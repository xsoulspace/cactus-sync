part of cactus_abstract;

abstract class GraphbackResultList<TModel> extends JsonSerializable {
  GraphbackResultList({
    required final this.items,
  });
  final List<TModel?> items;
}

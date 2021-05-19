import 'package:graphql/client.dart';

abstract class GraphbackResultList<TModel> extends JsonSerializable {
  final List<TModel?> items;
  GraphbackResultList({
    required this.items,
  });
}

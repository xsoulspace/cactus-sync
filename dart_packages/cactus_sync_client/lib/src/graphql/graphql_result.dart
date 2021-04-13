import 'package:graphql/client.dart';

///Generic query result based on query result
class GraphqlResult extends QueryResult {
  GraphqlResult(
      {Map<String, dynamic>? data,
      required QueryResultSource? source,
      OperationException? exception})
      : super(
            source: source,
            context: const Context(),
            data: data,
            exception: exception);
}

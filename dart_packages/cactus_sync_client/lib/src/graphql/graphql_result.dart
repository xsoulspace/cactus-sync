import 'package:graphql/client.dart';

import '../utils/utils.dart';

///Generic query result based on query result
///
///to use typed data provide fromJson callback and generic TResult
class GraphqlResult<TResult> extends QueryResult {
  final FromJsonCallback<TResult> fromJsonCallback;

  GraphqlResult({
    Map<String, dynamic>? data,
    required QueryResultSource? source,
    OperationException? exception,
    required this.fromJsonCallback,
  }) : super(
          source: source,
          context: const Context(),
          data: data,
          exception: exception,
        );

  static GraphqlResult<TResult> fromQueryResult<TResult>({
    required QueryResult queryResult,
    required FromJsonCallback<TResult> fromJsonCallback,
  }) {
    return GraphqlResult<TResult>(
      fromJsonCallback: fromJsonCallback,
      source: queryResult.source,
      data: queryResult.data,
      exception: queryResult.exception,
    );
  }

  TResult? get typedData => fromJsonCallback(data);
}

import 'package:graphql/client.dart';

typedef FromJsonCallback(Map<String, dynamic>? json);

///Generic query result based on query result
///
///to use typed data provide fromJson callback and generic TResult
class GraphqlResult<TResult> extends QueryResult {
  final FromJsonCallback fromJsonCallback;
  GraphqlResult(
      {Map<String, dynamic>? data,
      required QueryResultSource? source,
      OperationException? exception,
      required this.fromJsonCallback})
      : super(
            source: source,
            context: const Context(),
            data: data,
            exception: exception);
  static fromQueryResult<TResult>(
      {required QueryResult queryResult,
      required FromJsonCallback fromJsonCallback}) {
    return GraphqlResult<TResult>(
        fromJsonCallback: fromJsonCallback,
        source: queryResult.source,
        data: queryResult.data,
        exception: queryResult.exception);
  }

  TResult? get typedData => fromJsonCallback(data) as TResult;
}

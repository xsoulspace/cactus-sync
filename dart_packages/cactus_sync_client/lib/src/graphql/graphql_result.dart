part of cactus_graphql;

///Generic query result based on query result
///
///to use typed data provide fromJson callback and generic TResult
class GraphqlResult<TResult> extends QueryResult {
  final FromJsonCallback<TResult> fromJsonCallback;

  GraphqlResult({
    final Map<String, dynamic>? data,
    required final QueryResultSource? source,
    final OperationException? exception,
    required this.fromJsonCallback,
  }) : super(
          source: source,
          context: const Context(),
          data: data,
          exception: exception,
        );

  static GraphqlResult<TResult> fromQueryResult<TResult>({
    required final QueryResult queryResult,
    required final FromJsonCallback<TResult> fromJsonCallback,
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

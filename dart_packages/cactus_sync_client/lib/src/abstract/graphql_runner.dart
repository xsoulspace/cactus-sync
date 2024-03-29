part of cactus_abstract;

/// This config required to init GraphqlRunner
/// Under the hood it uses default ferry with hive and hive_flutter setup
/// as described in [ferry setup](https://ferrygraphql.com/docs/setup)
///
/// You can provide a [hiveSubDir] - where the hive boxes should be stored.
@immutable
class GraphqlRunnerConfig {
  const GraphqlRunnerConfig({
    required final this.authLink,
    required final this.httpLink,
    final this.hiveSubDir,
    final this.defaultPolicies,
    final this.alwaysRebroadcast = false,
    final this.cache,
    final this.defaultFetchPolicy,
  });
  final String? hiveSubDir;
  final HttpLink httpLink;
  final AuthLink authLink;
  final bool alwaysRebroadcast;
  final DefaultPolicies? defaultPolicies;
  final GraphQLCache? cache;
  final FetchPolicy? defaultFetchPolicy;
}

///To init this class use `GraphqlRunner.init(...)`
///
///to use ValueNotifier & Provider use recommendations from Grapphql package:
///https://pub.dev/packages/graphql_flutter/versions/5.0.0-nullsafety.2
///
class GraphqlRunner {
  GraphqlRunner({
    required final this.client,
    required final this.clientNotifier,
    final this.defaultFetchPolicy = FetchPolicy.networkOnly,
  });
  GraphQLClient client;
  ValueNotifier<GraphQLClient> clientNotifier;
  FetchPolicy defaultFetchPolicy;

  static Future<GraphqlRunner> init({
    required final GraphqlRunnerConfig config,
  }) async {
    await initHiveForFlutter(subDir: config.hiveSubDir);

    final link = config.authLink.concat(config.httpLink);
    final client = GraphQLClient(
      link: link,
      cache: config.cache ??
          GraphQLCache(
            store: HiveStore(),
          ),
      alwaysRebroadcast: config.alwaysRebroadcast,
      defaultPolicies: config.defaultPolicies,
    );
    final clientNotifier = ValueNotifier(client);
    final runner =
        GraphqlRunner(client: client, clientNotifier: clientNotifier);

    return runner;
  }

  /// Method to call mutations and queries
  Future<GraphqlResult<TQueryResult>>
      execute<TVariables extends JsonSerializable, TQueryResult>({
    required final String query,
    required final TVariables variableValues,
    required final DefaultGqlOperationType operationType,
    required final FromJsonCallback<TQueryResult> fromJsonCallback,
  }) async {
    final document = gql_lang.parseString(query);
    CactusSync.l.info({
      'execute document': document,
      'operationType': operationType,
      'variableValues': variableValues,
    });
    final jsonVariableValues = variableValues.toJson();
    switch (operationType) {
      case DefaultGqlOperationType.create:
      case DefaultGqlOperationType.update:
      case DefaultGqlOperationType.remove:
        final queryResult = await client.mutate(
          MutationOptions(
            document: document,
            variables: {'input': jsonVariableValues},
          ),
        );
        return GraphqlResult.fromQueryResult<TQueryResult>(
          queryResult: queryResult,
          fromJsonCallback: fromJsonCallback,
        );
      case DefaultGqlOperationType.get:
      case DefaultGqlOperationType.find:
        final queryResult = await client.query(
          QueryOptions(
            document: document,
            variables: jsonVariableValues,
            fetchPolicy: defaultFetchPolicy,
          ),
        );
        return GraphqlResult.fromQueryResult<TQueryResult>(
          queryResult: queryResult,
          fromJsonCallback: fromJsonCallback,
        );
      case DefaultGqlOperationType.fromString:
        throw Exception(
          'DefaultGqlOperationType is fromString but '
          'has to be different',
        );
    }
  }
}

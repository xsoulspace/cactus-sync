import 'package:flutter/material.dart';
import 'package:gql/language.dart' as gql_lang;
import 'package:gql_http_link/gql_http_link.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../graphql/gql_builder.dart';
import '../graphql/graphql_result.dart';
import '../utils/utils.dart';

/// This config required to init GraphqlRunner
/// Under the hood it uses default ferry with hive and hive_flutter setup
/// as described in [ferry setup](https://ferrygraphql.com/docs/setup)
///
/// You can provide a [hiveSubDir] - where the hive boxes should be stored.
class GraphqlRunnerConfig {
  String? hiveSubDir;
  HttpLink httpLink;
  AuthLink authLink;
  bool alwaysRebroadcast;
  DefaultPolicies? defaultPolicies;
  GraphQLCache? cache;
  FetchPolicy? defaultFetchPolicy;
  GraphqlRunnerConfig(
      {this.hiveSubDir,
      required this.authLink,
      required this.httpLink,
      this.defaultPolicies,
      this.alwaysRebroadcast = false,
      this.cache,
      this.defaultFetchPolicy});
}

///To init this class use `GraphqlRunner.init(...)`
///
///to use ValueNotifier & Provider use recommendations from Grapphql package:
///https://pub.dev/packages/graphql_flutter/versions/5.0.0-nullsafety.2
///
class GraphqlRunner {
  GraphQLClient client;
  ValueNotifier<GraphQLClient> clientNotifier;
  FetchPolicy defaultFetchPolicy;
  GraphqlRunner({
    required this.client,
    required this.clientNotifier,
    this.defaultFetchPolicy = FetchPolicy.networkOnly,
  });

  static Future<GraphqlRunner> init(
      {required GraphqlRunnerConfig config}) async {
    await initHiveForFlutter(subDir: config.hiveSubDir);

    final link = config.authLink.concat(config.httpLink);
    final client = GraphQLClient(
        link: link,
        cache: config.cache ??
            GraphQLCache(
              store: HiveStore(),
            ),
        alwaysRebroadcast: config.alwaysRebroadcast,
        defaultPolicies: config.defaultPolicies);
    final clientNotifier = ValueNotifier(client);
    final runner =
        GraphqlRunner(client: client, clientNotifier: clientNotifier);

    return runner;
  }

  /// Method to call mutations and queries
  Future<GraphqlResult<TQueryResult>> execute<TVariables, TQueryResult>({
    required String query,
    required Map<String, dynamic> variableValues,
    required DefaultGqlOperationType operationType,
    required FromJsonCallback fromJsonCallback,
  }) async {
    final document = gql_lang.parseString(query);
    switch (operationType) {
      case DefaultGqlOperationType.create:
      case DefaultGqlOperationType.update:
      case DefaultGqlOperationType.remove:
        final queryResult = await client.mutate(
            MutationOptions(document: document, variables: variableValues));
        return GraphqlResult.fromQueryResult<TQueryResult>(
            queryResult: queryResult, fromJsonCallback: fromJsonCallback);
      case DefaultGqlOperationType.get:
      case DefaultGqlOperationType.find:
        final queryResult = await client.query(QueryOptions(
            document: document,
            variables: variableValues,
            fetchPolicy: defaultFetchPolicy));
        return GraphqlResult.fromQueryResult<TQueryResult>(
            queryResult: queryResult, fromJsonCallback: fromJsonCallback);
      case DefaultGqlOperationType.fromString:
        throw Exception('DefaultGqlOperationType is fromString but '
            'has to be different');
    }
  }
}

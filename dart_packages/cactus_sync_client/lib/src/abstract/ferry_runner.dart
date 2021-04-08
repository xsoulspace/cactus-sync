import 'package:ferry/ferry.dart';
import 'package:ferry_hive_store/ferry_hive_store.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../graphql/DefaultGqlOperations.dart';
/// This config required to init FerryRunner
/// Under the hood it uses default ferry with hive and hive_flutter setup
/// as described in [ferry setup](https://ferrygraphql.com/docs/setup)
///
/// You can provide a [hiveSubDir] - where the hive boxes should be stored.
class FerryRunnerConfig {
  String? hiveSubDir;
  Cache? cache;
  HttpLink httpLink;
  FetchPolicy defaultFetchPolicy;
  FerryRunnerConfig(
      {this.hiveSubDir,
      this.cache,
      required this.httpLink,
      this.defaultFetchPolicy = FetchPolicy.NetworkOnly});
}

///To init this class use `FerryRunner.init(...)`
class FerryRunner {
  FetchPolicy defaultFetchPolicy;
  Client client;
  FerryRunner({required this.defaultFetchPolicy, required this.client});

  static Future<FerryRunner> init({required FerryRunnerConfig config}) async {
    await Hive.initFlutter();

    var initCache = () async {
      final box = await Hive.openBox("graphql");
      final store = HiveStore(box);
      return Cache(store: store);
    };

    final cache = config.cache ?? await initCache();

    final link = config.httpLink;

    final client = Client(
      link: link,
      cache: cache,
    );

    var runner = FerryRunner(
        defaultFetchPolicy: config.defaultFetchPolicy, client: client);

    return runner;
  }


  execute<
    TType,
    TVariables,
    TResult
  >( { query, variableValues, operationType }: ApolloRunnerExecute<TVariables>) async{
    switch (operationType) {
      case DefaultGqlOperationType.create:
      case DefaultGqlOperationType.update:
      case DefaultGqlOperationType.remove:
        return await this.apollo.mutate<TResult, TVariables>({
          mutation: parse(query),
          variables: variableValues,
        })
      case DefaultGqlOperationType.get_:
      case DefaultGqlOperationType.find:
        return await this.apollo.query<TResult, TVariables>({
          query: parse(query),
          variables: variableValues,
          fetchPolicy: this.defaultFetchPolicy,
        })
    }
  }
}

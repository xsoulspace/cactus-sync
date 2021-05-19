import 'package:graphql/client.dart';

import '../graphql/gql_builder.dart';
import '../graphql/graphql_result.dart';
import '../utils/utils.dart';
import 'cactus_sync.dart';
import 'graphql_runner.dart';
import 'recorded_model.dart';

/// [stringQueryGql] is a gql which replaces the whole gql
/// TODO: add an example
/// [modelFragmentGql] is used to fill requested fields only in gql
/// TODO: add an example
class QueryGql {
  String? stringQueryGql;
  String? modelFragmentGql;
  QueryGql({this.stringQueryGql, this.modelFragmentGql});
}

typedef CactusModelBuilder<
        TModel,
        TCreateInput extends JsonSerializable,
        TCreateResult,
        TUpdateInput extends JsonSerializable,
        TUpdateResult,
        TDeleteInput extends JsonSerializable,
        TDeleteResult,
        TGetResult,
        TFindInput extends JsonSerializable,
        TFindResult>
    = CactusModel<
            TModel,
            TCreateInput,
            TCreateResult,
            TUpdateInput,
            TUpdateResult,
            TDeleteInput,
            TDeleteResult,
            TGetResult,
            TFindInput,
            TFindResult>
        Function({required CactusSync db});

/// Abstract Model class to insure consistency in CUDGF
abstract class AbstractCactusModel<
    TCreateInput,
    TCreateResult,
    TUpdateInput,
    TUpdateResult,
    TRemoveInput,
    TRemoveResult,
    TGetResult,
    TFindInput,
    TFindResult> {
  Future<GraphqlResult<TCreateResult>> create({
    required TCreateInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  });
  Future<GraphqlResult<TUpdateResult>> update({
    required TUpdateInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  });
  Future<GraphqlResult<TRemoveResult>> remove({
    required TRemoveInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  });
  Future<GraphqlResult<TGetResult>> get({
    required RecordedModel variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  });
  Future<GraphqlResult<TFindResult>> find({
    required TFindInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  });
}

class CactusModel<
        TType,
        TCreateInput extends JsonSerializable,
        TCreateResult,
        TUpdateInput extends JsonSerializable,
        TUpdateResult,
        TRemoveInput extends JsonSerializable,
        TRemoveResult,
        TGetResult,
        TFindInput extends JsonSerializable,
        TFindResult>
    implements
        AbstractCactusModel<
            TCreateInput,
            TCreateResult,
            TUpdateInput,
            TUpdateResult,
            TRemoveInput,
            TRemoveResult,
            TGetResult,
            TFindInput,
            TFindResult> {
  FromJsonCallback<TCreateResult> createFromJsonCallback;
  FromJsonCallback<TFindResult> findFromJsonCallback;
  FromJsonCallback<TGetResult> getFromJsonCallback;
  FromJsonCallback<TRemoveResult> removeFromJsonCallback;
  FromJsonCallback<TUpdateResult> updateFromJsonCallback;

  final CactusSync db;
  final String graphqlModelName;
  late final GqlBuilder gqlBuilder;
  final List<String?> graphqlModelFieldNames;
  final String defaultModelFragment;

  CactusModel({
    required this.createFromJsonCallback,
    required this.updateFromJsonCallback,
    required this.removeFromJsonCallback,
    required this.getFromJsonCallback,
    required this.findFromJsonCallback,
    required this.defaultModelFragment,
    required this.graphqlModelFieldNames,
    required this.graphqlModelName,
    required this.db,
  }) {
    gqlBuilder = GqlBuilder(
      modelName: graphqlModelName,
      modelFields: graphqlModelFieldNames,
      modelFragment: defaultModelFragment,
    );
  }
  static CactusModelBuilder<
      TModel,
      TCreateInput,
      TCreateResult,
      TUpdateInput,
      TUpdateResult,
      TDeleteInput,
      TDeleteResult,
      TGetResult,
      TFindInput,
      TFindResult> init<
          TModel,
          TCreateInput extends JsonSerializable,
          TCreateResult,
          TUpdateInput extends JsonSerializable,
          TUpdateResult,
          TDeleteInput extends JsonSerializable,
          TDeleteResult,
          TGetResult,
          TFindInput extends JsonSerializable,
          TFindResult>({
    required List<String?> graphqlModelFieldNames,
    required String graphqlModelName,
    required String defaultModelFragment,
    required FromJsonCallback<TCreateResult> createFromJsonCallback,
    required FromJsonCallback<TFindResult> findFromJsonCallback,
    required FromJsonCallback<TGetResult> getFromJsonCallback,
    required FromJsonCallback<TDeleteResult> removeFromJsonCallback,
    required FromJsonCallback<TUpdateResult> updateFromJsonCallback,
  }) =>
      ({required db}) => CactusModel(
            createFromJsonCallback: createFromJsonCallback,
            db: db,
            defaultModelFragment: defaultModelFragment,
            findFromJsonCallback: findFromJsonCallback,
            getFromJsonCallback: getFromJsonCallback,
            graphqlModelFieldNames: graphqlModelFieldNames,
            graphqlModelName: graphqlModelName,
            removeFromJsonCallback: removeFromJsonCallback,
            updateFromJsonCallback: updateFromJsonCallback,
          );

  FromJsonCallback<TQueryResult>
      _getFromJsonCallbackByOperationType<TQueryResult>({
    required DefaultGqlOperationType operationType,
  }) {
    final callback = (() {
      switch (operationType) {
        case DefaultGqlOperationType.create:
          return createFromJsonCallback;
        case DefaultGqlOperationType.update:
          return updateFromJsonCallback;
        case DefaultGqlOperationType.remove:
          return removeFromJsonCallback;
        case DefaultGqlOperationType.get:
          return getFromJsonCallback;
        case DefaultGqlOperationType.find:
          return findFromJsonCallback;
        case DefaultGqlOperationType.fromString:
          throw Exception('DefaultGqlOperationType is fromString but '
              'has to be different');
      }
    })();
    return callback as FromJsonCallback<TQueryResult>;
  }

  GraphqlRunner get _graphqlRunner => db.graphqlRunner;
  Future<GraphqlResult<TQueryResult>>
      _execute<TVariables extends JsonSerializable, TQueryResult>({
    required String query,
    required TVariables variableValues,
    required DefaultGqlOperationType operationType,
    required FromJsonCallback<TQueryResult> fromJsonCallback,
  }) async {
    CactusSync.l.info({
      'is graphqlRunner initialized': _graphqlRunner != null,
    });
    return _graphqlRunner.execute<TVariables, TQueryResult>(
      fromJsonCallback: fromJsonCallback,
      operationType: operationType,
      query: query,
      variableValues: variableValues,
    );
  }

  String _resolveOperationGql({
    required DefaultGqlOperationType operationType,
    QueryGql? queryGql,
  }) {
    final stringQueryGql = queryGql?.stringQueryGql;
    if (stringQueryGql != null && stringQueryGql.isNotEmpty) {
      return stringQueryGql;
    }
    final modelFragmentGql = queryGql?.modelFragmentGql;
    final builder = modelFragmentGql != null && modelFragmentGql.isNotEmpty
        ? GqlBuilder(
            modelName: graphqlModelName,
            modelFragment: modelFragmentGql,
          )
        : gqlBuilder;
    return builder.getByOperationType(operationType: operationType);
  }

  Future<GraphqlResult<TResult>>
      _executeMiddleware<TVariables extends JsonSerializable, TResult>({
    QueryGql? queryGql,
    required DefaultGqlOperationType operationType,
    bool notifyListeners = true,
    required TVariables variableValues,
  }) async {
    /**
     * If we receive modelFragmentGql, we concat it with default query
     * If we receive stringQueryGql we replace default by stringQueryGql
     * If class has default fragment it will be use it
     * And then it will be use default fields
     */
    final query = _resolveOperationGql(
      operationType: operationType,
      queryGql: queryGql,
    );
    final fromJsonCallback = _getFromJsonCallbackByOperationType<TResult>(
        operationType: operationType);
    CactusSync.l.info({
      "query": query,
      "jsonCallback": fromJsonCallback,
    });

    final result = await _execute<TVariables, TResult>(
      variableValues: variableValues,
      query: query,
      operationType: operationType,
      fromJsonCallback: fromJsonCallback,
    );

    CactusSync.l.info(result);

    /// STATE UPDATES
    return result;
    // TODO: enable sync for different states
    // if (!notifyListeners) return result;
    // var validateAndEmit = ({bool? remove}){
    //   var { isNotValid, data } = validateStateModelResult(result);
    //   if (isNotValid || data == null) return;
    //   for (var maybeModel of Object.values(data)) {
    //     notifyStateModelListeners({
    //       emitter: this.db.graphqlRunner.subscriptionsEmitter,
    //       remove: remove,
    //       item: maybeModel,
    //       notifyListeners,
    //       modelName: this.modelName,
    //     });
    //   }
    // }
    // switch (operationType) {
    //   case DefaultGqlOperationType.create:
    //   case DefaultGqlOperationType.update:
    //     validateAndEmit({});
    //     break
    //   case DefaultGqlOperationType.remove:
    //     validateAndEmit({ remove: true });
    //     break
    // }
    // return result;
  }

  @override
  Future<GraphqlResult<TCreateResult>> create({
    required TCreateInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    CactusSync.l.info('create');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.create,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }

  @override
  Future<GraphqlResult<TUpdateResult>> update({
    required TUpdateInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    CactusSync.l.info('update');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.update,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }

  @override
  Future<GraphqlResult<TRemoveResult>> remove({
    required TRemoveInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    CactusSync.l.info('remove');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.remove,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }

  @override
  Future<GraphqlResult<TFindResult>> find({
    required TFindInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    CactusSync.l.info('find');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.find,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }

  @override
  Future<GraphqlResult<TGetResult>> get({
    required RecordedModel variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    CactusSync.l.info('get');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.get,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }
}

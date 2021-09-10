import 'package:graphql/client.dart';

import '../graphql/gql_builder.dart';
import '../graphql/graphql_result.dart';
import '../utils/utils.dart';
import 'cactus_sync.dart';
import 'graphql_runner.dart';
import 'recorded_model.dart';

/// [stringQueryGql] is a gql which replaces the whole gql
// TODO(arenukvern): add an example
/// [modelFragmentGql] is used to fill requested fields only in gql
// TODO(arenukvern): add an example
class QueryGql {
  const QueryGql({
    final this.stringQueryGql,
    final this.modelFragmentGql,
  });
  final String? stringQueryGql;
  final String? modelFragmentGql;
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
    required final TCreateInput variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
  });
  Future<GraphqlResult<TUpdateResult>> update({
    required final TUpdateInput variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
  });
  Future<GraphqlResult<TRemoveResult>> remove({
    required final TRemoveInput variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
  });
  Future<GraphqlResult<TGetResult>> get({
    required final RecordedModel variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
  });
  Future<GraphqlResult<TFindResult>> find({
    required final TFindInput variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
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
  CactusModel({
    required final this.createFromJsonCallback,
    required final this.updateFromJsonCallback,
    required final this.removeFromJsonCallback,
    required final this.getFromJsonCallback,
    required final this.findFromJsonCallback,
    required final this.defaultModelFragment,
    required final this.graphqlModelFieldNames,
    required final this.graphqlModelName,
    required final this.db,
  }) {
    gqlBuilder = GqlBuilder(
      modelName: graphqlModelName,
      modelFields: graphqlModelFieldNames,
      modelFragment: defaultModelFragment,
    );
  }
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
    required final List<String?> graphqlModelFieldNames,
    required final String graphqlModelName,
    required final String defaultModelFragment,
    required final FromJsonCallback<TCreateResult> createFromJsonCallback,
    required final FromJsonCallback<TFindResult> findFromJsonCallback,
    required final FromJsonCallback<TGetResult> getFromJsonCallback,
    required final FromJsonCallback<TDeleteResult> removeFromJsonCallback,
    required final FromJsonCallback<TUpdateResult> updateFromJsonCallback,
  }) =>
      ({required final db}) => CactusModel(
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
    required final DefaultGqlOperationType operationType,
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
          throw Exception(
            'DefaultGqlOperationType is fromString but '
            'has to be different',
          );
      }
    })();
    return callback as FromJsonCallback<TQueryResult>;
  }

  GraphqlRunner? get _graphqlRunner => db.graphqlRunner;
  Future<GraphqlResult<TQueryResult>>
      _execute<TVariables extends JsonSerializable, TQueryResult>({
    required final String query,
    required final TVariables variableValues,
    required final DefaultGqlOperationType operationType,
    required final FromJsonCallback<TQueryResult> fromJsonCallback,
  }) async {
    final resolvedGraphqlRunner = _graphqlRunner;
    if (resolvedGraphqlRunner == null) {
      throw ArgumentError.notNull('_graphqlRunner');
    }
    CactusSync.l.info({'is graphqlRunner initialized'});
    return resolvedGraphqlRunner.execute<TVariables, TQueryResult>(
      fromJsonCallback: fromJsonCallback,
      operationType: operationType,
      query: query,
      variableValues: variableValues,
    );
  }

  String _resolveOperationGql({
    required final DefaultGqlOperationType operationType,
    final QueryGql? queryGql,
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
    required final DefaultGqlOperationType operationType,
    required final TVariables variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
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
      operationType: operationType,
    );
    CactusSync.l.info({
      'query': query,
      'jsonCallback': fromJsonCallback,
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
    required final TCreateInput variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
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
    required final TUpdateInput variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
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
    required final TRemoveInput variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
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
    required final TFindInput variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
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
    required final RecordedModel variableValues,
    final QueryGql? queryGql,
    final bool notifyListeners = true,
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

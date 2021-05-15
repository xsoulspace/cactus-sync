import '../graphql/gql_builder.dart';
import '../graphql/graphql_result.dart';
import '../utils/utils.dart';
import 'cactus_sync.dart';
import 'graphql_runner.dart';

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
        TCreateInput,
        TCreateResult,
        TUpdateInput,
        TUpdateResult,
        TDeleteInput,
        TDeleteResult,
        TGetInput,
        TGetResult,
        TFindInput,
        TFindResult>
    = CactusModel<
            TModel,
            TCreateInput,
            TCreateResult,
            TUpdateInput,
            TUpdateResult,
            TDeleteInput,
            TDeleteResult,
            TGetInput,
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
    TGetInput,
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
    required TGetInput variableValues,
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
        TCreateInput,
        TCreateResult,
        TUpdateInput,
        TUpdateResult,
        TRemoveInput,
        TRemoveResult,
        TGetInput,
        TGetResult,
        TFindInput,
        TFindResult>
    implements
        AbstractCactusModel<
            TCreateInput,
            TCreateResult,
            TUpdateInput,
            TUpdateResult,
            TRemoveInput,
            TRemoveResult,
            TGetInput,
            TGetResult,
            TFindInput,
            TFindResult> {
  FromJsonCallback<TType> createFromJsonCallback;
  FromJsonCallback<TType> updateFromJsonCallback;
  FromJsonCallback<TType> removeFromJsonCallback;
  FromJsonCallback<TType> getFromJsonCallback;
  FromJsonCallback<TType> findFromJsonCallback;

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
      TGetInput,
      TGetResult,
      TFindInput,
      TFindResult> init<
          TModel,
          TCreateInput,
          TCreateResult,
          TUpdateInput,
          TUpdateResult,
          TDeleteInput,
          TDeleteResult,
          TGetInput,
          TGetResult,
          TFindInput,
          TFindResult>({
    required List<String?> graphqlModelFieldNames,
    required String graphqlModelName,
    required String defaultModelFragment,
    required FromJsonCallback<TModel> createFromJsonCallback,
    required FromJsonCallback<TModel> findFromJsonCallback,
    required FromJsonCallback<TModel> getFromJsonCallback,
    required FromJsonCallback<TModel> removeFromJsonCallback,
    required FromJsonCallback<TModel> updateFromJsonCallback,
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

  FromJsonCallback<TType> _getFromJsonCallbackByOperationType({
    required DefaultGqlOperationType operationType,
  }) {
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
  }

  GraphqlRunner get _graphqlRunner => db.graphqlRunner;
  Future<GraphqlResult<TQueryResult>> _execute<TVariables, TQueryResult>({
    required String query,
    required Map<String, dynamic> variableValues,
    required DefaultGqlOperationType operationType,
    required FromJsonCallback<TType> fromJsonCallback,
  }) async =>
      _graphqlRunner.execute<TVariables, TQueryResult>(
        fromJsonCallback: fromJsonCallback,
        operationType: operationType,
        query: query,
        variableValues: variableValues,
      );

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

  Future<GraphqlResult<TResult>> _executeMiddleware<TVariables, TResult>({
    QueryGql? queryGql,
    required DefaultGqlOperationType operationType,
    bool notifyListeners = true,
    variableValues,
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

    CactusSync.l.info(query);

    final result = await _execute<TVariables, TResult>(
      variableValues: variableValues,
      query: query,
      operationType: operationType,
      fromJsonCallback:
          _getFromJsonCallbackByOperationType(operationType: operationType),
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
  create({
    required variableValues,
    queryGql,
    notifyListeners = true,
  }) {
    CactusSync.l.info('create');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.create,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }

  @override
  update({
    required variableValues,
    queryGql,
    notifyListeners = true,
  }) {
    CactusSync.l.info('update');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.create,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }

  @override
  remove({
    required variableValues,
    queryGql,
    notifyListeners = true,
  }) {
    CactusSync.l.info('remove');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.create,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }

  @override
  find({
    required variableValues,
    queryGql,
    notifyListeners = true,
  }) {
    CactusSync.l.info('find');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.create,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }

  @override
  get({
    required variableValues,
    queryGql,
    notifyListeners = true,
  }) {
    CactusSync.l.info('get');
    return _executeMiddleware(
      operationType: DefaultGqlOperationType.create,
      queryGql: queryGql,
      notifyListeners: notifyListeners,
      variableValues: variableValues,
    );
  }
}

import 'package:cactus_sync_client/src/abstract/cactus_sync.dart';
import 'package:cactus_sync_client/src/abstract/graphql_runner.dart';
import 'package:cactus_sync_client/src/graphql/gql_builder.dart';
import 'package:cactus_sync_client/src/graphql/graphql_result.dart';
import "package:gql/schema.dart" as gql_schema;

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
    = CactusModel Function({required CactusSync db});

/// Abstract Model class to insure consistency in CUDGF
abstract class _AbstractModel<
    TCreateInput,
    TCreateResult,
    TUpdateResult,
    TUpdateInput,
    TRemoveResult,
    TRemoveInput,
    TGetResult,
    TGetInput,
    TFindResult,
    TFindInput> {
  GraphqlResult<TCreateResult> create(
      {required TCreateInput variableValues,
      QueryGql? queryGql,
      bool? notifyListeners});
  GraphqlResult<TUpdateResult> update(
      {required TUpdateInput variableValues,
      QueryGql? queryGql,
      bool? notifyListeners});
  GraphqlResult<TRemoveResult> remove(
      {required TRemoveInput variableValues,
      QueryGql? queryGql,
      bool? notifyListeners});
  GraphqlResult<TGetResult> get(
      {required TGetInput variableValues,
      QueryGql? queryGql,
      bool? notifyListeners});
  GraphqlResult<TFindResult> find(
      {required TFindInput variableValues,
      QueryGql? queryGql,
      bool? notifyListeners});
}

class CactusModel<
        TType,
        TCreateInput,
        TCreateResult,
        TUpdateResult,
        TUpdateInput,
        TRemoveResult,
        TRemoveInput,
        TGetResult,
        TGetInput,
        TFindResult,
        TFindInput>
    implements
        _AbstractModel<
            TCreateInput,
            TCreateResult,
            TUpdateResult,
            TUpdateInput,
            TRemoveResult,
            TRemoveInput,
            TGetResult,
            TGetInput,
            TFindResult,
            TFindInput> {
  FromJsonCallback createFromJsonCallback;
  FromJsonCallback updateFromJsonCallback;
  FromJsonCallback removeFromJsonCallback;
  FromJsonCallback getFromJsonCallback;
  FromJsonCallback findFromJsonCallback;

  CactusSync db;
  late String modelName;
  late GqlBuilder gqlBuilder;
  gql_schema.ObjectTypeDefinition graphqlModelType;
  String defaultModelFragment;

  CactusModel({
    required this.createFromJsonCallback,
    required this.updateFromJsonCallback,
    required this.removeFromJsonCallback,
    required this.getFromJsonCallback,
    required this.findFromJsonCallback,
    required this.defaultModelFragment,
    required this.graphqlModelType,
    required this.db,
  }) {
    var maybeModelName = graphqlModelType.name;
    if (maybeModelName == null) throw ArgumentError.notNull('Model name');
    modelName = maybeModelName;
    var fields = graphqlModelType.fields;
    var modelFields = this._getModelFieldNames(fields);
    gqlBuilder = GqlBuilder(
        modelName: modelName,
        modelFields: modelFields,
        modelFragment: defaultModelFragment);
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
    required gql_schema.ObjectTypeDefinition graphqlModelType,
    required String defaultModelFragment,
    required FromJsonCallback createFromJsonCallback,
    required FromJsonCallback findFromJsonCallback,
    required FromJsonCallback getFromJsonCallback,
    required FromJsonCallback removeFromJsonCallback,
    required FromJsonCallback updateFromJsonCallback,
  }) =>
      ({required db}) => CactusModel(
          createFromJsonCallback: createFromJsonCallback,
          db: db,
          defaultModelFragment: defaultModelFragment,
          findFromJsonCallback: findFromJsonCallback,
          getFromJsonCallback: getFromJsonCallback,
          graphqlModelType: graphqlModelType,
          removeFromJsonCallback: removeFromJsonCallback,
          updateFromJsonCallback: updateFromJsonCallback);

  /// We will remove any relationships by default for safety
  /// User anyway in anytime may call it with custom gql
  /// the idea is to get names of queired fields
  List<String?> _getModelFieldNames(List<gql_schema.FieldDefinition> fields) {
    var fieldsNames = fields
        .where((el) =>
            el.description?.contains('manyToOne') != true ||
            el.description?.contains('oneToMany') != true ||
            el.description?.contains('oneToOne') != true)
        .map((el) => el.name)
        .where((element) => element != null);
    return fieldsNames.toList();
  }

  FromJsonCallback _getFromJsonCallbackByOperationType(
      {required DefaultGqlOperationType operationType}) {
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
  Future<GraphqlResult<TQueryResult>> _execute<TVariables, TQueryResult>(
          {required String query,
          required Map<String, dynamic> variableValues,
          required DefaultGqlOperationType operationType,
          required FromJsonCallback fromJsonCallback}) async =>
      await _graphqlRunner.execute<TVariables, TQueryResult>(
          fromJsonCallback: fromJsonCallback,
          operationType: operationType,
          query: query,
          variableValues: variableValues);

  String _resolveOperationGql({
    required DefaultGqlOperationType operationType,
    QueryGql? queryGql,
  }) {
    var stringQueryGql = queryGql?.stringQueryGql;
    if (stringQueryGql != null) return stringQueryGql;
    var modelFragmentGql = queryGql?.modelFragmentGql;
    var builder = modelFragmentGql != null
        ? GqlBuilder(
            modelName: modelName,
            modelFragment: modelFragmentGql,
          )
        : gqlBuilder;
    return builder.getByOperationType(operationType: operationType);
  }

  _executeMiddleware<TVariables, TResult>(
      {QueryGql? queryGql,
      required DefaultGqlOperationType operationType,
      bool? notifyListeners,
      variableValues}) async {
    /**
     * If we receive modelFragmentGql, we concat it with default query
     * If we receive stringQueryGql we replace default by stringQueryGql
     * If class has default fragment it will be use it
     * And then it will be use default fields
     */
    var query =
        _resolveOperationGql(operationType: operationType, queryGql: queryGql);
    var result = await _execute<TVariables, TResult>(
      variableValues: variableValues,
      query: query,
      operationType: operationType,
      fromJsonCallback:
          _getFromJsonCallbackByOperationType(operationType: operationType),
    );

    /// STATE UPDATES

    if (notifyListeners == null || notifyListeners == false) return result;
    // TODO: enable sync for different states
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
  create({required variableValues, queryGql, notifyListeners}) {
    return _executeMiddleware(
        operationType: DefaultGqlOperationType.create,
        queryGql: queryGql,
        notifyListeners: notifyListeners,
        variableValues: variableValues);
  }

  @override
  update({required variableValues, queryGql, notifyListeners}) {
    return _executeMiddleware(
        operationType: DefaultGqlOperationType.create,
        queryGql: queryGql,
        notifyListeners: notifyListeners,
        variableValues: variableValues);
  }

  @override
  remove({required variableValues, queryGql, notifyListeners}) {
    return _executeMiddleware(
        operationType: DefaultGqlOperationType.create,
        queryGql: queryGql,
        notifyListeners: notifyListeners,
        variableValues: variableValues);
  }

  @override
  find({required variableValues, queryGql, notifyListeners}) {
    return _executeMiddleware(
        operationType: DefaultGqlOperationType.create,
        queryGql: queryGql,
        notifyListeners: notifyListeners,
        variableValues: variableValues);
  }

  @override
  get({required variableValues, queryGql, notifyListeners}) {
    return _executeMiddleware(
        operationType: DefaultGqlOperationType.create,
        queryGql: queryGql,
        notifyListeners: notifyListeners,
        variableValues: variableValues);
  }
}

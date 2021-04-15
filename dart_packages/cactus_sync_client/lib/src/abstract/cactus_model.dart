import 'package:cactus_sync_client/src/abstract/cactus_sync.dart';
import 'package:cactus_sync_client/src/abstract/graphql_runner.dart';
import 'package:cactus_sync_client/src/graphql/gql_builder.dart';
import 'package:cactus_sync_client/src/graphql/graphql_result.dart';
import 'package:gql/ast.dart';
import "package:gql/schema.dart" as gql_schema;

class OperationFunctionGql {
  String? stringGql;
  DocumentNode? fragmentGql;
  OperationFunctionGql({this.stringGql, this.fragmentGql})
      : assert(stringGql != null && fragmentGql != null);
}

typedef OperationFunction<TInput, TResult> = GraphqlResult<TResult> Function(
    {required TInput input, OperationFunctionGql? gql, bool? notifyListeners});

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
      {required TCreateInput input,
      OperationFunctionGql? gql,
      bool? notifyListeners});
  GraphqlResult<TUpdateResult> update(
      {required TUpdateInput input,
      OperationFunctionGql? gql,
      bool? notifyListeners});
  GraphqlResult<TRemoveResult> remove(
      {required TRemoveInput input,
      OperationFunctionGql? gql,
      bool? notifyListeners});
  GraphqlResult<TGetResult> get(
      {required TGetInput input,
      OperationFunctionGql? gql,
      bool? notifyListeners});
  GraphqlResult<TFindResult> find(
      {required TFindInput input,
      OperationFunctionGql? gql,
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
  gql_schema.TypeDefinition graphqlModelType;
  String defaultModelFragment;
  CactusModel(
      {required this.createFromJsonCallback,
      required this.updateFromJsonCallback,
      required this.removeFromJsonCallback,
      required this.getFromJsonCallback,
      required this.findFromJsonCallback,
      required this.defaultModelFragment,
      required this.graphqlModelType,
      required this.db,
      }) {
    var maybeModelName = graphqlModelType.name;
    if(maybeModelName == null) throw ArgumentError.notNull('Model name');
    modelName = maybeModelName;
    // TODO: 
    var fields = graphqlModelType.getFields();
    if (fields == null)
      throw Exception('no fields defined for ${graphqlModelType.name} model');
    // TODO: 
    var modelFields = this._getModelFieldNames(fields);
    gqlBuilder = GqlBuilder(
        modelName: modelName,
        modelFields: modelFields,
        modelFragment: defaultModelFragment);
  }

  /// We will remove any relationships by default for safety
  /// User anyway in anytime may call it with custom gql
  /// TODO: the idea is get names of queired fields
  _getModelFieldNames(DocumentNode fields) {
    //  var schema = gql_schema.GraphQLSchema.fromNode(fields);
    //   schema.query?.fields.removeWhere((el) =>
    //       el.description?.includes('manyToOne') ||
    //       el.description?.includes('oneToMany') ||
    //       el.description?.includes('oneToOne'));
    //   nodes.map((el) => el.name);
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
  GraphqlRunner get _graphqlRunner=>db.graphqlRunner;
 Future<GraphqlResult<TQueryResult>> _execute<TVariables, TQueryResult>(
    {
required DocumentNode query, required Map<String, dynamic> variableValues, required DefaultGqlOperationType operationType, required dynamic Function(Map<String, dynamic>?) fromJsonCallback
    }
  ) async => await _graphqlRunner.execute<TVariables, TQueryResult>(fromJsonCallback: fromJsonCallback,operationType:operationType ,query:query 
  ,variableValues: variableValues);
  

  _resolveOperationGql(
   {
 required DefaultGqlOperationType  operationType,
  DocumentNode?  fragmentGql,
   String? stringGql}
  ) {
    if (stringGql != null) return stringGql;
    var fragment = fragmentGql ?? defaultModelFragment;
    
    if (fragment) {
      return getDefaultGqlOperations({
        modelName: this.modelName,
        modelFragment: fragment,
      })[operationType]
    }
    return this._defaultGqlOperations[operationType];
  }

   _executeMiddleware<TInput, TResult>({
    String? fragmentGql,
    String? stringGql, 
    required DefaultGqlOperationType operationType,
    bool?  notifyListeners,
    variableValues
  }) async{
    /**
     * If we receive fragmentGql, we concat it with default query
     * If we receive stringGql we replace default by stringGql
     * If class has default fragment it will be use it
     * And then it will be use default fields
     */
    var query =_resolveOperationGql(
      operationType: operationType,
      fragmentGql: fragmentGql,
      stringGql: stringGql,
    );
    var result = await _execute<TInput, TResult>(
      variableValues: variableValues,
     query: query,
      operationType: operationType,fromJsonCallback: _getFromJsonCallbackByOperationType(operationType: operationType),
    );

    /// STATE UDPATES

    if (notifyListeners == null || notifyListeners == false) return result;
    var validateAndEmit = ({bool? remove}){
      var { isNotValid, data } = validateStateModelResult(result);
      // console.log({ isNotValid, data })
      if (isNotValid || data == null) return;
      for (var maybeModel of Object.values(data)) {
        notifyStateModelListeners({
          emitter: this.db.graphqlRunner.subscriptionsEmitter,
          remove: remove,
          item: maybeModel,
          notifyListeners,
          modelName: this.modelName,
        });
      }
    }
    switch (operationType) {
      case DefaultGqlOperationType.create:
      case DefaultGqlOperationType.update:
        validateAndEmit({});
        break
      case DefaultGqlOperationType.remove:
        validateAndEmit({ remove: true });
        break
    }
    return result;
  }
  @override
  create({required input, OperationFunctionGql? gql, bool? notifyListeners}) {
    var fromJsonCallback = _getFromJsonCallbackByOperationType(
        operationType: DefaultGqlOperationType.create);
    
    return GraphqlResult(data: ,exception: ,source: source, fromJsonCallback: fromJsonCallback);
  }

  @override
  update({required input, OperationFunctionGql? gql, bool? notifyListeners}) {
    var fromJsonCallback = _getFromJsonCallbackByOperationType(
        operationType: DefaultGqlOperationType.update);
    // TODO: implement
    return GraphqlResult(source: source, fromJsonCallback: fromJsonCallback);
  }

  @override
  remove({required input, OperationFunctionGql? gql, bool? notifyListeners}) {
    var fromJsonCallback = _getFromJsonCallbackByOperationType(
        operationType: DefaultGqlOperationType.remove);
    // TODO: implement
    return GraphqlResult(source: source, fromJsonCallback: fromJsonCallback);
  }

  @override
  find({required input, OperationFunctionGql? gql, bool? notifyListeners}) {
    var fromJsonCallback = _getFromJsonCallbackByOperationType(
        operationType: DefaultGqlOperationType.find);
    // TODO: implement
    return GraphqlResult(source: source, fromJsonCallback: fromJsonCallback);
  }

  @override
  get({required input, OperationFunctionGql? gql, bool? notifyListeners}) {
    var fromJsonCallback = _getFromJsonCallbackByOperationType(
        operationType: DefaultGqlOperationType.get);
    // TODO: implement
    return GraphqlResult(source: source, fromJsonCallback: fromJsonCallback);
  }
}

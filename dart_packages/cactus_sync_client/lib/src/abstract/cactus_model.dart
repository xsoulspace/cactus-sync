import 'package:cactus_sync_client/src/graphql/gql_builder.dart';
import 'package:cactus_sync_client/src/graphql/graphql_result.dart';
import 'package:gql/ast.dart';

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

  CactusModel(
      {required this.createFromJsonCallback,
      required this.updateFromJsonCallback,
      required this.removeFromJsonCallback,
      required this.getFromJsonCallback,
      required this.findFromJsonCallback});

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

  @override
  create({required input, OperationFunctionGql? gql, bool? notifyListeners}) {
    var fromJsonCallback = _getFromJsonCallbackByOperationType(
        operationType: DefaultGqlOperationType.create);
    // TODO: implement
    return GraphqlResult(source: source, fromJsonCallback: fromJsonCallback);
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

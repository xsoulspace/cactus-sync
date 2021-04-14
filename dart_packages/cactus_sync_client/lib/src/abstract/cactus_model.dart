import 'package:cactus_sync_client/src/graphql/DefaultGqlOperations.dart';
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

abstract class _AbstractModel {
  late final OperationFunction create;
  late final OperationFunction update;
  late final OperationFunction remove;
  late final OperationFunction get;
  late final OperationFunction find;
}

class CactusModel<TType, TInput> implements _AbstractModel {
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
  late final OperationFunction create = (
      {required TInput input,
      OperationFunctionGql? gql,
      bool? notifyListeners}) {
    var fromJsonCallback = _getFromJsonCallbackByOperationType(
        operationType: DefaultGqlOperationType.create);
  };

  @override
  late final OperationFunction find;

  @override
  late final OperationFunction get;

  @override
  late final OperationFunction remove;

  @override
  late final OperationFunction update;
}

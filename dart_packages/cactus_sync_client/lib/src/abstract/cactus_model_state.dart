import '../graphql/graphql_result.dart';
import 'cactus_model.dart';
import 'cactus_sync.dart';
import 'graphback_result_list.dart';
import 'serializable_model.dart';

enum StateModelEvents { addUpdateStateModel, removeStateModel }

class StateModelValidationResult<TData> {
  final bool isValid;
  final bool isNotValid;
  final TData data;
  StateModelValidationResult({
    required this.isValid,
    required this.isNotValid,
    required this.data,
  });
}

/// Every response model should contain method getList to get
/// items from `{ findSomething: { items: [] } }`
/// ANd also model should keep original json Map
///
class CactusModelState<
        TModel,
        TCreateInput extends SerializableModel,
        TCreateResult,
        TUpdateInput extends SerializableModel,
        TUpdateResult,
        TDeleteInput extends SerializableModel,
        TDeleteResult,
        TGetInput extends SerializableModel,
        TGetResult,
        TFindInput extends SerializableModel,
        TFindResult>
    extends AbstractCactusModel<
        TCreateInput,
        TCreateResult,
        TUpdateInput,
        TUpdateResult,
        TDeleteInput,
        TDeleteResult,
        TGetInput,
        TGetResult,
        TFindInput,
        TFindResult> {
  StateModelValidationResult<GraphqlResult<TResult>>
      validateStateModelResult<TResult>({
    required GraphqlResult<TResult> result,
  }) {
    final notValidResult = StateModelValidationResult<GraphqlResult<TResult>>(
      isNotValid: true,
      isValid: false,
      data: result,
    );
    if (result.hasException) return notValidResult;
    final data = result.typedData;
    if (data == null) return notValidResult;
    return StateModelValidationResult<GraphqlResult<TResult>>(
      isNotValid: false,
      isValid: true,
      data: result,
    );
  }

  final Set<TModel?> list = {};
  void setState(List<TModel?> value) {
    list
      ..clear()
      ..addAll(value);
  }

  CactusModel<
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
      TFindResult> cactusModel;
  CactusModelState({
    required this.cactusModel,
  }) {
    // TODO: implement listeners
    // _initSubscriptionListener();
    // _listenOtherStatesChanges();
  }

  /// ================== STATE CHANGES HANDLERS ======================
  /// Used only for find  method.
  /// Will clean up state and refill it
  /// with new data
  void _updateStateList<TResult>({
    required GraphqlResult<TResult> result,
    bool? notifyListeners,
  }) {
    final validatedResult = validateStateModelResult(result: result);
    if (validatedResult.isNotValid) return;
    final maybeData = validatedResult.data.typedData;
    if (maybeData == null) {
      CactusSync.l.warning('the model is null, state will not updated');
      return;
    }

    if (maybeData is GraphbackResultList) {
      CactusSync.l.fine({
        'maybeData is GraphbackResultList': maybeData is GraphbackResultList,
      });
      setState(maybeData.items as List<TModel?>);
      return;
    }
    CactusSync.l.warning(
      'the data has unknown type ${maybeData.runtimeType} '
      ', state will not updated',
    );
  }

  /// notifyListeners should notify all states for this model about
  /// new/updated/removed item
  ///
  /// should not be used with subscribed events
  void _updateStateModel<TResult>({
    required GraphqlResult<TResult> result,
    bool? remove,
    bool? notifyListeners,
  }) {
    final validatedResult = validateStateModelResult(result: result);
    if (validatedResult.isNotValid) return;
    final maybeModel = validatedResult.data.typedData;
    if (maybeModel is TModel) {
      final isItemExists = list.contains(maybeModel);
      if (remove == true) {
        if (isItemExists) list.remove(maybeModel);
      } else {
        list.add(maybeModel);
      }
      return;
    }

    CactusSync.l.warning('the model is null, state will not updated');
    // TODO: implement notify
    // notifyStateModelListeners(
    //   notifyListeners,
    //   modelName: this.modelName,
    //   item: maybeModel,
    //   emitter: _emitter,
    //   remove,
    // )
  }

  String get modelName => cactusModel.graphqlModelName;

  bool _verifyModelName({required String? name}) => name == modelName;

  /// ==================== PUBLIC SECTION ======================
  ///
  @override
  Future<GraphqlResult<TCreateResult>> create({
    required TCreateInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    final result = await cactusModel.create(
      variableValues: variableValues,
      notifyListeners: notifyListeners,
      queryGql: queryGql,
    );

    _updateStateModel(
      result: result,
      notifyListeners: true,
    );
    return result;
  }

  @override
  Future<GraphqlResult<TUpdateResult>> update({
    required TUpdateInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    final result = await cactusModel.update(
      variableValues: variableValues,
      notifyListeners: notifyListeners,
      queryGql: queryGql,
    );
    _updateStateModel(
      result: result,
      notifyListeners: true,
    );
    return result;
  }

  @override
  Future<GraphqlResult<TDeleteResult>> remove({
    required TDeleteInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    final result = await cactusModel.remove(
      variableValues: variableValues,
      notifyListeners: notifyListeners,
      queryGql: queryGql,
    );
    _updateStateModel(
      result: result,
      notifyListeners: true,
      remove: true,
    );
    return result;
  }

  @override
  Future<GraphqlResult<TFindResult>> find({
    required TFindInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    final result = await cactusModel.find(
      variableValues: variableValues,
      notifyListeners: notifyListeners,
      queryGql: queryGql,
    );
    CactusSync.l.info('find recevied result');
    _updateStateList(
      result: result,
    );
    return result;
  }

  @override
  Future<GraphqlResult<TGetResult>> get({
    required TGetInput variableValues,
    QueryGql? queryGql,
    bool notifyListeners = true,
  }) async {
    final result = await cactusModel.get(
      variableValues: variableValues,
      notifyListeners: notifyListeners,
      queryGql: queryGql,
    );
    _updateStateModel(
      result: result,
      notifyListeners: notifyListeners,
    );
    return result;
  }

  //  ===================== SUBSCRIPTIONS SECTION ========================
  // TODO: implement SUBSCRIPTIONS SECTION
  ///
  /// This function is responsible for listening changes
  /// in another states and should be initialized in constuctor
  ///
  // void _listenOtherStatesChanges() {}
  // final Stream<StateModelEvents> emitter = Stream<StateModelEvents>.empty();
  // List _subscriptions = [];

  // void _initSubscriptionListener() {}

  // void _subscribe() {}
  // void _unsubscribe() {}
  // void _updateOnSubscribe<TResult>({required TResult data}) {}

  // String _getSubscribeOperationType({required String str}) {}

  // void notifyStateModelListeners<TModel>(
  //     {required String modelName,
  //     required bool notifyListeners,
  //     required TModel item,
  //     required bool? remove}) {
  //   // if (notifyListeners) {
  //   //   const obj: StateModelChange<TModel> = {
  //   //     modelName: modelName,
  //   //     item,
  //   //   }
  //   //   const eventType = remove
  //   //     ? StateModelEvents.removeStateModel
  //   //     : StateModelEvents.addUpdateStateModel
  //   //   emitter.emit(eventType, obj)
  //   // }
  // }
}

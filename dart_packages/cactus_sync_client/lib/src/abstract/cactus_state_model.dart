import '../graphql/graphql_find_list.dart';
import '../graphql/graphql_result.dart';
import 'cactus_model.dart';

enum StateModelEvents { addUpdateStateModel, removeStateModel }

class StateModelValidationResult<TData> {
  final bool isValid;
  final bool isNotValid;
  final TData data;
  StateModelValidationResult(
      {required this.isValid, required this.isNotValid, required this.data});
}

/// Every response model should contain method getList to get
/// items from `{ findSomething: { items: [] } }`
/// ANd also model should keep original json Map
///
class CactusStateModel<
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
      validateStateModelResult<TResult>(
          {required GraphqlResult<TResult> result}) {
    var notValidResult = StateModelValidationResult<GraphqlResult<TResult>>(
        isNotValid: true, isValid: false, data: result);
    if (result.hasException) return notValidResult;
    var data = result.typedData;
    if (data == null) return notValidResult;
    return StateModelValidationResult<GraphqlResult<TResult>>(
        isNotValid: false, isValid: true, data: result);
  }

  final List<TModel?> list = [];
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
  CactusStateModel({
    required this.cactusModel,
  }) {
    // TODO: implement listeners
    // _initSubscriptionListener();
    // _listenOtherStatesChanges();
  }

  /// ================== STATE CHANGES HANDLERS ======================

  void _updateState<TResult>({
    required GraphqlResult<TResult> result,
    bool? remove,
    bool? notifyListeners,
  }) {
    var validatedResult = validateStateModelResult(result: result);
    if (validatedResult.isNotValid) return;
    var maybeData = validatedResult.data.typedData ?? [];
    if (maybeData is List)
      for (TModel? maybeModel in maybeData) {
        _updateStateModel(
            maybeModel: maybeModel,
            remove: remove,
            notifyListeners: notifyListeners);
      }
    else
      throw ArgumentError(
          'The data should have type List but has type ${maybeData.runtimeType}');
  }

  /// notifyListeners should notify all states for this model about
  /// new/updated/removed item
  ///
  /// should not be used with subscribed events
  _updateStateModel({TModel? maybeModel, bool? remove, bool? notifyListeners}) {
    if (maybeModel == null) return;
    var index = list.indexOf(maybeModel);
    var isIndexExists = index >= 0;
    if (remove == true) if (isIndexExists)
      list.removeAt(index);
    else if (isIndexExists)
      list[index] = maybeModel;
    else
      list.add(maybeModel);

    // TODO: implement notify
    // notifyStateModelListeners(
    //   notifyListeners,
    //   modelName: this.modelName,
    //   item: maybeModel,
    //   emitter: _emitter,
    //   remove,
    // )
  }

  String get modelName => cactusModel.modelName;

  bool _verifyModelName({required String? name}) => name == modelName;

  /// This function must be used only with queires and not mutations!
  /// The purpose is to update a whole state
  void _updateListState<TResult>({required GraphqlResult<TResult> result}) {
    var validatedResult = validateStateModelResult(result: result);
    var data = validatedResult.data.typedData;
    if (validatedResult.isNotValid ||
        data == null ||
        data is! GraphqlFindList<TModel>) return;
    var items = data.getValues;
    if (items.length == 0) return;
    setState(items);
  }

  /// ==================== PUBLIC SECTION ======================
  ///
  @override
  Future<GraphqlResult<TCreateResult>> create(
      {required TCreateInput variableValues,
      QueryGql? queryGql,
      bool? notifyListeners}) async {
    var result = await cactusModel.create(
        variableValues: variableValues,
        notifyListeners: notifyListeners,
        queryGql: queryGql);
    _updateState(result: result, notifyListeners: true);
    return result;
  }

  @override
  Future<GraphqlResult<TUpdateInput>> update(
      {required TUpdateResult variableValues,
      QueryGql? queryGql,
      bool? notifyListeners}) async {
    var result = await cactusModel.update(
        variableValues: variableValues,
        notifyListeners: notifyListeners,
        queryGql: queryGql);
    _updateState(result: result, notifyListeners: true);
    return result;
  }

  @override
  Future<GraphqlResult<TDeleteInput>> remove(
      {required TDeleteResult variableValues,
      QueryGql? queryGql,
      bool? notifyListeners}) async {
    var result = await cactusModel.remove(
        variableValues: variableValues,
        notifyListeners: notifyListeners,
        queryGql: queryGql);
    _updateState(result: result, notifyListeners: true);
    return result;
  }

  @override
  Future<GraphqlResult<TFindInput>> find(
      {required TFindResult variableValues,
      QueryGql? queryGql,
      bool? notifyListeners}) async {
    var result = await cactusModel.find(
        variableValues: variableValues,
        notifyListeners: notifyListeners,
        queryGql: queryGql);
    _updateListState(
      result: result,
    );
    return result;
  }

  @override
  Future<GraphqlResult<TGetInput>> get(
      {required TGetResult variableValues,
      QueryGql? queryGql,
      bool? notifyListeners}) async {
    var result = await cactusModel.get(
        variableValues: variableValues,
        notifyListeners: notifyListeners,
        queryGql: queryGql);
    _updateListState(
      result: result,
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

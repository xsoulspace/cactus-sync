part of cactus_abstract;

enum StateModelEvents { addUpdateStateModel, removeStateModel }

@immutable
class StateModelValidationResult<TData> {
  const StateModelValidationResult({
    required final this.isValid,
    required final this.isNotValid,
    required final this.data,
  });
  final bool isValid;
  final bool isNotValid;
  final TData data;
}

/// Every response model should contain method getList to get
/// items from `{ findSomething: { items: [] } }`
/// ANd also model should keep original json Map
///
class CactusModelState<
        TModel,
        TCreateInput extends JsonSerializable,
        TCreateResult,
        TUpdateInput extends JsonSerializable,
        TUpdateResult,
        TDeleteInput extends JsonSerializable,
        TDeleteResult,
        TGetResult,
        TFindInput extends JsonSerializable,
        TFindResult> extends StateNotifier<Set<TModel?>>
    implements
        AbstractCactusModel<
            TCreateInput,
            TCreateResult,
            TUpdateInput,
            TUpdateResult,
            TDeleteInput,
            TDeleteResult,
            TGetResult,
            TFindInput,
            TFindResult> {
  CactusModelState({
    required final this.cactusModel,
  }) : super({}) {
    // _listenOtherStatesChanges();
    _subscribeToChanges();
  }
  void _subscribeToChanges() {
    cactusModel.db.emitter.source
      ..on<CactusResetStateEvent>().listen((final _) => resetState())
      // in case if it is possible to make many states , then we need to remove
      // or make optional this listen
      ..on<CactusAddEvent>().listen((final event) {
        if (event.modelName == modelName) {
          _updateStateModel(
            result: event.result,
            notifyListeners: false,
          );
        }
      })
      ..on<CactusUpdateEvent>().listen((final event) {
        if (event.modelName == modelName) {
          _updateStateModel(
            result: event.result,
            notifyListeners: false,
          );
        }
      })
      ..on<CactusRemoveEvent>().listen((final event) {
        if (event.modelName == modelName) {
          _updateStateModel(
            result: event.result,
            notifyListeners: false,
            remove: true,
          );
        }
      });
  }

  StateModelValidationResult<GraphqlResult<TResult>>
      validateStateModelResult<TResult>({
    required final GraphqlResult<TResult> result,
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

  void setState(final Iterable<TModel?> value) {
    state = value.toSet();
  }

  void resetState() => setState({});

  CactusModel<
      TModel,
      TCreateInput,
      TCreateResult,
      TUpdateInput,
      TUpdateResult,
      TDeleteInput,
      TDeleteResult,
      TGetResult,
      TFindInput,
      TFindResult> cactusModel;

  /// ================== STATE CHANGES HANDLERS ======================
  /// Used only for find  method.
  /// Will clean up state and refill it
  /// with new data
  void _updateStateList<TResult>({
    required final GraphqlResult<TResult> result,
    final bool? notifyListeners,
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
    required final GraphqlResult<TResult> result,
    final bool? remove,
    final bool? notifyListeners,
  }) {
    final validatedResult = validateStateModelResult(result: result);
    if (validatedResult.isNotValid) return;
    final maybeModel = validatedResult.data.typedData;
    if (maybeModel is TModel) {
      final newState = {...state};
      if (remove == true) {
        newState.remove(maybeModel);
      } else {
        newState.add(maybeModel);
      }
      setState(newState);
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

  bool _verifyModelName({required final String? name}) => name == modelName;

  /// ==================== PUBLIC SECTION ======================
  ///
  @override
  Future<GraphqlResult<TCreateResult>> create({
    required final TCreateInput variableValues,
    final QueryGql? queryGql,
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
    required final TUpdateInput variableValues,
    final QueryGql? queryGql,
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
    required final TDeleteInput variableValues,
    final QueryGql? queryGql,
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
    required final TFindInput variableValues,
    final QueryGql? queryGql,
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
    required final RecordedModel variableValues,
    final QueryGql? queryGql,
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

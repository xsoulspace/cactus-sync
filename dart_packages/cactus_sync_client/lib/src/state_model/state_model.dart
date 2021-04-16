import 'package:cactus_sync_client/src/abstract/cactus_model.dart';

abstract class StateModel<TModel,
    TCreateInput,
    TCreateResult,
    TUpdateInput,
    TUpdateResult,
    TDeleteInput,
    TDeleteResult,
    TGetInput,
    TGetResult,
    TFindInput,
    TFindResult> extends AbstractCactusModel<
    TCreateInput,
    TCreateResult,
    TUpdateInput,
    TUpdateResult,
    TDeleteInput,
    TDeleteResult,
    TGetInput,
    TGetResult,
    TFindInput,
    TFindResult>{
  List<TModel?> _reactiveState;
  void _setReactiveState(List<TModel?>value);
 List<TModel?> get state;
  Map<String, int>  get stateIndexes;
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
    TFindResult
  > cactusModel;
  StateModel({
    required this.cactusModel,
  }) {
    _initSubscriptionListener();
    _listenOtherStatesChanges();
  }

  /// ================== STATE CHANGES HANDLERS ======================

  void _updateState<TResult>({
    remove,
    result,
    notifyListeners,
  }: {
    result: FetchResult<TResult> | ApolloQueryResult<TResult>
    remove?: Maybe<boolean>
    notifyListeners?: Maybe<boolean>
  }) ;
  
  /**
   * notifyListeners should notify all states for this model about
   * new/updated/removed item
   *
   * should not be used with subscribed events
   * @param param0
   * @returns
   */
  _updateStateModel({
    remove,
    maybeModel,
    notifyListeners,
  }: {
    maybeModel: Maybe<TModel>
    remove?: Maybe<boolean>
    notifyListeners?: Maybe<boolean>
  });
 String? get modelName;
    
  bool _verifyModelName(
    {required String? modelName}
  ) ;
  /**
   * This function is responsible for listening changes
   * in another states and should be initialized in constuctor
   */
  void _listenOtherStatesChanges() ;
 void _updateListState<TResult>(
   FetchResult<TResult> | ApolloQueryResult<TResult> result
  ) ;

  /// =================== PUBLIC OPERATIONS ========================

  List<TModel> get list;

  //  ===================== SUBSCRIPTIONS SECTION ========================
  // 
  List _subscriptions = [];
  
  get _emitter;
  void _initSubscriptionListener();

  void _subscribe();
  void _unsubscribe();
  void _updateOnSubscribe<TResult>({required TResult data});
  
  
  String _getSubscribeOperationType(
    {required String str}
  );
}

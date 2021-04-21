import 'package:cactus_sync_client/src/abstract/cactus_model.dart';
import 'package:cactus_sync_client/src/graphql/graphql_result.dart';
import 'package:riverpod/riverpod.dart';

 enum StateModelEvents {
  addUpdateStateModel = 'addUpdateStateModel',
  removeStateModel = 'removeStateModel',
}

class StateModelValidationResult<TData>{
  final bool isValid;
  final bool isNotValid;
  final TData data;
  StateModelValidationResult({required this.isValid, required this.isNotValid, required this.data});
}


class StateModel<TModel,
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

StateModelValidationResult<GraphqlResult<TResult>> validateStateModelResult<TResult>  (
  {required GraphqlResult<TResult> result}
) {
  var notValidResult = StateModelValidationResult<GraphqlResult<TResult>>(isNotValid: true, isValid: false, data: result);
  if (result.hasException) return notValidResult;
  var data = result.typedData;
  if(data == null) return notValidResult;
  return StateModelValidationResult<GraphqlResult<TResult>>(isNotValid: false, isValid: true, data: result);}

void notifyStateModelListeners <TModel>( {
 required String modelName,
required  bool notifyListeners,
 required  TModel item,
 required bool? remove
}) {
  // if (notifyListeners) {
  //   const obj: StateModelChange<TModel> = {
  //     modelName: modelName,
  //     item,
  //   }
  //   const eventType = remove
  //     ? StateModelEvents.removeStateModel
  //     : StateModelEvents.addUpdateStateModel
  //   emitter.emit(eventType, obj)
  // }
}

  final List<TModel?> list = [];
  void setState(List<TModel?>value){
    list.clear();
    list..addAll(value);
  } 
  Map<int, TModel?>  get stateIndexes => list.asMap();
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
   
 required  GraphqlResult<TResult> result,
  bool?  remove,
 bool?   notifyListeners,
  }){} 
  
  /**
   * notifyListeners should notify all states for this model about
   * new/updated/removed item
   *
   * should not be used with subscribed events
   * @param param0
   * @returns
   */
  _updateStateModel({
   TModel? maybeModel,
   bool? remove,
   bool? notifyListeners
  }){}
 String? get modelName=>"";
    
  bool _verifyModelName(
    {required String? modelName}
  ){} 
  /**
   * This function is responsible for listening changes
   * in another states and should be initialized in constuctor
   */
  void _listenOtherStatesChanges() {}
 void _updateListState<TResult>(
    {required GraphqlResult<TResult> result}
  ){} 

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

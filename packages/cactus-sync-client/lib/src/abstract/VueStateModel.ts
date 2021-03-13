import { ApolloQueryResult, FetchResult } from '@apollo/client/core'
import { computed, reactive } from 'vue'
import { SubscribeGqlOperationType } from '../graphql'
import { ApolloRunnerEvents } from './ApolloRunner'
import { Maybe } from './BasicTypes'
import {
  CactusModel,
  OperationFunction,
  QueryOperationFunction,
} from './CactusModel'
import {
  notifyStateModelListeners,
  StateModelChange,
  StateModelEvents,
  validateStateModelResult,
} from './StateModel'

/**
 * State management for Vue
 * When you use any of add, update, remove, find, get
 * This will update inner reactive state
 *
 * If you need just Model to access to methods use hooks generation or CactusModel
 */
export class VueStateModel<
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
> {
  private _reactiveState: Maybe<TModel>[] = reactive([])
  private _setReactiveState(value: Maybe<TModel>[]) {
    this._reactiveState.length = 0
    this._reactiveState.push(...value)
  }
  get state() {
    return computed(() => this._reactiveState)
  }
  get stateIndexes() {
    const map: Map<string, number> = new Map()
    for (let i = 0; i < this.state.value.length; i++) {
      const el = this.state.value[i]
      if (el) {
        const id = el['id']
        map.set(id, i)
      }
    }
    return map
  }
  protected _cactusModel: CactusModel<
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
  >
  constructor({
    cactusModel,
  }: {
    cactusModel: CactusModel<
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
    >
  }) {
    this._cactusModel = cactusModel
    this._initSubscriptionListener()
    this._listenOtherStatesChanges()
  }

  /// ================== STATE CHANGES HANDLERS ======================

  protected _updateState<TResult>({
    remove,
    result,
    notifyListeners,
  }: {
    result: FetchResult<TResult> | ApolloQueryResult<TResult>
    remove?: Maybe<boolean>
    notifyListeners?: Maybe<boolean>
  }) {
    const { isNotValid, data } = validateStateModelResult(result)
    if (isNotValid || data == null) return
    for (const maybeModel of Object.values(data)) {
      this._updateStateModel({ maybeModel, remove, notifyListeners })
    }
  }
  /**
   * notifyListeners should notify all states for this model about
   * new/updated/removed item
   *
   * should not be used with subscribed events
   * @param param0
   * @returns
   */
  protected _updateStateModel({
    remove,
    maybeModel,
    notifyListeners,
  }: {
    maybeModel: Maybe<TModel>
    remove?: Maybe<boolean>
    notifyListeners?: Maybe<boolean>
  }) {
    if (maybeModel == null) return
    const id = maybeModel['id']
    const index = this.stateIndexes.get(id)
    if (remove && index != null) {
      this._reactiveState.splice(index, 1)
    }
    if (!remove) {
      if (index != null) {
        this._reactiveState.splice(index, 1, maybeModel)
      } else {
        this._reactiveState.push(maybeModel)
      }
    }
    notifyStateModelListeners({
      notifyListeners,
      modelName: this.modelName,
      item: maybeModel,
      emitter: this._emitter,
      remove,
    })
  }
  get modelName() {
    return this._cactusModel.modelName
  }
  protected _verifyModelName(
    modelName: Maybe<string>
  ): { isVerified: boolean } {
    const isVerified = modelName == this.modelName
    return { isVerified }
  }
  /**
   * This function is responsible for listening changes
   * in another states and should be initialized in constuctor
   */
  protected _listenOtherStatesChanges() {
    const handleEvent = ({
      remove,
      obj,
    }: {
      obj: Maybe<StateModelChange<TModel>>
      remove?: Maybe<boolean>
    }) => {
      const { isVerified } = this._verifyModelName(obj?.modelName)
      if (isVerified) {
        const maybeModel = obj?.item
        if (maybeModel) {
          this._updateStateModel({
            maybeModel,
            remove,
          })
        }
      }
    }
    this._emitter.on(
      StateModelEvents.removeStateModel,
      (obj: Maybe<StateModelChange<TModel>>) =>
        handleEvent({ obj, remove: true })
    )
    this._emitter.on(
      StateModelEvents.addUpdateStateModel,
      (obj: Maybe<StateModelChange<TModel>>) => handleEvent({ obj })
    )
  }
  protected _updateListState<TResult>(
    result: FetchResult<TResult> | ApolloQueryResult<TResult>
  ) {
    const { isNotValid, data } = validateStateModelResult(result)
    if (isNotValid || data == null) return
    for (const findModels of Object.values(data)) {
      if (findModels == null) continue
      const items = findModels['items']
      if (items) {
        this._setReactiveState(items)
        return
      }
    }
  }

  /// =================== PUBLIC OPERATIONS ========================

  add: OperationFunction<TCreateInput, TCreateResult> = async (input, gql) => {
    const result = await this._cactusModel.add(input, gql, false)
    this._updateState({ result, notifyListeners: true })
    return result
  }
  update: OperationFunction<TUpdateInput, TUpdateResult> = async (
    input,
    gql
  ) => {
    const result = await this._cactusModel.update(input, gql, false)
    this._updateState({ result, notifyListeners: true })
    return result
  }
  remove: OperationFunction<TDeleteInput, TDeleteResult> = async (
    input,
    gql
  ) => {
    const result = await this._cactusModel.remove(input, gql, false)
    this._updateState({ result, remove: true, notifyListeners: true })
    return result
  }
  get: OperationFunction<TGetInput, TGetResult> = async (input, gql) => {
    const result = await this._cactusModel.get(input, gql)
    this._updateState({ result })
    return result
  }
  find: QueryOperationFunction<TModel, TFindInput, TFindResult> = async (
    input,
    gql
  ) => {
    const result = await this._cactusModel.find(input, gql)
    this._updateListState(result)
    return result
  }
  get list() {
    return this._reactiveState
  }

  //  ===================== SUBSCRIPTIONS SECTION ========================

  protected _subscriptions: ZenObservable.Subscription[] = []
  /**
   * This function listen when subscription begins and ends
   * for model. Should be called in constructor
   */
  protected get _emitter() {
    return this._cactusModel.db.graphqlRunner.subscriptionsEmitter
  }
  protected _initSubscriptionListener() {
    this._emitter.on(
      ApolloRunnerEvents.subscribeModelName,
      (maybeModelName) => {
        const { isVerified } = this._verifyModelName(maybeModelName)
        if (isVerified) this._subscribe()
      }
    )
    this._emitter.on(
      ApolloRunnerEvents.unsubscirbeModelName,
      (maybeModelName) => {
        const { isVerified } = this._verifyModelName(maybeModelName)
        if (isVerified) this._unsubscribe()
      }
    )
  }

  protected _subscribe() {
    const subscriptionsFns = this._cactusModel.graphqlSubscriptions
    for (const subscriptionFn of subscriptionsFns) {
      if (subscriptionFn == null) continue
      const subscription = subscriptionFn({
        next: (fetchResult) => {
          console.log('get result from subscription', { fetchResult })
          const { data, isNotValid } = validateStateModelResult(fetchResult)
          if (isNotValid || data == null) return
          this._updateOnSubscribe({
            data,
          })
        },
      })

      this._subscriptions.push(subscription)
    }
    console.log('subscribed', { subs: this._subscriptions })
  }
  protected _unsubscribe() {
    for (const subscription of this._subscriptions) {
      subscription.unsubscribe()
    }
    this._subscriptions.length = 0
    console.log('unsubscribed', { subs: this._subscriptions })
  }
  protected _updateOnSubscribe({
    data,
  }: {
    data: TCreateResult | TUpdateResult | TDeleteResult
  }) {
    console.log('Vue state model - _updateOnSubscribe', { data })

    for (const [operationName, maybeModel] of Object.entries(data)) {
      const maybeOperationType = this._getSubscribeOperationType(operationName)
      console.log('Vue state model - _updateOnSubscribe.maybeOperationType', {
        maybeOperationType,
        maybeModel,
      })
      if (maybeOperationType && maybeModel) {
        switch (maybeOperationType) {
          case SubscribeGqlOperationType.subscribeNew:
          case SubscribeGqlOperationType.subscribeUpdated:
            this._updateStateModel({ maybeModel })
            break
          case SubscribeGqlOperationType.subscribeDeleted:
            this._updateStateModel({ maybeModel, remove: true })
            break
        }
      }
    }
  }
  protected _getSubscribeOperationType(
    str: string
  ): Maybe<SubscribeGqlOperationType> {
    switch (true) {
      case str.startsWith('new'):
        return SubscribeGqlOperationType.subscribeNew
      case str.startsWith('updated'):
        return SubscribeGqlOperationType.subscribeUpdated
      case str.startsWith('deleted'):
        return SubscribeGqlOperationType.subscribeDeleted
      default:
        return null
    }
  }
}

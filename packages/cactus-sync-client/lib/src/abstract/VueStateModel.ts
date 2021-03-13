import { ApolloQueryResult, FetchResult, Observable } from '@apollo/client/core'
import { computed, reactive } from 'vue'
import { SubscribeGqlOperationType } from '../graphql'
import { Maybe } from './BasicTypes'
import {
  CactusModel,
  OperationFunction,
  QueryOperationFunction,
} from './CactusModel'

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
    this._subscribeToSubscribes()
  }
  protected _validateResult<TResult>(
    result: FetchResult<TResult> | ApolloQueryResult<TResult>
  ): { isNotValid: boolean; data?: Maybe<TResult> } {
    if (result.errors != null) return { isNotValid: true }
    const data = result.data
    if (typeof data != 'object') return { isNotValid: true }
    return { isNotValid: false, data }
  }
  protected _updateState<TResult>({
    remove,
    result,
  }: {
    result: FetchResult<TResult> | ApolloQueryResult<TResult>
    remove?: Maybe<boolean>
  }) {
    const { isNotValid, data } = this._validateResult(result)
    if (isNotValid || data == null) return
    for (const maybeModel of Object.values(data)) {
      this._updateStateModel({ maybeModel, remove })
    }
  }
  protected _updateStateModel({
    remove,
    maybeModel,
  }: {
    maybeModel: Maybe<TModel>
    remove?: Maybe<boolean>
  }) {
    if (maybeModel == null) return
    const id = maybeModel['id']
    const index = this.stateIndexes.get(id)
    if (index != null) {
      remove
        ? this._reactiveState.splice(index, 1)
        : this._reactiveState.splice(index, 1, maybeModel)
    } else {
      this._reactiveState.push(maybeModel)
    }
  }

  protected _updateListState<TResult>(
    result: FetchResult<TResult> | ApolloQueryResult<TResult>
  ) {
    const { isNotValid, data } = this._validateResult(result)
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
  add: OperationFunction<TCreateInput, TCreateResult> = async (input, gql) => {
    const result = await this._cactusModel.add(input, gql)
    this._updateState({ result })
    return result
  }
  update: OperationFunction<TUpdateInput, TUpdateResult> = async (
    input,
    gql
  ) => {
    const result = await this._cactusModel.update(input, gql)
    this._updateState({ result })
    return result
  }
  remove: OperationFunction<TDeleteInput, TDeleteResult> = async (
    input,
    gql
  ) => {
    const result = await this._cactusModel.remove(input, gql)
    this._updateState({ result, remove: true })
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
  protected _subscribeToSubscribes() {
    Observable.from(this._cactusModel.graphqlSubscriptions).subscribe({
      next: (subscription) => {
        if (subscription == null) {
          // TODO: how to remove subscription?
          return
        }
        subscription({
          next: (fetchResult) => {
            const { data, isNotValid } = this._validateResult(fetchResult)
            if (isNotValid || data == null) return
            this._updateOnSubscribe({
              data,
            })
          },
        })
      },
    })
  }
  protected _updateOnSubscribe({
    data,
  }: {
    data: TCreateResult | TUpdateResult | TDeleteResult
  }) {
    for (const [operationName, maybeModel] of Object.entries(data)) {
      const maybeOperationType = this._getSubscribeOperationType(operationName)
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

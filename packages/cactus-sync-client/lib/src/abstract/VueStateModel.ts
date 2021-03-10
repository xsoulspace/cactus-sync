import { ExecutionResult, Maybe } from 'graphql-tools'
import { Ref, ref } from 'vue'
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
  TFindResult,
  TPageRequest,
  TOrderByInput
> {
  protected _state: Ref<Maybe<TModel>[]> = ref([])
  protected get _stateIndexes() {
    const map: Map<string, number> = new Map()
    for (let i = 0; i < this._state.value.length; i++) {
      const el = this._state.value[i]
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
    TFindResult,
    TPageRequest,
    TOrderByInput
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
      TFindResult,
      TPageRequest,
      TOrderByInput
    >
  }) {
    this._cactusModel = cactusModel
  }
  protected _validateResult<TResult>(
    result: ExecutionResult<TResult>
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
    result: ExecutionResult<TResult>
    remove?: Maybe<boolean>
  }) {
    const { isNotValid, data } = this._validateResult(result)
    if (isNotValid || data == null) return
    for (const model of Object.values(data)) {
      if (model == null) continue
      const id = model['id']
      const index = this._stateIndexes.get(id)
      if (index != null) {
        remove
          ? this._state.value.splice(index, 1)
          : this._state.value.splice(index, 1, model)
      } else {
        this._state.value.push(model)
      }
    }
  }

  protected _updateListState<TResult>(result: ExecutionResult<TResult>) {
    const { isNotValid, data } = this._validateResult(result)
    if (isNotValid || data == null) return
    for (const findModels of Object.values(data)) {
      if (findModels == null) continue
      const items = findModels['items']
      this._state.value = items
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
  find: QueryOperationFunction<
    TFindInput,
    TFindResult,
    TPageRequest,
    TOrderByInput
  > = async (input, gql) => {
    const result = await this._cactusModel.find(input, gql)
    this._updateListState(result)
    return result
  }
  get list() {
    return this._state.value
  }
  set list(value: Maybe<TModel>[]) {
    this._state.value = value
  }
}
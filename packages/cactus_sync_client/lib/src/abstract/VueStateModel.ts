import { Maybe } from 'graphql-tools'
import { Ref, ref } from 'vue'
import { CactusModel } from './CactusModel'

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
  add = async (input, gql) => {
    this._cactusModel.add(input, gql)
  }
  update = async (input, gql) => {
    this._cactusModel.update(input, gql)
  }
  remove = async (input, gql) => {
    this._cactusModel.remove(input, gql)
  }
  get = async (input, gql) => {
    this._cactusModel.get(input, gql)
  }
  find = async (input, gql) => {
    this._cactusModel.find(input, gql)
  }
}

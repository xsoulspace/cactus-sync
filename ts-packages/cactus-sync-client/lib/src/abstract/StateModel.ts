import { ApolloQueryResult, FetchResult } from '@apollo/client/core'
import { Emitter } from 'mitt'
import { Maybe } from './BasicTypes'

export enum StateModelEvents {
  addUpdateStateModel = 'addUpdateStateModel',
  removeStateModel = 'removeStateModel',
}

export type StateModelChange<TModel> = {
  modelName: string
  item: TModel
}
export const validateStateModelResult = <TResult>(
  result: FetchResult<TResult> | ApolloQueryResult<TResult>
): { isNotValid: boolean; data?: Maybe<TResult>; isValid: boolean } => {
  if (result.errors != null) return { isNotValid: true, isValid: false }
  const data = result.data
  if (typeof data != 'object') return { isNotValid: true, isValid: false }
  return { isNotValid: false, data, isValid: true }
}
export const notifyStateModelListeners = <TModel>({
  remove,
  emitter,
  item,
  modelName,
  notifyListeners,
}: {
  modelName: string
  notifyListeners: Maybe<boolean>
  item: TModel
  remove?: Maybe<boolean>
  emitter: Emitter
}) => {
  if (notifyListeners) {
    const obj: StateModelChange<TModel> = {
      modelName: modelName,
      item,
    }
    const eventType = remove
      ? StateModelEvents.removeStateModel
      : StateModelEvents.addUpdateStateModel
    emitter.emit(eventType, obj)
  }
}

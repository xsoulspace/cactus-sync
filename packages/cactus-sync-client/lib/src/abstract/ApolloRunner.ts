import {
  ApolloClient,
  ApolloClientOptions,
  FetchPolicy,
  FetchResult,
  ObservableSubscription,
  Observer,
  OperationVariables,
} from '@apollo/client/core'
import Dexie from 'dexie'
import { GraphQLSchema, parse } from 'graphql'
import mitt from 'mitt'
import { DefaultGqlOperationType } from '../graphql'
import { Maybe } from './BasicTypes'
import { CactusModel } from './CactusModel'
import { ModelNameReplicationI } from './CactusSync'

export enum ApolloRunnerEvents {
  subscribeModelName = 'subscribeModelName',
  unsubscirbeModelName = 'unsubscirbeModelName',
}

export type ApolloRunnerExecute<TVariables extends OperationVariables> = {
  query: string
  variableValues?: TVariables
  operationType: Exclude<
    DefaultGqlOperationType,
    'subscribeNew' | 'subscribeUpdated' | 'subscribeDeleted'
  >
}
interface ApolloRunnerSubscribes extends ModelNameReplicationI {
  queries: string[]
}
interface ApolloRunnerI<TCacheShape> {
  apollo: ApolloClient<TCacheShape>
  schema: GraphQLSchema
  defaultFetchPolicy?: Maybe<FetchPolicy>
}
interface ApolloRunnerInitI<TCacheShape> {
  db: Dexie
  options: ApolloClientOptions<TCacheShape>
  schema: GraphQLSchema
  defaultFetchPolicy?: Maybe<FetchPolicy>
}

export type ApolloSubscription<TModel = any> = {
  (
    observer: Observer<
      FetchResult<TModel, Record<string, TModel>, Record<string, any>>
    >
  ): ObservableSubscription
  (
    onNext: (
      value: FetchResult<TModel, Record<string, TModel>, Record<string, any>>
    ) => void,
    onError?: ((error: any) => void) | undefined,
    onComplete?: (() => void) | undefined
  ): ObservableSubscription
}

/**
 * To initialize `ApolloRunner` use
 * `ApolloRunner.init(...)`
 */
export class ApolloRunner<TCacheShape> {
  schema: GraphQLSchema
  apollo: ApolloClient<TCacheShape>
  defaultFetchPolicy: FetchPolicy
  constructor({
    schema,
    apollo,
    defaultFetchPolicy,
  }: ApolloRunnerI<TCacheShape>) {
    this.apollo = apollo
    this.schema = schema
    this.defaultFetchPolicy = defaultFetchPolicy ?? 'network-only'
  }
  static init<TCacheShape>({
    options,
    schema,
  }: ApolloRunnerInitI<TCacheShape>) {
    const apollo = new ApolloClient(options)

    return new ApolloRunner({ apollo, schema })
  }

  async execute<
    TType,
    TVariables = OperationVariables,
    TResult = Maybe<TType>
  >({ query, variableValues, operationType }: ApolloRunnerExecute<TVariables>) {
    switch (operationType) {
      case DefaultGqlOperationType.create:
      case DefaultGqlOperationType.update:
      case DefaultGqlOperationType.remove:
        return await this.apollo.mutate<TResult, TVariables>({
          mutation: parse(query),
          variables: variableValues,
        })
      case DefaultGqlOperationType.get:
      case DefaultGqlOperationType.find:
        return await this.apollo.query<TResult, TVariables>({
          query: parse(query),
          variables: variableValues,
          fetchPolicy: this.defaultFetchPolicy,
        })
    }
  }
  modelSubscriptions: Map<
    CactusModel['modelName'],
    ApolloSubscription[]
  > = new Map()
  subscriptionsEmitter = mitt()

  getModelSubscriptions({ modelName }: ModelNameReplicationI) {
    return this.modelSubscriptions.get(modelName) ?? []
  }
  setModelSubscriptions({
    modelName,
    subscriptions,
  }: {
    modelName: CactusModel['modelName']
    subscriptions: ApolloSubscription[]
  }) {
    this.modelSubscriptions.set(modelName, subscriptions)
  }
  subscribe({ queries, modelName }: ApolloRunnerSubscribes) {
    try {
      const subscriptions = this.modelSubscriptions.get(modelName) ?? []

      if (subscriptions.length > 0) {
        // unsubscribe first
        this.unsubscribe({ modelName })
        // cleanup
        subscriptions.length = 0
      }
      for (const query of queries) {
        const subscripton = this.apollo.subscribe({ query: parse(query) })
        subscriptions.push(subscripton.subscribe)
        console.log('Apollo Runner - subscribe', { modelName, subscriptions })
      }
      /** Notifing all states about new subscriptions */
      this.subscriptionsEmitter.emit(
        ApolloRunnerEvents.subscribeModelName,
        modelName
      )
      this.setModelSubscriptions({ subscriptions, modelName })
      console.log({ emit: `subscribed ${modelName}`, subscriptions })
    } catch (error) {
      console.error(error)
    }
  }
  unsubscribe({ modelName }: ModelNameReplicationI) {
    /** Notifing all states about to cancel subscriptions */
    console.log({ emit: `unsubscribed ${modelName}` })
    this.subscriptionsEmitter.emit(
      ApolloRunnerEvents.unsubscirbeModelName,
      modelName
    )
    this.setModelSubscriptions({ modelName, subscriptions: [] })
  }
}

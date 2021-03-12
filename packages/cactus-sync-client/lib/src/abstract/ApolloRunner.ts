import {
  ApolloClient,
  ApolloClientOptions,
  OperationVariables,
} from '@apollo/client/core'
import Dexie from 'dexie'
import { GraphQLSchema, parse } from 'graphql'
import { DefautlGqlOperationType } from '../graphql'
import { Maybe } from './BasicTypes'
export type ApolloRunnerExecute<TVariables extends OperationVariables> = {
  query: string
  variableValues?: TVariables
  operationType: DefautlGqlOperationType
}

interface ApolloRunnerI<TCacheShape> {
  apollo: ApolloClient<TCacheShape>
  schema: GraphQLSchema
}
interface ApolloRunnerInitI<TCacheShape> {
  db: Dexie
  options: ApolloClientOptions<TCacheShape>
  schema: GraphQLSchema
}
/**
 * To initialize `ApolloRunner` use
 * `ApolloRunner.init(...)`
 */
export class ApolloRunner<TCacheShape> {
  schema: GraphQLSchema
  apollo: ApolloClient<TCacheShape>
  constructor({ schema, apollo }: ApolloRunnerI<TCacheShape>) {
    this.apollo = apollo
    this.schema = schema
  }
  static async init<TCacheShape>({
    db,
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
      case DefautlGqlOperationType.create:
      case DefautlGqlOperationType.update:
      case DefautlGqlOperationType.remove:
        return await this.apollo.mutate<TResult, TVariables>({
          mutation: parse(query),
          variables: variableValues,
        })
      case DefautlGqlOperationType.get:
      case DefautlGqlOperationType.find:
        return await this.apollo.query<TResult, TVariables>({
          query: parse(query),
          variables: variableValues,
        })
    }
  }
}

import { GraphbackContext } from '@graphback/core'
import { GraphQLResolveInfo } from 'graphql'
import { ExpressContext } from 'apollo-server-express'

export enum ECactusOperationType {
  CREATE = 'create',
  DELETE = 'delete',
  UPDATE = 'update',
}

export declare type IGraphQLCall<Type = any> = (
  data: Type,
  context?: GraphbackContext,
  info?: GraphQLResolveInfo
) => Promise<Type>

export declare type ICactusCallback<
  TSource = any,
  TContext = GraphbackContext,
  TArgs = any,
  TInfo = GraphQLResolveInfo
> = (
  _: TSource,
  args: TArgs,
  context: TContext,
  info: TInfo,
  type: ECactusOperationType
) => Promise<ExpressContext>

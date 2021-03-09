import { GraphbackContext } from '@graphback/core'
import { GraphQLResolveInfo } from 'graphql'
import { ECactusOperationType, ICactusCallback } from './interfaces'

export default async function cactusSyncMethod(
  _: any,
  args: any,
  context: GraphbackContext,
  info: GraphQLResolveInfo,
  modelName: string,
  callbacks: ICactusCallback[] | never[],
  operation: ECactusOperationType
) {
  const crudService = context.graphback[modelName]

  for (const callback of callbacks) {
    await callback(_, args, context, info, operation)
  }
  // use the model service created by Graphback to query the database
  const items = await crudService[operation](args, context, info)

  return items
}

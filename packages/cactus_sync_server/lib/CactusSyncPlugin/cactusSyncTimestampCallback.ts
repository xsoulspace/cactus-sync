import { ICactusCallback } from './interfaces'
import { GraphbackContext } from '@graphback/core'
import { GraphQLResolveInfo } from 'graphql'
import { ExpressContext } from 'apollo-server-express'

export const SYNC_TIMESTAMP_MODEL_NAME = 'CactusSyncTimestamp'

export const cactusSyncTimestampCallback: ICactusCallback = async (
  _,
  args,
  context,
  info,
  queryResult,
  modelName,
  type
): Promise<ExpressContext> => {
  const crudService = context.graphback[SYNC_TIMESTAMP_MODEL_NAME]
  const timestamp = (Date.now() / 1000) | 0

  const result = await crudService.create({
    timestamp,
    modelId: queryResult?._id,
    changeType: type.toUpperCase(),
    modelTypename: modelName,
  })
  return result
}

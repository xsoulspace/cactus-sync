import { ExpressContext } from 'apollo-server-express'

export function createCactusSyncContext(
  context: ExpressContext
): ExpressContext {
  const req = context.req
  const query = req.query
  const params = req.params

  return {
    ...context,
  }
}

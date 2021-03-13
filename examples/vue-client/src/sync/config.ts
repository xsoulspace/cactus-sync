import { createHttpLink, InMemoryCache } from '@apollo/client/core'
import { buildSchema } from 'graphql'
import { CactusSync } from '../../../../packages/cactus-sync-client/dist'
import schemaStr from '../../../../resources/schema.graphql?raw'

export const useCactusSyncInit = () => {
  const schema = buildSchema(schemaStr)
  const url = 'http://localhost:4000/graphql'
  const httpLink = createHttpLink({
    // You should use an absolute URL here
    uri: url,
  })
  // This is needed if you can use wss
  // const link = new WebSocketLink({
  //   url: 'wss://localhost:4000/graphql',
  //   connectionParams: () => {
  //     return {}
  //     // const session = getSession();
  //     // if (!session) {
  //     //   return {};
  //     // }
  //     // return {
  //     //   Authorization: `Bearer ${session.token}`,
  //     // };
  //   },
  // })
  const cache = new InMemoryCache()
  CactusSync.init({
    apolloOptions: {
      cache,
      link: httpLink,
    },
    schema: schema,
  })
}

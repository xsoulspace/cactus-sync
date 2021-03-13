import { makeExecutableSchema } from '@graphql-tools/schema'
import { ApolloServerExpressConfig } from 'apollo-server-express'
import { execute, subscribe } from 'graphql'
import { useServer } from 'graphql-ws/lib/use/ws'
import http from 'http'
import https from 'https'
import ws from 'ws' // yarn add ws

export function createGraphQLWS(
  server: http.Server | https.Server,
  config: ApolloServerExpressConfig
) {
  const wsServer = new ws.Server({
    server,
    path: '/graphql',
  })

  if (!config.typeDefs) {
    throw Error('TypeDefs not defined')
  }
  useServer(
    {
      schema: makeExecutableSchema({
        resolvers: config.resolvers,
        typeDefs: config.typeDefs,
        allowUndefinedInResolve: true,
      }),
      ...config,
      execute,
      subscribe,
    },
    wsServer
  )
}

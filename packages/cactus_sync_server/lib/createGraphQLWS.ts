import express from 'express'
import { ApolloServer, ApolloServerExpressConfig } from 'apollo-server-express'
import ws from 'ws' // yarn add ws
import { useServer } from 'graphql-ws/lib/use/ws'
import { execute, subscribe } from 'graphql'
import http from 'http'
import { buildSchema } from 'graphql'
import { makeExecutableSchema } from '@graphql-tools/schema'

export function createGraphQLWS(
  server: http.Server,
  config: ApolloServerExpressConfig
) {
  const wsServer = new ws.Server({
    server,
    path: '/graphql',
  })

  if (!config.typeDefs) {
    throw Error('TypeDefs not defined')
    return
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

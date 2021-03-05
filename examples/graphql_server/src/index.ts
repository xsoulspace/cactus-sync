// eslint-disable-next-line @typescript-eslint/no-require-imports
require('dotenv').config()
import { createMongoDbProvider } from '@graphback/runtime-mongo'
import { ApolloServer, ApolloServerExpressConfig } from 'apollo-server-express'
import cors from 'cors'
import express from 'express'
import { buildGraphbackAPI } from 'graphback'
import { loadConfigSync } from 'graphql-config'
import http from 'http'
// FIXME: resolve as package
import { createGraphQLWS } from '../../cactus_sync_server/lib'
import { connectDB } from './db'
import { noteResolvers } from './resolvers/noteResolvers'
async function start() {
  const app = express()

  app.use(cors())

  const graphbackExtension = 'graphback'
  const config = loadConfigSync({
    extensions: [
      () => ({
        name: graphbackExtension,
      }),
    ],
  })

  const projectConfig = config.getDefault()
  const graphbackConfig = projectConfig.extension(graphbackExtension)

  const modelDefs = projectConfig.loadSchemaSync(graphbackConfig.model)

  const db = await connectDB()

  const { typeDefs, resolvers, contextCreator } = buildGraphbackAPI(modelDefs, {
    dataProviderCreator: createMongoDbProvider(db),
  })

  const apolloConfig: ApolloServerExpressConfig = {
    typeDefs,
    resolvers: [resolvers, noteResolvers],
    context: contextCreator,
    uploads: false,
  }
  const apolloServer = new ApolloServer(apolloConfig)

  apolloServer.applyMiddleware({ app })

  const httpServer = http.createServer(app)
  apolloServer.installSubscriptionHandlers(httpServer)

  httpServer.listen({ port: 4000 }, () =>
    createGraphQLWS(httpServer, apolloConfig)
  )
}

start().catch((err: any) => console.log(err))

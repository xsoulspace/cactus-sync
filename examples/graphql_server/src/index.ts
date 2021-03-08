// eslint-disable-next-line @typescript-eslint/no-require-imports
require('dotenv').config()
import { createMongoDbProvider } from '@graphback/runtime-mongo'
import { ApolloServer, ApolloServerExpressConfig } from 'apollo-server-express'
import cors from 'cors'
import express from 'express'
import { buildGraphbackAPI } from 'graphback'
import { loadConfigSync } from 'graphql-config'
import http from 'http'
import {
  createGraphQLWS,
  CactusSyncPlugin,
} from '../../../packages/cactus_sync_server/lib'
import { connectDB } from './db'
// import { noteResolvers } from './resolvers/noteResolvers'
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
    plugins: [new CactusSyncPlugin()],
  })

  const apolloConfig: ApolloServerExpressConfig = {
    typeDefs,
    resolvers: [resolvers],
    context: contextCreator,
    uploads: false,
  }
  const apolloServer = new ApolloServer(apolloConfig)

  apolloServer.applyMiddleware({ app })

  const httpServer = http.createServer(app)
  apolloServer.installSubscriptionHandlers(httpServer)

  httpServer.listen({ port: 4000 }, () => {
    createGraphQLWS(httpServer, apolloConfig)
    console.log(`🚀  Server ready at http://localhost:4000/graphql`)
  })
}

start().catch((err: any) => console.log(err))

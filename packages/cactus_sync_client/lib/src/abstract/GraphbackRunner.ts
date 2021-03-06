import { buildGraphbackAPI, GraphbackContext } from 'graphback'
import { graphql, GraphQLSchema } from 'graphql'
import { loadConfigSync } from 'graphql-config'
import { makeExecutableSchema } from 'graphql-tools'
import { CactusSync } from './CactusSync'

interface GraphbackRunnerI {
  context: (context?: any) => GraphbackContext
  schema: GraphQLSchema
}

/**
 * To initialize `GraphbackRunner` use
 * `GraphbackRunner.init(...)`
 */
export class GraphbackRunner {
  schema: GraphQLSchema
  context: (context?: any) => GraphbackContext
  constructor({ context, schema }: GraphbackRunnerI) {
    this.context = context
    this.schema = schema
  }
  static async init({ db }: { db: CactusSync }) {
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

    const { typeDefs, resolvers, contextCreator } = buildGraphbackAPI(
      modelDefs,
      {
        // FIXME:
        dataProviderCreator: createDexieDbProvider(db),
      }
    )
    // TODO: make useRemoteConnect - function responsible to ibject
    // hook which will handle all changes in Dexie and will send/add to
    // QueueManager to send to remote server
    // or use middleware ??
    const useRemoteConnect = (resolvers: Record<string, any>) => {
      // TODO: wrap every function
      return resolvers
    }
    const finalResolvers = useRemoteConnect(resolvers)
    const executableGraphqlSchema: GraphQLSchema = makeExecutableSchema({
      typeDefs,
      resolvers: [finalResolvers],
    })
    return new GraphbackRunner({
      context: contextCreator,
      schema: executableGraphqlSchema,
    })
  }

  async graphqlExecute(query: string) {
    return await graphql(this.schema, query, null, this.context)
  }
}

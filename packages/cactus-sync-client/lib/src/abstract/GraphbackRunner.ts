import { createDexieDbProvider } from '@graphback/runtime-dexie'
import Dexie from 'dexie'
import { buildGraphbackAPI, GraphbackContext } from 'graphback'
import { graphql, GraphQLSchema } from 'graphql'
import { loadConfigSync } from 'graphql-config'
import { ExecutionResult, makeExecutableSchema, Maybe } from 'graphql-tools'

interface GraphbackRunnerI {
  context: GraphbackContext
  schema: GraphQLSchema
}

/**
 * To initialize `GraphbackRunner` use
 * `GraphbackRunner.init(...)`
 */
export class GraphbackRunner {
  schema: GraphQLSchema
  context: GraphbackContext
  constructor({ context, schema }: GraphbackRunnerI) {
    this.context = context
    this.schema = schema
  }
  static async init({ db }: { db: Dexie }) {
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
    const context = contextCreator()
    return new GraphbackRunner({
      context,
      schema: executableGraphqlSchema,
    })
  }

  async execute<
    TType,
    TVariables = any,
    TResult = Maybe<TType>,
    TExecutionResult extends ExecutionResult<TResult> = ExecutionResult<TResult>
  >(query: string, variableValues?: TVariables) {
    return (await graphql(
      this.schema,
      query,
      null,
      this.context,
      variableValues
    )) as TExecutionResult
  }
}

import { GraphbackContext } from '@graphback/core'
import { GraphQLResolveInfo } from 'graphql'

import { IResolvers, IObjectTypeResolver } from '@graphql-tools/utils'
import { GraphbackPlugin, GraphbackCoreMetadata } from 'graphback'
import { GraphQLSchema } from 'graphql'
import { SchemaComposer } from 'graphql-compose'

export class CactusSyncPlugin extends GraphbackPlugin {
  getPluginName() {
    return 'CactusSyncPlugin'
  }

  transformSchema(metadata: GraphbackCoreMetadata): GraphQLSchema {
    const schema = metadata.getSchema()
    const schemaComposer = new SchemaComposer(schema)

    return schemaComposer.buildSchema()
  }

  createResolvers(metadata: GraphbackCoreMetadata): IResolvers {
    const resolvers: IResolvers = {}
    const queryObj: IObjectTypeResolver = {}

    // loop through every Graphback model
    for (const model of metadata.getModelDefinitions()) {
      const modelName = model.graphqlType.name

      // create a resolver function for every query field created in `transformSchema`
      queryObj[`create${modelName}`] = async (
        _: any,
        args: any,
        context: GraphbackContext,
        info: GraphQLResolveInfo
      ) => {
        const crudService = context.graphback[modelName]

        // use the model service created by Graphback to query the database
        const items = await crudService.create(args, context, info)

        return items
      }

      queryObj[`update${modelName}`] = async (
        _: any,
        args: any,
        context: GraphbackContext,
        info: GraphQLResolveInfo
      ) => {
        const crudService = context.graphback[modelName]

        // use the model service created by Graphback to query the database
        const items = await crudService.update(args, context, info)

        return items
      }

      queryObj[`delete${modelName}`] = async (
        _: any,
        args: any,
        context: GraphbackContext,
        info: GraphQLResolveInfo
      ) => {
        const crudService = context.graphback[modelName]

        // use the model service created by Graphback to query the database
        const items = await crudService.delete(args, context, info)

        return items
      }
    }

    resolvers.Mutation = queryObj
    console.log(resolvers)
    return resolvers
  }
}

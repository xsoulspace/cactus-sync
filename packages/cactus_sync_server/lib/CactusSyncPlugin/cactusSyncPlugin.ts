import { GraphbackContext } from '@graphback/core'
import { GraphQLResolveInfo } from 'graphql'

import { IResolvers, IObjectTypeResolver } from '@graphql-tools/utils'
import { GraphbackPlugin, GraphbackCoreMetadata } from 'graphback'
import { GraphQLSchema } from 'graphql'
import { SchemaComposer } from 'graphql-compose'
import { ECactusOperationType, ICactusCallback } from './'
import cactusSyncMethod from './cactusSyncMethod'

export class CactusSyncPlugin extends GraphbackPlugin {
  callbacks: ICactusCallback[]

  getPluginName() {
    return 'CactusSyncPlugin'
  }

  constructor(callbacks: ICactusCallback[]) {
    super()
    this.callbacks = callbacks
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
      ) =>
        await cactusSyncMethod(
          _,
          args,
          context,
          info,
          modelName,
          this.callbacks,
          ECactusOperationType.CREATE
        )

      queryObj[`update${modelName}`] = async (
        _: any,
        args: any,
        context: GraphbackContext,
        info: GraphQLResolveInfo
      ) =>
        await cactusSyncMethod(
          _,
          args,
          context,
          info,
          modelName,
          this.callbacks,
          ECactusOperationType.UPDATE
        )

      queryObj[`delete${modelName}`] = async (
        _: any,
        args: any,
        context: GraphbackContext,
        info: GraphQLResolveInfo
      ) =>
        await cactusSyncMethod(
          _,
          args,
          context,
          info,
          modelName,
          this.callbacks,
          ECactusOperationType.DELETE
        )
    }

    resolvers.Mutation = queryObj
    console.log(resolvers)
    return resolvers
  }
}

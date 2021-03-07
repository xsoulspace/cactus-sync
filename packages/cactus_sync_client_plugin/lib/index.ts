import { DocumentNode, GraphQLSchema } from 'graphql'

module.exports = {
  plugin: (
    schema: GraphQLSchema,
    documents: DocumentNode[],
    config: Record<string, unknown | null | undefined>,
    info
  ) => {
    const typesMap = schema.getTypeMap()

    return Object.keys(typesMap).join('\n')
  },
}

import { makeExecutableSchema } from '@graphql-tools/schema'
import fs from 'fs'
import { graphql } from 'graphql'
import path from 'path'
describe('generateModelsAndTypes', () => {
  test('', async () => {
    const schemaStr = await fs.promises.readFile(
      path.resolve(__dirname, '../../../../resources/generatedSchema.graphql'),
      {
        encoding: 'utf8',
      }
    )
    // const schema = parse(schemaStr)

    // const types = schema.definitions.filter(
    //   (el) => el.kind == 'ObjectTypeDefinition'
    // )
    const exectableSchema = makeExecutableSchema({
      typeDefs: schemaStr,
      resolvers: {
        Query: {
          findTodos: async () => {
            console.log('findTodos')
            // async findTodos(parent, args, context, info) {
            return { items: [] }
          },
        },
      },
      logger: { log: (e) => console.log(e) },
    })
    const query = `
      query findTodos{
        findTodos{
          items{
            _id
          }
        }
      }
    `
    const result = await graphql(exectableSchema, query)

    expect(result).toEqual([])
  })
})

import fs from 'fs'
import { parse } from 'graphql'
import path from 'path'
import { generateModelsAndTypes } from './generateModelsAndTypes'
describe('generateModelsAndTypes', () => {
  test('', async () => {
    const schemaStr = await fs.promises.readFile(
      path.resolve(__dirname, '../../../resources/schema.graphql'),
      {
        encoding: 'utf8',
      }
    )
    const schema = parse(schemaStr)
    const types = generateModelsAndTypes(schema)

    expect(types).toEqual({})
  })
})

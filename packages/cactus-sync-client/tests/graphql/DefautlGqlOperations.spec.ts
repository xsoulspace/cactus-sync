import gql from 'graphql-tag'
import { getDefaultGqlOperations, gqlToFields } from '../../lib'

const normilizeString = (str: string) => str.trim().replace(/\s+/g, ' ')

describe('DefaultGqlOperations', () => {
  test('can create correct gql requests (CUDGF)', () => {
    const operations = getDefaultGqlOperations({
      modelFields: ['id', 'title'],
      modelName: 'TestModel',
    })

    expect(normilizeString(operations.create)).toBe(
      normilizeString(`
      mutation createTestModel($input: CreateTestModelInput!) {
        createTestModel(input: $input) {
          id
          title
        }
      }`)
    )

    expect(normilizeString(operations.remove)).toBe(
      normilizeString(`
      mutation deleteTestModel($input: MutateTestModelInput!) {
        deleteTestModel(input: $input) {
          id
          title
        }
      }`)
    )

    expect(normilizeString(operations.update)).toBe(
      normilizeString(`
      mutation updateTestModel($input: MutateTestModelInput!) {
        updateTestModel(input: $input) {
          id
          title
        }
      }`)
    )

    expect(normilizeString(operations.find)).toBe(
      normilizeString(`
      query findTestModel($filter: TestModelFilter, $page: PageRequest, $orderBy: OrderByInput) {
        findTestModels(filter: $filter, page: $page, orderBy: $orderBy) {
          items{
            id
            title
          }
        }
      }`)
    )

    expect(normilizeString(operations.get)).toBe(
      normilizeString(`
      query getTestModel($id: ID!) {
        getTestModel(id: $id) {
          id
          title
        }
      }`)
    )
  })
  test('can convert gql to string', () => {
    const todoFragment = gql`
      fragment TodoFragment on Todo {
        id
        title
        user {
          id
          name
        }
      }
    `
    const str = gqlToFields(todoFragment)
    const expectedStr = `
    id
    title
    user {
      id
      name
    }`

    expect(normilizeString(str)).toBe(normilizeString(expectedStr))
  })
})

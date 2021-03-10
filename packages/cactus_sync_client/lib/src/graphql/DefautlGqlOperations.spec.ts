import { getDefautlGqlOperations } from './DefautlGqlOperations'

describe('DefautlGqlOperations', () => {
  test('can create correct gql requests (CUDGF)', () => {
    const operations = getDefautlGqlOperations({
      modelFields: ['id', 'title'],
      modelName: 'TestModel',
    })

    expect(operations.create).toBe(`
mutation createTestModel($input: CreateTestModelInput!) {
  createTestModel(input: $input) {
id
title
  }
}`)

    expect(operations.delete).toBe(`
mutation deleteTestModel($input: MutateTestModelInput!) {
  deleteTestModel(input: $input) {
id
title
  }
}`)

    expect(operations.update).toBe(`
mutation updateTestModel($input: MutateTestModelInput!) {
  updateTestModel(input: $input) {
id
title
  }
}`)

    expect(operations.find).toBe(`
query findTestModel($filter: TestModelFilter, $page: PageRequest, $orderBy: OrderByInput) {
  findTestModels(filter: $filter, page: $page, orderBy: $orderBy) {
    items{
id
title
    }
  }
}`)

    expect(operations.get).toBe(`
query getTestModel($id: ID!) {
  getTestModel(id: $id) {
id
title
  }
}`)
  })
})

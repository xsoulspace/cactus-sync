export interface DefautlGqlOperations {
  create: string
  update: string
  delete: string
  get: string
  find: string
}

/**
 * Builds GraphQL mutations for models following
 * the [GraphQLCRUD specification]{@link https://graphqlcrud.org/}
 */
export const getDefautlGqlOperations = <TModel = unknown>({
  modelFields,
  modelName,
}: {
  modelFields: (keyof TModel)[]
  modelName: string
}): DefautlGqlOperations => {
  const returnFields = modelFields.join('\n')

  const mutations: DefautlGqlOperations = {
    create: `
mutation create${modelName}($input: Create${modelName}Input!) {
  create${modelName}(input: $input) {
${returnFields}
  }
}`,
    update: `
mutation update${modelName}($input: Mutate${modelName}Input!) {
  update${modelName}(input: $input) {
${returnFields}
  }
}`,
    delete: `
mutation delete${modelName}($input: Mutate${modelName}Input!) {
  delete${modelName}(input: $input) {
${returnFields}
  }
}`,
    get: `
query get${modelName}($id: ID!) {
  get${modelName}(id: $id) {
${returnFields}
  }
}`,
    find: `
query find${modelName}($filter: ${modelName}Filter, $page: PageRequest, $orderBy: OrderByInput) {
  find${modelName}s(filter: $filter, page: $page, orderBy: $orderBy) {
${returnFields}
  }
}`,
  }
  return mutations
}

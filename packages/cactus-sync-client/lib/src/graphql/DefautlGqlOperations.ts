import { DocumentNode, print } from 'graphql'
import { Maybe } from 'graphql-tools'

export enum DefautlGqlOperationType {
  create = 'create',
  update = 'update',
  remove = 'remove',
  get = 'get',
  find = 'find',
}
export type DefautlGqlOperations = {
  [operation in DefautlGqlOperationType]: string
}
/**
 * The function removes all outside {} from gql
 * and returns clear string
 * @param gqlNode
 * @returns {string}
 */
export const gqlToFields = (gqlNode: DocumentNode): string => {
  const origin = print(gqlNode)
  let arrOrigin = origin.split('{')
  arrOrigin.splice(0, 1)
  const cuttedStart = arrOrigin.join('{')
  const cuttedStartArr = cuttedStart.split('}')
  cuttedStartArr.splice(cuttedStartArr.length - 1)
  const finalStr = cuttedStartArr.join('}')
  return finalStr
}

/**
 * Builds GraphQL mutations for models following
 * the [GraphQLCRUD specification]{@link https://graphqlcrud.org/}
 *
 * If function receive modelFields it uses as default return fields
 *
 * If function receive modelFragment it uses as return fields
 */
export const getDefautlGqlOperations = <TModel = unknown>({
  modelFields,
  modelName,
  modelFragment,
}: {
  modelFields?: Maybe<(keyof TModel)[]>
  modelFragment?: Maybe<DocumentNode>
  modelName: string
}): DefautlGqlOperations => {
  const returnFields = modelFragment
    ? gqlToFields(modelFragment)
    : modelFields?.join('\n')
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
    remove: `
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
    items{
${returnFields}
    }
  }
}`,
  }
  return mutations
}

import { DocumentNode, print } from 'graphql'
import { Maybe } from '../abstract/BasicTypes'

export enum DefaultGqlOperationType {
  create = 'create',
  update = 'update',
  remove = 'remove',
  get = 'get',
  find = 'find',
}
export enum SubscribeGqlOperationType {
  subscribeNew = 'subscribeNew',
  subscribeUpdated = 'subscribeUpdated',
  subscribeDeleted = 'subscribeDeleted',
}
export type AllGqlOperationsType =
  | SubscribeGqlOperationType
  | DefaultGqlOperationType
export type DefaultGqlOperations = {
  [operation in AllGqlOperationsType]: string
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
export const getDefaultGqlOperations = <TModel = unknown>({
  modelFields,
  modelName,
  modelFragment,
}: {
  modelFields?: Maybe<(keyof TModel)[]>
  modelFragment?: Maybe<DocumentNode>
  modelName: string
}): DefaultGqlOperations => {
  const returnFields = modelFragment
    ? gqlToFields(modelFragment)
    : modelFields?.join('\n')
  const mutations: DefaultGqlOperations = {
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
    subscribeNew: `
      subscription new${modelName}($filter: ${modelName}Filter){
        new${modelName}(filter: $filter){
          ${returnFields}
        }
      }
    `,
    subscribeUpdated: `
      subscription updated${modelName}($filter: ${modelName}Filter){
        updated${modelName}(filter: $filter){
          ${returnFields}
        }
      }
    `,
    subscribeDeleted: `
      subscription deleted${modelName}($filter: ${modelName}Filter){
        deleted${modelName}(filter: $filter){
          ${returnFields}
        }
      }
    `,
  }
  return mutations
}

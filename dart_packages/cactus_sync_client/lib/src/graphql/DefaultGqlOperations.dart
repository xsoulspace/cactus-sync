import 'package:flutter/foundation.dart';


/// _from is used to get valid enum property from string
/// example:
///
/// ```dart
/// [fromString]['create'];
/// ```
///
/// to get string value use toStringValue
/// example:
///
/// ```dart
/// [create].toStringValue() // output: 'create'
/// ```
enum DefaultGqlOperationType { fromString, create, update, remove, get, find }

extension DefaultGqlOperationTypeDescribe on DefaultGqlOperationType {
  /// Overload the [] getter to get the name 
  /// based on https://stackoverflow.com/a/60209631
  operator [](String key) => (name) {
        switch (name) {
          case 'create':
            return DefaultGqlOperationType.create;
          case 'update':
            return DefaultGqlOperationType.update;
          case 'remove':
            return DefaultGqlOperationType.remove;
          case 'get':
            return DefaultGqlOperationType.get;
          case 'find':
            return DefaultGqlOperationType.find;
          default:
            throw RangeError('enum DefaultGqlOperationTypeDescribe '
            'contains no value $name');
        }
      }(key);

  /// returns string for enum value only
  String toStringValue() => describeEnum(this);
}


/// _from is used to get valid enum property from string
/// example:
///
/// ```dart
/// [fromString]['subscribeNew'];
/// ```
///
/// to get string value use toStringValue
/// example:
///
/// ```dart
/// [subscribeNew].toStringValue() // output: 'subscribeNew'
/// ```
enum SubscribeGqlOperationType {
  fromString,
   subscribeNew ,
   subscribeUpdated ,
   subscribeDeleted 
}

extension SubscribeGqlOperationTypeDescribe on SubscribeGqlOperationType {
  /// Overload the [] getter to get the name 
  /// based on https://stackoverflow.com/a/60209631
  operator [](String key) => (name) {
        switch (name) {
          case 'create':
            return SubscribeGqlOperationType.subscribeNew;
          case 'update':
            return SubscribeGqlOperationType.subscribeUpdated;
          case 'remove':
            return SubscribeGqlOperationType.subscribeDeleted;
          default:
            throw RangeError('enum SubscribeGqlOperationTypeDescribe '
            'contains no value $name');
        }
      }(key);

  /// returns string for enum value only
  String toStringValue() => describeEnum(this);
}


type AllGqlOperationsType =
  | SubscribeGqlOperationType
  | DefaultGqlOperationType
type DefaultGqlOperations = {
  [operation in AllGqlOperationsType]: string
}
/**
 * The function removes all outside {} from gql
 * and returns clear string
 * @param gqlNode
 * @returns {string}
 */
const gqlToFields = (gqlNode: DocumentNode): string => {
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
const getDefaultGqlOperations = <TModel = unknown>({
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
  const pluralModelName = toPluralName(modelName)
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
      query find${pluralModelName}($filter: ${modelName}Filter, $page: PageRequest, $orderBy: OrderByInput) {
        find${pluralModelName}(filter: $filter, page: $page, orderBy: $orderBy) {
          items{
            ${returnFields}
          }
        }
      }`,
    subscribeNew: `
      subscription new${modelName}($filter: ${modelName}SubscriptionFilter){
        new${modelName}(filter: $filter){
          ${returnFields}
        }
      }
    `,
    subscribeUpdated: `
      subscription updated${modelName}($filter: ${modelName}SubscriptionFilter){
        updated${modelName}(filter: $filter){
          ${returnFields}
        }
      }
    `,
    subscribeDeleted: `
      subscription deleted${modelName}($filter: ${modelName}SubscriptionFilter){
        deleted${modelName}(filter: $filter){
          ${returnFields}
        }
      }
    `,
  }
  return mutations
}

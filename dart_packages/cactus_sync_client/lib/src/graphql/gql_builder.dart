import 'package:cactus_sync_client/src/utils/naming.dart';
import 'package:flutter/foundation.dart';
import 'package:gql/ast.dart';
import "package:gql/language.dart" as gqlLang;

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
  subscribeNew,
  subscribeUpdated,
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

///
/// Builds GraphQL mutations for models following
/// the [GraphQLCRUD specification]{@link https://graphqlcrud.org/}
///
/// If function receive modelFields it uses as default return fields
///
/// If function receive modelFragment it uses as return fields
///
class GqlBuilder {
  String modelName;
  late String returnFields;
  late String pluralModelName;
  GqlBuilder(
      {List<String>? modelFields,
      DocumentNode? modelFragment,
      required String this.modelName}) {
    if (modelFragment != null) {
      returnFields = toFields(gqlNode: modelFragment);
    } else if (modelFields != null) {
      returnFields = modelFields.join('\n');
    } else {
      throw ArgumentError.notNull('modelFragment or modelFields');
    }
    pluralModelName = StringUtil.toPluralName(modelName);
  }

  ///
  /// The function removes all outside {} from gql
  /// and returns clear string
  ///
  String toFields({required DocumentNode gqlNode}) {
    var origin = gqlLang.printNode(gqlNode);
    var arrOrigin = origin.split('{');
    arrOrigin.removeAt(0);
    var cuttedStart = arrOrigin.join('{');
    var cuttedStartArr = cuttedStart.split('}');
    cuttedStartArr.removeAt(cuttedStartArr.length - 1);
    var finalStr = cuttedStartArr.join('}');
    return finalStr;
  }

  get createGqlStr => '''
        mutation create$modelName(\$input: Create${modelName}Input!) {
          create$modelName(input: \$input) {
            $returnFields
          }
        }
    '''
      .toString();

  get updateGqlStr => '''
        mutation update$modelName(\$input: Mutate${modelName}Input!) {
          update${modelName}(input: \$input) {
            $returnFields
          }
        }
    '''
      .toString();
  get removeGqlStr => '''
        mutation delete$modelName(\$input: Mutate${modelName}Input!) {
          delete$modelName(input: \$input) {
            $returnFields
          }
        }
    '''
      .toString();
  get getGqlStr => '''
        query get$modelName(\$id: ID!) {
          get$modelName(id: \$id) {
            $returnFields
          }
        }
    '''
      .toString();
  get findGqlStr => '''
        query find$pluralModelName(
          \$filter: ${modelName}Filter, 
          \$page: PageRequest, 
          \$orderBy: OrderByInput
        ) {
          find$pluralModelName(
            filter: \$filter, page: \$page, orderBy: \$orderBy
          ) {
            items{
              $returnFields
            }
          }
        }
    '''
      .toString();
  get subscribeNewGqlStr => '''
        subscription new$modelName(
          \$filter: ${modelName}SubscriptionFilter
        ){
          new$modelName(filter: \$filter){
            $returnFields
          }
        }
    '''
      .toString();
  get subscribeUpdatedGqlStr => '''
        subscription updated$modelName(
          \$filter: ${modelName}SubscriptionFilter
        ){
          updated$modelName(filter: \$filter){
            $returnFields
          }
        }
    '''
      .toString();
  get subscribeDeletedGqlStr => '''
        subscription deleted$modelName(
          \$filter: ${modelName}SubscriptionFilter
        ){
          deleted$modelName(filter: \$filter){
            $returnFields
          }
        }
    '''
      .toString();
}

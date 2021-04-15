import 'package:cactus_sync_client/src/utils/naming.dart';

enum DefaultGqlOperationType { fromString, create, update, remove, get, find }
enum SubscribeGqlOperationType {
  fromString,
  subscribeNew,
  subscribeUpdated,
  subscribeDeleted
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
      {List<String?>? modelFields,
      String? modelFragment,
      required String this.modelName}) {
    if (modelFragment != null) {
      returnFields = toFields(gqlFragment: modelFragment);
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
  String toFields({required String gqlFragment}) {
    var arrOrigin = gqlFragment.split('{');
    arrOrigin.removeAt(0);
    var cuttedStart = arrOrigin.join('{');
    var cuttedStartArr = cuttedStart.split('}');
    cuttedStartArr.removeAt(cuttedStartArr.length - 1);
    var finalStr = cuttedStartArr.join('}');
    return finalStr;
  }

  String getByOperationType({required DefaultGqlOperationType operationType}) {
    switch (operationType) {
      case DefaultGqlOperationType.create:
        return createGqlStr;
      case DefaultGqlOperationType.update:
        return updateGqlStr;
      case DefaultGqlOperationType.remove:
        return removeGqlStr;
      case DefaultGqlOperationType.get:
        return getGqlStr;
      case DefaultGqlOperationType.find:
        return findGqlStr;
      case DefaultGqlOperationType.fromString:
        throw Exception('operationType cannot be fromString');
    }
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

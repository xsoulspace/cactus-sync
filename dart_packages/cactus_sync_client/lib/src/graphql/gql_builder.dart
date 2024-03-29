part of cactus_graphql;

enum DefaultGqlOperationType {
  fromString,
  create,
  update,
  remove,
  get,
  find,
}
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
  final String modelName;
  late final String returnFields;
  late final String pluralModelName;
  GqlBuilder({
    final List<String?>? modelFields,
    final String? modelFragment,
    required this.modelName,
  }) {
    if (modelFragment != null && modelFragment.isNotEmpty) {
      returnFields = toFields(gqlFragment: modelFragment);
    } else if (modelFields != null && modelFields.isNotEmpty) {
      returnFields = modelFields.join('\n');
    } else {
      throw ArgumentError.notNull('modelFragment or modelFields');
    }
    pluralModelName = modelName.toPluralName();
  }

  ///
  /// The function removes all outside {} from gql
  /// and returns clear string
  ///
  String toFields({required final String gqlFragment}) {
    final arrOrigin = gqlFragment.split('{');
    arrOrigin.removeAt(0);
    final cuttedStart = arrOrigin.join('{');
    final cuttedStartArr = cuttedStart.split('}');
    cuttedStartArr.removeAt(cuttedStartArr.length - 1);
    final finalStr = cuttedStartArr.join('}');
    return finalStr;
  }

  String getByOperationType(
      {required final DefaultGqlOperationType operationType}) {
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

  String get createGqlStr => '''
        mutation create$modelName(\$input: Create${modelName}Input!) {
          create$modelName(input: \$input) {
            $returnFields
          }
        }
    '''
      .toString();

  String get updateGqlStr => '''
        mutation update$modelName(\$input: Mutate${modelName}Input!) {
          update$modelName(input: \$input) {
            $returnFields
          }
        }
    '''
      .toString();
  String get removeGqlStr => '''
        mutation delete$modelName(\$input: Mutate${modelName}Input!) {
          delete$modelName(input: \$input) {
            $returnFields
          }
        }
    '''
      .toString();
  String get getGqlStr => '''
        query get$modelName(\$id: ID!) {
          get$modelName(id: \$id) {
            $returnFields
          }
        }
    '''
      .toString();
  String get findGqlStr => '''
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
  String get subscribeNewGqlStr => '''
        subscription new$modelName(
          \$filter: ${modelName}SubscriptionFilter
        ){
          new$modelName(filter: \$filter){
            $returnFields
          }
        }
    '''
      .toString();
  String get subscribeUpdatedGqlStr => '''
        subscription updated$modelName(
          \$filter: ${modelName}SubscriptionFilter
        ){
          updated$modelName(filter: \$filter){
            $returnFields
          }
        }
    '''
      .toString();
  String get subscribeDeletedGqlStr => '''
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

import "package:gql/schema.dart" as gql_schema;

import '../utils/utils.dart';

class GqlModelProviderCreator {
  String getModelProvider({
    required String camelModelName,
    required String properModelType,
  }) {
    return '''
        final use${camelModelName}State = Provider<$properModelType>((_)=>
          CactusStateModel<$properModelType>()
        );
      ''';
  }

  StringBuffer getModelProviders({
    required Iterable<gql_schema.TypeDefinition?> operationTypes,
  }) {
    final strBuffer = StringBuffer();
    for (final type in operationTypes) {
      if (type == null) continue;
      final typeName = type.name;
      // print(gql_lang.printNode());

      if (typeName == null || isSystemType(typeName: typeName)) continue;
      final strModelsBuffer = generateCactusModels(
        properModelType: typeName,
      );
      strBuffer.writeln(strModelsBuffer);
    }
    return strBuffer;
  }

  StringBuffer generateCactusModels({
    required String properModelType,
  }) {
    final pluralProperModelName = properModelType.toPluralName();
    final strBuffer = StringBuffer();
    final properModelName = '${properModelType}Model';

    final camelModelName = '${properModelType.toCamelCase()}Model';

    final defaultFragmentName = '${properModelType}Fragment';

    final mutationCreateArgs = 'MutationCreate${properModelType}Args';
    final mutationCreateResult =
        '{ create$properModelType: Maybe<$properModelType> }';

    final mutationUpdateArgs = 'MutationUpdate${properModelType}Args';
    final mutationUpdateResult =
        '{ update$properModelType: Maybe<$properModelType> }';

    final mutationDeleteArgs = 'MutationDelete${properModelType}Args';
    final mutationDeleteResult =
        '{ delete$properModelType: Maybe<$properModelType> }';

    final queryGetArgs = 'QueryGet${properModelType}Args';
    final queryGetResult = '{ get$properModelType: Maybe<$properModelType> }';

    final queryFindArgs = 'QueryFind${pluralProperModelName}Args';
    final queryFindResult = '${properModelType}ResultList';
    final queryFindResultI = '{ find$pluralProperModelName: $queryFindResult}';
    const defaultFragment = '';
    final modelStr = '''
        final $properModelName = CactusSync.attachModel(
          CactusModel.init<
            $properModelType,
            $mutationCreateArgs,
            $mutationCreateResult,
            $mutationUpdateArgs,
            $mutationUpdateResult,
            $mutationDeleteArgs,
            $mutationDeleteResult,
            $queryGetArgs,
            $queryGetResult,
            $queryFindArgs,
            $queryFindResultI
          >(graphqlModelType: $defaultFragment)б
        );
      ''';
    final providerStr = getModelProvider(
        camelModelName: camelModelName, properModelType: properModelType);
    strBuffer.writeAll([providerStr, modelStr], "\n");
    return strBuffer;
  }

  bool isSystemType({required String typeName}) =>
      typeName.contains('_') || typeName.toLowerCase() == 'query';
}

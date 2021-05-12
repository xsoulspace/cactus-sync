import 'package:code_builder/code_builder.dart';
import "package:gql/ast.dart";
import "package:gql/schema.dart" as gql_schema;

import '../utils/utils.dart';
import 'gql_object_type_definition.dart';

class GqlModelBuilder extends GqlObjectTypeDefinition {
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

  Set<Class> makeModelsAndProviders({
    required Iterable<gql_schema.TypeDefinition?> operationTypes,
  }) {
    final finalClasses = <Class>{};

    for (final typeNode in operationTypes) {
      if (typeNode == null) continue;
      final typeDefinitionName = typeNode.name;
      if (typeDefinitionName == null) continue;
      final astNode = typeNode.astNode;

      if (astNode is ObjectTypeDefinitionNode) {
        final typeDefinition = gql_schema.ObjectTypeDefinition(astNode);
        final dartModel = makeModelClass(
          typeDefinition: typeDefinition,
          typeDefinitionName: typeDefinitionName,
        );
        finalClasses.add(dartModel);
      } else if (astNode is InterfaceTypeDefinitionNode) {
        final typeDefinition = gql_schema.InterfaceTypeDefinition(astNode);

        final dartInterface = makeInterfaceClass(
          typeDefinition: typeDefinition,
          typeDefinitionName: typeDefinitionName,
        );
        finalClasses.add(dartInterface);
      } else {
        continue;
      }

      // TODO: handle different types

      // if (astNode is ScalarTypeDefinitionNode) {
      //   gql_schema.ScalarTypeDefinition(astNode);
      // }

      // if (astNode is UnionTypeDefinitionNode) {
      //   gql_schema.UnionTypeDefinition(astNode);
      // }

      // if (astNode is EnumTypeDefinitionNode) {
      //   gql_schema.EnumTypeDefinition(astNode);
      // }

      // if (astNode is InputObjectTypeDefinitionNode) {
      //   gql_schema.InputObjectTypeDefinition(astNode);
      // }
      // FIXME:
      // final strModelsBuffer = makeCactusModels(
      //   properModelType: typeDefinitionName,
      // );
      // strBuffer.writeln(strModelsBuffer);
    }
    return finalClasses;
  }

  Class makeInterfaceClass({
    required gql_schema.InterfaceTypeDefinition typeDefinition,
    required String? typeDefinitionName,
  }) =>
      makeModelClass(
        typeDefinition: typeDefinition,
        typeDefinitionName: typeDefinitionName,
        abstract: true,
      );

  Class makeModelClass({
    required gql_schema.TypeDefinitionWithFieldSet typeDefinition,
    required String? typeDefinitionName,
    bool abstract = false,
  }) {
    final List<Field> fieldsDiefinitions = [];
    final List<Parameter> defaultConstructorInitializers = [];
    for (final field in typeDefinition.fields) {
      fillClassParametersFromField(
        fieldsDiefinitions: fieldsDiefinitions,
        defaultConstructorInitializers: defaultConstructorInitializers,
        name: field.name,
        // FIXME: errors happened with comments
        description: '', //field.description ,
        baseTypeName: field.type?.baseTypeName,
      );
    }
    final dartClass = makeClassContructor(
      fieldsDiefinitions: fieldsDiefinitions,
      defaultConstructorInitializers: defaultConstructorInitializers,
      typeDefinitionName: typeDefinitionName,
      abstract: abstract,
    );
    return dartClass;
  }

  StringBuffer makeCactusModels({
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

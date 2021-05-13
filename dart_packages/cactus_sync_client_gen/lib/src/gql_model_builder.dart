import 'package:code_builder/code_builder.dart';
import "package:gql/ast.dart";
import "package:gql/schema.dart" as gql_schema;

import '../utils/utils.dart';
import 'gql_object_type_definition.dart';

class GqlModelBuilder extends GqlObjectTypeDefinition {
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
          implementsInterfaces: typeDefinition.interfaces,
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
    List<gql_schema.InterfaceTypeDefinition>? implementsInterfaces,
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
    List<gql_schema.InterfaceTypeDefinition?>? implementsInterfaces,
  }) {
    final List<Field> fieldsDiefinitions = [];
    final List<Method> methodsDefinitions = [];
    final List<Parameter> defaultConstructorInitializers = [];
    for (final field in typeDefinition.fields) {
      final args = field.args;
      if (args != null && args.isNotEmpty == true) {
        fillClassMethodField(
          methodsDiefinitions: methodsDefinitions,
          name: field.name,
          // FIXME: errors happened with comments
          description: '', //field.description ,
          baseTypeName: field.type?.baseTypeName,
          args: args,
        );
      } else {
        fillClassParameterFromField(
          fieldsDiefinitions: fieldsDiefinitions,
          defaultConstructorInitializers: defaultConstructorInitializers,
          name: field.name,
          // FIXME: errors happened with comments
          description: '', //field.description ,
          baseTypeName: field.type?.baseTypeName,
        );
      }
    }
    final dartClass = makeClassContructor(
      fieldsDiefinitions: fieldsDiefinitions,
      methodsDefinitions: methodsDefinitions,
      defaultConstructorInitializers: defaultConstructorInitializers,
      typeDefinitionName: typeDefinitionName,
      abstract: abstract,
      implementsInterfaces: implementsInterfaces,
    );
    return dartClass;
  }

  StringBuffer makeCactusModels({
    required String properModelType,
  }) {
    final pluralProperModelName = properModelType.toPluralName();
    final strBuffer = StringBuffer();
    final properModelName = properModelType;

    final camelModelName = properModelType.toCamelCase();
    // FIXME: fix all results
    final defaultFragmentName = '${properModelType}Fragment';

    final mutationCreateArgs = 'Create${properModelType}Input';
    final mutationCreateResult = '{ create$properModelType: $properModelType }';

    final mutationUpdateArgs = 'Mutate${properModelType}Input';
    final mutationUpdateResult = '{ update$properModelType: $properModelType }';

    final mutationDeleteArgs = 'Mutate${properModelType}Input';
    final mutationDeleteResult = '{ delete$properModelType: $properModelType }';

    final queryGetArgs = properModelType;
    final queryGetResult = '{ get$properModelType: $properModelType }';

    final queryFindArgs = '${pluralProperModelName}Filter';
    final queryFindResult = '${properModelType}ResultList';
    final queryFindResultI = '{ find$pluralProperModelName: $queryFindResult}';
    // TODO: add params
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
          >(
            graphqlModelType: ,
            defaultModelFragment: $defaultModelFragment,
            createFromJsonCallback: () {

            },
            findFromJsonCallback: () {

            },
            getFromJsonCallback: () {

            },
            removeFromJsonCallback: () {

            },
            updateFromJsonCallback: () {

            },
          )
        );
      ''';
    final providerStr = getModelProvider(
        camelModelName: camelModelName, properModelType: properModelType);
    strBuffer.writeAll([providerStr, modelStr], "\n");
    return strBuffer;
  }

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

  bool isSystemType({required String typeName}) =>
      typeName.contains('_') || typeName.toLowerCase() == 'query';
}

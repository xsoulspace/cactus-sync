import 'package:code_builder/code_builder.dart';
import "package:gql/ast.dart";
import "package:gql/schema.dart" as gql_schema;

import '../utils/utils.dart';
import 'gql_object_type_definition.dart';

class ModelsAndProvidersResult {
  final Set<Class> models;
  final StringBuffer providers;
  const ModelsAndProvidersResult({
    required this.models,
    required this.providers,
  });
}

class GqlModelBuilder extends GqlObjectTypeDefinition {
  ModelsAndProvidersResult makeModelsAndProviders({
    required Iterable<gql_schema.TypeDefinition?> operationTypes,
  }) {
    final finalClasses = <Class>{};
    final finalProviderBuffer = StringBuffer();

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
        final strProviderBuffer = makeCactusModels(
          properModelType: typeDefinitionName,
          fieldDefinitions: typeDefinition.fields,
        );
        finalProviderBuffer.writeln(strProviderBuffer);
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
    }
    return ModelsAndProvidersResult(
      models: finalClasses,
      providers: finalProviderBuffer,
    );
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
    final List<Field> definedFields = [];
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
          definedFields: definedFields,
          defaultConstructorInitializers: defaultConstructorInitializers,
          name: field.name,
          // FIXME: errors happened with comments
          description: '', //field.description ,
          baseTypeName: field.type?.baseTypeName,
        );
      }
    }
    final dartClass = makeClassContructor(
      definedFields: definedFields,
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
    required List<gql_schema.FieldDefinition> fieldDefinitions,
  }) {
    final pluralProperModelName = properModelType.toPluralName();
    final strBuffer = StringBuffer();
    final camelModelName = properModelType.toCamelCase();

    // FIXME: default fragment
    final defaultFragmentName = '${properModelType}Fragment';
    final defaultModelFragment = '';

    final mutationCreateArgs = 'Create${properModelType}Input';
    final mutationCreateCallback =
        '(json)=> $properModelType.fromJson(json["create$properModelType"])';

    final mutationUpdateArgs = 'Mutate${properModelType}Input';
    final mutationUpdateCallback =
        '(json)=> $properModelType.fromJson(json["update$properModelType"])';

    final mutationDeleteArgs = 'Mutate${properModelType}Input';
    final mutationDeleteCallback =
        '(json)=> $properModelType.fromJson(json["delete$properModelType"])';

    final queryGetArgs = properModelType;
    final queryGetCallback =
        '(json)=> $properModelType.fromJson(json["get$properModelType"])';

    final queryFindArgs = '${pluralProperModelName}Filter';
    final queryFindResult = '${properModelType}ResultList';
    final queryFindCallback =
        '(json)=> $queryFindResult.fromJson(json["find$properModelType"])';

    // TODO: add params
    final modelStr = '''
        final $camelModelName = CactusSync.attachModel(
          CactusModel.init<
            $properModelType,
            $mutationCreateArgs,
            $properModelType,
            $mutationUpdateArgs,
            $properModelType,
            $mutationDeleteArgs,
            $properModelType,
            $queryGetArgs,
            $properModelType,
            $queryFindArgs,
            $queryFindResult
          >(
            graphqlModelFields: $fieldDefinitions,
            graphqlModelName: $properModelType,
            defaultModelFragment: $defaultModelFragment,
            createFromJsonCallback: $mutationCreateCallback,
            findFromJsonCallback: $queryFindCallback,
            getFromJsonCallback: $queryGetCallback,
            removeFromJsonCallback: $mutationDeleteCallback,
            updateFromJsonCallback: $mutationUpdateCallback,
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
          final use${properModelType}State = Provider<$properModelType>((_)=>
            CactusStateModel<$properModelType>()
          );
        ''';
  }

  bool isSystemType({required String typeName}) =>
      typeName.contains('_') || typeName.toLowerCase() == 'query';
}

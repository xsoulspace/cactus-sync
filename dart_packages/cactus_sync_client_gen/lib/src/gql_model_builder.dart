import 'package:code_builder/code_builder.dart';
import "package:gql/ast.dart";
import "package:gql/schema.dart" as gql_schema;
import 'package:indent/indent.dart';

import '../utils/utils.dart';
import 'gql_object_type_definition.dart';

class ModelsAndProvidersResult {
  final Iterable<Class> models;
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
    final finalClasses = <String /** Class name*/, Class>{};
    final finalProviderBuffer = StringBuffer();

    for (final typeNode in operationTypes) {
      if (typeNode == null) continue;
      final typeDefinitionName = typeNode.name;
      if (typeDefinitionName == null) continue;
      final astNode = typeNode.astNode;

      if (astNode is ObjectTypeDefinitionNode) {
        final typeDefinition = gql_schema.ObjectTypeDefinition(astNode);
        final isSystemType = isItSystemType(typeName: typeDefinitionName);
        final dartModel = makeModelClass(
          typeDefinition: typeDefinition,
          typeDefinitionName: typeDefinitionName,
          implementsInterfaces: typeDefinition.interfaces,
          serializable: !isSystemType,
        );
        finalClasses.putIfAbsent(dartModel.name, () => dartModel);
        // FIXME: Issue #6: refactor: separate models from input classes
        if (isSystemType || isItResultListType(typeName: typeDefinitionName)) {
          continue;
        }
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
        finalClasses.putIfAbsent(dartInterface.name, () => dartInterface);
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
      models: finalClasses.values,
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
    bool serializable = false,
  }) {
    final Set<Field> definedFields = {};
    final Set<Method> definedMethods = {};
    final Set<Constructor> definedConstructors = {};
    final Set<Parameter> defaultConstructorInitializers = {};
    for (final field in typeDefinition.fields) {
      final args = field.args;
      if (args != null && args.isNotEmpty == true) {
        fillClassMethodField(
          methodsDiefinitions: definedMethods,
          name: field.name,
          // FIXME: errors happened with comments
          description: '', //field.description ,
          baseTypeName: field.type?.baseTypeName,
          args: args,
        );
      } else {
        fillClassParameterFromField(
          definedFields: definedFields,
          isRequired: true,
          defaultConstructorInitializers: defaultConstructorInitializers,
          name: field.name,
          // FIXME: errors happened with comments
          description: '', //field.description ,
          baseTypeName: field.type?.baseTypeName,
        );
      }
    }
    if (serializable) {
      fillSerializers(
        definedMethods: definedMethods,
        definedConstructors: definedConstructors,
        typeName: typeDefinitionName,
      );
    }
    final dartClass = makeClassContructor(
      serializable: serializable,
      definedFields: definedFields,
      definedMethods: definedMethods,
      definedConstructors: definedConstructors,
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
    final strBuffer = StringBuffer();

    final camelModelName = properModelType.toCamelCase();
    final pluralModelName = properModelType.toPluralName();
    final fieldDefinitionNames = getModelFieldNames(
      fields: fieldDefinitions,
    );
    final defaultModelFragment = '""';

    // ********** CALLBACKS ******
    String getCallbackStr({
      required String operationName,
      bool isPlural = false,
    }) {
      return """
          (json){
            final verifiedJson = ArgumentError.checkNotNull(json,'json');
            return $properModelType.fromJson(
              verifiedJson["$operationName${isPlural ? pluralModelName : properModelType}"],
            );
          }"""
          .unindent();
    }

    final mutationCreateArgs = 'Create${properModelType}Input';
    final mutationCreateCallback = getCallbackStr(operationName: 'create');

    final mutationUpdateArgs = 'Mutate${properModelType}Input';
    final mutationUpdateCallback = getCallbackStr(operationName: 'update');

    final mutationDeleteArgs = 'Mutate${properModelType}Input';
    final mutationDeleteCallback = getCallbackStr(operationName: 'delete');

    final queryGetArgs = properModelType;
    final queryGetCallback = getCallbackStr(operationName: 'get');

    final queryFindArgs = '${properModelType}Filter';
    final queryFindResult = '${properModelType}ResultList';
    final queryFindCallback = getCallbackStr(
      operationName: 'find',
      isPlural: true,
    );

    final modelName = '${camelModelName}Model';
    final modelProviderStr = '''
          final use${properModelType}State = Provider<
            CactusModelState<
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
            >
          >((_) =>
            CactusModelState<
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
              cactusModel: $modelName,
            )
          );
        '''
        .unindent();

    // TODO: add params
    final modelStr = '''
        final $modelName = CactusSync.attachModel<
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
              graphqlModelFieldNames: $fieldDefinitionNames,
              graphqlModelName: '$properModelType',
              defaultModelFragment: $defaultModelFragment,
              createFromJsonCallback: $mutationCreateCallback,
              findFromJsonCallback: $queryFindCallback,
              getFromJsonCallback: $queryGetCallback,
              removeFromJsonCallback: $mutationDeleteCallback,
              updateFromJsonCallback: $mutationUpdateCallback,
            )
        );
      '''
        .unindent();
    strBuffer.writeAll([modelProviderStr, modelStr], "\n");
    return strBuffer;
  }

  /// We will remove any relationships by default for safety
  /// User anyway in anytime may call it with custom gql
  /// the idea is to get names of queired fields
  List<String?> getModelFieldNames({
    required List<gql_schema.FieldDefinition> fields,
  }) {
    final fieldsNames = fields
        .where((el) =>
            el.description?.toLowerCase().contains('manytoone') != true &&
            el.description?.toLowerCase().contains('onetomany') != true &&
            el.description?.toLowerCase().contains('onetoone') != true)
        .map((el) => el.name)
        .whereType<String>()
        .map((e) => "'$e'");

    return fieldsNames.toList();
  }

  bool isItSystemType({required String typeName}) =>
      typeName.contains('_') ||
      (() {
        switch (typeName.toLowerCase()) {
          case 'query':
          case 'mutation':
          case 'subscription':
            return true;
          default:
            return false;
        }
      })();
  bool isItResultListType({required String typeName}) =>
      typeName.contains('ResultList');
}

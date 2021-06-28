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
      prepareModels(
        finalClasses: finalClasses,
        finalProviderBuffer: finalProviderBuffer,
        typeNode: typeNode,
      );
    }
    return ModelsAndProvidersResult(
      models: finalClasses.values,
      providers: finalProviderBuffer,
    );
  }

  void prepareModels({
    required gql_schema.TypeDefinition? typeNode,
    required StringBuffer finalProviderBuffer,
    required Map<String /** Class name*/, Class> finalClasses,
  }) {
    if (typeNode == null) return;
    final astNode = typeNode.astNode;

    final typeDefinitionName = typeNode.name;
    if (typeDefinitionName == null) return;

    if (astNode is ObjectTypeDefinitionNode) {
      final typeDefinition = gql_schema.ObjectTypeDefinition(astNode);
      final isSystemType = isItGraphqlSystemType(typeName: typeDefinitionName);
      final isResultList = isItResultListType(typeName: typeDefinitionName);
      final dartModel = makeModelClass(
        typeDefinition: typeDefinition,
        typeDefinitionName: typeDefinitionName,
        implementsInterfaces: typeDefinition.interfaces,
        serializable: !isSystemType,
        isResultList: isResultList,
        isEquatable: !isResultList,
      );
      finalClasses.putIfAbsent(dartModel.name, () => dartModel);
      // FIXME: Issue #6: refactor: separate models from input classes
      if (isSystemType || isResultList) return;

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
    bool isResultList = false,
    bool isEquatable = false,
  }) {
    final Set<Field> definedFields = {};
    final Set<Method> definedMethods = {};
    final Set<Constructor> definedConstructors = {};
    final Set<Parameter> defaultConstructorInitializers = {};

    String itemsBaseTypeName = '';

    for (final field in typeDefinition.fields) {
      /// FIXME: will suppose that all types are same.
      /// its wrong but for the concept should work
      if (field.type?.astNode is ListTypeNode) {
        final isItems = field.name == 'items';
        fillClassParamFromListTypeField(
          definedFields: definedFields,
          defaultConstructorInitializers: defaultConstructorInitializers,
          // FIXME: as
          field: field, isItems: isItems,
        );
        if (isItems) {
          itemsBaseTypeName = field.type?.baseTypeName ?? '';
        }
      } else {
        fillClassParamFromFieldDefinition(
          definedFields: definedFields,
          defaultConstructorInitializers: defaultConstructorInitializers,
          field: field,
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
      isResultList: isResultList,
      definedFields: definedFields,
      definedMethods: definedMethods,
      definedConstructors: definedConstructors,
      defaultConstructorInitializers: defaultConstructorInitializers,
      typeDefinitionName: typeDefinitionName,
      abstract: abstract,
      implementsInterfaces: implementsInterfaces,
      baseTypeName: itemsBaseTypeName,
      isEquatable: isEquatable,
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
      String? jsonSerializableName,
    }) {
      return """
          (json){
            final verifiedJson = ArgumentError.checkNotNull(json,'json');
            return ${jsonSerializableName ?? properModelType}.fromJson(
              verifiedJson["$operationName${isPlural ? pluralModelName : properModelType}"] as Map<String, dynamic>,
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

    final queryGetCallback = getCallbackStr(operationName: 'get');

    final queryFindArgs = '${properModelType}Filter';
    final queryFindResult = '${properModelType}ResultList';
    final queryFindCallback = getCallbackStr(
      operationName: 'find',
      isPlural: true,
      jsonSerializableName: queryFindResult,
    );

    final modelName = '${camelModelName}Model';
    final modelStateName = '${modelName}State';
    final modelStateNotifierName = '${modelStateName}Notifier';

    final modelProviderStr = '''
          final $modelStateName = CactusModelState<
              $properModelType,
              $mutationCreateArgs,
              $properModelType,
              $mutationUpdateArgs,
              $properModelType,
              $mutationDeleteArgs,
              $properModelType,
              $properModelType,
              $queryFindArgs,
              $queryFindResult
            >(
              cactusModel: $modelName,
            );
          final $modelStateNotifierName = StateNotifierProvider<
            CactusModelState<
              $properModelType,
              $mutationCreateArgs,
              $properModelType,
              $mutationUpdateArgs,
              $properModelType,
              $mutationDeleteArgs,
              $properModelType,
              $properModelType,
              $queryFindArgs,
              $queryFindResult
            >,
            Set<$properModelType?>
          >((_) => $modelStateName);
          final ${modelStateName}List = Provider((ref)=>ref.watch($modelStateNotifierName).toList());
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
    strBuffer.writeAll([
      modelStr,
      modelProviderStr,
    ], "\n");
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

  bool isItGraphqlSystemType({required String typeName}) =>
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
  static bool isItResultListType({required String typeName}) =>
      typeName.toLowerCase().contains('resultlist');
}

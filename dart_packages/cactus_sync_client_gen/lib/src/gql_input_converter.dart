import 'package:cactus_sync_client_gen/src/gql_object_type_definition.dart';
import 'package:code_builder/code_builder.dart';
import "package:gql/ast.dart" as ast;
import "package:gql/schema.dart" as gql_schema;

class GqlInputs extends GqlObjectTypeDefinition {
  /// Use it to generate inputs for mutations
  /// and queries
  Set<Class> fromSchema({
    required List<gql_schema.InputObjectTypeDefinition> inputObjectTypes,
  }) {
    final finalClasses = <Class>{};
    for (final item in inputObjectTypes) {
      final inputClass = toClassFromTypeDefinition(
        typeDefinition: item,
      );

      finalClasses.add(inputClass);
    }

    return finalClasses;
  }

  Class toClassFromTypeDefinition({
    required gql_schema.InputObjectTypeDefinition typeDefinition,
    List<gql_schema.InterfaceTypeDefinition>? implementsInterfaces,
  }) {
    final List<Field> definedFields = [];
    final List<Method> methodsDefinitions = [];
    final List<Parameter> defaultConstructorInitializers = [];
    for (final gqlField in typeDefinition.fields) {
      fillClassParameterFromField(
        definedFields: definedFields,
        defaultConstructorInitializers: defaultConstructorInitializers,
        name: gqlField.name,
        description: gqlField.description,
        baseTypeName: gqlField.type?.baseTypeName,
      );
    }
    final inputClass = makeClassContructor(
      definedFields: definedFields,
      implementsInterfaces: implementsInterfaces,
      methodsDefinitions: methodsDefinitions,
      defaultConstructorInitializers: defaultConstructorInitializers,
      typeDefinitionName: typeDefinition.name,
    );
    return inputClass;
  }

  gql_schema.FieldDefinition? makeFieldDefinitionFormInput(
      gql_schema.InputValueDefinition inputValueDefinition) {
    final name = ast.NameNode(value: inputValueDefinition.name ?? '');
    final type = inputValueDefinition.type?.astNode;
    final description = ast.StringValueNode(
      value: inputValueDefinition.description ?? '',
      isBlock: false,
    );
    if (type == null) return null;
    final fieldDefinition = gql_schema.FieldDefinition(
      ast.FieldDefinitionNode(
        name: name,
        type: type,
        description: description,
      ),
    );
    return fieldDefinition;
  }
}

import 'package:cactus_sync_client_gen/src/gql_object_type_definition.dart';
import 'package:code_builder/code_builder.dart';
import "package:gql/schema.dart" as gql_schema;

class GqlInputs extends GqlObjectTypeDefinition {
  /// Use it to generate inputs for mutations
  /// and queries
  Set<Class> fromSchema({
    required List<gql_schema.InputObjectTypeDefinition> inputObjectTypes,
  }) {
    final finalClasses = <Class>{};
    for (final item in inputObjectTypes) {
      final inputClass = toClassFromTypeDefinition(typeDefinition: item);

      finalClasses.add(inputClass);
    }

    return finalClasses;
  }

  Class toClassFromTypeDefinition({
    required gql_schema.InputObjectTypeDefinition typeDefinition,
  }) {
    final List<Field> fieldsDiefinitions = [];
    final List<Parameter> defaultConstructorInitializers = [];
    for (final gqlField in typeDefinition.fields) {
      fillClassParameterFromField(
        fieldsDiefinitions: fieldsDiefinitions,
        defaultConstructorInitializers: defaultConstructorInitializers,
        name: gqlField.name,
        description: gqlField.description,
        baseTypeName: gqlField.type?.baseTypeName,
      );
    }
    final inputClass = makeClassContructor(
      fieldsDiefinitions: fieldsDiefinitions,
      defaultConstructorInitializers: defaultConstructorInitializers,
      typeDefinitionName: typeDefinition.name,
    );
    return inputClass;
  }
}

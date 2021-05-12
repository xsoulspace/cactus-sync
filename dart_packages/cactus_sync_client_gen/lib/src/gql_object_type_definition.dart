import 'package:cactus_sync_client_gen/src/gql_input_field_helper.dart';
import 'package:cactus_sync_client_gen/src/gql_scalar.dart';
import 'package:code_builder/code_builder.dart';

class GqlObjectTypeDefinition {
  Class makeClassContructor({
    required List<Field> fieldsDiefinitions,
    required List<Parameter> defaultConstructorInitializers,
    required String? typeDefinitionName,
    bool abstract = false,
  }) {
    if (typeDefinitionName == null || typeDefinitionName.isEmpty) {
      throw ArgumentError.value(
        typeDefinitionName,
        'typeDefinitionName',
        'Empty name',
      );
    }
    final defaultConstructor = Constructor((c) => c
      ..constant = true
      ..optionalParameters.addAll(
        defaultConstructorInitializers,
      ));

    final finalClass = Class(
      (b) => b
        ..name = typeDefinitionName
        ..fields.addAll(fieldsDiefinitions)
        ..constructors.addAll([defaultConstructor])
        ..abstract = abstract

      // ..methods.add(Method.returnsVoid((b) => b
      //   ..name = 'eat'
      //   ..body = const Code("print('Yum');")))
      ,
    );
    return finalClass;
  }

  void fillClassParametersFromField({
    required List<Field> fieldsDiefinitions,
    required List<Parameter> defaultConstructorInitializers,
    required String? name,
    required String? description,
    required String? baseTypeName,
  }) {
    final rawGqlFieldName = name ?? '';
    final verifiedGqlFieldName = GqlInputFieldHelper.verifyName(
      name: rawGqlFieldName,
    );
    final gqlFieldName = verifiedGqlFieldName.name;
    if (gqlFieldName.isEmpty) return;

    final rawTypeName = baseTypeName ?? '';
    final typeName = GqlScalar.verifyName(
      name: rawTypeName,
    );
    if (typeName.isEmpty) return;

    fieldsDiefinitions.add(
      Field(
        (f) {
          f
            ..modifier = FieldModifier.final$
            ..name = gqlFieldName
            ..type = refer(typeName)
            ..docs.add(description ?? '');

          if (verifiedGqlFieldName.isKeyword) {
            f.annotations.addAll(
              [
                refer(
                  'BuiltValueField',
                  'package:built_value/built_value.dart',
                ).call(
                  [],
                  {
                    'wireName': refer(
                      "'$rawGqlFieldName'",
                    ),
                  },
                ),
              ],
            );
          }
        },
      ),
    );
    defaultConstructorInitializers.add(
      Parameter(
        (p) => p
          ..toThis = true
          ..named = true
          ..required = true
          ..name = gqlFieldName,
      ),
    );
  }
}

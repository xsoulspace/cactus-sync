import 'package:cactus_sync_client_gen/src/gql_input_field_helper.dart';
import 'package:cactus_sync_client_gen/src/gql_scalar.dart';
import 'package:code_builder/code_builder.dart';
import "package:gql/schema.dart" as gql_schema;

class _VerifiedTypeName {
  final bool isKeyword;
  final String typedefName;
  final String baseTypeName;
  final String rawGqlFieldName;
  const _VerifiedTypeName({
    required this.isKeyword,
    required this.typedefName,
    required this.baseTypeName,
    required this.rawGqlFieldName,
  });
}

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

  _VerifiedTypeName? verifyTypeAndName({
    required String? typedefName,
    required String? baseTypeName,
  }) {
    final rawGqlFieldName = typedefName ?? '';
    final verifiedGqlFieldName = GqlInputFieldHelper.verifyName(
      name: rawGqlFieldName,
    );
    final gqlFieldName = verifiedGqlFieldName.name;
    if (gqlFieldName.isEmpty) return null;

    final rawTypeName = baseTypeName ?? '';
    final typeName = GqlScalar.verifyName(
      name: rawTypeName,
    );
    if (typeName.isEmpty) return null;
    return _VerifiedTypeName(
      rawGqlFieldName: rawGqlFieldName,
      baseTypeName: typeName,
      isKeyword: verifiedGqlFieldName.isKeyword,
      typedefName: verifiedGqlFieldName.name,
    );
  }

  void fillClassMethodField({
    required List<Field> fieldsDiefinitions,
    required String? name,
    required String? description,
    required String? baseTypeName,
    required List<gql_schema.InputValueDefinition> args,
  }) {}
  void fillClassParameterFromField({
    required List<Field> fieldsDiefinitions,
    required List<Parameter> defaultConstructorInitializers,
    required String? name,
    required String? description,
    required String? baseTypeName,
  }) {
    final verifiedTypeNames = verifyTypeAndName(
      baseTypeName: baseTypeName,
      typedefName: name,
    );
    if (verifiedTypeNames == null) return;
    fieldsDiefinitions.add(
      Field(
        (f) {
          f
            ..modifier = FieldModifier.final$
            ..name = gqlFieldName
            ..type = refer(typeName)
            ..docs.add(description ?? '');

          if (verifiedTypeNames.isKeyword) {
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

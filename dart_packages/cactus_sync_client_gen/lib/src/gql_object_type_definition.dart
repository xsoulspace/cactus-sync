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
    required List<Method> methodsDefinitions,
    required List<Parameter> defaultConstructorInitializers,
    required String? typeDefinitionName,
    bool abstract = false,
    List<gql_schema.InterfaceTypeDefinition?>? implementsInterfaces,
  }) {
    if (typeDefinitionName == null || typeDefinitionName.isEmpty) {
      throw ArgumentError.value(
        typeDefinitionName,
        'typeDefinitionName',
        'Empty name',
      );
    }
    final defaultConstructor = Constructor(
      (c) => c
        ..constant = true
        ..optionalParameters.addAll(
          defaultConstructorInitializers,
        ),
    );

    final finalClass = Class(
      (b) => b
        ..name = typeDefinitionName
        ..fields.addAll(fieldsDiefinitions)
        ..methods.addAll(methodsDefinitions)
        ..constructors.addAll([defaultConstructor])
        ..abstract = abstract
      // FIXME: interfaces are not working
      // ..implements.addAll(
      //   (implementsInterfaces ?? [])
      //       .map(
      //         (e) => e?.name != null ? refer("'${e?.name ?? ''}'") : null,
      //       )
      //       .whereType<Reference>(),
      // )
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
      typedefName: verifiedGqlFieldName.name,
      baseTypeName: typeName,
      isKeyword: verifiedGqlFieldName.isKeyword,
    );
  }

  void fillClassMethodField({
    required List<Method> methodsDiefinitions,
    required String? name,
    required String? description,
    required String? baseTypeName,
    required List<gql_schema.InputValueDefinition> args,
  }) {
    final verifiedTypeNames = verifyTypeAndName(
      baseTypeName: baseTypeName,
      typedefName: name,
    );
    if (verifiedTypeNames == null) return;
  }

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
            ..name = verifiedTypeNames.typedefName
            ..type = refer(
              // FIXME: temp solving arrays
              verifiedTypeNames.typedefName == 'items'
                  ? "List<${verifiedTypeNames.baseTypeName}?>"
                  : verifiedTypeNames.baseTypeName,
            )
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
                      "'${verifiedTypeNames.rawGqlFieldName}'",
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
          ..name = verifiedTypeNames.typedefName,
      ),
    );
  }
}

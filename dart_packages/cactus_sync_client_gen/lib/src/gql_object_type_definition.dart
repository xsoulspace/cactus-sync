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
    required Set<Field> definedFields,
    required Set<Method> definedMethods,
    required Set<Constructor> definedConstructors,
    required Set<Parameter> defaultConstructorInitializers,
    required String? typeDefinitionName,
    bool abstract = false,
    List<gql_schema.InterfaceTypeDefinition?>? implementsInterfaces,
    bool serializable = false,
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
      (b) {
        b
          ..annotations.addAll(serializable
              ? [
                  refer(
                    'JsonSerializable',
                    'package:json_annotation/json_annotation.dart',
                  ).call([], {
                    'explicitToJson': refer('true'),
                  }),
                ]
              : [])
          ..name = typeDefinitionName
          ..fields.addAll(definedFields)
          ..methods.addAll(definedMethods)
          ..constructors.addAll(
            [
              defaultConstructor,
              ...definedConstructors,
            ],
          )
          ..abstract = abstract;
        if (serializable) {
          b.extend = refer(
            'Serializable',
            'package:cactus_sync_client/cactus_sync_client.dart',
          );
        }
      }
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
    required Set<Method> methodsDiefinitions,
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
    required Set<Field> definedFields,
    required Set<Parameter> defaultConstructorInitializers,
    required String? name,
    required String? description,
    required String? baseTypeName,
    required bool isRequired,
  }) {
    final verifiedTypeNames = verifyTypeAndName(
      baseTypeName: baseTypeName,
      typedefName: name,
    );
    if (verifiedTypeNames == null) return;
    final fieldTypeName = (() {
      // FIXME: temp solving arrays
      final name = verifiedTypeNames.typedefName == 'items'
          ? "List<${verifiedTypeNames.baseTypeName}?>"
          : verifiedTypeNames.baseTypeName;

      if (isRequired) return name;
      return "$name?";
    })();
    final field = Field(
      (f) {
        f
          ..modifier = FieldModifier.final$
          ..name = verifiedTypeNames.typedefName
          ..type = refer(fieldTypeName)
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
    );
    definedFields.add(field);

    defaultConstructorInitializers.add(
      Parameter(
        (p) => p
          ..toThis = true
          ..named = true
          ..required = isRequired
          ..name = verifiedTypeNames.typedefName,
      ),
    );
  }

  void fillSerializers({
    required Set<Method> definedMethods,
    required Set<Constructor> definedConstructors,
    required String? typeName,
  }) {
    if (typeName?.isEmpty == true) return;
    // @override
    // Map<String, dynamic> toJson() => _$ModelToJson(this);
    final toJsonMethod = Method(
      (m) => m
        ..name = 'toJson'
        ..returns = refer('Map<String, dynamic>')
        ..body = Code('return _\$${typeName}ToJson(this);'),
    );
    definedMethods.add(toJsonMethod);
    // factory Model.fromJson(Map<String, dynamic> json) =>
    //   _$ModelFromJson(json);
    final fromJsonFactory = Constructor(
      (c) => c
        ..factory = true
        ..requiredParameters.addAll(
          [
            Parameter(
              (p) => p
                ..name = 'json'
                ..type = refer('Map<String, dynamic>'),
            )
          ],
        )
        ..body = Code(
          'return _\$${typeName}FromJson(json);',
        )
        ..name = 'fromJson',
    );
    definedConstructors.add(fromJsonFactory);
  }
}

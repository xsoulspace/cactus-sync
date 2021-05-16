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

/// The [isResultList] is a param that needed to
/// point class with items.
/// The [baseTypeName] is a param that used as generic type
/// for list in case if it is a result list class
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
    bool isResultList = false,
    String baseTypeName = '',
    bool isEquatable = false,
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
        )
        ..initializers.addAll(
          [
            if (isResultList)
              const Code(
                'super(items: items)',
              ),
          ],
        ),
    );
    final getters = isEquatable
        ? [
            Method(
              (m) => m
                ..annotations.addAll([refer('override')])
                ..name = 'props'
                ..type = MethodType.getter
                ..body = Code((() {
                  final names = definedFields
                      .map((f) => f.name)
                      .where((f) => f.toLowerCase().contains('id'))
                      .join(',');
                  return "return [$names];";
                })())
                ..returns = refer('List<dynamic?>'),
            ),
            Method(
              (m) => m
                ..annotations.addAll([refer('override')])
                ..name = 'stringify'
                ..type = MethodType.getter
                ..body = const Code('return true;')
                ..returns = refer('bool'),
            ),
          ]
        : [];
    final finalClass = Class(
      (b) {
        b
          ..annotations.addAll(
            serializable
                ? [
                    refer(
                      'JsonSerializable',
                      'package:json_annotation/json_annotation.dart',
                    ).call(
                      [],
                      {
                        'explicitToJson': refer('true'),
                      },
                    ),
                  ]
                : [],
          )
          ..name = typeDefinitionName
          ..fields.addAll(definedFields)
          ..methods.addAll(
            [
              ...getters,
              ...definedMethods,
            ],
          )
          ..constructors.addAll(
            [
              defaultConstructor,
              ...definedConstructors,
            ],
          )
          ..implements.addAll(
            serializable
                ? [
                    refer(
                      'SerializableModel',
                      'package:cactus_sync_client/cactus_sync_client.dart',
                    ),
                  ]
                : [],
          )
          ..abstract = abstract;
        if (isResultList) {
          b.extend = refer(
            'GraphbackResultList<$baseTypeName>',
            'package:cactus_sync_client/cactus_sync_client.dart',
          );
        } else if (isEquatable) {
          b.extend = refer(
            'Equatable',
            'package:equatable/equatable.dart',
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
    bool isResultList = false,
  }) {
    final verifiedTypeNames = verifyTypeAndName(
      baseTypeName: baseTypeName,
      typedefName: name,
    );
    if (verifiedTypeNames == null) return;
    final fieldTypeName = (() {
      // FIXME: Issue #2: how to handle array type?
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
    final isItemsFieldInsideResultList =
        isResultList && verifiedTypeNames.typedefName == 'items';
    final isNotItemsFieldInsideResultList = !isItemsFieldInsideResultList;
    if (isNotItemsFieldInsideResultList) definedFields.add(field);
    defaultConstructorInitializers.add(
      Parameter(
        (p) {
          p
            ..toThis = isNotItemsFieldInsideResultList
            ..named = true
            ..required = isRequired
            ..name = verifiedTypeNames.typedefName;
          if (isItemsFieldInsideResultList) {
            p.type = refer(fieldTypeName);
          }
        },
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
        ..annotations.addAll([refer('override')])
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

import 'package:cactus_sync_client_gen/src/gql_input_field_helper.dart';
import 'package:cactus_sync_client_gen/src/gql_scalar.dart';
import 'package:cactus_sync_client_gen/src/used_directives.dart';
import 'package:code_builder/code_builder.dart';
import "package:gql/schema.dart" as gql_schema;

class _VerifiedTypeName {
  final bool isKeyword;
  final String fieldName;
  final String fieldType;
  final String rawGqlFieldName;
  const _VerifiedTypeName({
    required this.isKeyword,
    required this.fieldName,
    required this.fieldType,
    required this.rawGqlFieldName,
  });
}

/// The [isResultList] is a param that needed to
/// point class with items.
/// The [fieldType] is a param that used as generic type
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
        ..constant = false
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
    final isVerifiedEquatable = isEquatable && !isResultList;
    final getters = isVerifiedEquatable
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
                ..returns = refer('List<dynamic>'),
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
        : <Method>[];
    final finalClass = Class(
      (b) {
        b
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
          ..abstract = abstract;

        if (serializable) {
          if (isResultList) {
            b.extend = refer(
              'GraphbackResultList<$baseTypeName>',
              UsedDirectives.cactusClient,
            );
          } else {
            b.extend = refer(
              'graphql.JsonSerializable',
              UsedDirectives.graphqlClient,
            );
          }

          b.annotations.addAll([
            refer(
              'JsonSerializable',
              UsedDirectives.jsonAnnotation,
            ).call(
              [],
              {
                'explicitToJson': refer('true'),
                'includeIfNull': refer('false'),
              },
            ),
          ]);
        }
        if (isVerifiedEquatable) {
          b.mixins.addAll(
            [
              refer(
                'EquatableMixin',
                UsedDirectives.equatable,
              ),
            ],
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
    required String? rawFieldName,
    required String? rawFieldType,
  }) {
    final rawGqlFieldName = rawFieldName ?? '';
    final verifiedGqlFieldName = GqlInputFieldHelper.verifyName(
      name: rawGqlFieldName,
    );
    final gqlFieldName = verifiedGqlFieldName.name;
    if (gqlFieldName.isEmpty) return null;

    final rawTypeName = rawFieldType ?? '';
    final typeName = GqlScalar.verifyName(
      name: rawTypeName,
    );
    if (typeName.isEmpty) return null;
    return _VerifiedTypeName(
      rawGqlFieldName: rawGqlFieldName,
      fieldName: verifiedGqlFieldName.name,
      fieldType: typeName,
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
      rawFieldType: baseTypeName,
      rawFieldName: name,
    );
    if (verifiedTypeNames == null) return;
  }

  void fillClassParamFromListTypeField({
    required Set<Field> definedFields,
    required Set<Parameter> defaultConstructorInitializers,
    required gql_schema.FieldDefinition field,
    required bool isItems,
    required bool isResultList,
  }) =>
      fillClassParamFromFieldDefinition(
        defaultConstructorInitializers: defaultConstructorInitializers,
        definedFields: definedFields,
        field: field,
        isList: true,
        isItems: isItems,
        isResultList: isResultList,
      );

  void fillClassParamFromFieldDefinition({
    required Set<Field> definedFields,
    required Set<Parameter> defaultConstructorInitializers,
    required gql_schema.FieldDefinition field,
    required bool isResultList,
    bool isList = false,
    bool isItems = false,
  }) {
    final rawFieldType = field.type?.baseTypeName ?? '';
    final rawFieldName = field.name;
    final isRequired = field.type?.isNonNull == true;
    final isNullable =
        (isResultList && !isItems) || (!isResultList && isList) || !isRequired;
    final verifiedTypeNames = verifyTypeAndName(
      rawFieldType: rawFieldType,
      rawFieldName: rawFieldName,
    );

    if (verifiedTypeNames == null) return;

    final correctedFieldTypeName = (() {
      if (isList) return "List<${verifiedTypeNames.fieldType}?>";
      return verifiedTypeNames.fieldType;
    })();

    final optionalFieldName = "$correctedFieldTypeName?";
    final fieldTypeName = (() {
      if (isNullable) return optionalFieldName;
      return correctedFieldTypeName;
    })();

    final classField = Field(
      (f) {
        f
          ..modifier = FieldModifier.final$
          ..name = verifiedTypeNames.fieldName
          ..type = refer(fieldTypeName)
          ..docs.addAll(
            "/// ${field.description}".replaceAll('\n', "\n ///").split("\n"),
          );

        if (!verifiedTypeNames.isKeyword) return;

        f.annotations.addAll(
          [
            refer(
              'BuiltValueField',
              UsedDirectives.builtValue,
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
      },
    );
    final isNotItems = !isItems;
    if (isNotItems) definedFields.add(classField);
    defaultConstructorInitializers.add(
      Parameter(
        (p) {
          p
            ..toThis = isNotItems
            ..named = true
            ..required = isRequired
            ..name = verifiedTypeNames.fieldName;
          if (isItems) {
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

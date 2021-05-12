import 'package:cactus_sync_client_gen/src/gql_dart_formatter.dart';
import 'package:cactus_sync_client_gen/src/gql_input_field_helper.dart';
import 'package:cactus_sync_client_gen/src/gql_scalar.dart';
import 'package:code_builder/code_builder.dart';
import "package:gql/schema.dart" as gql_schema;

class GqlInputs {
  /// Use it to generate inputs for mutations
  /// and queries
  static StringBuffer fromSchema({
    required List<gql_schema.InputObjectTypeDefinition> inputObjectTypes,
  }) {
    final finalClasses = StringBuffer();
    for (final item in inputObjectTypes) {
      final inputClass = classFromTypeDefinition(typeDefinition: item);

      // Formatting
      final formattedStrInputClass = GqlDartFormatter.stringifyAndFormat(
        dartClass: inputClass,
      );

      finalClasses.writeln(formattedStrInputClass);
    }

    return finalClasses;
  }

  static Class classFromTypeDefinition({
    required gql_schema.InputObjectTypeDefinition typeDefinition,
  }) {
    final List<Field> fieldsDiefinitions = [];
    final List<Parameter> defaultConstructorInitializers = [];
    for (final gqlField in typeDefinition.fields) {
      final rawGqlFieldName = gqlField.name ?? '';
      final verifiedGqlFieldName = GqlInputFieldHelper.verifyName(
        name: rawGqlFieldName,
      );
      final gqlFieldName = verifiedGqlFieldName.name;
      if (gqlFieldName.isEmpty) continue;

      final rawTypeName = gqlField.type?.baseTypeName ?? '';
      final typeName = GqlScalar.verifyName(
        name: rawTypeName,
      );
      if (typeName.isEmpty) continue;

      fieldsDiefinitions.add(
        Field(
          (f) {
            f
              ..modifier = FieldModifier.final$
              ..name = gqlFieldName
              ..type = refer(typeName)
              ..docs.add(gqlField.description ?? '');

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

    final defaultConstructor = Constructor((c) => c
      ..constant = true
      ..optionalParameters.addAll(
        defaultConstructorInitializers,
      ));

    final inputClass = Class(
      (b) => b
        ..name = typeDefinition.name
        ..fields.addAll(fieldsDiefinitions)
        ..constructors.addAll([defaultConstructor])
      // ..methods.add(Method.returnsVoid((b) => b
      //   ..name = 'eat'
      //   ..body = const Code("print('Yum');")))
      ,
    );

    return inputClass;
  }
}

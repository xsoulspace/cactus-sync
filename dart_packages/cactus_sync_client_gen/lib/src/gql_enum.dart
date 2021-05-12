import 'package:cactus_sync_client_gen/src/gql_dart_formatter.dart';
import 'package:code_builder/code_builder.dart';
import "package:gql/schema.dart" as gql_schema;

class GqlEnums {
  static StringBuffer fromSchema({
    required List<gql_schema.EnumTypeDefinition> schemaEnums,
  }) {
    final finalBuffer = StringBuffer();
    for (final item in schemaEnums) {
      final dartEnum = Enum(
        (e) => e
          ..name = item.name
          ..values.addAll(
            item.values.map(
              (v) => EnumValue(
                (ev) => ev
                  ..name = v.name
                  ..docs.add(v.description ?? ''),
              ),
            ),
          ),
      );
      final formattedStr = GqlDartFormatter.stringifyAndFormat(
        dartEnum: dartEnum,
      );
      finalBuffer.writeln(formattedStr);
    }
    return finalBuffer;
  }
}

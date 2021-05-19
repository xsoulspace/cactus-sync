import 'package:code_builder/code_builder.dart';
import "package:gql/schema.dart" as gql_schema;

class GqlEnums {
  static Iterable<Enum> fromSchema({
    required List<gql_schema.EnumTypeDefinition> schemaEnums,
  }) {
    final dartEnums = <String, Enum>{};
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
      dartEnums.putIfAbsent(dartEnum.name, () => dartEnum);
    }
    return dartEnums.values;
  }
}

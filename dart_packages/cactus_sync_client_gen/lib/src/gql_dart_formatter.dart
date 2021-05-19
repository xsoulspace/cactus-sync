import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:indent/indent.dart';

class GqlDartFormatter {
  static String formatAndStringify({
    required Library library,
  }) {
    final emitter = DartEmitter(
      allocator: Allocator.simplePrefixing(),
      useNullSafetySyntax: true,
    );

    final formattedStr =
        DartFormatter().format("${library.accept(emitter)}").unindent();

    return formattedStr;
  }
}

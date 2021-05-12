import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:indent/indent.dart';

class GqlDartFormatter {
  static StringBuffer stringifyAndFormat({
    Class? dartClass,
    Enum? dartEnum,
  }) {
    final emitter = DartEmitter();
    final dartClassString = dartClass?.accept(emitter).toString() ?? '';
    final dartEnumString = dartEnum?.accept(emitter).toString() ?? '';
    final formattedBuffer = StringBuffer();

    for (final str in [
      dartClassString,
      dartEnumString,
    ]) {
      final formattedStr = DartFormatter()
          .format(
            str,
          )
          .unindent();
      formattedBuffer.writeln(formattedStr);
    }

    return formattedBuffer;
  }
}

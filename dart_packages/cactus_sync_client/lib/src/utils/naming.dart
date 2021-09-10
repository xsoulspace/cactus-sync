/// This extensition able to plurify name
/// If you update this file please update file
/// in cactus_sync_client_gen too
part of cactus_utils;

extension StringUtil on String {
  String toPluralName() {
    final lastLetter = substring(length - 1).toLowerCase();
    var newStr = toString();
    switch (lastLetter) {
      case 'h':
        newStr = '${newStr}es';
        return newStr;
      case 'y':
        newStr = newStr.substring(0, newStr.length - 1);
        newStr = '${newStr}ies';
        return newStr;
      default:
        return '${this}s';
    }
  }

  String toCamelCase() {
    final str = this;
    if (str.isEmpty) return '';
    final strBuffer = StringBuffer();
    final first = str[0].toLowerCase();
    final rest = str.substring(1);
    for (final txt in [first, rest]) {
      strBuffer.write(txt);
    }

    return strBuffer.toString();
  }
}

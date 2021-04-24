/// This extensition able to plurify name
/// If you update this file please update file
/// in cactus_sync_client_gen too
extension StringUtil on String {
  String toPluralName() {
    final str = this;
    final lastLetter = str.substring(str.length - 1).toLowerCase();
    var newStr = str.toString();
    switch (lastLetter) {
      case 'h':
        newStr = '${newStr}es';
        return newStr;
      case 'y':
        newStr = newStr.substring(0, newStr.length - 1);
        newStr = '${newStr}ies';
        return newStr;
      default:
        return '${str}s';
    }
  }
}

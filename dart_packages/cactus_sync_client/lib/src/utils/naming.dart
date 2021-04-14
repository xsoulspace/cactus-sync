class StringUtil {
  static String toPluralName(String str) {
    var lastLetter = str.substring(str.length - 1).toLowerCase();
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

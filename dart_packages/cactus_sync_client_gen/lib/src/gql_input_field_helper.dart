class VerifiedGqlInputFieldName {
  final String name;
  final bool isKeyword;
  const VerifiedGqlInputFieldName({
    required this.isKeyword,
    required this.name,
  });
}

class GqlInputFieldHelper {
  static VerifiedGqlInputFieldName verifyName({
    required String name,
  }) {
    switch (name) {
      case 'in':
        return const VerifiedGqlInputFieldName(
          isKeyword: true,
          name: 'ins',
        );
      default:
        return VerifiedGqlInputFieldName(
          isKeyword: false,
          name: name,
        );
    }
  }
}

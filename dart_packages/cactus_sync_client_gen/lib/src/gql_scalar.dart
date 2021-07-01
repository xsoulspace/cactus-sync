class GqlScalar {
  /// Mostly usefull to convert scalar to dart type
  static String verifyName({
    required String name,
  }) {
    /// Graphql Scalars
    /// TODO: make it modular. Implementation example:
    /// https://ferrygraphql.com/docs/custom-scalars/#create-a-custom-serializer
    ///
    /// ID: string;
    /// String: string;
    /// Boolean: boolean;
    /// Int: number;
    /// Float: number;
    /// GraphbackDateTime: any;
    /// GraphbackTimestamp: any;

    switch (name) {
      case 'ID':
        return 'String';
      case 'GraphbackDateTime':
        return 'int';
      case 'GraphbackTimestamp':
        return 'int';
      case 'Float':
        return 'double';
      case 'Int':
        return 'int';
      case 'Boolean':
        return 'bool';
      default:
        return name;
    }
  }
}

import 'package:graphql/client.dart';

/// Simple class with only one property - ID

class RecordedModel extends JsonSerializable {
  final String id;
  RecordedModel({
    required this.id,
  });
  @override
  Map<String, dynamic> toJson() => {'id': id};
}

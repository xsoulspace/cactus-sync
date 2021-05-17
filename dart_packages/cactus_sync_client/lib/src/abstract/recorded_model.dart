/// Simple class with only one property - ID
class RecordedModel {
  final String id;
  const RecordedModel({
    required this.id,
  });
  Map<String, dynamic> toJson() => {'id': id};
}

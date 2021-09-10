part of cactus_abstract;

/// Simple class with only one property - ID

class RecordedModel extends JsonSerializable {
  RecordedModel({
    required final this.id,
  });
  final String id;
  @override
  Map<String, dynamic> toJson() => {'id': id};
}

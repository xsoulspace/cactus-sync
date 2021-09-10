part of cactus_abstract;

// ignore: avoid_implementing_value_types
abstract class CactusEvent {}

/// Used to add states dependant from particaluar model
@immutable
class CactusAddEvent with EquatableMixin implements CactusEvent {
  const CactusAddEvent({
    required final this.result,
    required final this.modelName,
  });
  final GraphqlResult result;
  final String modelName;
  @override
  List<Object?> get props => [modelName];
  @override
  bool? get stringify => true;
}

/// Used to add states dependant from particaluar model
@immutable
class CactusUpdateEvent with EquatableMixin implements CactusEvent {
  const CactusUpdateEvent({
    required final this.result,
    required final this.modelName,
  });
  final GraphqlResult result;
  final String modelName;
  @override
  List<Object?> get props => [modelName];
  @override
  bool? get stringify => true;
}

@immutable
class CactusRemoveEvent with EquatableMixin implements CactusEvent {
  const CactusRemoveEvent({
    required final this.result,
    required final this.modelName,
  });
  final GraphqlResult result;
  final String modelName;
  @override
  List<Object?> get props => [modelName];
  @override
  bool? get stringify => true;
}

@immutable
class CactusResetStateEvent implements CactusEvent {
  const CactusResetStateEvent();
}

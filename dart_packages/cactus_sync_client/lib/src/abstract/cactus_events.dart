part of cactus_client_abstract;

// ignore: avoid_implementing_value_types
abstract class CactusEvent implements Equatable {}

/// Used to update states dependant from particaluar model
@immutable
class CactusAddUpdateEvent<T> with EquatableMixin implements CactusEvent {
  const CactusAddUpdateEvent({
    required final this.model,
    required final this.modelName,
  });
  final T model;
  final String modelName;
  @override
  List<Object?> get props => [modelName];
  @override
  bool? get stringify => true;
}

@immutable
class CactusRemoveEvent<T> with EquatableMixin implements CactusEvent {
  const CactusRemoveEvent({
    required final this.model,
    required final this.modelName,
  });
  final T model;
  final String modelName;
  @override
  List<Object?> get props => [modelName];
  @override
  bool? get stringify => true;
}

@immutable
class CactusResetStateEvent with EquatableMixin implements CactusEvent {
  const CactusResetStateEvent({
    required final this.modelName,
  });
  final String modelName;
  @override
  List<Object?> get props => [modelName];
  @override
  bool? get stringify => true;
}

part of cactus_abstract;

class CactusEmitter {
  /// to read more use https://pub.dev/packages/event_bus
  final source = EventBus();
  void add(final CactusEvent event) {
    source.fire(event);
  }
}

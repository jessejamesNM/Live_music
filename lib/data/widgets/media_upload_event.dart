// lib/core/event_bus.dart
class MediaUploadEvent {
  final String mediaUrl;
  
  MediaUploadEvent(this.mediaUrl);
}

class EventBus {
  static final EventBus _instance = EventBus._internal();
  final _eventControllers = <Type, List<Function>>{};

  factory EventBus() => _instance;

  EventBus._internal();

  void subscribe<T>(void Function(T) handler) {
    _eventControllers[T] ??= [];
    _eventControllers[T]!.add(handler as Function);
  }

  void unsubscribe<T>(void Function(T) handler) {
    _eventControllers[T]?.remove(handler as Function);
  }

  void publish<T>(T event) {
    _eventControllers[T]?.forEach((handler) => handler(event));
  }
}
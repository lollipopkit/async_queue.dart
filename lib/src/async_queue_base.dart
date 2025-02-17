import 'dart:async';

/// A queue that processes elements asynchronously.
class AsyncQueue<T> {
  final int? _capacity;
  final _queue = <T>[];
  final _waiters = <Completer<T>>[];
  final _addCompleters = <Completer<void>>[];
  Completer<void>? _waitCompleter;

  AsyncQueue({int? capacity}) : _capacity = capacity {
    if (capacity != null && capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'Must be greater than 0');
    }
  }

  /// The maximum number of items that can be added to the queue.
  /// 
  /// - If the queue is full, [add] will wait until an item is taken.
  /// - If the queue is empty, [take] will wait until an item is added.
  /// - If [capacity] is null, the queue has no limit.
  /// 
  /// Must greater than 0.
  int? get capacity => _capacity;

  /// Returns the number of items in the queue.
  int get length => _queue.length;

  /// Adds an item to the queue.
  /// 
  /// If the queue is full, this method will wait until an item is taken.
  Future<void> add(T item) async {
    while (_capacity != null && _queue.length >= _capacity) {
      final completer = Completer<void>();
      _addCompleters.add(completer);
      await completer.future;
    }

    _queue.add(item);
    if (_waiters.isNotEmpty) {
      final waiter = _waiters.removeAt(0);
      waiter.complete(_queue.removeAt(0));
    }
  }

  /// Adds multiple items to the queue.
  /// 
  /// If the queue is full, this method will wait until an item is taken.
  Future<void> addAll(Iterable<T> items) async {
    for (final item in items) {
      await add(item);
    }
  }

  /// Takes an item from the queue.
  /// 
  /// If the queue is empty, this method will wait until an item is added.
  Future<T> take() async {
    if (_queue.isEmpty) {
      final completer = Completer<T>();
      _waiters.add(completer);
      return completer.future;
    }

    final item = _queue.removeAt(0);
    if (_addCompleters.isNotEmpty) {
      final addCompleter = _addCompleters.removeAt(0);
      addCompleter.complete();
    }

    _checkWaitComplete();
    return item;
  }

  /// Clears all items from the queue.
  /// 
  /// It's recommended to call this method before disposing the queue.
  void clear() {
    _queue.clear();
    for (final waiter in _waiters) {
      waiter.completeError(StateError('Queue was cleared'));
    }
    _waiters.clear();
    for (final completer in _addCompleters) {
      completer.completeError(StateError('Queue was cleared'));
    }
    _addCompleters.clear();
    _waitCompleter?.completeError(StateError('Queue was cleared'));
    _waitCompleter = null;
  }

  /// Waits for all items in the queue to be taken.
  Future<void> wait() async {
    if (_queue.isEmpty) return;
    
    _waitCompleter ??= Completer<void>();
    return _waitCompleter!.future;
  }

  void _checkWaitComplete() {
    if (_queue.isEmpty && _waitCompleter != null && !_waitCompleter!.isCompleted) {
      _waitCompleter!.complete();
      _waitCompleter = null;
    }
  }
}

import 'dart:async';

/// Callback for when an item is added/taken to the queue
typedef OnItemCallback<T> = void Function(T item);

/// An asynchronous queue implementation that supports:
/// - capacity limits
/// - waiting operations.
class AsyncQueue<T> {
  final int? _capacity;
  final List<T> _queue;
  final List<Completer<T>> _waiters;
  final List<Completer<void>> _addCompleters;
  Completer<void>? _waitCompleter;
  bool _isClosed = false;

  /// {@template async_queue_on_add}
  /// Callback that's called when an item is added to the queue.
  /// {@endtemplate}
  OnItemCallback<T>? onAdd;

  /// {@template async_queue_on_remove}
  /// Callback that's called when an item is taken from the queue.
  /// {@endtemplate}
  OnItemCallback<T>? onRemove;

  /// Creates an [AsyncQueue] with an optional capacity limit.
  ///
  /// - [capacity] is the maximum number of items that can be added to the queue.
  /// If the queue is full, [add] will wait until an item is taken.
  /// If it's null, the queue has no limit.
  /// - [onAdd] is a callback that's called when an item is added to the queue.
  /// - [onRemove] is a callback that's called when an item is taken from the queue.
  AsyncQueue({
    int? capacity,
    this.onAdd,
    this.onRemove,
  })  : _capacity = capacity,
        _queue = <T>[],
        _waiters = <Completer<T>>[],
        _addCompleters = <Completer<void>>[] {
    if (capacity != null && capacity <= 0) {
      throw ArgumentError.value(
          capacity, 'capacity', 'Must be greater than 0 if specified');
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

  /// Adds an item to the queue with an optional timeout.
  ///
  /// - [item] is the item to add.
  /// - [timeout] is the maximum time to wait for the operation.
  ///
  /// Throws [TimeoutException] if the operation times out.
  /// Throws [StateError] if the queue is closed.
  Future<void> add(T item, {Duration? timeout}) async {
    if (_isClosed) throw StateError('Queue is closed');

    if (timeout != null) {
      return await _timeoutFuture(() => _addItem(item), timeout);
    }
    return await _addItem(item);
  }

  /// Adds multiple items to the queue.
  ///
  /// If the queue is full, this method will wait until an item is taken.
  Future<void> addAll(Iterable<T> items) async {
    for (final item in items) {
      await add(item);
    }
  }

  /// Takes an item from the queue with an optional timeout.
  ///
  /// Throws [TimeoutException] if the operation times out.
  /// Throws [StateError] if the queue is closed.
  Future<T> take({Duration? timeout}) async {
    if (_isClosed) throw StateError('Queue is closed');

    if (timeout != null) {
      return await _timeoutFuture(() => _takeItem(), timeout);
    }
    return await _takeItem();
  }

  /// Returns the first item in the queue without removing it.
  ///
  /// Throws [StateError] if the queue is empty or closed.
  T peek() {
    if (_isClosed) throw StateError('Queue is closed');
    if (_queue.isEmpty) throw StateError('Queue is empty');
    return _queue.first;
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

  /// Closes the queue, preventing further additions.
  ///
  /// Any pending operations will be completed or error out.
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    clear();
  }

  /// Returns true if the queue is closed.
  bool get isClosed => _isClosed;

  /// Returns true if the queue is full.
  bool get isFull => _capacity != null && _queue.length >= _capacity;

  /// Returns true if the queue is empty.
  bool get isEmpty => _queue.isEmpty;

  /// Waits for all items in the queue to be taken.
  Future<void> wait() async {
    if (_queue.isEmpty) return;

    _waitCompleter ??= Completer<void>();
    return _waitCompleter!.future;
  }
}

extension _Basic<T> on AsyncQueue<T> {
  Future<void> _addItem(T item) async {
    while (_capacity != null && _queue.length >= _capacity) {
      final completer = Completer<void>();
      _addCompleters.add(completer);
      await completer.future;
      if (_isClosed) throw StateError('Queue was closed while waiting');
    }

    _queue.add(item);
    onAdd?.call(item);
    _notifyWaiters();
  }

  Future<T> _takeItem() async {
    if (_queue.isEmpty) {
      final completer = Completer<T>();
      _waiters.add(completer);
      return completer.future;
    }

    final item = _queue.removeAt(0);
    onRemove?.call(item);

    if (_addCompleters.isNotEmpty) {
      final addCompleter = _addCompleters.removeAt(0);
      addCompleter.complete();
    }

    _checkWaitComplete();
    return item;
  }
}

extension _Helper<T> on AsyncQueue<T> {
  Future<R> _timeoutFuture<R>(
      Future<R> Function() operation, Duration timeout) {
    return operation().timeout(
      timeout,
      onTimeout: () => throw TimeoutException('Operation timed out', timeout),
    );
  }

  void _notifyWaiters() {
    while (_waiters.isNotEmpty && _queue.isNotEmpty) {
      final waiter = _waiters.removeAt(0);
      waiter.complete(_queue.removeAt(0));
    }
    _checkWaitComplete();
  }

  void _checkWaitComplete() {
    if (_queue.isEmpty &&
        _waitCompleter != null &&
        !_waitCompleter!.isCompleted) {
      _waitCompleter!.complete();
      _waitCompleter = null;
    }
  }
}

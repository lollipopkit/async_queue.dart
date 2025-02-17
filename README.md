# Async Queue

A Dart implementation of an asynchronous queue with support for capacity limits, timeouts, and waiting operations.

## Features

- Optional capacity limits
- Timeout support for operations
- Multiple producers and consumers
- Queue state monitoring
- Clear and close operations
- Peek functionality
- Wait for empty queue
- Operation callbacks
- Error handling

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  async_queue: ^1.0.0
```

Then run:

```bash
dart pub get
```

## Usage

```dart
import 'package:async_queue/async_queue.dart';

// Create an unlimited queue
final queue = AsyncQueue<int>();

// Create a bounded queue
final boundedQueue = AsyncQueue<int>(capacity: 2);

// Basic operations
await queue.add(1);
final item = await queue.take(); // 1

// Add with timeout
try {
  await queue.add(2, timeout: Duration(seconds: 1));
} on TimeoutException catch (e) {
  print('Operation timed out');
}

// Peek at first item without removing it
final firstItem = queue.peek();

// Wait for queue to empty
await queue.wait();

// Clear the queue
queue.clear();

// Close the queue
queue.close();
```

### Callbacks

```dart
final queue = AsyncQueue<int>();

// Set callbacks
queue.onAdd = (item) => print('Added: $item');
queue.onRemove = (item) => print('Removed: $item');

await queue.add(1); // Prints: Added: 1
await queue.take(); // Prints: Removed: 1
```

### Error Handling

```dart
final queue = AsyncQueue<int>(capacity: 1);

try {
  queue.close();
  await queue.add(1); // Throws StateError
} on StateError catch (e) {
  print('Queue is closed');
}

try {
  await queue.add(1, timeout: Duration(milliseconds: 100));
} on TimeoutException catch (e) {
  print('Operation timed out');
}
```

## API Reference

### Constructor

- `AsyncQueue({int? capacity})`
  - Creates a new queue with optional capacity limit
  - Throws `ArgumentError` if capacity is less than 1

### Methods

- `Future<void> add(T item, {Duration? timeout})`
  - Adds an item to the queue
  - Throws `TimeoutException` if timeout is reached
  - Throws `StateError` if queue is closed

- `Future<void> addAll(Iterable<T> items)`
  - Adds multiple items to the queue
  - Throws `StateError` if queue is closed

- `Future<T> take({Duration? timeout})`
  - Takes an item from the queue
  - Throws `TimeoutException` if timeout is reached
  - Throws `StateError` if queue is closed

- `T peek()`
  - Returns the first item without removing it
  - Throws `StateError` if queue is empty or closed

- `void clear()`
  - Removes all items from the queue
  - Cancels all pending operations

- `void close()`
  - Closes the queue
  - Prevents further operations

- `Future<void> wait()`
  - Waits for all items to be taken
  - Completes immediately if queue is empty

### Properties

- `int? capacity` - Maximum number of items (null for unlimited)
- `int length` - Current number of items
- `bool isClosed` - Whether the queue is closed
- `bool isFull` - Whether the queue is at capacity
- `bool isEmpty` - Whether the queue is empty
- `Function(T)? onAdd` - Callback when item is added
- `Function(T)? onRemove` - Callback when item is removed

### Exceptions

- `TimeoutException` - Thrown when an operation times out
- `StateError` - Thrown when operating on a closed queue
- `ArgumentError` - Thrown when creating queue with invalid capacity

## License

```
MIT lollipopkit
```

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

## API Reference

### Constructor

- `AsyncQueue({int? capacity})` - Creates a new queue with optional capacity limit

### Methods

- `Future<void> add(T item, {Duration? timeout})` - Adds an item to the queue
- `Future<void> addAll(Iterable<T> items)` - Adds multiple items to the queue
- `Future<T> take({Duration? timeout})` - Takes an item from the queue
- `T peek()` - Returns the first item without removing it
- `void clear()` - Removes all items from the queue
- `void close()` - Closes the queue
- `Future<void> wait()` - Waits for all items to be taken

### Properties

- `int? capacity` - Maximum number of items (null for unlimited)
- `int length` - Current number of items
- `bool isClosed` - Whether the queue is closed
- `bool isFull` - Whether the queue is at capacity
- `bool isEmpty` - Whether the queue is empty

## License

```
MIT lollipopkit
```

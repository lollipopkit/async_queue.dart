import 'dart:async';

import 'package:async_queue/async_queue.dart';

void main() async {
  // Create a queue with callbacks
  final queue = AsyncQueue<int>();
  
  // Set up callbacks
  queue.onAdd = (item) => print('Added: $item');
  queue.onRemove = (item) => print('Removed: $item');

  // Add some items
  await queue.add(1);  // prints: Added: 1
  await queue.add(2);  // prints: Added: 2
  
  // Take items
  await queue.take();  // prints: Removed: 1
  await queue.take();  // prints: Removed: 2

  // Create an unlimited queue
  final unlimitedQueue = AsyncQueue<int>();
  print('Unlimited queue capacity: ${unlimitedQueue.capacity}'); // null

  // Add many items without blocking
  for (var i = 0; i < 100; i++) {
    await unlimitedQueue.add(i);
  }
  print('Added 100 items successfully');

  // Create a bounded queue for comparison
  final boundedQueue = AsyncQueue<int>(capacity: 2);
  print('Bounded queue capacity: ${boundedQueue.capacity}'); // 2

  // Add items with timeout
  try {
    await boundedQueue.add(1, timeout: Duration(seconds: 1));
    await boundedQueue.add(2, timeout: Duration(seconds: 1));
    print('Queue is full: ${boundedQueue.isFull}'); // true

    // Peek at first item
    print('First item: ${boundedQueue.peek()}'); // 1

    // Take items
    final item = await boundedQueue.take(timeout: Duration(seconds: 1));
    print('Took item: $item'); // 1

    // Close the queue
    boundedQueue.close();
    print('Queue is closed: ${boundedQueue.isClosed}'); // true
  } on TimeoutException catch (e) {
    print('Operation timed out: $e');
  } on StateError catch (e) {
    print('Queue error: $e');
  }
}

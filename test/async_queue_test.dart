import 'dart:async';

import 'package:test/test.dart';
import 'package:async_queue/async_queue.dart';

void main() {
  group('AsyncQueue', () {
    test('basic add and take operations', () async {
      final queue = AsyncQueue<int>();
      await queue.add(1);
      await queue.add(2);

      expect(await queue.take(), equals(1));
      expect(await queue.take(), equals(2));
    });

    test('respects capacity limit', () async {
      final queue = AsyncQueue<int>(capacity: 2);
      await queue.add(1);
      await queue.add(2);

      // This should wait until an item is taken
      var addFuture = queue.add(3);
      var completed = false;
      addFuture.then((_) => completed = true);

      await Future.delayed(Duration(milliseconds: 100));
      expect(completed, isFalse);

      await queue.take();
      await Future.delayed(Duration(milliseconds: 100));
      expect(completed, isTrue);
    });

    test('addAll works correctly', () async {
      final queue = AsyncQueue<int>();
      await queue.addAll([1, 2, 3]);

      expect(await queue.take(), equals(1));
      expect(await queue.take(), equals(2));
      expect(await queue.take(), equals(3));
    });

    test('wait completes when queue is empty', () async {
      final queue = AsyncQueue<int>();
      await queue.addAll([1, 2]);

      var waitFuture = queue.wait();
      var completed = false;
      waitFuture.then((_) => completed = true);

      expect(completed, isFalse);
      await queue.take();
      expect(completed, isFalse);
      await queue.take();
      await Future.delayed(Duration(milliseconds: 100));
      expect(completed, isTrue);
    });

    test('clear operation works correctly', () async {
      final queue = AsyncQueue<int>();
      await queue.addAll([1, 2, 3]);

      queue.clear();
      expect(queue.length, equals(0));

      // Adding should still work after clear
      await queue.add(4);
      expect(await queue.take(), equals(4));
    });

    test('clear cancels pending operations', () async {
      final queue = AsyncQueue<int>();

      // Start a take operation that will wait
      var takeFuture = queue.take();
      queue.clear();

      expect(takeFuture, throwsStateError);
    });

    test('throws on invalid capacity', () {
      expect(() => AsyncQueue<int>(capacity: 0), throwsArgumentError);
      expect(() => AsyncQueue<int>(capacity: -1), throwsArgumentError);
    });

    test('multiple producers and consumers', () async {
      final queue = AsyncQueue<int>();

      // Producers
      Future<void> producer(int start) async {
        for (var i = start; i < start + 3; i++) {
          await queue.add(i);
        }
      }

      // Start multiple producers
      await Future.wait([
        producer(0),
        producer(3),
        producer(6),
      ]);

      // Consume all items
      var results = <int>[];
      for (var i = 0; i < 9; i++) {
        results.add(await queue.take());
      }

      expect(results..sort(), equals(List.generate(9, (i) => i)));
    });

    test('timeout handling', () async {
      final queue = AsyncQueue<int>(capacity: 1);
      await queue.add(1);

      await expectLater(
        queue.add(2, timeout: Duration(milliseconds: 100)),
        throwsA(isA<TimeoutException>()),
      );

      expect(
        await queue.take(timeout: Duration(milliseconds: 100)),
        equals(1),
      );
    });

    test('queue closure handling', () async {
      final queue = AsyncQueue<int>();
      await queue.add(1);

      queue.close();
      expect(queue.isClosed, isTrue);
      expect(() => queue.add(2), throwsStateError);
      expect(() => queue.take(), throwsStateError);
    });

    test('peek operation', () async {
      final queue = AsyncQueue<int>();
      await queue.add(1);
      await queue.add(2);

      expect(queue.peek(), equals(1));
      expect(queue.length, equals(2)); // Length shouldn't change
      expect(await queue.take(), equals(1)); // Can still take items
    });

    test('unlimited capacity when capacity is null', () async {
      final queue = AsyncQueue<int>();

      // Should be able to add many items without blocking
      for (var i = 0; i < 1000; i++) {
        await queue.add(i);
      }

      expect(queue.length, equals(1000));
      expect(queue.capacity, isNull);
      expect(queue.isFull, isFalse);
    });
  });
}

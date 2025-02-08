import 'package:async_queue/async_queue.dart';

void main() async {
  final queue = AsyncQueue<int>(capacity: 2);
  await queue.addAll([1, 2, 3, 4, 5]);
}

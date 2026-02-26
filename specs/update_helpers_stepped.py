import sys
import re

file_path = '../test/widget/swipe_action_cell_intentional_test.dart'
with open(file_path, 'r') as f:
    content = f.read()

new_swipe_left = """Future<void> swipeLeft(
  WidgetTester tester, {
  double distance = 260.0,
}) async {
  final gesture = await tester.startGesture(const Offset(300, 30));
  await tester.pump();
  await gesture.moveBy(Offset(-distance / 2, 0));
  await tester.pump();
  await gesture.moveBy(Offset(-distance / 2, 0));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}"""

new_swipe_right = """Future<void> swipeRight(
  WidgetTester tester, {
  double distance = 260.0,
}) async {
  final gesture = await tester.startGesture(const Offset(100, 30));
  await tester.pump();
  await gesture.moveBy(Offset(distance / 2, 0));
  await tester.pump();
  await gesture.moveBy(Offset(distance / 2, 0));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}"""

content = re.sub(r'Future<void> swipeLeft\(.*?pumpAndSettle\(\);' + chr(10) + r'}', new_swipe_left, content, flags=re.DOTALL)
content = re.sub(r'Future<void> swipeRight\(.*?pumpAndSettle\(\);' + chr(10) + r'}', new_swipe_right, content, flags=re.DOTALL)

with open(file_path, 'w') as f:
    f.write(content)

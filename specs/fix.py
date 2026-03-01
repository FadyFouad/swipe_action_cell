import sys
import re

# 1. Fix the barrel file
barrel_path = "../lib/swipe_action_cell.dart"
content = open(barrel_path).read()
# Clean up the broken export
content = re.sub(r"export src/painting/swipe_painting_config\.dart;", "", content)
content = re.sub(r"export 'src/painting/swipe_painting_config\.dart';\s*", "", content)
content = content.strip() + "
export 'src/painting/swipe_painting_config.dart';
"
open(barrel_path, "w").write(content)

# 2. Fix _NoOpPainter in swipe_action_cell.dart
file_path = "../lib/src/widget/swipe_action_cell.dart"
content = open(file_path).read()

# Remove any existing _NoOpPainter class at the end
content = re.sub(r"class _NoOpPainter extends CustomPainter \{.*?\}
?", "", content, flags=re.DOTALL)

# Add it back properly at the very end of the file
noop_class = """
class _NoOpPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(_NoOpPainter old) => false;
}
"""
content = content.strip() + "
" + noop_class
open(file_path, "w").write(content)

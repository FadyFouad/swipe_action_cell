import sys
import re

def fix_quotes(file_path):
    with open(file_path, "r") as f:
        content = f.read()
    content = content.replace("\"", "'")
    with open(file_path, "w") as f:
        f.write(content)

fix_quotes("../lib/src/testing/mock_swipe_controller.dart")
fix_quotes("../lib/src/testing/swipe_assertions.dart")
fix_quotes("../lib/src/testing/swipe_test_harness.dart")
fix_quotes("../lib/testing.dart")

# Fix SwipeTester docs and quotes
file_path_tester = "../lib/src/testing/swipe_tester.dart"
with open(file_path_tester, "r") as f:
    c = f.read()

c = c.replace("\"", "'")
c = c.replace("  static Future<void> swipeLeft", "  /// Drags the cell left by the specified [ratio] of its width.\n  static Future<void> swipeLeft")
c = c.replace("  static Future<void> swipeRight", "  /// Drags the cell right by the specified [ratio] of its width.\n  static Future<void> swipeRight")
c = c.replace("  static Future<void> flingLeft", "  /// Flings the cell left with the specified [velocity].\n  static Future<void> flingLeft")
c = c.replace("  static Future<void> flingRight", "  /// Flings the cell right with the specified [velocity].\n  static Future<void> flingRight")
c = c.replace("  static Future<void> dragTo", "  /// Drags the cell to the exact [offset] and pumps exactly one frame.\n  static Future<void> dragTo")
c = c.replace("  static Future<void> tapAction", "  /// Taps the action button at [actionIndex] in a revealed cell.\n  static Future<void> tapAction")

with open(file_path_tester, "w") as f:
    f.write(c)

# Fix testing.dart library name and sorting
file_path_testing = "../lib/testing.dart"
with open(file_path_testing, "r") as f:
    c = f.read()

c = c.replace("library testing;", "library;")
lines = c.split("\n")
exports = sorted([line for line in lines if line.startswith("export")])
other = [line for line in lines if not line.startswith("export")]
new_c = ""
for line in other:
    if line.strip() and not line.startswith("//"):
        new_c += line + "\n"
new_c += "\n" + "\n".join(exports)

with open(file_path_testing, "w") as f:
    f.write(new_c)

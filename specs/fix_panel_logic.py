import os

def replace_in_file(file_path, old_text, new_text):
    with open(file_path, 'r') as f:
        content = f.read()
    if old_text not in content:
        print(f"ERROR: Could not find old_text in {file_path}")
        return False
    new_content = content.replace(old_text, new_text)
    with open(file_path, 'w') as f:
        f.write(new_content)
    print(f"SUCCESS: Replaced in {file_path}")
    return True

file_path = '../lib/src/actions/intentional/swipe_action_panel.dart'

# Modify build to use SizedBox logic if designatedActionIndex is present (even if ratio is 0.0)
old_logic = """    if (widget.fullSwipeRatio > 0.0 && widget.designatedActionIndex != null) {"""
new_logic = """    if (widget.designatedActionIndex != null) {"""

replace_in_file(file_path, old_logic, new_logic)

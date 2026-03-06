import os

def replace_in_file(file_path, old_text, new_text):
    with open(file_path, 'r') as f:
        content = f.read()
    if old_text not in content:
        print(f"ERROR: Could not find old_text in {file_path}")
        # print("CONTENT WAS:")
        # print(content)
        return False
    new_content = content.replace(old_text, new_text)
    with open(file_path, 'w') as f:
        f.write(new_content)
    print(f"SUCCESS: Replaced in {file_path}")
    return True

# T002 + T003 + T016: width distribution + ClipRect + Opacity
file_path = '../lib/src/actions/intentional/swipe_action_panel.dart'
old_text = """    return Row(
      children: [
        for (int i = 0; i < widget.actions.length; i++)
          Expanded(
            flex: widget.actions[i].flex > 0 ? widget.actions[i].flex : 1,
            child: GestureDetector(
              onTap: () => _handleButtonTap(i),
              child: ColoredBox(
                color: widget.actions[i].backgroundColor,
                child: _buildButtonContent(widget.actions[i]),
              ),
            ),
          ),
      ],
    );"""

new_text = """    if (widget.fullSwipeRatio > 0.0 && widget.designatedActionIndex != null) {
      final int totalFlex = widget.actions.fold(0, (sum, a) => sum + (a.flex > 0 ? a.flex : 1));
      final List<double> widths = List.filled(widget.actions.length, 0.0);
      double nonDesignatedSum = 0.0;

      for (int i = 0; i < widget.actions.length; i++) {
        if (i != widget.designatedActionIndex) {
          final double normalWidth = widget.panelWidth *
              ((widget.actions[i].flex > 0 ? widget.actions[i].flex : 1) /
                  totalFlex);
          widths[i] = normalWidth * (1.0 - widget.fullSwipeRatio);
          nonDesignatedSum += widths[i];
        }
      }
      widths[widget.designatedActionIndex!] =
          widget.panelWidth - nonDesignatedSum;

      return Row(
        children: [
          for (int i = 0; i < widget.actions.length; i++)
            SizedBox(
              width: widths[i],
              child: ClipRect(
                child: Opacity(
                  opacity: i == widget.designatedActionIndex
                      ? 1.0
                      : (1.0 - widget.fullSwipeRatio),
                  child: GestureDetector(
                    onTap: () => _handleButtonTap(i),
                    child: ColoredBox(
                      color: widget.actions[i].backgroundColor,
                      child: _buildButtonContent(widget.actions[i]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < widget.actions.length; i++)
          Expanded(
            flex: widget.actions[i].flex > 0 ? widget.actions[i].flex : 1,
            child: GestureDetector(
              onTap: () => _handleButtonTap(i),
              child: ColoredBox(
                color: widget.actions[i].backgroundColor,
                child: _buildButtonContent(widget.actions[i]),
              ),
            ),
          ),
      ],
    );"""

replace_in_file(file_path, old_text, new_text)

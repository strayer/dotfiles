# herdr panes set TERM_PROGRAM=herdr, which hides the real terminal from
# hyperlink detection, so tools like Claude Code drop OSC 8 links even though
# herdr passes them through (herdrdev/herdr#4748). FORCE_HYPERLINK is the
# supports-hyperlinks convention for overriding that detection.
if status --is-interactive; and test "$TERM_PROGRAM" = herdr
  set -gx FORCE_HYPERLINK 1
end

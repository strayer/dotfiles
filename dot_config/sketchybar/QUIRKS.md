# SketchyBar Quirks

Hard-won, non-obvious behaviors of SketchyBar/SbarLua and this config's
integrations. Read this before touching brackets, layout, item ordering, or
anything that shells out via `sbar.exec`. Each entry: symptom → cause → rule.
Engine claims were verified against the sources in `~/dev-explore/SketchyBar`
and `~/dev-explore/SbarLua`.

## Brackets & layout engine

### Bracket regexes are POSIX *basic* regex

- **Symptom:** A bracket with `(a|b)` alternation or `.+` never matches;
  no error anywhere.
- **Cause:** `regcomp(&regex, regstring, 0)` in `src/message.c` — no
  `REG_EXTENDED`. `+`, `|`, `(`, `)` are literal characters.
- **Rule:** Only use `.*` in member patterns. Need alternation? Pass multiple
  patterns: `{ "/left\\.space\\..*/", "/left\\.rift_layout\\..*/" }`.

### An unmatched member pattern fails the whole SbarLua bracket add

- **Symptom:** Bracket silently doesn't exist even though most patterns match;
  the CLI equivalent "works" (prints only a `[?] Regex: No match` warning).
- **Cause:** The daemon returns NULL for a no-match pattern; the SbarLua add
  path aborts on it.
- **Rule:** Never register a pattern for items that might not exist yet.
  Guard dynamic islands: only (re)create the bracket when at least one
  matching item exists (see `refresh_workspace_island` call site in
  `items/rift.lua`).

### Brackets resolve members only at creation

- **Symptom:** Items added after a bracket exists don't get its background.
- **Cause:** Member regexes are evaluated once, at `--add bracket` time.
- **Rule:** Remove and re-add the bracket whenever membership changes
  (`refresh_*_island` in `items/brackets.lua`). Bracket stacking follows
  creation order: a bracket drawn "on top" must be created after the one
  below it.

### Bracket pills include edge members' item paddings; item backgrounds don't

- **Symptom:** Gaps around single-item islands (chevron, clock) come out
  ~5pt wider than between bracket islands.
- **Cause:** `group_get_length` (src/group.c) extends the backdrop by the
  first member's `padding_left` and last member's `padding_right`. An item's
  *own* background spans only content — item paddings sit outside it.
- **Rule:** Single-item islands get `padding = 0` on the gap side and keep
  padding only toward the screen edge. Inner "corner padding" for bracket
  islands comes from edge members' item paddings.

### Items with fixed `width` break spacing

- **Symptom:** Spacer items with `width = N` produce uneven gaps; their
  `bounding_rects` overlap neighbors and report wrong sizes.
- **Cause:** `has_const_width` items take a different cursor-advance path in
  `src/bar.c` (`custom_width - padding_left`) that drops paddings from the
  flow.
- **Rule:** Build spacers as contentless items (icon/label `drawing = false`)
  with plain `padding_left`/`padding_right`, never `width`
  (see `items/padding.lua`).

### Never use the bar's `y_offset`

- **Symptom:** All island content sits visibly low; underlines hug the
  bracket's bottom border ~3px deeper than the math says.
- **Cause:** The bar `y_offset` is applied to item content but *not* to
  bracket backdrops — they center on different baselines.
- **Rule:** Keep `y_offset = 0` and fold any offset into `bar_height`
  (38+0, not 35+3 — same bottom edge, symmetric centering).

### Notch display: reserved strip + `notch_display_height`

- **Symptom:** Spacing tuned on external displays comes out asymmetric on the
  built-in display (windows too far below the pills, or glued to the notch).
- **Cause:** Two per-display differences stack. (1) macOS reserves the
  menu-bar/notch strip on the built-in display, so rift's usable frame
  already starts below it (`rift-cli query displays` → `frame.origin.y`,
  38pt at "More Space" scaling) — rift's per-display `outer.top` is measured
  from *that* origin, while external displays' frames start at the true
  screen top. (2) The strip height depends on the display's scaling mode, so
  any coincidence with the bar height is fragile.
- **Rule:** Use the bar's `notch_display_height` (applies to the built-in
  display only; items and pills re-center per display automatically) to give
  the notch display its own strip height, and tune the rift per-display
  `outer.top` relative to the *frame origin*, not the screen top. Current
  numbers: `notch_display_height = 43` + internal `outer.top = 5` → pills at
  6..37 with 6pt above/below; externals keep `bar_height = 38` + global
  `top = 38`. Re-check after changing the internal display's scaling.

### Right-position items stack leftward; batched moves anchor-push

- **Symptom:** "Why is the item I created first at the far right?" /
  reorder commands scramble.
- **Cause:** For `position = "right"`, first created = rightmost. `--move X
  after <anchor>` places X directly beside the anchor, pushing previously
  moved items outward.
- **Rule:** Order the right side by requiring modules outside-in
  (`items/init.lua`). Reorder dynamic items with ONE batched command, all
  moves targeting the same anchor, iterated so the first-moved item ends up
  farthest away (see `enforce_workspace_order` in `items/rift.lua` and the
  move batch in `items/dock_badges.lua`). Separate async moves race.

## Execution environment

### launchd PATH is minimal - absolute paths in `sbar.exec`

- **Symptom:** `sbar.exec("sketchybar --move ...")` (or any Homebrew/`~/.bin`
  tool) does nothing, with no error anywhere.
- **Cause:** The service PATH is `/usr/bin:/bin:/usr/sbin:/sbin` — no
  `/opt/homebrew/bin`, no `~/.bin`. The command exits 127 silently.
- **Rule:** Always call binaries by absolute path: `settings.sketchybar_bin`,
  the `~/.bin/rift-cli` shim, `~/.bin/*` helpers.

### Item names travel through shells and regexes

- **Symptom:** A dynamic name containing a space or metacharacter breaks the
  batched move command and/or bracket membership.
- **Rule:** Sanitize anything user/app-derived before it becomes an item
  name: `name:gsub("[^%w]", "_")` (badges and workspace items both do this).

## Text, colors & events

### Font-specific vertical centering

- **Symptom:** Text measures a couple of px below the geometric center of
  its island; different fonts disagree.
- **Cause:** Baselines are placed at `y - (ascent - descent)/2`
  (src/text.c); how a font's metrics bracket its glyphs decides the optical
  result. Measured: PragmataPro sits ~1pt low; `sketchybar-app-font` is
  optically centered.
- **Rule:** Defaults carry `y_offset = 1` for PragmataPro text; any text
  using the app-icons font must pin `y_offset = 0`.

### Hidden items receive no events by default

- **Symptom:** An invisible anchor item never fires its subscription.
- **Cause:** The `updates = "when_shown"` default suppresses events for
  `drawing = false` items.
- **Rule:** Event anchors need `updates = true` (see `right.dock_badges`).

### Subscribe to `theme_colors_updated`, not `theme_change`

- **Symptom:** An item recolors with stale palette values on theme switch.
- **Cause:** Raw `theme_change` handler order is not guaranteed; the colors
  module may not have refreshed yet. `items/system_theme.lua` refreshes the
  palette on `theme_change` and then triggers `theme_colors_updated`.
- **Rule:** All visual items subscribe to `theme_colors_updated`.

### `icon`/`label` have their own backgrounds; item backgrounds make underlines

- Text objects support `background = { color, corner_radius, height }` —
  good for bubbles/chips behind just the count or glyph.
- An item's background shrunk to a few px with a negative
  `background.y_offset` is the focus-underline trick (focused workspace in
  `items/rift.lua`). The underline spans content width only (item paddings
  excluded), which is what keeps it clear of the pill's rounded ends.

## Rift integration

### Per-space workspace `index` drifts - use canonical order

- **Symptom:** Workspace order inverts on one display; clicking workspace
  "1" switches to "D".
- **Cause:** `rift-cli query workspaces --space-id N` returns per-display
  indexes that drift and can fully invert.
- **Rule:** Canonical order and switch ids come from the *global*
  `rift-cli query workspaces` (matches `workspace_names` in the rift
  config). `workspace switch` takes the canonical **0-based index** — it
  does not accept names. The rank map can race rift at startup: retry with
  a callback that applies ordering when ranks land.

## Debug & test recipes

- Inject test badges without waiting for the counter:
  `sketchybar --trigger dock_badges BADGES='{"Microsoft Teams":"5","Discord":"7","Spotify":"•"}'`
  — the real dock-badge-counter heartbeat overwrites them within ~1 minute.
- Geometry questions: `sketchybar --query <item>` for paddings/colors/fonts;
  `bounding_rects` for positions (unreliable for const-width items).
  Brackets expose their member list but no bounding rect.
- `screencapture` is blocked for the terminal (no Screen Recording
  permission) — ask for a screenshot and measure it (retina = 2px/pt).
- The SketchyBar and SbarLua sources live in `~/dev-explore/` — when
  behavior seems impossible, read the engine instead of guessing.

# Project: `rift-provider` — fork-free Rift → SketchyBar event bridge

**Status:** planned, not started.
**Owner:** Sven Grunewaldt.
**Scope of this document:** everything needed to build the provider without prior context. All findings below were verified against local source checkouts (paths in [Reference material](#reference-material)) in August 2026, at Rift v0.5.3, SketchyBar v2.24.0 (commit `6284ee8`), SbarLua commit `dba9cc4`.

---

## 1. Goal

Build a small long-running sidecar binary (Rust, working name **`rift-provider`**) that lives in this sketchybar config repo, subscribes to window-manager events from **Rift** (a macOS tiling WM) over its native Mach IPC, enriches them with workspace/window state, and pushes ready-to-render updates **directly into SketchyBar's Mach port** as custom event triggers. The SBarLua config then renders from the delivered payload without executing a single external process.

**Hard requirement: Rift must not be modified.** Everything must be built with the IPC surface Rift v0.5.3 already ships. (Extending Rift with a native "sketchybar subscriber" backend was considered and explicitly rejected by the owner.)

Target data flow at steady state — every arrow is one Mach message, **zero forks**:

```
rift  ──(event push, existing Mach subscription)──▶  rift-provider
rift  ◀─(state query, one round-trip per event)───   rift-provider
rift-provider ──(--trigger rift_update + JSON)────▶  SketchyBar bar process
SketchyBar   ──(mach_helper env delivery)─────────▶  SBarLua Lua process
SBarLua      ──(sbar.set, batched)────────────────▶  SketchyBar (render)
```

## 2. Why (current architecture and its problems)

Today the Rift integration in this config works like this:

1. **Event push (crude):** Rift's config (`~/.config/rift/config.toml`, chezmoi source `dot_config/rift/config.toml`, `startup_commands`) registers two *CLI subscriptions* inside Rift:
   ```
   rift-cli subscribe cli --event workspace_changed --command sh --args -c --args 'sketchybar --trigger rift_workspace_change RIFT_SPACE_ID="$RIFT_SPACE_ID" ...'
   rift-cli subscribe cli --event windows_changed  --command sh ... (same pattern)
   ```
   On **every** matching WM event, Rift forks `sh`, which forks the `sketchybar` CLI, which sends a `--trigger` carrying only three env vars (space id, display UUID, workspace name) — no actual state.
2. **Re-query on every event:** the Lua handler (`items/rift.lua`) receives the trigger and then forks again: `sbar.exec(rift-cli query workspaces --space-id N)` (plus sometimes `rift-cli query displays` first) to fetch real state as JSON, parses it, and renders.

So one workspace switch costs **3–4 process spawns** (sh, sketchybar CLI, rift-cli ×1–2), and the WM fires these constantly (focus changes, window moves/appearances, title changes). This is pure overhead: as of Rift v0.5.3, both ends of the pipeline natively speak Mach and can exchange typed, complete payloads. Additionally, the CLI event set is narrower than what Rift now broadcasts (no focused-window / title / stack events), so features like a live focused-window title are currently impossible.

The **actions** direction (clicking a workspace item → `rift-cli execute workspace switch N`) is explicitly **out of scope**: it fires only on human clicks, one short-lived fork there is fine, and it stays as-is (`items/rift.lua` `mouse.clicked` handler).

## 3. Why not reuse the existing PoC (`lib/rift.lua` + `rift.so`)

The repo contains a proof-of-concept native Lua module (`lib/rift.lua`, loading `~/.local/share/rift.lua/rift.so`) that speaks Rift's Mach protocol in-process. Do **not** build on it:

- It is **query-only** (get_workspaces / get_displays / get_windows). It has no event subscription support, which is the entire point of this project. It even shells out to `rift-cli` for the execute path.
- It predates Rift's `rift-protocol` crate and speaks the legacy untyped JSON shapes by hand.
- It is currently **unused** by `items/rift.lua` (everything goes through the `~/.bin/rift-cli` shim).
- The in-process approach has structural hazards a sidecar avoids: SbarLua statically links its own Lua 5.5 (`SbarLua/makefile` links vendored `liblua.a`), so any second native module must exactly match the host interpreter's ABI; the Lua state may only be touched from main-runloop callbacks; and `sbar.exec`'s `fork()` clones the module's Mach/thread state into short-lived children.
- A sidecar is independently restartable and debuggable (run it in a terminal with logging); an in-process module is not.

An in-process module would save exactly one resident process and nothing else. Once the provider exists, the PoC (`lib/rift.lua` and `~/.local/share/rift.lua/`) should be deleted.

## 4. Alternatives considered and rejected

| Alternative | Why rejected |
|---|---|
| Extend Rift with a native sketchybar-trigger subscriber backend (third fan-out in `src/ipc/subscriptions.rs`) | Vetoed by owner: Rift must stay unmodified. |
| Native Lua module inside the SBarLua process (proper rewrite of the PoC) | See §3: Lua ABI hazard, threading rules, fork interactions; saves only one process. |
| `NSDistributedNotification` bridge (SketchyBar's `--add event <name> <notification>` can bind an event to a distributed notification) | Would still need a process to *post* the notifications, since Rift can't (unmodified) — so it's a sidecar anyway, with an extra hop and less control. |
| Keep the CLI pipeline, just add more events | Multiplies the fork storm; still no payload in events. |

## 5. What to build

### 5.1 Location, language, dependencies

- New Rust crate at **`helpers/rift-provider/`** in this repo (chezmoi source: `dot_config/sketchybar/helpers/rift-provider/`). This mirrors the idiomatic SketchyBar "event provider" pattern (cf. FelixKratz's dotfiles `cpu_load`/`network_load` helpers, which are compiled inside the config dir).
- Depend on Rift's client crates. They are **not on crates.io** (v0.1.0, path-deps only) — use a git dependency:
  ```toml
  rift-client = { git = "https://github.com/acsandmann/rift", tag = "v0.5.3" }
  ```
  (`rift-client` re-exports all of `rift-protocol` via `pub use rift_protocol::*;`. A local checkout exists at `~/dev/rift` if a path dep is preferred during development.)
- `rift-client` is **fully synchronous** (no tokio) — the provider is a plain single-threaded blocking loop. `RiftMachClient` is a stateless `Copy` type.
- The SketchyBar send path is ~80 lines of raw `mach_msg` FFI (spec in §7); no crate exists for it. Port it from `SbarLua/src/mach.h` (`mach_get_bs_port` + `mach_send_message`).

### 5.2 Behavior

1. **Connect & subscribe:** `RiftMachClient::connect()`, then `client.subscribe(EventKind::All)` → `RiftMachSubscription`. Subscribe **before** taking the initial state snapshot (avoids a race — this ordering is copied from Rift's reference client, `~/dev/rift/crates/rift-client/examples/dimmer.rs`).
2. **Initial snapshot:** `get_displays()`, then for each display push a full update (see payload schema).
3. **Event loop:** block on `recv_event()`. Every `RiftEvent` variant carries `space_id` and `display_uuid` accessors — use them **only for routing/invalidation**. Do not try to render from event payloads (see gotchas §6.3).
4. **Enrich:** on each event, call `get_workspaces(Some(space_id))` → `Vec<WorkspaceData>` (contains everything the bar needs: name, index, `is_active`, `layout_mode`, and embedded `WindowData` with `title`, `app_name`, `bundle_id`, `is_focused`).
5. **Coalesce:** Rift bursts events (one workspace switch fires workspace-changed + windows-changed + focused-window-changed). Debounce ~25–50 ms per display so one burst becomes one trigger.
6. **Push full state, not deltas:** each trigger carries the complete workspace list for the affected display. Rendering stays idempotent; missed events don't matter; startup is just "push one snapshot".
7. **Send trigger:** one fire-and-forget Mach message to `git.felix.sketchybar` (wire format §7). Suggested framing:
   ```
   --trigger\0rift_update\0DISPLAY_UUID=<uuid>\0SPACE_ID=<id>\0WORKSPACES=<json>\0\0
   ```
   where `WORKSPACES` is a JSON array. **SBarLua auto-decodes JSON env values into Lua tables** (see §8), so the Lua callback receives a ready table.
8. **Resilience:**
   - If Rift is down: `client.is_available()` + retry with backoff; `recv_event` errors → resubscribe loop.
   - If SketchyBar restarts: the cached send right goes stale → re-`bootstrap_look_up` and retry once (same pattern as `SbarLua/src/sketchybar.c:82-92`); on persistent failure, keep the event loop running and retry lookup periodically.
   - Triggers for an event name the bar doesn't know yet are **silently dropped** (no error) — harmless because of the lifecycle below.
9. **Logging:** `env_logger`/`tracing` to stderr; running the binary manually in a terminal must show the event/push flow.

### 5.3 Lifecycle (who starts it)

Launch from the end of the Lua config (`init.lua`), the same way stock event providers are launched:

```lua
sbar.exec("killall rift-provider >/dev/null 2>&1; " .. CONFIG_DIR .. "/helpers/rift-provider/target/release/rift-provider &")
```

This is one fork **per config load**, zero at runtime, and it solves two problems at once:

- **Ordering:** by the time the provider starts, the Lua config has already run `sbar.add("event", "rift_update")`/`subscribe` (SbarLua's subscribe registers the event with the bar itself, §8), so the provider's initial snapshot lands on a registered event.
- **Bar restarts:** the bar re-executes the config on restart/reload → the provider is killed and relaunched → fresh snapshot pushed. No orphan-detection logic needed beyond exiting when sends fail for a long time (optional; `getppid()`-based checks do **not** work here — the provider is reparented to launchd immediately because the forked `sh` exits).

Build step: document `cargo build --release` in the crate README; optionally add a `make`/justfile hook. (Chezmoi manages the sources; the `target/` dir must be gitignored.)

### 5.4 Lua-side changes

- `items/rift.lua`: replace the trigger handlers + `sbar.exec(rift-cli query …)` chains with a single `rift_update` subscription that renders from `env.WORKSPACES` (already a Lua table). Keep: item creation/styling, the display-UUID → SketchyBar display number mapping (`build_display_map`), the Outlook-reminder title filter (`"%d+ Erinnerungen"`), and the `mouse.clicked` → `rift-cli execute workspace switch N` action (out of scope, see §2).
- `build_display_map` currently forks `sketchybar --query displays` via `sbar.exec`; that runs only at startup/display-change, which is acceptable — but check whether SbarLua's direct query API (`sbar.query`, which sends `--query` over Mach in-process) can return the displays object and use it if so.
- `init.lua`: add the provider launch line (§5.3).

### 5.5 Cleanup after cutover

1. Remove the two `rift-cli subscribe cli ...` lines from `startup_commands` in `dot_config/rift/config.toml`.
2. Delete `lib/rift.lua` and `~/.local/share/rift.lua/` (unused PoC, §3).
3. Remove the now-dead `rift_workspace_change`/`rift_windows_change` event registrations if nothing else consumes them.
4. Update `CLAUDE.md`/`AGENTS.md` in this repo (they document the old CLI-subscription integration, lines ~271, ~340, ~349-354).

### 5.6 Acceptance criteria

- Steady-state operation spawns **no processes** (verify: `execsnoop`/`ps` while switching workspaces; only Mach traffic).
- Workspace switch, window open/close/move-to-workspace, focus change, and title change all update the bar, per display, within ~100 ms.
- Killing and restarting either `rift` or `sketchybar` recovers automatically (fresh snapshot, no stale items, no provider crash-loop).
- Clicking a workspace item still switches workspaces (unchanged path).
- With Rift not running, the bar starts cleanly and the provider idles/retries quietly.

---

## Reference material

Local checkouts (read-only reference; findings below were extracted from these):

| Repo | Path | Version |
|---|---|---|
| Rift (WM, Rust) | `~/dev/rift` (working repo) | v0.5.3, `main` |
| SketchyBar (bar, C) | `~/dev-explore/SketchyBar` | v2.24.0, `6284ee8` |
| SbarLua (Lua bindings, C) | `~/dev-explore/SbarLua` | `dba9cc4` |
| Old PoC module | `~/dev-explore/rift.lua` | unused, do not build on |

## 6. Rift IPC facts (v0.5.3) — `~/dev/rift`

### 6.1 Crates

- **`rift-protocol`** — `crates/rift-protocol/`: pure serde types, no macOS deps. Modules: `commands.rs`, `events.rs`, `layout.rs`, `queries.rs`, `selectors.rs`, `transport.rs`. The server uses the same crate (`src/model/broadcast.rs` re-exports `RiftEvent` as its broadcast type), so wire shapes are authoritative.
- **`rift-client`** — `crates/rift-client/src/lib.rs` (single file): synchronous Mach client. Key API:
  ```rust
  RiftMachClient::connect() -> Result<Self, ClientError>   // lookup is lazy per request
  client.is_available() -> bool
  client.get_workspaces(space_id: Option<u64>) -> Result<Vec<WorkspaceData>, ClientError>
  client.get_displays() -> Result<Vec<DisplayData>, ClientError>
  client.get_windows(space_id: Option<u64>) -> Result<Vec<WindowData>, ClientError>
  client.get_window_info(window_id) / get_layout_state(space_id) / get_workspace_layouts(...)
  client.subscribe(event: EventKind) -> Result<RiftMachSubscription, ClientError>
  subscription.recv_event() -> Result<RiftEvent, ClientError>   // blocking
  ```
  `RiftMachSubscription` owns a Mach receive right (queue limit 1024); `Drop` releases it. Errors via `ClientError` (thiserror). Examples: `crates/rift-client/examples/{dimmer.rs, listen.rs, query.rs}` — **dimmer.rs is the reference architecture for this provider** (subscribe-before-snapshot, event-as-invalidation-signal, re-query-then-diff).
- Transport details: bootstrap name **`git.acsandmann.rift`** (env override `RIFT_BS_NAME`); `MAX_MESSAGE_SIZE = 262_144` bytes for request/response and event payloads; NUL-terminated JSON with 4-byte alignment; service lookup retries 5× with 50ms·2ⁿ backoff.

### 6.2 Events (`crates/rift-protocol/src/events.rs`)

`EventKind` (wire names, snake_case; `All` = `"*"`): `workspace_changed`, `windows_changed`, `window_title_changed`, `focused_window_changed`, `stacks_changed`. That is the complete list.

`RiftEvent` (serde `tag = "type"`), every variant has `space_id: u64` and `display_uuid: Option<String>` plus accessors `.kind()`, `.space_id()`, `.display_uuid()`:

- `WorkspaceChanged { space_id, workspace_id, workspace_name, display_uuid }`
- `WindowsChanged { workspace_id, workspace_name, windows: Vec<String>, space_id, display_uuid }`
- `WindowTitleChanged { window_id, workspace_id, workspace_index, workspace_name, previous_title, new_title, space_id, display_uuid }`
- `FocusedWindowChanged { window_id, workspace_id, workspace_index, workspace_name, space_id, display_uuid }`
- `StacksChanged { workspace_id, workspace_index, workspace_name, stacks: Vec<StackInfo>, active_workspace_has_fullscreen, space_id, display_uuid }`

Emission caveats: `WindowsChanged` fires for the **active workspace only**; `WindowTitleChanged` only when the title actually changed and the space is active; `StacksChanged` only when at least one stack exists.

### 6.3 Gotchas

- `WindowsChanged.windows` / `StackInfo.windows` are **`WindowId` debug strings** (`"WindowId { pid: 42, idx: 7 }"`), *not* titles. Titles/app names require a query — hence the enrich step.
- `WorkspaceData.id` (a slotmap debug string from queries) and the event-side `WorkspaceId { idx, version }` **do not match textually**. Correlate workspaces by `index` or `name`.
- Query payload structs (`crates/rift-protocol/src/queries.rs`):
  `WorkspaceData { id, index, name, layout_mode, is_active, window_count, windows: Vec<WindowData> }`,
  `WindowData { id, title, frame, is_floating, is_focused, bundle_id, app_name, window_server_id }`,
  `DisplayData { uuid, name, screen_id, frame, space: Option<u64>, is_active_space, is_active_context, active_space_ids, inactive_space_ids }`.
- With `space_id = None`, queries resolve against a server-chosen default space — always pass an explicit `space_id` when routing per display.
- There is no dedicated "get active workspace" request; it's the `WorkspaceData` entry with `is_active == true`.

## 7. SketchyBar Mach protocol facts — `~/dev-explore/SketchyBar`

This is what the provider must implement (client side) to push triggers. There is **no auth, no handshake, no protocol version**; any process in the login session can send.

- **Service name:** `git.felix.sketchybar` (`src/mach.h`: `MACH_BS_NAME_FMT "git.felix.%s"` + binary basename). Look up via `task_get_special_port(TASK_BOOTSTRAP_PORT)` + `bootstrap_look_up`.
- **Message struct** (`src/mach.h`):
  ```c
  struct mach_message {
    mach_msg_header_t         header;
    mach_msg_size_t           msgh_descriptor_count;  // always 1
    mach_msg_ool_descriptor_t descriptor;             // the payload (out-of-line)
  };
  ```
  Descriptor: `address = payload`, `size = len`, `copy = MACH_MSG_VIRTUAL_COPY`, `deallocate = false`, `type = MACH_MSG_OOL_DESCRIPTOR`. Header for **fire-and-forget** (what the provider wants): `msgh_remote_port = service port`, `msgh_local_port = MACH_PORT_NULL`, `msgh_bits = MACH_MSGH_BITS_SET(MACH_MSG_TYPE_COPY_SEND & MACH_MSGH_BITS_REMOTE_MASK, 0, 0, MACH_MSGH_BITS_COMPLEX)`, `msgh_size = sizeof(struct mach_message)`. Send with `mach_msg(..., MACH_SEND_MSG, sizeof(struct mach_message), 0, MACH_PORT_NULL, MACH_MSG_TIMEOUT_NONE, MACH_PORT_NULL)`. If a reply is wanted (not needed here), set `msgh_local_port`/`msgh_id` to a temp receive port with `MACH_MSG_TYPE_MAKE_SEND` local bits; the server always replies to a non-null remote port (replies starting `"[!]"` are errors). Reference implementation to port: `SbarLua/src/mach.h` (`mach_get_bs_port`, `mach_send_message`); server-side parse: `SketchyBar/src/message.c` `handle_message_mach()` (line ~596).
- **Payload framing:** argv tokens, each NUL-terminated, concatenated, plus one extra NUL (double-NUL terminates the message). No length prefixes. Example: `--trigger\0rift_update\0WORKSPACES=[...]\0\0`. Multiple commands can be batched in one message; the splitter looks for `\0` followed by `-` (`get_batch_line`, `src/message.c:468`).
- **`--trigger` handling** (`handle_domain_trigger`, `src/message.c:66-101`): first token = event name, remaining tokens split as `KEY=value` **on the first `=` only** (JSON containing `=` is safe). Unknown event name → **silent no-op**. A few built-in names (`space_change`, `display_change`, …) are special-cased; custom names go to `bar_manager_custom_events_trigger` (`src/bar_manager.c:743`), which delivers to every item whose `update_mask` has the event's bit.
- **Delivery to subscribers** (`bar_item_update`, `src/bar_item.c`): items with `script=` get a forked `sh -c` (this is why the *old* pipeline forks); items with `mach_helper=<bootstrap name>` get the env vars serialized as `key\0value\0…\0` and Mach-sent to that service **without any fork**. `SENDER=<event name>` and the item's `NAME` are merged in automatically.
- **Constraints:** payloads are OOL → no practical size limit; server port queue = `MACH_PORT_QLIMIT_LARGE` (1024); all handling is serialized on the bar's main thread (don't send hundreds/sec — the debounce in §5.2 covers this); events are bits in a `uint64_t` → **max 64 distinct event names** (18 built-in), so the provider uses a single `rift_update` event, not one per Rift event kind; the CLI's reply wait uses a 100 ms receive timeout, but the provider skips replies entirely.

## 8. SbarLua facts — `~/dev-explore/SbarLua`

Why the Lua side needs no changes beyond the rewrite in §5.4:

- The Lua config process is long-lived: `sbar.event_loop()` runs a **CFRunLoop on the main thread** (`src/sketchybar.c:622-642`). It registers its own Mach service `git.lua.sketchybar<id>` at module load (`src/sketchybar.c:848-857`) and receives bar events there via a CFMachPort runloop source (`src/mach.h:250-268`).
- `item:subscribe("event", fn)` sends `--add event <event>`, then `--set <item> script= mach_helper=<its service>`, then `--subscribe` (`subscribe_register_event`, `src/sketchybar.c:292-310`). So subscribing from Lua **registers the custom event with the bar** and routes delivery over Mach — no shell scripts involved. This is why the provider must be launched *after* the config subscribed (§5.3).
- **Env values are JSON-auto-decoded:** the event callback (`callback_function`, `src/sketchybar.c:233`) parses the `key\0value\0` blob and converts each value via `json_to_lua_table` when it parses as JSON. Sending `WORKSPACES=<json array>` therefore arrives as a real Lua table.
- `sbar.set/add/trigger/query` are direct Mach messages to the bar (`sketchybar()`, `src/sketchybar.c:62-94`), and **every event callback is implicitly wrapped in a transaction** — all `sbar.set` calls inside one callback coalesce into a single Mach message at callback exit. Rendering a full display update is one message.
- Only `sbar.exec` forks (`fork` + `execvp`/`popen`, `src/sketchybar.c:714-764`). After the rewrite it remains only in: provider launch (once per config load), `build_display_map` (startup/display-change; possibly replaceable with the direct query API), and the click action.
- The Lua process self-terminates when the bar dies (1 Hz `getppid() == 1` orphan check) and exits on the bar's 2-byte `"k"` kill message — the provider does not need to manage the Lua side's lifecycle at all.

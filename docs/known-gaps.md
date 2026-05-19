# Known gaps (v0.1)

What's covered by automated tests in this repo and what requires manual
validation in Roblox Studio before the package can be considered fully
production-ready.

## Covered by CI / local tests

- 95 unit + parity + namespace tests under Lune (`lune run tests/runner.luau`)
- 5 pylast parity regressions (PR #528, #529, #530, #531, #532)
- Live-API smoke: `LASTFM_API_KEY=... lune run examples/lune-smoke.luau`
  exercises `track.getInfo`, `user.getRecentTracks`, the cache, signed
  `auth.getToken`, and empty-search edge cases against real Last.fm
- Type-check (`luau-lsp analyze`), lint (`selene`), format (`stylua --check`)
- Wally manifest packaging (`wally package`)

## Validated in Roblox Studio (2026-05-19)

All four Studio-only items below were exercised in a live Studio session via
the Roblox Studio MCP (place loaded, `LastFM` ModuleScript tree placed under
`ReplicatedStorage`, API services + HTTP enabled). The pass uncovered three
Roblox-runtime bugs that the Lune CI never reached; each was committed as its
own fix before the corresponding validation was re-run and recorded green.

### 1. DataStore round-trip — Validated
Live DataStoreService round-trip through `SessionStore.RobloxDataStore`:
SetSession → SaveSessionAsync(12345) → ForgetSession → LoadSessionAsync(12345)
restored `Name = "alice"`, `Subscriber = false`; ClearSessionAsync(12345)
followed by LoadSessionAsync(12345) returned `false`. UpdateAsync concurrent-
merge logic verified by writing a newer-StoredAt entry, then an older one —
the merger correctly kept the newer record. No budget-low warning fired
(Studio budget stayed well above the 6-request threshold).

Studio prerequisite: "Enable Studio Access to API Services" must be on in
Game Settings → Security; otherwise `DataStoreService:GetDataStore` throws
"You must publish this place to the web" before the lib ever runs.

### 2. AuthGui visual smoke — Validated
`AuthGui.Show(playerGui, url)` rendered the expected modal in Play mode:
title "Approve Last.fm access", subtitle, full URL in a read-only TextBox
(TextEditable = false, ClearTextOnFocus = false), copy hint below. No
crashes from the `GuiService:OpenBrowserWindow` best-effort call (it's
already wrapped in pcall). Visual capture archived during the validation
session.

Caveat carried forward: TextBox selection on `TextEditable=false` boxes
does not visibly highlight in Studio screenshots; Ctrl+C copy behavior
across PC / mobile / console still needs eyes from an actual user.

### 3. HTTP enabled error — Validated
With `HttpService.HttpEnabled = false`, `client.Track:GetInfoAsync(...)`
returns Err with `Kind = "HttpError"` and the friendly Message
"HttpService is not enabled. In Studio: HttpService.HttpEnabled = true.
In published places: Game Settings > Security > Allow HTTP Requests."

This validation uncovered two Roblox-only bugs, fixed before recording green:
- The runtime-detection helper used `rawget(_G, "game")`, which always
  returns nil in Roblox (game is a script-scoped global, not in `_G`).
  Detection fell through to "Unknown" and the Roblox HTTP polyfill was
  never selected.
- `HttpService:RequestAsync` rejected the lib's `user-agent` header before
  the HttpEnabled check could trigger, so the friendly hint never fired.
  Roblox-managed headers are now stripped in the polyfill. The case of
  Roblox's error message ("HTTP requests are not enabled") also didn't
  match the lib's substring check ("Http..."); fixed with a lower-case
  comparison.

### 4. Rate-limit + task scheduler — Validated
With `RateLimit = { Enabled = true, RequestsPerSecond = 5, Burst = 5 }`,
the baseline `client.Track:GetInfoAsync("Daft Punk", "One More Time")`
succeeded against the live API. Ten `task.spawn`-ed concurrent calls
completed in **1.08 s**, exactly on target for 5 rps (5 instant from
burst, 5 throttled at 0.2 s intervals). Zero unexpected error kinds.

This validation uncovered a concurrency race in `RateLimit.Acquire`:
under load, multiple coroutines woke from the same `task.wait` and each
"consumed" the single refilled token, defeating the limiter. Fixed by
looping the acquire so each waiter re-checks the bucket after wakeup.
Before the fix the same 10-call test ran in 0.31 s — no real throttling.

## How to validate before publishing

1. Run `examples/lune-smoke.luau` once more against a real API key
2. Build with Rojo: `rojo build default.project.json -o lastfm-luau.rbxm`
3. Load in Studio + run the 4 manual scenarios above
4. `wally publish` (requires Wally auth token)

## Bundle bloat (minor)

`wally package` currently includes `tests/`, `examples/`, `scripts/`, and
project-config files in the published artifact (~180KB). The `include` field
in wally.toml is more permissive than expected in v0.3.2. Investigate whether
v0.3.3+ tightens this, or use a published-only manifest variant.

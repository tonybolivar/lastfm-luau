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

## Needs Roblox Studio (not validated yet)

### 1. DataStore round-trip
The `SessionStore.RobloxDataStore` implementation uses `DataStoreService:UpdateAsync`
with a concurrent-merge function and budget-warning logic. Tested via type-check
and structurally, but not exercised against a live DataStore. Before publishing:

1. Build the project: `rojo build default.project.json -o lastfm-luau.rbxm`
2. Open a Studio place, insert the rbxm into ReplicatedStorage
3. Enable Studio API services
4. Run a server Script that:
   - Constructs a Client with `SessionStore = RobloxDataStore.New(...)`
   - Calls `SetSession` with a fake session and `SaveSessionAsync(123)`
   - Restarts the script
   - Calls `LoadSessionAsync(123)` and confirms round-trip
   - Calls `ClearSessionAsync(123)`, then `LoadSessionAsync` returns false
5. Trigger a code-9 API response (e.g., by passing a corrupt session key)
   and confirm the auto-invalidation drops the in-memory session AND clears
   the DataStore entry.

### 2. In-experience auth flow
`Polyfills.Roblox.AuthGui.Show(parent, url)` builds a ScreenGui with a
read-only TextBox the player can select-and-copy. Verified structurally
(parses, type-checks) but the UX needs eyes:

1. Test that `setclipboard` falls back gracefully (it doesn't exist on the
   stock player client; the helper does not call it)
2. Test that `GuiService:OpenBrowserWindow` (deprecated) doesn't crash when
   it no-ops on console / mobile
3. Test on PC, mobile, and console — TextBox selection behavior differs

### 3. HTTP enabled error
The Roblox HTTP adapter rethrows the "Http requests are not enabled" error
as a clear `HttpError`. Needs a Studio test with HttpService.HttpEnabled = false
to confirm the friendly message reaches the caller.

### 4. Rate-limit interaction with Roblox's 500/min cap
A single server is capped at 500 `HttpService:RequestAsync` calls per minute.
Our default 5 rps limiter sustains 300/min, well under the cap. But verify
with `task.spawn`-ed parallel callers that the limiter actually serializes
them via `task.wait`. This was validated in Lune; Roblox's task scheduler
has different yield semantics worth confirming.

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

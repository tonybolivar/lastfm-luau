# lastfm-luau

API client for Luau. Roblox and Lune.

## Install

### Wally (Roblox)

```toml
[dependencies]
LastFM = "tonybolivar/lastfm-luau@1.0.0"
```

Then `wally install`.

### Lune

Clone and `require("./src")`.

## Quick start

```lua
--!strict
local LastFM = require(ReplicatedStorage.Packages.LastFM)

local client = LastFM.new({
    ApiKey = "...",
    Secret = "...",
    UserAgent = "MyGame/1.0",
})

local info = client.Track:GetInfoAsync("Artist", "Track"):Await():UnwrapOk()
print(info.Name, info.Artist.Name, info.PlayCount)

local page = client.User:GetRecentTracksAsync("username", { Limit = 50 }):Await():UnwrapOk()
for _, track in page.Items do
    print(track.Date.Iso8601, track.Name, track.Artist.Name)
end
if page:HasMore() then
    local next = page:NextAsync():Await():UnwrapOk()
end
```

## Auth + DataStore persistence

```lua
local Players = game:GetService("Players")
local store = LastFM.SessionStore.RobloxDataStore.New({ Name = "Sessions", Scope = "v1" })
local client = LastFM.new({ ApiKey = "...", Secret = "...", SessionStore = store })

Players.PlayerAdded:Connect(function(player)
    local loaded = client:LoadSessionAsync(player.UserId):Await()
    if loaded:IsOk() and loaded:UnwrapOk() then
        return
    end

    local token = client.Auth:GetTokenAsync():Await():UnwrapOk()
    local approval = client.Auth:GetApprovalUrl(token)
    LastFM.AuthGui.Show(player.PlayerGui, approval.Url)

    local session = client.Auth:GetSessionAsync(token):Await():UnwrapOk()
    client:SetSession(session)
    client:SaveSessionAsync(player.UserId):Await():UnwrapOk()
end)
```

## Writes

Require an active session:

```lua
client.Track:LoveAsync("Artist", "Track"):Await():UnwrapOk()

client.Track:ScrobbleAsync({
    { Artist = "A", Track = "T1", Timestamp = os.time() - 240 },
    { Artist = "A", Track = "T2", Timestamp = os.time() - 480 },
}):Await():UnwrapOk()

client.Track:UpdateNowPlayingAsync("Artist", "Track"):Await():UnwrapOk()
```

## Configuration

| Field | Default | Notes |
|---|---|---|
| `ApiKey` | required | |
| `Secret` | nil | Required for signed methods (auth, writes) |
| `UserAgent` | `lastfm-luau/1.0` | Prepended to your value if provided |
| `HttpClient` | auto-detect | Inject for tests or custom transport |
| `Cache` | `InMemoryCache` | Implement the `Cache` interface to swap |
| `SessionStore` | nil | First-class persistence, see auth section |
| `RateLimit` | `{ RequestsPerSecond = 5, Burst = 5 }` | Token bucket, yields by default |
| `Retry` | `{ Attempts = 3, BaseSeconds = 0.5, CapSeconds = 30 }` | Exponential backoff with full jitter |
| `Logger` | noop | `(level, message, ctx) -> ()` |
| `AutoInvalidateStoredSessions` | true | Drop session on API code 9 |

## Security (Roblox)

**Construct the client on the server only.** `Config.Secret` and session keys grant write access to user accounts and must never reach the client.

- Put `LastFM.new(...)` in `ServerScriptService`, never `LocalScript`.
- Don't return session keys through `RemoteFunction`.
- For client-driven UIs, send the intent over `RemoteEvent` (the parameters) and execute the signed call from the server.
- `Secret.New(...)` masks the value in `tostring` and blocks mutation, revealed only at signing time.

## Lune usage

```lua
local LastFM = require("./src")
local client = LastFM.new({ ApiKey = "..." })
local info = client.Track:GetInfoAsync("Artist", "Track"):Await():UnwrapOk()
print(info.Name)
```

## License

[MIT](LICENSE).

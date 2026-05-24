--!strict
-- End-to-end smoke against the live Last.fm API.
-- Proves the full pipeline: construct client → sign (if needed) → HTTP →
-- parse → typed result.
--
-- Usage (from project root):
--   LASTFM_API_KEY=xxx [LASTFM_SECRET=yyy] lune run examples/lune-smoke.luau

local process = require("@lune/process")
local LastFM = require("@self")

local apiKey = process.env.LASTFM_API_KEY
local secret = process.env.LASTFM_SECRET

if not apiKey or apiKey == "" then
	error("LASTFM_API_KEY environment variable is required", 0)
end

print(`lastfm-luau smoke, runtime: {LastFM.Runtime}`)
print(`API key: {string.sub(apiKey, 1, 8)}... (secret {if secret then "set" else "not set"})`)
print()

local client = LastFM.new({
	ApiKey = apiKey,
	Secret = secret,
	UserAgent = "lastfm-luau-smoke/1.0",
	Logger = function(level, message, ctx)
		if level == "warn" or level == "error" then
			print(`[{level}] {message}`)
		end
	end,
})

-- 1. Read public data
print("== track.getInfo: Daft Punk, One More Time ==")
local trackResult = client.Track:GetInfoAsync("Daft Punk", "One More Time"):Await()
if trackResult:IsErr() then
	local err = trackResult:UnwrapErr()
	error(`track.getInfo failed: [{err.Kind}] {err.Message}`, 0)
end
local track = trackResult:UnwrapOk()
print(`  Name:      {track.Name}`)
print(`  Artist:    {track.Artist.Name}`)
print(`  Duration:  {track.Duration} ms`)
print(`  PlayCount: {track.PlayCount}`)
print(`  Listeners: {track.Listeners}`)
print(`  Url:       {track.Url}`)
print()

-- 2. Paginated reads
print("== user.getRecentTracks: rj (limit=3) ==")
local recentResult = client.User:GetRecentTracksAsync("rj", { Limit = 3 }):Await()
if recentResult:IsErr() then
	local err = recentResult:UnwrapErr()
	error(`user.getRecentTracks failed: [{err.Kind}] {err.Message}`, 0)
end
local page = recentResult:UnwrapOk()
print(`  Page {page.PageNumber} of {page.TotalPages} ({page.TotalItems} total)`)
for i, t in page.Items do
	local when = if t.Date then t.Date.Iso8601 else "now playing"
	print(`  {i}. {when}, {t.Artist.Name}, {t.Name}`)
end
print()

-- 3. Cache hit on second call (proves the cache+request pipeline is wired)
print("== cache hit check (re-call track.getInfo, should not re-fetch) ==")
local before = os.clock()
client.Track:GetInfoAsync("Daft Punk", "One More Time"):Await():UnwrapOk()
local elapsed = (os.clock() - before) * 1000
print(`  Second call took {string.format("%.2f", elapsed)} ms (cache hit if << 100ms)`)
print()

-- 4. Signed request, auth.getToken. Only runs if SECRET is set.
if secret then
	print("== auth.getToken (signed) ==")
	local tokenResult = client.Auth:GetTokenAsync():Await()
	if tokenResult:IsErr() then
		local err = tokenResult:UnwrapErr()
		error(`auth.getToken failed: [{err.Kind}] {err.Message}`, 0)
	end
	local token = tokenResult:UnwrapOk()
	print(`  Token (32 hex): {token}`)
	local approval = client.Auth:GetApprovalUrl(token)
	print(`  Approval URL: {approval.Url}`)
	print()
else
	print("(skipping auth.getToken, LASTFM_SECRET not set)")
	print()
end

-- 5. Empty-search regression check (pylast #530 territory)
print("== artist.search no-results query (pylast #530) ==")
local emptyResult = client.Artist:SearchAsync("zzzqzzzqzzzqxyzzz12345", { Limit = 3 }):Await()
if emptyResult:IsErr() then
	local err = emptyResult:UnwrapErr()
	error(`artist.search failed: [{err.Kind}] {err.Message}`, 0)
end
local emptyPage = emptyResult:UnwrapOk()
print(`  Items: {#emptyPage.Items}, TotalItems: {emptyPage.TotalItems}`)
assert(#emptyPage.Items == 0, "expected empty Items list on no-results search")
print(`  OK, empty search returned an empty Page without crashing`)
print()

print("All smoke checks passed.")

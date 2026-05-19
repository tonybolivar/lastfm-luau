--!strict
-- Token bucket rate limiter. By default yields the caller until tokens
-- are available; with ThrowOnLimit = true, raises a RateLimited error instead.
--
-- The `Wait` function is injected so the limiter stays runtime-agnostic
-- (Roblox `task.wait`, Lune `@lune/task`.wait, or a fake for tests).

local Errors = require(script.Parent.Errors)

export type WaitFn = (seconds: number) -> ()

export type Bucket = typeof(setmetatable(
	{} :: {
		_Capacity: number,
		_Tokens: number,
		_RefillRate: number,
		_LastRefill: number,
		_ThrowOnLimit: boolean,
		_Wait: WaitFn,
	},
	{} :: any
))

local RateLimit = {}

local bucketMt = {}
bucketMt.__index = bucketMt

local function refill(self: any)
	local now = os.clock()
	local elapsed = now - self._LastRefill
	if elapsed > 0 then
		self._Tokens = math.min(self._Capacity, self._Tokens + elapsed * self._RefillRate)
		self._LastRefill = now
	end
end

function bucketMt.Acquire(self: Bucket)
	local s = self :: any
	refill(s)
	if s._Tokens >= 1 then
		s._Tokens -= 1
		return
	end
	if s._ThrowOnLimit then
		error(Errors.New("RateLimited", "Rate limit exceeded (local bucket)"), 0)
	end
	local needed = 1 - s._Tokens
	local waitSeconds = needed / s._RefillRate
	s._Wait(waitSeconds)
	refill(s)
	s._Tokens = math.max(0, s._Tokens - 1)
end

function bucketMt.Available(self: Bucket): number
	local s = self :: any
	refill(s)
	return s._Tokens
end

function RateLimit.New(opts: {
	Wait: WaitFn,
	RequestsPerSecond: number?,
	Burst: number?,
	ThrowOnLimit: boolean?,
}): Bucket
	local capacity = opts.Burst or 5
	return setmetatable({
		_Capacity = capacity,
		_Tokens = capacity,
		_RefillRate = opts.RequestsPerSecond or 5,
		_LastRefill = os.clock(),
		_ThrowOnLimit = opts.ThrowOnLimit or false,
		_Wait = opts.Wait,
	}, bucketMt) :: any
end

-- Noop bucket — used when rate limiting is disabled. Acquire() returns instantly.
local noopMt = {}
noopMt.__index = noopMt
function noopMt.Acquire(_) end
function noopMt.Available(_): number
	return math.huge
end

function RateLimit.Noop(): Bucket
	return setmetatable({}, noopMt) :: any
end

return RateLimit

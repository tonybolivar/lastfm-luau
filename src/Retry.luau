--!strict
-- Retry with exponential backoff and full jitter.
-- Only retries errors flagged as retryable by Errors.IsRetryable (Transient + RateLimited).

local Errors = require("@self/Errors")

export type WaitFn = (seconds: number) -> ()

export type RetryConfig = {
	Attempts: number?,
	BaseSeconds: number?,
	CapSeconds: number?,
	Wait: WaitFn,
}

local Retry = {}

local DEFAULT_ATTEMPTS = 3
local DEFAULT_BASE = 0.5
local DEFAULT_CAP = 30

-- Execute thunk with retries. Returns the value or rethrows the final error.
-- If the error has a Retry-After hint (set by HTTP layer for 429s), uses it
-- instead of the computed backoff.
function Retry.Run<T>(thunk: () -> T, config: RetryConfig): T
	local attempts = config.Attempts or DEFAULT_ATTEMPTS
	local base = config.BaseSeconds or DEFAULT_BASE
	local cap = config.CapSeconds or DEFAULT_CAP
	local wait = config.Wait

	local lastErr: any = nil
	for attempt = 1, attempts do
		local ok, result = pcall(thunk)
		if ok then
			return result
		end

		if Errors.IsLastFMError(result) then
			local err = (result :: any) :: Errors.LastFMError
			err.Attempt = attempt
			lastErr = err
			if not Errors.IsRetryable(err) or attempt == attempts then
				error(err, 0)
			end

			-- Respect Retry-After hint stamped onto the error by the HTTP layer.
			local retryAfter = (err :: any).RetryAfterSeconds
			local delay: number
			if typeof(retryAfter) == "number" and retryAfter > 0 then
				delay = math.min(cap, retryAfter)
			else
				delay = math.random() * math.min(cap, base * (2 ^ (attempt - 1)))
			end
			wait(delay)
		else
			-- Non-structured error: don't retry.
			error(result, 0)
		end
	end

	error(lastErr, 0)
end

return Retry

--!strict
-- Minimal Future + Result implementation.
--
-- Future represents a deferred computation. Construct with Future.New(thunk).
-- The thunk runs synchronously inside :Await(). For typical Last.fm usage,
-- the thunk will yield internally (HttpService:RequestAsync, etc.), so :Await
-- will yield the calling coroutine until the result is ready.
--
-- Result is the value a Future resolves to: Ok(value) or Err(error).

local Future = {}

local resultMt = {}
resultMt.__index = resultMt

export type Result<E, T> = typeof(setmetatable(
	{} :: {
		_Ok: boolean,
		_Value: T?,
		_Error: E?,
	},
	resultMt
))

export type FutureLike<E, T> = typeof(setmetatable(
	{} :: {
		_Done: boolean,
		_Running: boolean,
		_Thunk: () -> T,
		_Result: Result<E, T>?,
	},
	{} :: any
))

function resultMt.IsOk<E, T>(self: Result<E, T>): boolean
	return (self :: any)._Ok
end

function resultMt.IsErr<E, T>(self: Result<E, T>): boolean
	return not (self :: any)._Ok
end

function resultMt.UnwrapOk<E, T>(self: Result<E, T>): T
	if not (self :: any)._Ok then
		error(`Result is Err: {tostring((self :: any)._Error)}`, 2)
	end
	return (self :: any)._Value
end

function resultMt.UnwrapErr<E, T>(self: Result<E, T>): E
	if (self :: any)._Ok then
		error("Result is Ok, not Err", 2)
	end
	return (self :: any)._Error
end

local function makeOk<E, T>(value: T): Result<E, T>
	return setmetatable({ _Ok = true, _Value = value }, resultMt) :: any
end

local function makeErr<E, T>(err: E): Result<E, T>
	return setmetatable({ _Ok = false, _Error = err }, resultMt) :: any
end

local futureMt = {}
futureMt.__index = futureMt

function futureMt.Await<E, T>(self: FutureLike<E, T>): Result<E, T>
	local s = self :: any
	if s._Done then
		return s._Result
	end
	if s._Running then
		error("Future is already being awaited concurrently; concurrent awaits on the same Future are not supported", 2)
	end
	s._Running = true
	local ok, value = pcall(s._Thunk)
	s._Done = true
	if ok then
		s._Result = makeOk(value)
	else
		s._Result = makeErr(value)
	end
	return s._Result
end

function futureMt.Poll<E, T>(self: FutureLike<E, T>): Result<E, T>?
	return (self :: any)._Result
end

function futureMt.IsComplete<E, T>(self: FutureLike<E, T>): boolean
	return (self :: any)._Done
end

function Future.New<E, T>(thunk: () -> T): FutureLike<E, T>
	return setmetatable({
		_Done = false,
		_Running = false,
		_Thunk = thunk,
		_Result = nil,
	}, futureMt) :: any
end

function Future.Ok<E, T>(value: T): FutureLike<E, T>
	local f = Future.New(function(): T
		return value
	end)
	-- Pre-resolve so callers don't even have to await.
	local fAny = f :: any
	fAny._Result = makeOk(value)
	fAny._Done = true
	return f
end

function Future.Err<E, T>(err: E): FutureLike<E, T>
	local f = Future.New(function(): T
		error(err)
	end)
	local fAny = f :: any
	fAny._Result = makeErr(err)
	fAny._Done = true
	return f
end

return Future

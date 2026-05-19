--!strict
-- Shared type aliases re-exported from across the library.
-- Consumers usually `require(LastFM.Types)` once and use everything from here.

local Future = require("@self/Future")
local Errors = require("@self/Errors")

export type FutureLike<E, T> = Future.FutureLike<E, T>
export type Result<E, T> = Future.Result<E, T>
export type LastFMError = Errors.LastFMError
export type ErrorKind = Errors.ErrorKind

export type LogLevel = "debug" | "info" | "warn" | "error"
export type Logger = (level: LogLevel, message: string, ctx: { [string]: any }?) -> ()

export type RateLimitConfig = {
	Enabled: boolean?,
	RequestsPerSecond: number?,
	Burst: number?,
	ThrowOnLimit: boolean?,
}

export type RetryConfig = {
	Attempts: number?,
	BaseSeconds: number?,
	CapSeconds: number?,
}

export type ImageSize = "small" | "medium" | "large" | "extralarge" | "mega"
export type Image = { Size: ImageSize, Url: string }
export type Period = "overall" | "7day" | "1month" | "3month" | "6month" | "12month"
export type LastDate = { UnixSeconds: number, Iso8601: string }

export type Session = {
	Name: string,
	Key: string,
	Subscriber: boolean,
}

export type StoredSession = {
	Name: string,
	Key: string,
	Subscriber: boolean,
	StoredAt: number,
	Version: number,
}

export type HttpRequest = {
	method: "GET" | "POST",
	url: string,
	headers: { [string]: string }?,
	body: string?,
	timeout: number?,
}

export type HttpResponse = {
	ok: boolean,
	status: number,
	statusMessage: string?,
	headers: { [string]: string },
	body: string,
}

export type HttpClient = {
	Request: (self: HttpClient, req: HttpRequest) -> HttpResponse,
}

return {}

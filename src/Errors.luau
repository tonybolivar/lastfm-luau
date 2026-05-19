--!strict
export type ErrorKind =
	"InvalidParameter"
	| "InvalidApiKey"
	| "ApiError"
	| "HttpError"
	| "Transient"
	| "RateLimited"
	| "AuthRequired"
	| "AuthForbidden"
	| "NoSecret"
	| "ParseError"
	| "NotFound"
	| "DataStoreError"

export type LastFMError = {
	Kind: ErrorKind,
	Message: string,
	ApiCode: number?,
	HttpStatus: number?,
	Method: string?,
	Attempt: number?,
	Cause: any?,
}

local Errors = {}

function Errors.New(kind: ErrorKind, message: string, fields: { [string]: any }?): LastFMError
	local err: any = { Kind = kind, Message = message }
	if fields then
		for k, v in fields do
			err[k] = v
		end
	end
	return err :: LastFMError
end

local CODE_TO_KIND: { [number]: ErrorKind } = {
	[2] = "Transient",
	[3] = "ApiError",
	[4] = "AuthRequired",
	[5] = "ApiError",
	[6] = "InvalidParameter",
	[7] = "NotFound",
	[8] = "Transient",
	[9] = "AuthRequired",
	[10] = "InvalidApiKey",
	[11] = "Transient",
	[13] = "AuthRequired",
	[16] = "Transient",
	[17] = "AuthForbidden",
	[26] = "InvalidApiKey",
	[29] = "RateLimited",
}

function Errors.FromApiCode(code: number, message: string, method: string?): LastFMError
	local kind: ErrorKind = CODE_TO_KIND[code] or "ApiError"
	return Errors.New(kind, message, { ApiCode = code, Method = method })
end

function Errors.IsRetryable(err: LastFMError): boolean
	return err.Kind == "Transient" or err.Kind == "RateLimited"
end

function Errors.IsLastFMError(value: any): boolean
	return type(value) == "table" and type((value :: any).Kind) == "string" and type((value :: any).Message) == "string"
end

return Errors

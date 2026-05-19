--!strict
local Logger = {}

export type LogLevel = "debug" | "info" | "warn" | "error"
export type LoggerFn = (level: LogLevel, message: string, ctx: { [string]: any }?) -> ()

local LEVEL_RANK: { [LogLevel]: number } = {
	debug = 10,
	info = 20,
	warn = 30,
	error = 40,
}

function Logger.Noop(_: LogLevel, _: string, _: { [string]: any }?) end

function Logger.Print(level: LogLevel, message: string, ctx: { [string]: any }?)
	local ctxStr = ""
	if ctx then
		local parts: { string } = {}
		for k, v in ctx do
			table.insert(parts, `{k}={tostring(v)}`)
		end
		if #parts > 0 then
			ctxStr = " [" .. table.concat(parts, " ") .. "]"
		end
	end
	local line = `[lastfm:{level}]{ctxStr} {message}`
	if level == "warn" or level == "error" then
		warn(line)
	else
		print(line)
	end
end

function Logger.WithMinLevel(min: LogLevel, inner: LoggerFn): LoggerFn
	local minRank = LEVEL_RANK[min]
	return function(level, message, ctx)
		if LEVEL_RANK[level] >= minRank then
			inner(level, message, ctx)
		end
	end
end

return Logger

--!strict
-- Immutable paginated result. Carries a closure `_Refetch(page)` that the
-- Rest layer captures with the original method + base params, so :NextAsync
-- and friends can re-issue the call cleanly.

local Future = require("@self/Future")
local Errors = require("@self/Errors")

export type Refetch<T> = (page: number) -> Future.FutureLike<Errors.LastFMError, Page<T>>

export type Page<T> = typeof(setmetatable(
	{} :: {
		Items: { T },
		PageNumber: number,
		PageSize: number,
		TotalPages: number,
		TotalItems: number,
		_Refetch: Refetch<T>,
	},
	{} :: any
))

local pageMt = {}
pageMt.__index = pageMt

function pageMt.HasMore<T>(self: Page<T>): boolean
	local s = self :: any
	return s.PageNumber < s.TotalPages
end

function pageMt.HasPrev<T>(self: Page<T>): boolean
	return (self :: any).PageNumber > 1
end

function pageMt.NextAsync<T>(self: Page<T>): Future.FutureLike<Errors.LastFMError, Page<T>>
	local s = self :: any
	if s.PageNumber >= s.TotalPages then
		return Future.Err(Errors.New("InvalidParameter", "Already on the last page"))
	end
	return s._Refetch(s.PageNumber + 1)
end

function pageMt.PrevAsync<T>(self: Page<T>): Future.FutureLike<Errors.LastFMError, Page<T>>
	local s = self :: any
	if s.PageNumber <= 1 then
		return Future.Err(Errors.New("InvalidParameter", "Already on the first page"))
	end
	return s._Refetch(s.PageNumber - 1)
end

function pageMt.GoToAsync<T>(self: Page<T>, page: number): Future.FutureLike<Errors.LastFMError, Page<T>>
	local s = self :: any
	if page < 1 then
		return Future.Err(Errors.New("InvalidParameter", `Page {page} out of bounds (min 1)`))
	end
	if s.TotalPages > 0 and page > s.TotalPages then
		return Future.Err(Errors.New("InvalidParameter", `Page {page} out of bounds (max {s.TotalPages})`))
	end
	return s._Refetch(page)
end

local Page = {}

function Page.New<T>(opts: {
	Items: { T },
	PageNumber: number,
	PageSize: number,
	TotalPages: number,
	TotalItems: number,
	Refetch: Refetch<T>,
}): Page<T>
	return setmetatable({
		Items = opts.Items,
		PageNumber = opts.PageNumber,
		PageSize = opts.PageSize,
		TotalPages = opts.TotalPages,
		TotalItems = opts.TotalItems,
		_Refetch = opts.Refetch,
	}, pageMt) :: any
end

-- Convenience: build a Page from a Parse.Pagination block.
function Page.Build<T>(opts: {
	Items: { T },
	Pagination: { Page: number, PerPage: number, TotalPages: number, Total: number },
	Refetch: Refetch<T>,
}): Page<T>
	return Page.New({
		Items = opts.Items,
		PageNumber = opts.Pagination.Page,
		PageSize = opts.Pagination.PerPage,
		TotalPages = opts.Pagination.TotalPages,
		TotalItems = opts.Pagination.Total,
		Refetch = opts.Refetch,
	})
end

-- Empty page, carried-forward fix from pylast #530: empty searches return an
-- empty Page<T> rather than crashing on a missing `matches` element.
function Page.Empty<T>(refetch: Refetch<T>): Page<T>
	return Page.New({
		Items = {} :: { T },
		PageNumber = 1,
		PageSize = 0,
		TotalPages = 0,
		TotalItems = 0,
		Refetch = refetch,
	})
end

return Page

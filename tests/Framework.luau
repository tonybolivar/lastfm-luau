--!strict
-- Minimal test framework, jest-like API.
-- Spec files return a function that, when called, registers cases.

local Framework = {}

type Case = { name: string, fn: () -> () }

local cases: { Case } = {}
local suiteStack: { string } = {}

local function fullName(name: string): string
	if #suiteStack == 0 then
		return name
	end
	return table.concat(suiteStack, " > ") .. " > " .. name
end

function Framework.describe(name: string, fn: () -> ())
	table.insert(suiteStack, name)
	fn()
	table.remove(suiteStack)
end

function Framework.it(name: string, fn: () -> ())
	table.insert(cases, { name = fullName(name), fn = fn })
end

local function deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= type(b) then
		return false
	end
	if type(a) ~= "table" then
		return false
	end
	for k, v in (a :: any) do
		if not deepEqual(v, (b :: any)[k]) then
			return false
		end
	end
	for k in (b :: any) do
		if (a :: any)[k] == nil then
			return false
		end
	end
	return true
end

local function reprError(err: any): string
	if type(err) == "table" and (err :: any).Message then
		return tostring((err :: any).Kind or "?") .. ": " .. tostring((err :: any).Message)
	end
	return tostring(err)
end

export type Expector = {
	toBe: (expected: any) -> (),
	toEqual: (expected: any) -> (),
	toBeTruthy: () -> (),
	toBeFalsy: () -> (),
	toBeNil: () -> (),
	toBeType: (expected: string) -> (),
	toMatch: (pattern: string) -> (),
	toThrow: (matchPattern: string?) -> (),
	toThrowKind: (kind: string) -> (),
}

function Framework.expect(value: any): Expector
	local e: Expector = {} :: any
	e.toBe = function(expected)
		if value ~= expected then
			error(`Expected {tostring(expected)}, got {tostring(value)}`, 2)
		end
	end
	e.toEqual = function(expected)
		if not deepEqual(value, expected) then
			error("Tables not deeply equal", 2)
		end
	end
	e.toBeTruthy = function()
		if not value then
			error(`Expected truthy, got {tostring(value)}`, 2)
		end
	end
	e.toBeFalsy = function()
		if value then
			error(`Expected falsy, got {tostring(value)}`, 2)
		end
	end
	e.toBeNil = function()
		if value ~= nil then
			error(`Expected nil, got {tostring(value)}`, 2)
		end
	end
	e.toBeType = function(expected)
		if type(value) ~= expected then
			error(`Expected type {expected}, got {type(value)}`, 2)
		end
	end
	e.toMatch = function(pattern)
		if type(value) ~= "string" or not string.find(value, pattern) then
			error(`Expected "{tostring(value)}" to match "{pattern}"`, 2)
		end
	end
	e.toThrow = function(matchPattern)
		assert(type(value) == "function", "toThrow expects a function value")
		local ok, err = pcall(value :: any)
		if ok then
			error("Expected function to throw, but it did not", 2)
		end
		if matchPattern then
			local msg = reprError(err)
			if not string.find(msg, matchPattern) then
				error(`Error "{msg}" did not match pattern "{matchPattern}"`, 2)
			end
		end
	end
	e.toThrowKind = function(kind)
		assert(type(value) == "function", "toThrowKind expects a function value")
		local ok, err = pcall(value :: any)
		if ok then
			error("Expected function to throw, but it did not", 2)
		end
		if type(err) ~= "table" or (err :: any).Kind ~= kind then
			error(`Expected error Kind="{kind}", got "{reprError(err)}"`, 2)
		end
	end
	return e
end

function Framework.run(): boolean
	local passed, failed = 0, 0
	local failures: { string } = {}
	for _, case in cases do
		local ok, err = pcall(case.fn)
		if ok then
			passed += 1
			print(`PASS  {case.name}`)
		else
			failed += 1
			local msg = reprError(err)
			print(`FAIL  {case.name}\n      {msg}`)
			table.insert(failures, case.name)
		end
	end
	print(`\n  {passed} passed, {failed} failed (of {passed + failed} total)`)
	if failed > 0 then
		print(`\n  Failures:`)
		for _, name in failures do
			print(`    - {name}`)
		end
	end
	return failed == 0
end

function Framework.reset()
	cases = {}
	suiteStack = {}
end

return Framework

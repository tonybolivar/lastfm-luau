--!strict
-- Pure-Luau MD5 implementation. Returns the MD5 hash of a string as a
-- 32-character lowercase hex string.
--
-- Test vectors (RFC 1321):
--   ""                            -> d41d8cd98f00b204e9800998ecf8427e
--   "a"                           -> 0cc175b9c0f1b6a831c399e269772661
--   "abc"                         -> 900150983cd24fb0d6963f7d28e17f72
--   "message digest"              -> f96b697d7cb7938d525a2f31aaf161d0
--   "The quick brown fox jumps over the lazy dog"
--                                 -> 9e107d9d372bb6826bd81d3542a419d6

local Md5 = {}

local band = bit32.band
local bor = bit32.bor
local bxor = bit32.bxor
local bnot = bit32.bnot
local lshift = bit32.lshift
local rshift = bit32.rshift
local lrotate = bit32.lrotate

local SHIFTS = {
	7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
	5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
	4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
	6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
}

local T = {
	0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
	0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
	0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
	0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
	0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
	0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
	0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
	0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
	0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
	0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
	0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
	0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
	0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
	0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
	0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
	0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
}

local function pad(input: string): string
	local len = #input
	local padded = input .. "\128"
	local zeros = (56 - (len + 1) % 64) % 64
	padded ..= string.rep("\0", zeros)
	local bitLen = len * 8
	for i = 0, 7 do
		padded ..= string.char(band(rshift(bitLen, i * 8), 0xff))
	end
	return padded
end

local function readU32LE(s: string, i: number): number
	return bor(
		string.byte(s, i),
		lshift(string.byte(s, i + 1), 8),
		lshift(string.byte(s, i + 2), 16),
		lshift(string.byte(s, i + 3), 24)
	)
end

local function u32ToHexLE(n: number): string
	return string.format(
		"%02x%02x%02x%02x",
		band(n, 0xff),
		band(rshift(n, 8), 0xff),
		band(rshift(n, 16), 0xff),
		band(rshift(n, 24), 0xff)
	)
end

function Md5.Hash(input: string): string
	local padded = pad(input)
	local a0, b0, c0, d0 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476

	for chunkStart = 1, #padded, 64 do
		local M: { number } = table.create(16, 0)
		for i = 0, 15 do
			M[i + 1] = readU32LE(padded, chunkStart + i * 4)
		end

		local a, b, c, d = a0, b0, c0, d0
		for i = 1, 64 do
			local f, g
			if i <= 16 then
				f = bor(band(b, c), band(bnot(b), d))
				g = i
			elseif i <= 32 then
				f = bor(band(b, d), band(c, bnot(d)))
				g = ((5 * (i - 1) + 1) % 16) + 1
			elseif i <= 48 then
				f = bxor(b, bxor(c, d))
				g = ((3 * (i - 1) + 5) % 16) + 1
			else
				f = bxor(c, bor(b, bnot(d)))
				g = ((7 * (i - 1)) % 16) + 1
			end
			local temp = d
			d = c
			c = b
			b = band(b + lrotate(band(a + f + T[i] + M[g], 0xffffffff), SHIFTS[i]), 0xffffffff)
			a = temp
		end

		a0 = band(a0 + a, 0xffffffff)
		b0 = band(b0 + b, 0xffffffff)
		c0 = band(c0 + c, 0xffffffff)
		d0 = band(d0 + d, 0xffffffff)
	end

	return u32ToHexLE(a0) .. u32ToHexLE(b0) .. u32ToHexLE(c0) .. u32ToHexLE(d0)
end

return Md5

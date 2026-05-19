--!strict
-- Test HTTP adapter. Pass a map of { [methodName] = jsonString } to configure
-- responses; the adapter records every call for inspection.

local FakeHttp = {}

export type Call = {
	method: string?,
	url: string,
	httpMethod: string,
	body: string?,
}

export type FakeHttpClient = {
	Request: (self: any, req: any) -> any,
	Calls: { Call },
	Responses: { [string]: string },
	SetResponse: (self: any, method: string, body: string) -> (),
}

local function extractMethodFromUrl(url: string): string?
	return string.match(url, "method=([^&]+)")
end

local function extractMethodFromBody(body: string?): string?
	if not body then
		return nil
	end
	return string.match(body, "method=([^&]+)")
end

function FakeHttp.New(initialResponses: { [string]: string }?): FakeHttpClient
	local self: any = {
		Responses = initialResponses or {},
		Calls = {} :: { Call },
	}
	function self:Request(req: any): any
		local method = extractMethodFromUrl(req.url) or extractMethodFromBody(req.body)
		table.insert(self.Calls, {
			method = method,
			url = req.url,
			httpMethod = req.method,
			body = req.body,
		})
		local body = self.Responses[method or "(unknown)"]
		if not body then
			error(`FakeHttp: no response configured for method "{tostring(method)}"`, 0)
		end
		return {
			ok = true,
			status = 200,
			statusMessage = "OK",
			headers = {} :: { [string]: string },
			body = body,
		}
	end
	function self:SetResponse(method: string, body: string)
		self.Responses[method] = body
	end
	return self
end

return FakeHttp

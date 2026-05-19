--!strict
-- Rest namespace aggregator. Each per-namespace module exposes a .New(client)
-- factory; Client mounts these as fields on itself (client.Track, client.User,
-- and so on).

local Rest = {}

Rest.Request = require(script.Request)
Rest.Album = require(script.Album)
Rest.Artist = require(script.Artist)
Rest.Auth = require(script.Auth)
Rest.Chart = require(script.Chart)
Rest.Geo = require(script.Geo)
Rest.Library = require(script.Library)
Rest.Tag = require(script.Tag)
Rest.Track = require(script.Track)
Rest.User = require(script.User)

return Rest

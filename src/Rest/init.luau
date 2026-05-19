--!strict
-- Rest namespace aggregator. Each per-namespace module exposes a .New(client)
-- factory; Client mounts these as fields on itself (client.Track, client.User,
-- and so on).

local Rest = {}

Rest.Request = require("@self/Rest/Request")
Rest.Album = require("@self/Rest/Album")
Rest.Artist = require("@self/Rest/Artist")
Rest.Auth = require("@self/Rest/Auth")
Rest.Chart = require("@self/Rest/Chart")
Rest.Geo = require("@self/Rest/Geo")
Rest.Library = require("@self/Rest/Library")
Rest.Tag = require("@self/Rest/Tag")
Rest.Track = require("@self/Rest/Track")
Rest.User = require("@self/Rest/User")

return Rest

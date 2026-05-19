--!strict
-- OO wrappers around the typed records returned by Rest methods.
-- Most users will work with the plain Resources.X records directly; Classes
-- are useful when you want behavior bound to the data (Album's compilation
-- variant lookup, for example).

local Classes = {}

Classes.Artist = require("@self/Classes/Artist")
Classes.Album = require("@self/Classes/Album")
Classes.Track = require("@self/Classes/Track")
Classes.Tag = require("@self/Classes/Tag")
Classes.User = require("@self/Classes/User")

return Classes

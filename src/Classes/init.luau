--!strict
-- OO wrappers around the typed records returned by Rest methods.
-- Most users will work with the plain Resources.X records directly; Classes
-- are useful when you want behavior bound to the data (Album's compilation
-- variant lookup, for example).

local Classes = {}

Classes.Artist = require(script.Artist)
Classes.Album = require(script.Album)
Classes.Track = require(script.Track)
Classes.Tag = require(script.Tag)
Classes.User = require(script.User)

return Classes

#!/usr/bin/env python3
"""Read-only smoke test against the live Last.fm API.

Verifies that the shapes our Parse module expects still match what Last.fm
actually returns. Hit by hand when bumping the library or after a long pause
to catch any silent API drift.

Usage:
    LASTFM_API_KEY=... LASTFM_SECRET=... python scripts/smoke.py

LASTFM_SECRET is optional; without it the signed auth.getToken check is skipped.
"""

import hashlib
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://ws.audioscrobbler.com/2.0/"

API = os.environ.get("LASTFM_API_KEY")
SECRET = os.environ.get("LASTFM_SECRET")

if not API:
    print("LASTFM_API_KEY is required", file=sys.stderr)
    sys.exit(1)


def call(method, signed=False, **params):
    params["method"] = method
    params["api_key"] = API
    if signed:
        if not SECRET:
            raise RuntimeError("LASTFM_SECRET is required for signed calls")
        items = sorted((k, v) for k, v in params.items() if k not in ("format", "callback"))
        concat = "".join(k + str(v) for k, v in items) + SECRET
        params["api_sig"] = hashlib.md5(concat.encode("utf-8")).hexdigest()
    params["format"] = "json"
    url = BASE + "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"User-Agent": "lastfm-luau-smoke/0.1"})
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status, json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode("utf-8"))


def assert_field(label, value, predicate, expected_desc):
    if predicate(value):
        print(f"  OK   {label}")
    else:
        print(f"  FAIL {label}: expected {expected_desc}, got {value!r}")


def smoke_track_get_info():
    print("track.getInfo (Daft Punk - One More Time)")
    s, r = call("track.getInfo", artist="Daft Punk", track="One More Time")
    t = r.get("track", {})
    assert_field("HTTP status", s, lambda v: v == 200, "200")
    assert_field("track.name == 'One More Time'", t.get("name"), lambda v: v == "One More Time", "'One More Time'")
    artist = t.get("artist") or {}
    assert_field("artist.name == 'Daft Punk'", artist.get("name"), lambda v: v == "Daft Punk", "'Daft Punk'")
    assert_field("duration is string-encoded int", t.get("duration"), lambda v: isinstance(v, str) and v.isdigit(), "str digits")
    assert_field("playcount is string-encoded int", t.get("playcount"), lambda v: isinstance(v, str) and v.isdigit(), "str digits")


def smoke_user_get_recent_tracks():
    print("user.getRecentTracks (rj — Last.fm built-in user)")
    s, r = call("user.getRecentTracks", user="rj", limit=2)
    rt = r.get("recenttracks", {})
    attr = rt.get("@attr", {})
    assert_field("HTTP status", s, lambda v: v == 200, "200")
    assert_field("@attr.totalPages is string-encoded int", attr.get("totalPages"), lambda v: isinstance(v, str) and v.isdigit(), "str digits")
    assert_field("@attr.page is '1'", attr.get("page"), lambda v: v == "1", "'1'")
    track_list = rt.get("track", [])
    assert_field("track is a list", track_list, lambda v: isinstance(v, list), "list")


def smoke_empty_search():
    print("artist.search (no-results query — pylast #530 territory)")
    s, r = call("artist.search", artist="zzzqzzzqzzzqxyzzz123456789", limit=3)
    matches = (r.get("results") or {}).get("artistmatches")
    assert_field("HTTP status", s, lambda v: v == 200, "200")
    assert_field("artistmatches.artist == []", (matches or {}).get("artist"), lambda v: v == [], "[]")


def smoke_track_get_info_with_username():
    print("track.getInfo with username (pylast #532 territory)")
    s, r = call("track.getInfo", artist="Bon Jovi", track="Its My Life", username="rj")
    t = r.get("track", {})
    assert_field("HTTP status", s, lambda v: v == 200, "200")
    assert_field("userplaycount field is present and string", t.get("userplaycount"), lambda v: isinstance(v, str), "str")
    assert_field("userloved field is present and string", t.get("userloved"), lambda v: isinstance(v, str), "str")


def smoke_auth_get_token():
    if not SECRET:
        print("auth.getToken (SIGNED) — skipped, LASTFM_SECRET not set")
        return
    print("auth.getToken (SIGNED) — verifies signing algorithm")
    s, r = call("auth.getToken", signed=True)
    assert_field("HTTP status", s, lambda v: v == 200, "200")
    assert_field("token is 32-char hex", r.get("token"), lambda v: isinstance(v, str) and len(v) == 32, "32-char string")


for fn in (smoke_track_get_info, smoke_user_get_recent_tracks, smoke_empty_search, smoke_track_get_info_with_username, smoke_auth_get_token):
    fn()
    print()

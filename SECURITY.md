# Security policy

Hopla is a local app: it never connects to the internet, and it only writes inside
`~/Library/Application Support/Hopla` and its own preferences.

The most sensitive part is loading **avatar files shared by other people** (JSON files in the avatars folder).
They are treated as untrusted: size-limited, ids sanitized so they can never become file paths, colors
validated, and saving/deleting never leaves the avatars folder. Unit tests cover these rules
(`Tests/HoplaTests/AvatarTests.swift`), including hundreds of malformed files.

## Reporting a vulnerability

Please **don't open a public issue**. Use GitHub's private reporting instead:
[Report a vulnerability](https://github.com/JustinSimonToSpace/hopla/security/advisories/new).
You'll get an answer within a week. Thanks for helping keep Hopla safe!

# Changelog

All notable changes to this project will be documented in this file.

## [1.3.0] - 2026-09-23

### Added

- **Grand Athenaeum Overhaul**: Complete visual and interactive modernization of the LoreArchive interface.
- **Intelligent Auto-Tagging**: Automated Warcraft lore keyword analyzer scanning titles and texts across 13 major lore domains (Titans, Old Gods, Dragonflights, Scourge, Elves, Dwarves, Orcs, Tauren, Forsaken, Light, Void, Druidism).
- **Chronicler's Notes**: Dedicated personal research notebook per lore entry with real-time character/word counts, timestamp logging ([+ Timestamp]), and persistent database saving.
- **Cross-References Network**: Dynamic correlation engine discovering related library entries sharing tags, geographic zones, or lore themes with clickable jump cards.
- **Cartography & Discovery Atlas**: Zone discovery density counter, in-game map navigation (C_Map.OpenWorldMap), and TomTom waypoint integration (TomTom:AddWaypoint).
- **Voice & TTS Narration**: Integrated Blizzard Text-to-Speech (C_VoiceChat.SpeakText) with system voice selector, playback controls, and real-time status.
- **Multi-Format Export Modal**: Export single tomes or the entire library in Markdown, Plain Text, JSON, and Discord Quote formats.
- **Milestones & Achievements**: Interactive progression tracker with title-bar collection rank badges (Novice to Grand Lorekeeper).
- **Logout Safety Flush**: Registered PLAYER_LOGOUT to ensure in-progress multi-page lore text is saved before game exit.

### Changed

- Migrated main frame to Blizzard native BasicFrameTemplateWithInset to guarantee authentic borders across modern (Dragonflight/TWW) and legacy clients.
- Locked sub-panels to the main frame to prevent detached or separately movable frames.
- Replaced non-standard UTF-8 emojis with native textures and clean ASCII to prevent font rendering errors.
- Added automatic library refresh on ADDON_LOADED so recorded tomes display immediately upon login.

### Fixed

- Fixed missing background and border textures across Dragonflight and The War Within clients.
- Fixed an issue where the main window child panels could be dragged independently off the frame.

## [1.2.3] - 2026-09-23

### Changed

- Updated interface version numbers to latest.

## [1.2.2] - 2026-09-23

### Added

- Added support for WoW Forever (interface version `16001`).
- Added completion percentage display to the collection progress counter.

### Changed

- Cached readable items total count to optimize collection list rendering performance.
- Debounced search box input to reduce UI redraw overhead while typing.
- Improved multi-page lore text accumulation to prevent page duplication on non-sequential navigation.
- Updated dynamic addon version fallback in Options to `1.2.2`.

## [1.2.1] - 2026-04-30

### Changed

- Consolidated TOC files across clients.
- Improved Classic Era and Vanilla client compatibility.
- Enhanced Options UI with dynamic version retrieval.

## [1.2.0] - 2026-03-23

### Added

- Added **Completion Tracking**! The main UI now displays progress as "**X / Y collected**".
- Integrated a comprehensive lore database (`readable_items.lua`) containing **433 unique titles** from items and world objects.
- Added a new **Addon Options Menu** (Game Settings integration) with client-agnostic registration for modern, legacy, and anniversary WoW versions.
- Added a **Debug Data Inspector** window to help troubleshoot lore capture issues and view raw item data (accessible via Options).

### Changed

- Bumped addon version to **1.2.0** across all supported clients.

## [1.1.2] - 2026-03-20

### Added

- Added automation for CurseForge and GitHub releases via GitHub Actions.
- Created `.pkgmeta` to exclude development files from release packages.
- Added CurseForge Project ID to all `.toc` files for automated packaging.

### Changed

- Enhanced UI list presentation with an active state for the selected item.
- Bumped addon version to **1.1.2** across all supported clients.

## [1.1.1] - 2026-03-19

- Fixed the SearchBox placeholder to disappear when field is focused.

## [1.1.0] - 2026-03-19

### Added

- Added dedicated TOC files for **Classic**, **MoP**, **Retail**, **TBC Anniversary**, and **Wrath** clients.
- Added support for multiple interface versions in the primary `LoreArchive.toc` for broad compatibility.

### Changed

- Bumped addon version from **1.0.0** to **1.1.0** in all `.toc` files.
- Enhanced UI with tag management features (tag pills, edit mode, normalization).

## [1.0.0] - (initial release)

### Added

- Initial addon implementation with core functionality, UI, and saved-variable database.
- Provided base `.toc` files for initial supported clients.

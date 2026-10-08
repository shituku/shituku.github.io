# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Hexo 7.3.0 static blog. Theme: redefine v2 (`EvanNotFound/hexo-theme-redefine`). Deploys to GitHub Pages: `shituku/shituku.github.io` (`git@github.com:shituku/shituku.github.io.git`, branch `main`).

**This directory is not a git repo** — only Hexo's `.deploy_git/` internal directory handles git for `hexo deploy`.

## Commands

```bash
npx hexo server          # dev server http://localhost:4000
npx hexo generate        # build to public/
npx hexo clean           # wipe public/ + cache
npx hexo deploy          # push to GitHub Pages
npx hexo new post "..."  # new post
npx hexo new page "..."  # new page
```

Full publish: `npx hexo clean && npx hexo generate && npx hexo deploy`

## Key Config

- **Site URL**: `https://3322888.xyz`
- **Author**: `Rory` (site config) / `The Roryn` (theme config)
- **Language**: `zh-CN` — must match theme language filename exactly (`themes/redefine/languages/zh-CN.yml`)
- **Theme primary color**: `#A31F34`; default mode: light
- **Background image**: `居家.png` (global bg), blur=4, overlay opacity=0.55; content cards at 75% opacity
- **Home banner**: light=`wallhaven-wqery6-light.webp`, dark=`居家.png`
- **Posts per page**: 10; permalink: `/year/month/day/title/`

## Architecture

```
_config.yml                    # Hexo site config
themes/redefine/
  _config.yml                  # Theme config (colors, fonts, navbar, inject, plugins)
  AGENTS.md                    # Theme dev conventions — read before modifying theme
  layout/
    page.ejs                   # Outer shell: <main id="swup"> wraps all pages
    components/
      header/head.ejs          # <head>, inject scripts, Swup init config
      header/navbar.ejs        # Navbar (uses theme.navbar.links)
      swup.ejs                 # Swup instance creation (containers: ["#swup"])
    pages/
      post/article-content.ejs # Article page template
      gallery/gallery.ejs      # Custom gallery page (see below)
  source/css/                  # Stylus source (editable)
    common/markdown.styl       # Article body heading sizes (h1-h6)
    layout/_partials/global-bg.styl # Global background image CSS
    layout/_partials/navbar.styl # Navbar layout
  source/images/                # Theme images (favicon, banners, bg images)
  source/js/                   # Browser JS source (ES modules)
  scripts/helpers/             # Node-side Hexo helpers (CommonJS)
    page-helpers.js            # Maps page 'type' → partial template
  languages/zh-CN.yml          # i18n strings (navbar labels use `__(key)`)
source/
  _data/gallery.yml            # Gallery album data (see below)
  _posts/                      # Blog posts (.md)
  gallery/index.md             # Gallery page (type: gallery)
  uploads/gallery/             # Gallery photos
```

## Critical: Swup.js and Inline Scripts

**The theme uses Swup.js for SPA navigation.** The `<main id="swup">` container's content is replaced via `innerHTML` on every page navigation. This has a crucial consequence:

**`<script>` tags inside `#swup` do NOT execute after Swup navigation.** The browser does not execute scripts inserted via `innerHTML`. This is by design.

### How to handle interactivity

1. **`onclick` attributes DO work** — inline event handlers survive `innerHTML` replacement.
2. **`<style>` tags inside `#swup` DO work** — CSS is applied regardless of how it enters the DOM.
3. **`<script type="application/json">` tags survive** — they aren't executed but remain in the DOM and can be read by other scripts.
4. **Event delegation via `inject.head`** — scripts in `<head>` with `data-swup-reload-script` run on every navigation. Use `document.addEventListener('click', ...)` pattern. Scripts in `inject.head` with `data-swup-reload-script` are re-executed by SwupScriptsPlugin (optin mode) after each navigation.
5. **`position: fixed` breaks inside `.main-content-body`** — because `.transition-fade-up` always has `transform: translateY(0)`, which creates a new CSS containing block per spec. Place fixed elements as direct children of `<main id="swup">` (in `page.ejs`) instead.

### Adding a new page type

1. Create `source/<name>/index.md` with `type: <name>` in frontmatter
2. Add entry to `themes/redefine/scripts/helpers/page-helpers.js` mapping the type to a partial template
3. Create the partial at `themes/redefine/layout/pages/<name>/<name>.ejs`
4. Add navbar link in `themes/redefine/_config.yml` under `navbar.links`
5. Add translation in `themes/redefine/languages/zh-CN.yml`

## Gallery Page

Custom page at `/gallery`. Album cards grid with click-to-view photos.

- **Data**: `source/_data/gallery.yml` — array of albums with `name`, `desc`, `cover`, `photos[image, title, desc]`
- **Template**: `themes/redefine/layout/pages/gallery/gallery.ejs`
- **Architecture**: All album photo HTML is pre-rendered server-side in hidden `display:none` sections. Clicking an album card calls `window.showGalleryAlbum(index)` (defined in `inject.head`), which simply toggles `display` — no JSON parsing, no dynamic innerHTML at runtime. This avoids the Swup inline-script problem entirely.
- **Background**: Gallery page now uses the global background image (`居家.png`) — the dedicated gallery background was removed in favor of the unified global background.
- **Global functions** (in `inject.head`): `window.showGalleryAlbum(n)`, `window.hideGalleryAlbum()`

## Recent Theme Modifications

### Layout changes
- **`page.ejs`**: Added conditional global background div (`global-body-bg`) as direct child of `<main id="swup">`. Added conditional gallery background div when `page.type === 'gallery'`.
- **`navbar.styl`**: Removed `justify-content: center` from `.navbar-container` so the site title stays left-aligned
- **`markdown.styl`**: Reduced all heading sizes (h1: 3.2→1.9rem, h2: 2.5→1.55rem, h3: 1.8→1.3rem, h4: 1.5→1.15rem, h5: 1.28→1.05rem, h6: 1.2→1rem)
- **`article-content.ejs`**: Reduced article title (md:text-6xl→md:text-4xl without cover; md:text-5xl→md:text-4xl with cover)

### Global background image
- **Config**: `global_bg` section in theme `_config.yml` — `enable`, `image` (path), `blur` (px), `opacity` (overlay, 0–1)
- **CSS**: `themes/redefine/source/css/layout/_partials/global-bg.styl` — auto-imported via `style.styl`'s `@require 'layout/_partials/*'`
- **Template**: `page.ejs` renders `<div class="global-body-bg">` as direct child of `<main id="swup">` (same positioning pattern as gallery background — avoids CSS transform containing-block issue)
- **Architecture**: Fixed full-screen div with blurred `<img>` + semi-transparent overlay using `var(--background-color)` (auto-adapts to light/dark mode). Content cards made semi-transparent via `color-mix()` to let the background show through.
- **Stylus note**: `color-mix()` is not natively supported by Stylus — use `@css { }` block to pass raw CSS through Stylus unprocessed.

### Content card transparency
When `global_bg.enable` is true, content cards are made semi-transparent (75% opacity) via `color-mix(in srgb, var(--background-color) 75%, transparent)`. Targeted selectors: `.home-article-item`, `.article-content-container`, `.sidebar-content`, `.sidebar-links`, `.archive-container`, `.tag-container`, `.page-template-container`.

### Music player dock (APlayer)
- The theme uses APlayer fixed-mode in bottom-left corner. A JS snippet in `inject.head` (third entry, with `data-swup-reload-script`) docks the player to the left screen edge when not in use.
- **Behavior**: Player body hidden (opacity:0), miniswitcher arrow tab repositioned to `position:fixed; left:0; top:50%` as a visible pull-tab. Hovering the tab reveals the full player, leaving hides it. Player body/list/lrc get opacity:0 by default.
- **Swup compatibility**: Uses `player.dataset.dockInit` (per-element) rather than a global flag, so it re-initializes correctly after Swup page navigation (old element destroyed, new element gets fresh init).
- **Mobile skip**: `window.innerWidth <= 768` check prevents dock behavior on mobile.

### `inject.head` scripts (in theme `_config.yml`)
Contains three injected entries:
1. Custom CSS (mobile music player, code block fixes, mobile banner)
2. Gallery event handlers (`window.showGalleryAlbum`, `window.hideGalleryAlbum`)
3. Music player dock JS (APlayer edge-dock behavior)

# Halo

**A modern macOS driver for the Logitech NuLOOQ Navigator: twenty years late, and better than the original.**

<p align="center"><em>Puck. Ring. Five buttons. Back from the dead.</em></p>

<p align="center"><a href="docs/halo-intro.mp4">▶ Watch the 43-second intro</a></p>

<p align="center">
  <img src="docs/screenshots/profiles/00-general.png" alt="Halo's mapping window showing the General (macOS) profile, a live view of the NuLOOQ, and settings for the buttons, touch ring, puck twist and puck push" width="640">
</p>

---

## The story

I fell in love with the NuLOOQ Navigator back when I was working in architecture.

If you never saw one: it's a heavy little puck that sits beside your mouse. You can nudge it in any direction, twist it, and slide a finger around the touch-sensitive ring that circles it. There are five buttons around the edge. Logitech and Adobe launched it together in **February 2006** as a $149.99 bundle for Creative Suite 2, and it was **Mac-only** at launch. Panning drawings, zooming, flipping tools: it felt like the computer had grown a proper instrument panel. It made long nights of drawings feel a little less like work.

It didn't last. By **October 2006**, less than a year after launch, Logitech had discontinued the *tooldial*, the software that made the NuLOOQ special, and sold the bare navigator on its own. After that the product just faded away. No new drivers, no updates, no announcement. It was simply abandoned.

Then the Mac moved on without it. The original software was built for PowerPC and 32-bit Intel Macs. Apple dropped PowerPC support in 2011 and 32-bit apps in 2019, so for most of the past two decades the NuLOOQ has been a beautiful paperweight. Plug it into a modern Mac and macOS recognizes it, then does absolutely nothing with it.

Mine sat in a drawer for **about twenty years**.

### Bringing it back

In 2026 I plugged it into my Mac and asked Claude, whether there was anything we could do. Within one afternoon of back-and-forth we had:

1. **Read the device's own description of itself.** It turns out the NuLOOQ reports everything over standard USB HID: puck X/Y, twist, ring angle, ring touch pressure, five buttons and five LEDs. No secret handshake required.
2. **Written a small driver** in Swift that listens to those signals and turns them into real actions.
3. **Built a proper Mac app** around it, with a settings window, per-app profiles and a live view of the device.
4. **Fixed the quirks of a 20-year-old piece of hardware.** The ring's direction was backwards, and my puck's tired spring doesn't quite return to centre, so Halo now learns where "centre" is on the fly.

I didn't write this code by hand. I described what I wanted, tested it with the real device on my desk, reported what felt wrong, and iterated. It's a small, honest example of what working with an LLM can look like: you bring the hardware, the taste and the patience to try things, and it brings the know-how.

It's alive again. And it does more now than it ever did in 2006.

This was a really fun project.

---

## What Halo does

Halo lives in your menu bar (◎) and turns the NuLOOQ into a fully programmable controller.

| Control | Default (General profile) |
|---|---|
| **Push the puck** | Smooth, pressure-sensitive scrolling in any direction (or move the pointer instead) |
| **Twist the puck** | Zoom in / out (⌘= / ⌘−) |
| **Slide around the touch ring** | Volume up (clockwise) / down (counter-clockwise) |
| **Buttons 1–5** | Undo, Redo, Copy, Paste, Mission Control |
| **Button LEDs** | Off, light while pressed, or always on while the Mac is awake |

Every control can be mapped to:

- **Keyboard shortcuts:** click "Record" and press the combo
- **Media keys:** play/pause, next, previous, volume, mute, brightness
- **Mouse clicks:** left, right or middle
- **Open an app or file**
- **Run a shell command**

### Per-app profiles

Halo switches profiles automatically based on the app in front. It comes with ready-made presets for apps I actually use:

- **Safari / Chrome:** the ring flips through tabs; the buttons do back, forward, new tab, close and reload
- **Finder:** back/forward, Quick Look, enclosing folder
- **Preview:** page through documents, rotate, zoom to fit
- **Music:** play/pause and skip; twist changes tracks; the ring sets volume
- **Photoshop:** the ring resizes the brush; the buttons pick brush, eraser and move
- **Spotify / VLC:** play, skip and volume without leaving what you're doing
- **Keynote / Pages / Numbers:** the ring steps through slides, pages or cells; twist zooms
- **Xcode / VS Code / Ghostty:** run, build and stop; the ring switches tabs
- **iMovie / GarageBand:** play, split or record; the ring scrubs the playhead
- **Firefox, Illustrator, Lightroom Classic, Figma, Sketch, Final Cut Pro:** sensible starting points

You can add any other app with **+**, starting from a preset or from your General profile.

<p align="center">
  <img src="docs/screenshots/profiles/01-safari.png" alt="Safari profile: buttons mapped to back, forward, new tab, close tab and reload; the ring switches tabs" width="49%">
  <img src="docs/screenshots/profiles/07-lightroom-classic.png" alt="Lightroom Classic profile: buttons mapped to pick, reject, unflag, undo and Develop; the ring steps through photos" width="49%">
</p>

<details>
<summary><strong>See every built-in profile (21)</strong></summary>
<br>
<table>
  <tr><td align="center" width="33%"><a href="docs/screenshots/profiles/00-general.png"><img src="docs/screenshots/profiles/00-general.png" alt="Halo settings for General (macOS)"></a><br><sub>General (macOS)</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/01-safari.png"><img src="docs/screenshots/profiles/01-safari.png" alt="Halo settings for Safari"></a><br><sub>Safari</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/02-google-chrome.png"><img src="docs/screenshots/profiles/02-google-chrome.png" alt="Halo settings for Google Chrome"></a><br><sub>Google Chrome</sub></td></tr>
  <tr><td align="center" width="33%"><a href="docs/screenshots/profiles/03-finder.png"><img src="docs/screenshots/profiles/03-finder.png" alt="Halo settings for Finder"></a><br><sub>Finder</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/04-preview.png"><img src="docs/screenshots/profiles/04-preview.png" alt="Halo settings for Preview"></a><br><sub>Preview</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/05-music.png"><img src="docs/screenshots/profiles/05-music.png" alt="Halo settings for Music"></a><br><sub>Music</sub></td></tr>
  <tr><td align="center" width="33%"><a href="docs/screenshots/profiles/06-adobe-illustrator.png"><img src="docs/screenshots/profiles/06-adobe-illustrator.png" alt="Halo settings for Adobe Illustrator"></a><br><sub>Adobe Illustrator</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/07-lightroom-classic.png"><img src="docs/screenshots/profiles/07-lightroom-classic.png" alt="Halo settings for Lightroom Classic"></a><br><sub>Lightroom Classic</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/08-figma.png"><img src="docs/screenshots/profiles/08-figma.png" alt="Halo settings for Figma"></a><br><sub>Figma</sub></td></tr>
  <tr><td align="center" width="33%"><a href="docs/screenshots/profiles/09-visual-studio-code.png"><img src="docs/screenshots/profiles/09-visual-studio-code.png" alt="Halo settings for Visual Studio Code"></a><br><sub>Visual Studio Code</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/10-firefox.png"><img src="docs/screenshots/profiles/10-firefox.png" alt="Halo settings for Firefox"></a><br><sub>Firefox</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/11-spotify.png"><img src="docs/screenshots/profiles/11-spotify.png" alt="Halo settings for Spotify"></a><br><sub>Spotify</sub></td></tr>
  <tr><td align="center" width="33%"><a href="docs/screenshots/profiles/12-vlc.png"><img src="docs/screenshots/profiles/12-vlc.png" alt="Halo settings for VLC"></a><br><sub>VLC</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/13-keynote.png"><img src="docs/screenshots/profiles/13-keynote.png" alt="Halo settings for Keynote"></a><br><sub>Keynote</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/14-pages.png"><img src="docs/screenshots/profiles/14-pages.png" alt="Halo settings for Pages"></a><br><sub>Pages</sub></td></tr>
  <tr><td align="center" width="33%"><a href="docs/screenshots/profiles/15-numbers.png"><img src="docs/screenshots/profiles/15-numbers.png" alt="Halo settings for Numbers"></a><br><sub>Numbers</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/16-xcode.png"><img src="docs/screenshots/profiles/16-xcode.png" alt="Halo settings for Xcode"></a><br><sub>Xcode</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/17-sketch.png"><img src="docs/screenshots/profiles/17-sketch.png" alt="Halo settings for Sketch"></a><br><sub>Sketch</sub></td></tr>
  <tr><td align="center" width="33%"><a href="docs/screenshots/profiles/18-imovie.png"><img src="docs/screenshots/profiles/18-imovie.png" alt="Halo settings for iMovie"></a><br><sub>iMovie</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/19-garageband.png"><img src="docs/screenshots/profiles/19-garageband.png" alt="Halo settings for GarageBand"></a><br><sub>GarageBand</sub></td><td align="center" width="33%"><a href="docs/screenshots/profiles/20-ghostty.png"><img src="docs/screenshots/profiles/20-ghostty.png" alt="Halo settings for Ghostty"></a><br><sub>Ghostty</sub></td></tr>
</table>
</details>

### Features the original never had

- Works with **any** app, not just Adobe's
- Media keys, shell commands and app launching
- A **live device view** that lights up as you touch each control, so you always know which is which
- **Pause mapping** to explore the controls without triggering anything
- **Auto-recentring** for pucks with worn springs
- **Always-on button lights** that go dark when the Mac sleeps

---

## Install

Requirements: a Mac running **macOS 15 or later** (Apple Silicon) and a NuLOOQ Navigator (USB `046d:c640`).

```bash
git clone <this repo> halo
cd halo
./build.sh
```

`build.sh` compiles the app, generates its icon, signs it for local use and installs it to `/Applications/Halo.app`. Then:

1. Open **Halo**. A ◎ appears in the menu bar and the mapping window opens.
2. Grant **Accessibility** when macOS asks (System Settings → Privacy & Security → Accessibility). Halo needs this to send keystrokes and scroll events.
3. Optional: turn on **Launch at Login** from the menu bar icon.

Your mappings are saved to `~/Library/Application Support/Halo/config.json`.

> **Note:** Halo is signed ad hoc, so macOS treats every rebuild as a new app and Accessibility has to be granted again. In the Accessibility list, remove Halo with **−**, add it again with **+**, then restart Halo.

---

## Troubleshooting

**Scrolling by itself.** The puck isn't resting at centre. Halo recentres automatically after about a second of stillness. If it still drifts, raise **Dead zone** under *Puck push*.

**Nothing happens.** Check that the yellow Accessibility banner is gone, and that the toolbar toggle in the top-right is **blue** (mapping on), not grey (paused).

**A direction feels backwards.** Use **Swap directions** on the ring or twist section, or **Reverse horizontal/vertical** for the puck.

**What is the device actually sending?** The original command-line tool is still here as a diagnostic:

```bash
swiftc -O nulooqd.swift -o nulooqd
./nulooqd monitor
```

It prints live values for every axis, the ring and the buttons.

---

## How it works

The NuLOOQ is a standard USB HID device. Its report descriptor exposes:

| Report | Contents |
|---|---|
| 1 | Puck X, Y and twist (Rz): signed 16-bit, ±512, spring-loaded |
| 2 | Ring angle (0–4095, one full turn) and touch pressure (0–63) |
| 3 | Five buttons |
| 4 (output) | Five LEDs, one bit each |

Halo reads these through `IOHIDManager`. No kernel extension is needed, and macOS already exposes the device to user-space apps. It turns them into actions with `CGEvent`. The puck and twist are spring-loaded, so Halo acts on *held deflection* about 60 times a second, with a quadratic curve for fine control. The ring is relative, so Halo tracks movement while your finger is down and handles wrap-around at 0/4095.

```
App/
  HaloApp.swift     app entry, menu bar, login item
  Driver.swift      HID input, profile switching, puck/ring/twist logic, LEDs
  Actions.swift     keyboard, media, mouse, open and shell actions
  Model.swift       settings and persistence
  Presets.swift     built-in app profiles
  MapperView.swift  the mapping window
tools/makeicon.swift  draws the app icon
build.sh              build, sign and install
nulooqd.swift         original command-line driver (now a diagnostic tool)
```

---

## A note on the name

**NuLOOQ** is a trademark of Logitech. Halo is an independent, personal project and is not affiliated with, endorsed by or supported by Logitech or 3Dconnexion. The name refers to the device only to describe the hardware Halo works with.

---

*Built with love for an old friend.*

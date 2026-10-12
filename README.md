# C3 Bilbao

Live departures and arrivals for the C3 commuter line (Orduña ↔ Abando) and the Bilbao tram.
The web app lives in `www/`. The Android app (Capacitor) loads it from GitHub Pages, so a push to
`main` updates the installed app without rebuilding the APK.

## One-time setup
1. GitHub repo → Settings → Pages → Source: **GitHub Actions**.
2. Push to `main`. The workflow in `.github/workflows/pages.yml` publishes `www/` to
   https://johnnydeey.github.io/c3-bilbao/ (the footer shows the build id).
3. Build the APK once: `npm install`, `npx cap sync android`, `npx cap open android`, then Build in Android Studio.

## Everyday use
Edit files in `www/`, push to `main`, wait about a minute, open the app. Rebuild the APK only when
`capacitor.config.json`, the Capacitor plugins or the icons change.

## Notes
- First launch needs internet. After that the service worker (`www/sw.js`) serves the cached app offline.
- If the app can't reach the site and has no cache, it shows `www/offline.html`.

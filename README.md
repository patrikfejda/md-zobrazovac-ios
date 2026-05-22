# Markdown zobrazovač

Offline-friendly iOS/macOS aplikácia, ktorá si stiahne markdown obsah z GitHub repa a potom ho zobrazuje aj bez internetu.

Žiadny backend — všetko sa serveruje cez GitHub raw URL (alebo GitHub Pages) ako statický obsah.

## Štruktúra

```
.
├── ios/             # Swift/SwiftUI aplikácia
├── content/         # Zdrojový obsah (toto sa servuje cez GitHub)
│   ├── manifest.json
│   ├── *.md         # markdown stránky (v koreni alebo v podpriečinkoch)
│   └── assets/      # obrázky a ďalšie binárky
├── scripts/
│   └── generate-manifest.py
└── README.md
```

## Ako to funguje

1. **Zdroj dát.** Obsah žije v priečinku `content/` v tomto repe. Každý `.md` súbor pod `content/` je samostatná stránka. Podpriečinky vytvárajú hierarchiu, ktorá sa v appke zobrazí ako drill-down knižnica. Obrázky/binárky idú do `content/assets/`.
2. **Manifest.** Skript `scripts/generate-manifest.py` prejde `content/` a vyrobí `content/manifest.json` — zoznam všetkých súborov so SHA-256 hashom a veľkosťou. Tento súbor je single source of truth pre app.
3. **App.** Pri spustení (alebo po stlačení „Synchronizovať") stiahne `manifest.json`, porovná hashe s lokálnou kópiou a stiahne len zmenené súbory. Všetko uloží do `Application Support/content/` na zariadení → ďalej funguje offline.

## Setup obsahu

```bash
# 1. Pridáš/upravíš markdown v content/
$ vim content/moja-stranka.md

# 2. Pregeneruješ manifest
$ python3 scripts/generate-manifest.py

# 3. Commit + push — app to nájde pri ďalšej synchronizácii
$ git add content/
$ git commit -m "Add my page"
$ git push
```

Manifest sa **nesmie** editovať ručne — vždy je generovaný.

## Setup iOS app

1. Otvor `ios/MdViewer.xcodeproj` v Xcode (potrebuješ 16+).
2. V `Signing & Capabilities` priraď svoj Team a `Bundle Identifier`.
3. Pri prvom spustení app otvor Nastavenia → vlož **Content URL** — URL kde sa nachádza `manifest.json`. Pre tento repo bude typicky:
   ```
   https://raw.githubusercontent.com/<USER>/md-zobrazovac-ios/main/content/manifest.json
   ```
4. Stlač „Synchronizovať" — stiahne obsah a od tohto momentu funguje offline.

## Prečo nie GitHub Pages priamo v prehliadači

Statickú stránku s markdownom by si vyrobil cez Pages za 5 minút. Ale Pages potrebuje internet *zakaždým*. Táto appka rieši ten use case, kedy chceš čítať aj v lietadle / metre / na chate bez signálu — stiahneš si raz, potom sa pozeráš zo zariadenia.

## Limity, o ktorých treba vedieť

- **GitHub raw rate limit:** 60 nezauthovaných requestov/hodinu z IP. Pri normálnom použití (sync ráz za deň) je to ďaleko od limitu, ale pri masívnom obsahu (stovky súborov) treba zvážiť CDN alebo GitHub Pages namiesto raw.
- **Privátny repo:** raw URL vyžaduje OAuth token — komplikuje to. Default je verejný repo. Ak naozaj potrebuješ privátnosť, použij GH Pages na privátnom repe (platený plán) alebo iný hosting.
- **Manifest schemaVersion = 1** — keď meníš formát manifestu, bumpni číslo a aktualizuj parser.

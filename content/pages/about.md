# O aplikácii

Markdown zobrazovač je jednoduchá iOS/macOS aplikácia, ktorá si stiahne sadu markdown súborov z GitHub repozitára a potom ich zobrazuje offline.

## Filozofia

- **Žiadny backend.** Obsah je iba sada súborov v Git-e. Zmeny sú commity.
- **Offline-first.** Po prvom stiahnutí už internet nepotrebuješ.
- **Verzionovaný obsah.** Git ti dáva históriu zadarmo.

## Technologický stack

- SwiftUI (iOS 17+, macOS 14+)
- Žiadne externé Swift dependencies
- Python script na generovanie manifestu

## Limity

Manifest má teraz `schemaVersion = 1`. Ak zmeníš jeho štruktúru, treba bumpnúť verziu a aktualizovať parser v `ContentManifest.swift`.

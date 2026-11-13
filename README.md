# Kommunikationskit Grundlagenberichte

Passwortgeschützte Webversion des Kommunikationskits zu den Grundlagenberichten 2022.

- `index.html` – die veröffentlichte Seite (verschlüsselt, öffnet sich erst mit Passwort)
- `dateien/` – Berichte, Bilder, Grafiken, Präsentationen und Videos
- `passwortschutz/` – Vorlage der Passwortseite und Skript zum Verschlüsseln

## Kit ändern

Die unverschlüsselte Originalseite `Kommunikationskit.html` liegt nur lokal und ist absichtlich nicht im Repository.
Nach einer Änderung neu verschlüsseln und hochladen:

```
powershell -ExecutionPolicy Bypass -File passwortschutz\verschluesseln.ps1
git add index.html
git commit -m "Kit aktualisiert"
git push
```

Das Skript fragt nach dem Passwort. Mit einem neuen Passwort verfallen gespeicherte Anmeldungen.

# Einrichtung

## 1. Bauen und installieren

Es gibt keine fertige, signierte App zum Herunterladen. Du baust sie selbst.

Voraussetzungen: ein Mac mit **Intel-Prozessor**, macOS 14 oder neuer, Xcode 16.2 oder neuer (getestet mit Xcode 16.2 unter macOS 14.6.1), Git und [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
git clone https://github.com/DocViper/sprachzutext-intel.git
cd sprachzutext-intel
./build.sh --install --run
```

Das Skript lädt die Swift-Pakete, wendet den Intel-Patch für WhisperKit an (`patches/whisperkit-intel.patch`), baut die App nur für Intel und legt sie als `/Applications/SprachZuText.app` ab. Sie erscheint in der Menüleiste. Der erste Bau dauert auf älteren Macs einige Minuten.

Die App ist nur "ad hoc" signiert. Das genügt für den eigenen Mac.

## 2. Berechtigungen

- **Mikrofon:** zum Aufnehmen.
- **Bedienungshilfen:** zum Einfügen in die App, in der du gerade schreibst. Ohne sie bleibt das Ergebnis in der Zwischenablage.

Nach jedem Neubau ändert sich die Signatur. Dann öffnest du **Systemeinstellungen > Datenschutz & Sicherheit > Bedienungshilfen**, entfernst den alten Eintrag von SprachZuText, fügst die aktuelle App hinzu und startest sie neu. Hilft das nicht, setzt du die Freigabe im Terminal zurück: `tccutil reset Accessibility io.github.docviper.sprachzutext`.

## 3. Lokales Sprachmodell

Öffne **Einstellungen > Modelle > Spracherkennung**, wähle ein Whisper-Modell und lade es einmal:

- **Whisper Small:** schneller, für kurze Diktate meist ausreichend.
- **Whisper Large v3 Turbo:** genauer, aber langsamer.

Die Spracherkennung rechnet auf Intel-Macs nur mit dem Prozessor. Zum Vergleich, gemessen auf einem iMac von 2015: Ein kurzer Satz dauert mit Small etwa 45 Sekunden und mit Large v3 Turbo etwa 70 Sekunden. Auf neueren Intel-Macs geht es schneller.

Parakeet Ultra braucht Apple Silicon und steht auf Intel-Macs nicht zur Verfügung.

## 4. Schreibmodi

Die Modi mit KI (SprachZuText+, $%&!, :)) brauchen ein Sprachmodell. Apple Intelligence setzt Apple Silicon voraus und fehlt deshalb auf Intel-Macs. Du brauchst einen eigenen Modell-Anbieter:

**Einstellungen > Modelle > Modell-Anbieter**, Anbieter wählen, API-Schlüssel eintragen, Verbindung testen. Lokale Server wie Ollama oder LM Studio funktionieren über "Eigene Adresse".

Das wortgenaue Diktieren funktioniert auch ohne Anbieter.

## 5. Tastenkürzel

Die `fn`-Kürzel funktionieren nur auf Apple-Tastaturen. Auf anderen Tastaturen legst du unter **Einstellungen > Allgemein > Tastenkürzel** ein eigenes Kürzel pro Modus fest, zum Beispiel `⌃⌥D` oder `F13`. Ein eigenes Kürzel ersetzt das `fn`-Kürzel dieses Modus. `fn` selbst kann nicht Teil eines eigenen Kürzels sein.

**Halten:** gedrückt halten zum Aufnehmen, loslassen zum Verarbeiten. **Drücken:** drücken zum Starten, nochmal drücken oder `Esc` zum Beenden.

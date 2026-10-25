# Datenschutz

SprachZuText hat kein Backend. Die App sammelt, sendet und speichert keine Daten auf Servern des Fork-Autors. Der Fork stammt nicht von Blackboat und wird auch nicht von Blackboat betrieben.

## Was auf deinem Mac bleibt

- **Audio:** wird auf deinem Mac mit einem lokalen Whisper-Modell aufgenommen und transkribiert. Temporäre Aufnahmen werden nach jedem Vorgang gelöscht.
- **Einstellungen, Wörterbuch, Prompts:** lokaler App-Speicher.
- **Verlauf (optional):** verschlüsselt auf deinem Mac, so lange wie du es einstellst (aus, 24 Stunden, 7 Tage).
- **API-Schlüssel** für einen optionalen Modell-Anbieter: im macOS-Schlüsselbund.
- **Text um den Cursor:** Wenn ein Diktat startet, liest die App das aktive Textfeld über die Bedienungshilfen, um Leerzeichen und Großschreibung anzupassen. Passwortfelder werden nie gelesen. Der Text bleibt auf deinem Mac, es sei denn, du schaltest "KI-Modi sehen den Text am Cursor" ein (siehe unten).
- **Browser-Adresse:** Nur wenn du eine Website unter "Modus je App" eingetragen hast, liest die App beim Drücken des Kürzels die Adresse des vordersten Browser-Tabs, um den Modus zu wählen. Sie bleibt auf deinem Mac.

## Wann Daten deinen Mac verlassen

- **Modell-Download:** Beim Laden eines Sprachmodells wird es von Hugging Face (huggingface.co) heruntergeladen. Hugging Face sieht die Anfrage wie bei jedem Download.
- **Optionaler Modell-Anbieter:** Wenn du einen eigenen Anbieter mit API-Schlüssel einträgst, geht der *erkannte Text* der KI-Modi direkt von deinem Mac an diesen Anbieter. Audio nie. Es gelten dein Vertrag und die Datenschutzbestimmungen des Anbieters.
- **Text um den Cursor für die KI-Modi (standardmäßig aus):** Mit "KI-Modi sehen den Text am Cursor" geht der Text um deinen Cursor an den Modell-Anbieter.
- **Updates:** Dieser Fork prüft nicht selbst auf Updates. Neue Versionen gibt es nur im GitHub-Repository.

## Zwischenablage

Zum Einfügen legt die App den Text in die Zwischenablage und stellt danach deine vorherige Zwischenablage wieder her. Zwischenablage-Manager sehen den Text eventuell, solange er dort liegt.

## Sensible Inhalte

Die Spracherkennung ist lokal. Wenn du einen externen Modell-Anbieter einrichtest, prüfe, ob deine Inhalte dorthin gesendet werden dürfen.

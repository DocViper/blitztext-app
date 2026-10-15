import SwiftUI

/// What changed in this release. Shown once per `version`: on the next popover opening,
/// or right after the first dictation for people who only use the shortcuts.
enum WhatsNew {
    /// Bump together with the items when a release deserves a note.
    static let version = "1.13"

    struct Item: Identifiable {
        let icon: String
        let title: String
        let detail: String
        var id: String { title }
    }

    static let items: [Item] = [
        Item(
            icon: "bubble.left.fill",
            title: "Neues Aussehen",
            detail: "Blitztext sieht jetzt aus wie auf dem iPhone: klare Karten, Blackboat-Farben und die Sprechblase. Die Modi zeigen ihre Farbe, dein letzter Text steht als Nachricht bereit und ist mit einem Klick kopiert."
        ),
        Item(
            icon: "waveform",
            title: "Aufnahme sichtbar",
            detail: "Unten am Bildschirm zeigt eine kleine lila Anzeige, dass Blitztext zuh\u{00F6}rt. Sie bewegt sich mit deiner Stimme, ein Klick stoppt die Aufnahme. Abschalten kannst du sie unter Einstellungen, Allgemein."
        ),
    ]
}

struct WhatsNewView: View {
    @Bindable var appState: AppState

    private var needsSetup: Bool {
        !appState.isConfigured || !appState.canRewrite
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Neu in Blitztext \(WhatsNew.version)")
                    .font(BlackboatType.publicSans(20, .bold, relativeTo: .title3))
                Text("Einmal kurz, dann geht es weiter wie gewohnt.")
                    .font(.ui(12))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().opacity(0.16)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(WhatsNew.items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: item.icon)
                            .font(.ui(14, .semibold))
                            .foregroundStyle(BlitztextTheme.accent)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.ui(13, .semibold))
                            Text(item.detail)
                                .font(.ui(11.5))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !appState.isConfigured {
                    NoticeRow(
                        icon: "arrow.down.circle",
                        title: "Noch ein Schritt",
                        detail: "Lade einmal ein lokales Sprachmodell, sonst kann Blitztext nicht transkribieren."
                    )
                } else if !appState.canRewrite {
                    NoticeRow(
                        icon: "key",
                        title: "KI-Modi einrichten",
                        detail: "Ohne Apple Intelligence brauchen Blitztext+, $%&! und :) einen eigenen API-Key."
                    )
                }
            }
            .padding(16)

            Divider().opacity(0.16)

            HStack(spacing: 8) {
                Spacer()
                if needsSetup {
                    Button {
                        appState.markWhatsNewSeen()
                        appState.page = .settings
                    } label: {
                        Text("Einrichten")
                            .font(.ui(12, .medium))
                    }
                    .buttonStyle(.glassAction)
                }
                Button {
                    appState.markWhatsNewSeen()
                    appState.page = .main
                } label: {
                    Text("Verstanden")
                        .font(.ui(12, .semibold))
                }
                .buttonStyle(.glassAction)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

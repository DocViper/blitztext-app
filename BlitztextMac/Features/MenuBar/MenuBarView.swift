import SwiftUI

struct MenuBarView: View {
    @Bindable var appState: AppState

    static let width: CGFloat = 420

    var body: some View {
        VStack(spacing: 0) {
            switch appState.page {
            case .main:
                mainPage
            case .onboarding:
                onboardingPage
            case .settings:
                settingsPage
            case .workflow:
                workflowPage
            case .history:
                historyPage
            case .audioFile:
                AudioFileView(appState: appState)
            case .whatsNew:
                WhatsNewView(appState: appState)
            }
        }
        .frame(width: Self.width)
        .background {
            BlitztextSurface.windowBackground
        }
        .tint(BlitztextTheme.accent)
        .animation(.easeInOut(duration: 0.2), value: appState.page)
    }

    // MARK: - Main Page

    @State private var copiedLast = false

    private var mainPage: some View {
        VStack(spacing: 0) {
            miniHeader
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 16) {
                if !appState.isConfigured {
                    setupHero
                }

                if BlitztextInstallLocationService.shouldOfferMoveToApplications {
                    NoticeRow(
                        icon: "externaldrive.badge.plus",
                        title: "Nach /Applications verschieben",
                        detail: "So startet Blitztext zuverl\u{00E4}ssig mit dem Mac und bekommt Updates.",
                        actionTitle: "Pr\u{00FC}fen",
                        action: { appState.page = .settings }
                    )
                }

                if !appState.accessibilityPermissionGranted {
                    NoticeRow(
                        icon: "hand.raised.fill",
                        title: "Einf\u{00FC}gen braucht Bedienungshilfen",
                        detail: "Nach Updates kann macOS die Freigabe neu verlangen.",
                        actionTitle: "\u{00D6}ffnen",
                        action: { appState.requestAccessibilityPermission() }
                    )
                }

                dictationCard

                VStack(alignment: .leading, spacing: 8) {
                    SectionHeader(title: "Modi")

                    VStack(spacing: 0) {
                        ForEach(Array(WorkflowType.mainMenuCases.enumerated()), id: \.element) { index, type in
                            if index > 0 {
                                Divider().opacity(0.5).padding(.leading, 62).padding(.trailing, 12)
                            }
                            WorkflowRowView(
                                type: type,
                                enabled: appState.isWorkflowAvailable(type),
                                customName: appState.displayName(for: type),
                                subtitle: appState.workflowSubtitle(for: type),
                                hotkeyLabel: appState.hotkeyLabel(for: type)
                            ) {
                                appState.startWorkflow(type)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .glassPanel()
                }

                if let entry = appState.history.entries.first {
                    lastMessage(entry)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            footerBar
        }
    }

    private var miniHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            BrandRow()

            Spacer(minLength: 0)

            Button {
                appState.page = .settings
            } label: {
                Image(systemName: "gearshape")
                    .font(.ui(13))
                    .foregroundStyle(.primary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(BlitztextTheme.card))
                    .shadow(color: BlitztextTheme.cardShadow, radius: 2, y: 1)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)
            .help("Einstellungen")
            .accessibilityLabel("Einstellungen")
        }
    }

    private var setupHero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Einrichtung n\u{00F6}tig")
                .font(.ui(17, .bold))
            Text("Installiere in den Einstellungen ein lokales Sprachmodell. Blitztext transkribiert direkt auf diesem Mac.")
                .font(.ui(12.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                appState.page = .settings
            } label: {
                Label("Einstellungen \u{00F6}ffnen", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.filledAction)
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel()
    }

    /// The speech bubble of the iOS app, the shortcut to use, the model and where the
    /// text is processed.
    private var dictationCard: some View {
        let modelOptions = LocalTranscriptionService.modelOptions(selected: appState.selectedLocalModelName)
        let selectedModelInstalled = appState.selectedLocalModelIsInstalled

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Button {
                    appState.startWorkflow(.tapTalk)
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.ui(20, .semibold))
                        .foregroundStyle(BlitztextTheme.onAccent)
                        .frame(width: 52, height: 52)
                        .background(SpeechBubbleShape().fill(WorkflowType.tapTalk.tint))
                        .padding(.bottom, 6)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(!appState.isWorkflowAvailable(.tapTalk))
                .help("Blitztext jetzt starten")
                .accessibilityLabel("Aufnahme starten")

                VStack(alignment: .leading, spacing: 3) {
                    Text(dictationTitle)
                        .font(.ui(14, .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(modePanelSubtitle(selectedModelInstalled: selectedModelInstalled))
                        .font(.ui(11.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Text("Modell")
                    .font(.ui(12))
                    .foregroundStyle(.secondary)

                Picker("", selection: Binding(
                    get: { appState.selectedLocalModelName },
                    set: { appState.appSettings.selectedLocalTranscriptionModelName = $0 }
                )) {
                    ForEach(modelOptions) { model in
                        Text(model.pickerLabel)
                            .tag(model.id)
                    }
                }
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .controlSize(.small)
                .disabled(appState.isDownloadingLocalModel)
            }

            if let progress = appState.localModelDownloadProgress {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progress)
                        .tint(BlitztextTheme.accent)
                    Text(appState.localModelDownloadStatusText ?? "Modell wird geladen ...")
                        .font(.ui(11))
                        .foregroundStyle(.secondary)
                }
            } else if !selectedModelInstalled {
                Button {
                    appState.installSelectedLocalModel()
                } label: {
                    Label(appState.localModelDownloadButtonTitle, systemImage: "arrow.down")
                }
                .buttonStyle(.filledAction)
            }

            if let errorText = appState.localModelDownloadErrorText {
                NoticeRow(icon: "xmark.circle.fill", title: errorText, tint: BlitztextTheme.danger)
            }

            HStack(spacing: 6) {
                Image(systemName: statusIsLocal ? "lock.fill" : "arrow.up.forward.circle.fill")
                    .font(.ui(10.5, .semibold))
                    .foregroundStyle(statusIsLocal ? BlitztextTheme.ready : BlitztextTheme.accent)
                Text(aiStatusText)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.ui(11.5))
        }
        .padding(16)
        .glassPanel()
    }

    private var dictationTitle: String {
        let hotkey = appState.hotkeyLabel(for: .tapTalk)
        switch appState.appSettings.hotkeyMode {
        case .hold: return "\(hotkey) halten und sprechen"
        default: return "\(hotkey) dr\u{00FC}cken und sprechen"
        }
    }

    private var statusIsLocal: Bool {
        TextRewriter.runsLocally(engine: appState.appSettings.rewriteEngine) || !appState.isAIProviderReady
    }

    /// Where the speech and the AI modes run right now.
    private var aiStatusText: String {
        let engine = appState.appSettings.rewriteEngine
        if TextRewriter.runsLocally(engine: engine) {
            return "Sprache und KI-Modi bleiben auf diesem Mac."
        }
        if appState.isAIProviderReady, let provider = appState.aiProvider?.provider {
            return "Sprache bleibt auf diesem Mac, KI-Modi \u{00FC}ber \(provider.displayName)."
        }
        return "Sprache bleibt auf diesem Mac. KI-Modi brauchen Apple Intelligence oder einen API-Key."
    }

    private func modePanelSubtitle(selectedModelInstalled: Bool) -> String {
        if appState.isDownloadingLocalModel {
            return appState.localModelDownloadStatusText ?? "Lokales Modell wird geladen."
        }
        if selectedModelInstalled {
            return "Der Text landet direkt am Cursor."
        }
        return "\(appState.selectedLocalModelDisplayName) ist noch nicht installiert."
    }

    /// The last result as a sent message, like on iOS. A click copies it.
    private func lastMessage(_ entry: TranscriptHistoryEntry) -> some View {
        VStack(alignment: .trailing, spacing: 5) {
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(entry.text, forType: .string)
                withAnimation(.easeOut(duration: 0.15)) { copiedLast = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.6))
                    withAnimation(.easeOut(duration: 0.15)) { copiedLast = false }
                }
            } label: {
                Text(entry.text)
                    .font(.ui(12.5))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(MessageBubbleShape(radius: 16).fill(entry.workflow.tint.opacity(0.14)))
            }
            .buttonStyle(.plain)
            .help("Kopieren")
            .accessibilityLabel("Letzter Text: \(entry.text)")

            Group {
                if copiedLast {
                    Label("Kopiert", systemImage: "checkmark")
                        .foregroundStyle(BlitztextTheme.ready)
                } else {
                    Label("\(appState.displayName(for: entry.workflow)), \(Self.relativeTime(entry.createdAt))", systemImage: "doc.on.doc")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.ui(11))
            .padding(.trailing, 6)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.leading, 40)
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.unitsStyle = .full
        return formatter
    }()

    private static func relativeTime(_ date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    private var footerBar: some View {
        HStack(spacing: 8) {
            Text(versionText)
                .font(.ui(11))
                .foregroundStyle(.tertiary)
                .lineLimit(1)

            Spacer()

            Button {
                NotificationCenter.default.post(name: .chooseAudioFile, object: nil)
            } label: {
                Label("Audiodatei", systemImage: "waveform.badge.plus")
                    .lineLimit(1)
                    .fixedSize()
            }
            .buttonStyle(.glassAction)
            .help("Sprachmemo oder WhatsApp-Sprachnachricht transkribieren. Du kannst Dateien auch auf das Blitztext-Symbol im Finder ziehen.")

            Button {
                appState.page = .history
            } label: {
                Label("Verlauf", systemImage: "clock")
                    .lineLimit(1)
                    .fixedSize()
            }
            .buttonStyle(.glassAction)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Beenden")
                    .font(.ui(12))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            }
            .buttonStyle(.subtle)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Divider().opacity(0.6)
        }
    }

    private var versionText: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = (info["CFBundleShortVersionString"] as? String) ?? "?"
        let build = (info["CFBundleVersion"] as? String) ?? "?"
        var suffix = Bundle.main.bundleURL.path.hasPrefix("/Applications/") ? "" : ", Dev"
        #if DEBUG
        if MacSnapshots.folder != nil { suffix = "" }
        #endif
        return "v\(version) (\(build))\(suffix)"
    }

    // MARK: - Onboarding

    private var onboardingPage: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Willkommen")
                        .font(BlackboatType.publicSans(20, .bold, relativeTo: .title3))
                    Text("bei Blitztext")
                        .font(.ui(12, .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Sp\u{00E4}ter") {
                    appState.page = .main
                }
                .font(.ui(12))
                .foregroundStyle(.secondary)
                .buttonStyle(.subtle)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            Divider().opacity(0.16)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Einmal einrichten, dann direkt loslegen.")
                        .font(BlackboatType.publicSans(18, .semibold, relativeTo: .headline))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Ein lokales Sprachmodell reicht. Danach sprechen und einf\u{00FC}gen, alles auf diesem Mac.")
                        .font(.ui(12.5))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if BlitztextInstallLocationService.shouldOfferMoveToApplications {
                    NoticeRow(
                        icon: "arrow.down.app",
                        title: "Lege Blitztext zuerst nach /Applications",
                        detail: "So startet Blitztext zuverl\u{00E4}ssig mit dem Mac und bekommt Updates."
                    )
                }

                VStack(alignment: .leading, spacing: 0) {
                    onboardingStep(number: "1", title: "Sprachmodell laden", detail: "In den Einstellungen ein lokales Modell installieren, zum Beispiel Parakeet Ultra.")
                    Divider().opacity(0.18)
                    onboardingStep(number: "2", title: "Berechtigungen erlauben", detail: "Mikrofon und Bedienungshilfen f\u{00FC}r das Einf\u{00FC}gen freigeben.")
                    Divider().opacity(0.18)
                    onboardingStep(number: "3", title: "Modus w\u{00E4}hlen", detail: "Per Tastenk\u{00FC}rzel oder direkt aus der Men\u{00FC}leiste starten.")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)
                .glassPanel()

                Button {
                    appState.page = .settings
                } label: {
                    Label("Jetzt einrichten", systemImage: "slider.horizontal.3")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.filledAction)
            }
            .padding(16)
        }
    }

    private func onboardingStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(number)
                .font(.ui(12, .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(Circle().fill(BlitztextTheme.tonal))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ui(13, .semibold))
                Text(detail)
                    .font(.ui(11.5))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Settings Page

    private var settingsPage: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Einstellungen", onBack: { appState.page = .main }) {
                settingsQuickAction
            }

            SettingsContentView(appState: appState)
        }
        .frame(height: 640)
    }

    @ViewBuilder
    private var settingsQuickAction: some View {
        if !appState.accessibilityPermissionGranted {
            Button {
                appState.requestAccessibilityPermission()
            } label: {
                Label("Rechte", systemImage: "hand.raised")
                    .font(.ui(12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.subtle)
        } else if BlitztextInstallLocationService.currentInstallLocation.isCanonicalInstall &&
            appState.appUpdateService.updatesInApp {
            Button {
                appState.appUpdateService.checkForUpdates()
            } label: {
                Label("Updates", systemImage: "arrow.trianglehead.clockwise")
                    .font(.ui(12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.subtle)
            .disabled(!appState.appUpdateService.canCheckForUpdates)
        }
    }

    // MARK: - History Page

    private var historyPage: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Verlauf", onBack: { appState.page = .main })

            Divider().opacity(0.16)

            HistoryListView(appState: appState)
        }
        .frame(height: 520)
    }

    // MARK: - Workflow Page

    private var workflowPage: some View {
        VStack(spacing: 0) {
            if let workflow = appState.activeWorkflow {
                PageHeader(title: appState.displayName(for: workflow.type), onBack: { appState.resetCurrentWorkflow() }) {
                    Image(systemName: workflow.type.icon)
                        .font(.ui(12))
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 4)
                }

                Divider().opacity(0.16)

                WorkflowActiveView(workflow: workflow)
            }
        }
    }
}

// MARK: - Active Workflow

/// Recording, processing, result and error of the running mode; the same for all modes.
struct WorkflowActiveView: View {
    let workflow: any Workflow

    var body: some View {
        VStack(spacing: 0) {
            switch workflow.phase {
            case .idle, .running:
                if workflow.isRecording {
                    recordingView
                } else {
                    processingView(message: runningMessage, tint: workflow.type.tint)
                }

            case .done(let text):
                autoPasteView(text: text, tint: workflow.type.tint)

            case .error(let message):
                errorView(message: message) {
                    workflow.reset()
                    workflow.start()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    /// Plain dictation only shows its message when the model prepares slowly; the AI
    /// modes say which step runs.
    private var runningMessage: String {
        guard case .running(let message) = workflow.phase, !message.isEmpty else {
            return "Wird transkribiert \u{2026}"
        }
        switch workflow.type {
        case .tapTalk, .localTapTalk:
            return message == LocalTranscriptionService.slowPreparationMessage ? message : "Wird transkribiert \u{2026}"
        default:
            return message
        }
    }

    private var recordingView: some View {
        VStack(spacing: 18) {
            WaveformView(audioLevel: workflow.audioLevel, isRecording: true, accentColor: workflow.type.tint)
                .frame(height: 44)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            Button {
                workflow.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.ui(17, .semibold))
                    .foregroundStyle(BlitztextTheme.onAccent)
                    .frame(width: 52, height: 52)
                    .background(SpeechBubbleShape().fill(workflow.type.tint))
                    .padding(.bottom, 6)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Aufnahme stoppen")

            Text("Aufnahme l\u{00E4}uft. Zum Stoppen klicken.")
                .font(.ui(11.5))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
        }
    }
}

// MARK: - Shared Result / Error Views

private func processingView(message: String, tint: Color) -> some View {
    VStack(spacing: 14) {
        TypingIndicator(color: tint, dotColor: BlitztextTheme.onAccent, size: 44)
            .padding(.top, 24)
            .padding(.bottom, 6)
        Text(message)
            .font(.ui(12))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
    }
}

private func autoPasteView(text: String, tint: Color) -> some View {
    VStack(spacing: 12) {
        Image(systemName: "checkmark")
            .font(.ui(17, .bold))
            .foregroundStyle(BlitztextTheme.onAccent)
            .frame(width: 44, height: 44)
            .background(SpeechBubbleShape().fill(tint))
            .padding(.top, 20)
            .padding(.bottom, 6)

        Text("Eingef\u{00FC}gt")
            .font(.ui(14, .semibold))
            .foregroundStyle(.primary)

        Text(text)
            .font(.ui(12))
            .foregroundStyle(.primary)
            .lineLimit(4)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(MessageBubbleShape(radius: 16).fill(tint.opacity(0.14)))
            .padding(.leading, 32)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.bottom, 8)
    }
}

private func errorView(message: String, onRetry: @escaping () -> Void) -> some View {
    VStack(spacing: 12) {
        Image(systemName: "exclamationmark")
            .font(.ui(17, .bold))
            .foregroundStyle(BlitztextTheme.danger)
            .frame(width: 44, height: 44)
            .background(SpeechBubbleShape().fill(BlitztextTheme.danger.opacity(0.14)))
            .padding(.top, 16)
            .padding(.bottom, 6)

        Text(message)
            .font(.ui(12))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)

        Button(action: onRetry) {
            Text("Nochmal versuchen")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.filledAction)
        .padding(.top, 4)
    }
}

import Foundation

enum AppTab: Hashable {
    case bot
    case status
    case settings
}

enum ConnectionType: String, CaseIterable, Codable, Identifiable {import SwiftUI

struct TutorialView: View {
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MineBot")
                            .font(.system(size: 34, weight: .bold))
                        Text("Welcome.")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    CardView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("This app lets you run a Minecraft AFK bot remotely from your phone.")
                                .font(.body)

                            VStack(alignment: .leading, spacing: 12) {
                                TutorialRow(number: "1", text: "Enter your access code")
                                TutorialRow(number: "2", text: "Link your Microsoft account")
                                TutorialRow(number: "3", text: "Start your bot")
                            }

                            Text("Your bot will stay online even when the app is closed.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        Haptics.light()
                        onContinue()
                    } label: {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .blue))
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct TutorialRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .frame(width: 24, height: 24)
                .background(Color.blue.opacity(0.12))
                .clipShape(Circle())
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
import SwiftUI

struct StatusView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                CardView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Bot Status")
                            .font(.headline)

                        StatusBadge(status: appModel.botStatus?.status ?? "offline")

                        MetricRow(title: "Server", value: appModel.botStatus?.server ?? "-")
                        MetricRow(title: "Uptime", value: formattedUptime(appModel.botStatus?.uptimeMs))
                    }
                }

                CardView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Server Metrics")
                            .font(.headline)

                        MetricRow(title: "Server Latency", value: appModel.serverLatencyMs.map { "\($0) ms" } ?? "-")
                        MetricRow(title: "Memory Usage", value: appModel.health.map { "\($0.memoryMb) MB" } ?? "-")
                        MetricRow(title: "Global Memory Usage", value: appModel.health.map { "\($0.memoryMb) MB / \(appModel.maxGlobalMemoryMb) MB" } ?? "-")
                        MetricRow(title: "Active Bots", value: appModel.health.map { "\($0.bots) / \($0.maxBots)" } ?? "-")
                    }
                }
            }
            .frame(maxWidth: 500)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .navigationTitle("Status")
        .task {
            await appModel.refreshAll(showTransitionFeedback: false)
        }
        .refreshable {
            await appModel.refreshAll(showTransitionFeedback: false)
        }
    }

    private func formattedUptime(_ uptimeMs: TimeInterval?) -> String {
        guard let uptimeMs else { return "-" }
        let totalSeconds = Int(uptimeMs / 1000)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
import SwiftUI

struct SnackbarHost: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        Group {
            if let snackbar = appModel.snackbar {
                SnackbarView(snackbar: snackbar)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(duration: 0.35), value: appModel.snackbar)
    }
}

struct SnackbarView: View {
    let snackbar: SnackbarData

    private var accentColor: Color {
        switch snackbar.style {
        case .info:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(accentColor)
                .frame(width: 10, height: 10)

            Text(snackbar.message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.thinMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 6)
    }
}
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var showingAddServer = false

    var body: some View {
        List {
            Section("Servers") {
                if appModel.servers.isEmpty {
                    Text("No saved servers yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appModel.servers) { server in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(server.ip)
                                .font(.body.weight(.semibold))
                            Text("Port \(server.port)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete(perform: appModel.removeServers)
                }

                Button("Add Server") {
                    showingAddServer = true
                    Haptics.light()
                }
                .foregroundStyle(.blue)
            }

            Section("Community") {
                Button("Join our Discord") {
                    appModel.openDiscord()
                }
                .foregroundStyle(.blue)
            }

            Section("About") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Made with love ❤️")
                    Text("Developer")
                        .foregroundStyle(.secondary)
                    Text("@ilovecatssm2")
                }
                .padding(.vertical, 4)
            }

            Section("Session") {
                Button("Sign Out") {
                    appModel.logout()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingAddServer) {
            AddServerView()
                .environmentObject(appModel)
        }
    }
}
import Foundation

enum ServerStore {
    private static let serversKey = "MineBot.Servers"
    private static let selectedServerKey = "MineBot.SelectedServerID"

    static func loadServers() -> [ServerRecord] {
        guard let data = UserDefaults.standard.data(forKey: serversKey) else {
            return []
        }
        return (try? JSONDecoder().decode([ServerRecord].self, from: data)) ?? []
    }

    static func saveServers(_ servers: [ServerRecord]) {
        guard let data = try? JSONEncoder().encode(servers) else { return }
        UserDefaults.standard.set(data, forKey: serversKey)
    }

    static func loadSelectedServerID() -> String {
        UserDefaults.standard.string(forKey: selectedServerKey) ?? ""
    }

    static func saveSelectedServerID(_ id: String) {
        UserDefaults.standard.set(id, forKey: selectedServerKey)
    }
}
# MineBot iOS source

Flat-file SwiftUI source for the MineBot iOS app.

## Files
- `MineBotApp.swift`
- `Models.swift`
- `API.swift`
- `AppModel.swift`
- `Keychain.swift`
- `Haptics.swift`
- `ServerStore.swift`
- `Snackbar.swift`
- `CommonViews.swift`
- `TutorialView.swift`
- `LoginView.swift`
- `BotView.swift`
- `StatusView.swift`
- `SettingsView.swift`
- `AddServerView.swift`

## How to use
1. Create a new **iOS App** project in Xcode.
2. Delete the default Swift files.
3. Drag all `.swift` files from this zip into your Xcode project target.
4. Build and run.

## Notes
- API base URL is set in `API.swift`.
- Token is stored in Keychain.
- Saved servers are stored in `UserDefaults`.
- The app is English-only.
- Designed to fit small displays like iPhone SE 3 by using `ScrollView`, `List`, and flexible layouts.

## Current backend endpoints used
- `POST /auth/redeem`
- `GET /auth/me`
- `GET /accounts`
- `POST /accounts/link/start`
- `GET /accounts/link/status`
- `POST /accounts/unlink`
- `POST /bots/start`
- `POST /bots/stop`
- `POST /bots/reconnect`
- `GET /bots`
- `GET /health`
import Foundation

enum AppTab: Hashable {
    case bot
    case status
    case settings
}

enum ConnectionType: String, CaseIterable, Codable, Identifiable {
    case online = "online"
    case offline = "offline"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .online: return "Online"
        case .offline: return "Offline"
        }
    }
}

struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

struct APIErrorEnvelope: Decodable {
    let success: Bool?
    let error: String?
}

struct AuthRedeemResponse: Decodable {
    let token: String
    let userId: String
    let linkedAccounts: [LinkedAccount]?
}

struct AuthMeResponse: Decodable {
    let userId: String
    let createdAt: TimeInterval?
    let lastActive: TimeInterval?
    let connectionType: String
    let bedrockVersion: String
    let linkedAccounts: [LinkedAccount]
    let bot: AuthMeBotSummary?
}

struct AuthMeBotSummary: Decodable {
    let sessionId: String
    let status: String
    let connected: Bool
    let server: String
    let startedAt: TimeInterval
    let uptimeMs: TimeInterval
}

struct LinkedAccount: Decodable, Identifiable {
    let id: String
    let label: String
    let createdAt: TimeInterval?
    let tokenAcquiredAt: TimeInterval?
    let lastUsedAt: TimeInterval?
    let legacy: Bool?
}

struct PendingLink: Decodable {
    let status: String
    let verificationUri: String?
    let userCode: String?
    let accountId: String?
    let error: String?
    let createdAt: TimeInterval?
    let expiresAt: TimeInterval?
}

struct AccountsResponse: Decodable {
    let linked: [LinkedAccount]
    let pendingLink: PendingLink?
}

struct LinkStartResponse: Decodable {
    let status: String
    let verificationUri: String?
    let userCode: String?
    let accountId: String?
}

struct LinkStatusResponse: Decodable {
    let status: String
    let verificationUri: String?
    let userCode: String?
    let accountId: String?
    let error: String?
    let expiresAt: TimeInterval?
}

struct UnlinkResponse: Decodable {
    let removed: Bool
    let accountId: String
}

struct BotStatusResponse: Decodable {
    let sessionId: String?
    let status: String
    let connected: Bool?
    let isReconnecting: Bool?
    let reconnectAttempt: Int?
    let server: String?
    let startedAt: TimeInterval?
    let uptimeMs: TimeInterval?
    let lastConnectedAt: TimeInterval?
    let lastError: String?
    let lastDisconnectReason: String?
    let connectionType: String?
    let accountId: String?
}

struct BotStartResponse: Decodable {
    let sessionId: String
    let status: String
    let server: String
    let connectionType: String
    let bedrockVersion: String
}

struct BotActionResponse: Decodable {
    let stopped: Bool?
    let reconnected: Bool?
    let sessionId: String?
    let status: String?
}

struct HealthResponse: Decodable {
    let status: String
    let uptimeSec: Int
    let bots: Int
    let memoryMb: Int
    let maxBots: Int
}

struct ServerRecord: Codable, Identifiable, Equatable {
    let id: String
    let ip: String
    let port: Int

    init(id: String = UUID().uuidString, ip: String, port: Int) {
        self.id = id
        self.ip = ip
        self.port = port
    }

    var label: String {
        "\(ip):\(port)"
    }
}

enum SnackbarStyle {
    case info
    case success
    case error
}

struct SnackbarData: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: SnackbarStyle
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL."
        case .invalidResponse:
            return "Invalid server response."
        case .server(let message):
            return message
        case .decoding(let message):
            return message
        }
    }
}

extension BotStatusResponse {
    var statusTitle: String {
        switch status.lowercased() {
        case "connected": return "Connected"
        case "reconnecting": return "Reconnecting"
        case "starting": return "Starting"
        case "error": return "Error"
        case "disconnected": return "Disconnected"
        default: return "Offline"
        }
    }
}
import SwiftUI

@main
struct MineBotApp: App {
    @AppStorage("tutorialSeen") private var tutorialSeen = false
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(tutorialSeen: $tutorialSeen)
                .environmentObject(appModel)
        }
    }
}

struct RootView: View {
    @Binding var tutorialSeen: Bool
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if !tutorialSeen {
                    TutorialView {
                        tutorialSeen = true
                    }
                } else if !appModel.isLoggedIn {
                    LoginView()
                } else {
                    MainTabsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))

            SnackbarHost()
                .environmentObject(appModel)
        }
    }
}

struct MainTabsView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        TabView(selection: $appModel.selectedTab) {
            NavigationStack {
                BotView()
            }
            .tabItem {
                Label("Bot", systemImage: "cpu")
            }
            .tag(AppTab.bot)

            NavigationStack {
                StatusView()
            }
            .tabItem {
                Label("Status", systemImage: "chart.bar")
            }
            .tag(AppTab.status)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
        .tint(.blue)
    }
}
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appModel: AppModel
    @State private var code = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MineBot")
                            .font(.system(size: 34, weight: .bold))
                        Text("Enter your access code")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    CardView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Access Code")
                                .font(.headline)

                            TextField("XXXX-XXXX-XXXX", text: $code)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled(true)
                                .font(.system(.body, design: .monospaced))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .onChange(of: code) { _, newValue in
                                    let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
                                    code = String(filtered.prefix(14))
                                }
                        }
                    }

                    Button {
                        Task {
                            await appModel.login(code: code)
                        }
                    } label: {
                        Text(appModel.isBusy ? "Loading..." : "Login")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .blue))
                    .disabled(appModel.isBusy)
                }
                .frame(maxWidth: 500)
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
import Foundation
import Security

enum Keychain {
    private static let service = "MineBot.AccessToken"
    private static let account = "main"

    static func save(token: String) {
        guard let data = token.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insertQuery = query
            insertQuery[kSecValueData as String] = data
            SecItemAdd(insertQuery as CFDictionary, nil)
        }
    }

    static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }

    static func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)
    }
}
import UIKit

enum Haptics {
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }

    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }

    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}
import SwiftUI

struct CardView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.8 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(color.opacity(configuration.isPressed ? 0.12 : 0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(color.opacity(0.25), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct StatusBadge: View {
    let status: String

    private var color: Color {
        switch status.lowercased() {
        case "connected": return .green
        case "reconnecting": return .orange
        case "error": return .red
        case "starting": return .gray
        case "disconnected": return .orange
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.headline)
        }
        .foregroundStyle(.primary)
    }

    private var label: String {
        switch status.lowercased() {
        case "connected": return "Connected"
        case "reconnecting": return "Reconnecting"
        case "starting": return "Starting"
        case "error": return "Error"
        case "disconnected": return "Disconnected"
        default: return "Offline"
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.body)
    }
}
import SwiftUI

struct BotView: View {
    @EnvironmentObject var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                statusCard
                serverCard
                accountCard
                actionButtons
            }
            .frame(maxWidth: 500)
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .navigationTitle("Bot")
        .task {
            await appModel.refreshAll(showTransitionFeedback: false)
        }
        .refreshable {
            await appModel.refreshAll(showTransitionFeedback: false)
        }
    }

    private var statusCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Bot Status")
                    .font(.headline)

                StatusBadge(status: appModel.botStatus?.status ?? "offline")

                MetricRow(title: "Server", value: appModel.botStatus?.server ?? appModel.selectedServer?.label ?? "Not selected")
                MetricRow(title: "Uptime", value: formattedUptime(appModel.botStatus?.uptimeMs))
            }
        }
    }

    private var serverCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Server")
                    .font(.headline)

                if appModel.servers.isEmpty {
                    Text("No saved servers yet. Add one in Settings.")
                        .foregroundStyle(.secondary)

                    Button("Open Settings") {
                        appModel.selectedTab = .settings
                    }
                    .buttonStyle(SecondaryButtonStyle(color: .blue))
                } else {
                    Picker("Saved Server", selection: Binding(
                        get: { appModel.selectedServerID },
                        set: { appModel.selectServer(id: $0) }
                    )) {
                        ForEach(appModel.servers) { server in
                            Text(server.label).tag(server.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(appModel.isBotRunning)

                    MetricRow(title: "IP Address", value: appModel.selectedServer?.ip ?? "-")
                    MetricRow(title: "Port", value: appModel.selectedServer.map { String($0.port) } ?? "-")

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Connection Type")
                            .font(.subheadline.weight(.semibold))

                        Picker("Connection Type", selection: $appModel.connectionType) {
                            ForEach(ConnectionType.allCases) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(appModel.isBotRunning)
                    }

                    if appModel.connectionType == .offline {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Offline Username")
                                .font(.subheadline.weight(.semibold))
                            TextField("Steve", text: $appModel.offlineUsername)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .disabled(appModel.isBotRunning)
                        }
                    }
                }
            }
        }
    }

    private var accountCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Microsoft Account")
                    .font(.headline)

                if let pending = appModel.pendingLink,
                   pending.status == "starting" || pending.status == "pending" || pending.status == "error" {

                    MetricRow(title: "Status", value: pending.status.capitalized)

                    if let verificationUri = pending.verificationUri, !verificationUri.isEmpty {
                        MetricRow(title: "Link", value: verificationUri)
                    }

                    if let userCode = pending.userCode, !userCode.isEmpty {
                        MetricRow(title: "Code", value: userCode)
                    }

                    if pending.status == "pending" || pending.status == "starting" {
                        Button("Open Microsoft Link") {
                            appModel.openLinkURL()
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .blue))

                        Button("Copy Code") {
                            appModel.copyLinkCode()
                        }
                        .buttonStyle(SecondaryButtonStyle(color: .blue))

                        Button("Refresh Link Status") {
                            Task { await appModel.refreshMicrosoftLinkStatus() }
                        }
                        .buttonStyle(SecondaryButtonStyle(color: .blue))
                    } else if pending.status == "error" {
                        Text(pending.error ?? "Link failed.")
                            .font(.subheadline)
                            .foregroundStyle(.red)

                        Button("Try Again") {
                            Task { await appModel.beginMicrosoftLink() }
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .blue))
                    }
                } else if let account = appModel.firstLinkedAccount {
                    MetricRow(title: "Linked", value: account.label)

                    Button("Unlink Account") {
                        Task { await appModel.unlinkFirstAccount() }
                    }
                    .buttonStyle(SecondaryButtonStyle(color: .blue))
                } else {
                    Text("No linked Microsoft account.")
                        .foregroundStyle(.secondary)

                    Button("Link Microsoft Account") {
                        Task { await appModel.beginMicrosoftLink() }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .blue))
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(appModel.isBusy ? "Working..." : "Start Bot") {
                Task { await appModel.startBot() }
            }
            .buttonStyle(PrimaryButtonStyle(color: .green))
            .disabled(appModel.isBusy)

            Button("Reconnect") {
                Task { await appModel.reconnectBot() }
            }
            .buttonStyle(PrimaryButtonStyle(color: .blue))
            .disabled(appModel.isBusy || !appModel.isBotRunning)

            Button("Stop Bot") {
                Task { await appModel.stopBot() }
            }
            .buttonStyle(PrimaryButtonStyle(color: .red))
            .disabled(appModel.isBusy || !appModel.isBotRunning)
        }
    }

    private func formattedUptime(_ uptimeMs: TimeInterval?) -> String {
        guard let uptimeMs else { return "-" }
        let totalSeconds = Int(uptimeMs / 1000)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
import Foundation
import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    @Published var isLoggedIn: Bool
    @Published var selectedTab: AppTab = .bot

    @Published var linkedAccounts: [LinkedAccount] = []
    @Published var pendingLink: PendingLink?
    @Published var botStatus: BotStatusResponse?
    @Published var health: HealthResponse?
    @Published var serverLatencyMs: Int?
    @Published var snackbar: SnackbarData?

    @Published var servers: [ServerRecord]
    @Published var selectedServerID: String
    @Published var connectionType: ConnectionType = .online
    @Published var offlineUsername: String = ""

    @Published var isBusy = false
    @Published var isRefreshingStatus = false

    private var token: String?
    private var statusTimer: Timer?
    private var lastStatusValue: String?

    let maxGlobalMemoryMb = 512

    init() {
        let savedToken = Keychain.load()
        self.token = savedToken
        self.isLoggedIn = savedToken != nil
        self.servers = ServerStore.loadServers()
        self.selectedServerID = ServerStore.loadSelectedServerID()

        if servers.isEmpty == false, selectedServerID.isEmpty {
            selectedServerID = servers[0].id
        }

        if isLoggedIn {
            startPolling()
            Task {
                await refreshAll(showTransitionFeedback: false)
            }
        }
    }

    var selectedServer: ServerRecord? {
        servers.first(where: { $0.id == selectedServerID })
    }

    var firstLinkedAccount: LinkedAccount? {
        linkedAccounts.first
    }

    var isBotRunning: Bool {
        guard let status = botStatus?.status.lowercased() else { return false }
        return status == "connected" || status == "starting" || status == "reconnecting" || status == "disconnected"
    }

    func completeLogin(with token: String) {
        self.token = token
        self.isLoggedIn = true
        Keychain.save(token: token)
        startPolling()
    }

    func logout() {
        statusTimer?.invalidate()
        statusTimer = nil
        token = nil
        isLoggedIn = false
        linkedAccounts = []
        pendingLink = nil
        botStatus = nil
        health = nil
        serverLatencyMs = nil
        lastStatusValue = nil
        Keychain.deleteToken()
        showSnackbar("Signed out.", style: .info)
    }

    func login(code: String) async {
        let cleanedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard cleanedCode.count == 14 else {
            showSnackbar("Please enter a valid access code.", style: .error)
            return
        }

        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        do {
            let response = try await APIClient.shared.redeemCode(cleanedCode)
            completeLogin(with: response.token)
            showSnackbar("Login successful.", style: .success)
            await refreshAll(showTransitionFeedback: false)
        } catch {
            showSnackbar(error.localizedDescription, style: .error)
        }
    }

    func refreshAll(showTransitionFeedback: Bool = false) async {
        guard let token else { return }

        isRefreshingStatus = true
        defer { isRefreshingStatus = false }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.refreshBotStatus(showTransitionFeedback: showTransitionFeedback)
            }
            group.addTask { [weak self] in
                await self?.refreshHealth()
            }
            group.addTask { [weak self] in
                await self?.refreshAccounts()
            }
        }
    }

    func refreshAccounts() async {
        guard let token else { return }
        do {
            let response = try await APIClient.shared.fetchAccounts(token: token)
            linkedAccounts = response.linked
            if let pending = response.pendingLink, pending.status.lowercased() == "success", response.linked.isEmpty == false {
                pendingLink = nil
            } else {
                pendingLink = response.pendingLink
            }
        } catch {
            // silent; status polling should not spam users
        }
    }

    func refreshHealth() async {
        let startedAt = Date()
        do {
            let response = try await APIClient.shared.fetchHealth()
            health = response
            let latency = Int(Date().timeIntervalSince(startedAt) * 1000)
            serverLatencyMs = max(latency, 1)
        } catch {
            // silent to avoid noisy polling UX
        }
    }

    func refreshBotStatus(showTransitionFeedback: Bool = false) async {
        guard let token else { return }
        do {
            let response = try await APIClient.shared.fetchBotStatus(token: token)
            let previous = lastStatusValue
            botStatus = response
            lastStatusValue = response.status.lowercased()

            guard showTransitionFeedback, previous != response.status.lowercased() else { return }
            handleStatusTransition(to: response)
        } catch {
            if showTransitionFeedback {
                showSnackbar(error.localizedDescription, style: .error)
            }
        }
    }

    private func handleStatusTransition(to status: BotStatusResponse) {
        switch status.status.lowercased() {
        case "connected":
            showSnackbar("Bot connected.", style: .success)
        case "reconnecting":
            showSnackbar("Bot reconnecting...", style: .info)
        case "error":
            showSnackbar(status.lastError ?? "Bot error.", style: .error)
        case "offline":
            showSnackbar("Bot offline.", style: .info)
        default:
            break
        }
    }

    func startPolling() {
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.refreshAll(showTransitionFeedback: true)
                await self.refreshPendingLinkIfNeeded()
            }
        }
    }

    func refreshPendingLinkIfNeeded() async {
        guard let token else { return }
        guard let pendingLink else { return }
        guard pendingLink.status == "starting" || pendingLink.status == "pending" else { return }

        do {
            let response = try await APIClient.shared.fetchMicrosoftLinkStatus(token: token)
            self.pendingLink = PendingLink(
                status: response.status,
                verificationUri: response.verificationUri,
                userCode: response.userCode,
                accountId: response.accountId,
                error: response.error,
                createdAt: nil,
                expiresAt: response.expiresAt
            )

            if response.status == "success" {
                showSnackbar("Microsoft account linked.", style: .success)
                await refreshAccounts()
            } else if response.status == "error", let error = response.error {
                showSnackbar(error, style: .error)
            }
        } catch {
            // silent while polling
        }
    }

    func beginMicrosoftLink() async {
        guard let token else { return }
        guard !isBusy else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            let response = try await APIClient.shared.startMicrosoftLink(token: token)
            pendingLink = PendingLink(
                status: response.status,
                verificationUri: response.verificationUri,
                userCode: response.userCode,
                accountId: response.accountId,
                error: nil,
                createdAt: Date().timeIntervalSince1970,
                expiresAt: nil
            )
            showSnackbar("Microsoft login started.", style: .success)
        } catch {
            showSnackbar(error.localizedDescription, style: .error)
        }
    }

    func refreshMicrosoftLinkStatus() async {
        guard let token else { return }
        do {
            let response = try await APIClient.shared.fetchMicrosoftLinkStatus(token: token)
            pendingLink = PendingLink(
                status: response.status,
                verificationUri: response.verificationUri,
                userCode: response.userCode,
                accountId: response.accountId,
                error: response.error,
                createdAt: pendingLink?.createdAt,
                expiresAt: response.expiresAt
            )

            if response.status == "success" {
                showSnackbar("Microsoft account linked.", style: .success)
                await refreshAccounts()
            } else if response.status == "error" {
                showSnackbar(response.error ?? "Microsoft link failed.", style: .error)
            }
        } catch {
            showSnackbar(error.localizedDescription, style: .error)
        }
    }

    func unlinkFirstAccount() async {
        guard let token, let firstLinkedAccount else { return }
        guard !isBusy else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            _ = try await APIClient.shared.unlinkAccount(token: token, accountId: firstLinkedAccount.id)
            showSnackbar("Account unlinked.", style: .success)
            await refreshAccounts()
        } catch {
            showSnackbar(error.localizedDescription, style: .error)
        }
    }

    func addServer(ip: String, port: Int) {
        let trimmedIP = ip.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIP.isEmpty else {
            showSnackbar("Please enter an IP address.", style: .error)
            return
        }

        let server = ServerRecord(ip: trimmedIP, port: port)
        servers.append(server)
        ServerStore.saveServers(servers)

        if selectedServerID.isEmpty {
            selectedServerID = server.id
            ServerStore.saveSelectedServerID(server.id)
        }

        showSnackbar("Server added.", style: .success)
    }

    func removeServers(at offsets: IndexSet) {
        let idsToDelete = offsets.map { servers[$0].id }
        servers.remove(atOffsets: offsets)

        if idsToDelete.contains(selectedServerID) {
            selectedServerID = servers.first?.id ?? ""
        }

        ServerStore.saveServers(servers)
        ServerStore.saveSelectedServerID(selectedServerID)
        showSnackbar("Server removed.", style: .info)
    }

    func selectServer(id: String) {
        selectedServerID = id
        ServerStore.saveSelectedServerID(id)
        Haptics.light()
    }

    func startBot() async {
        guard let token else { return }
        guard let selectedServer else {
            showSnackbar("Add a server first in Settings.", style: .error)
            selectedTab = .settings
            return
        }

        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }

        if connectionType == .online, linkedAccounts.isEmpty {
            showSnackbar("Link a Microsoft account first.", style: .error)
            return
        }

        do {
            _ = try await APIClient.shared.startBot(
                token: token,
                server: selectedServer,
                connectionType: connectionType,
                offlineUsername: offlineUsername
            )
            showSnackbar("Bot starting...", style: .success)
            await refreshAll(showTransitionFeedback: false)
        } catch {
            showSnackbar(error.localizedDescription, style: .error)
        }
    }

    func stopBot() async {
        guard let token else { return }
        guard !isBusy else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            _ = try await APIClient.shared.stopBot(token: token)
            showSnackbar("Bot stopped.", style: .info)
            await refreshAll(showTransitionFeedback: false)
        } catch {
            showSnackbar(error.localizedDescription, style: .error)
        }
    }

    func reconnectBot() async {
        guard let token else { return }
        guard !isBusy else { return }

        isBusy = true
        defer { isBusy = false }

        do {
            _ = try await APIClient.shared.reconnectBot(token: token)
            showSnackbar("Reconnect requested.", style: .success)
            await refreshAll(showTransitionFeedback: false)
        } catch {
            showSnackbar(error.localizedDescription, style: .error)
        }
    }

    func openDiscord() {
        guard let url = URL(string: "https://discord.gg/CNZsQDBYvw") else { return }
        UIApplication.shared.open(url)
        Haptics.light()
    }

    func openLinkURL() {
        guard let urlString = pendingLink?.verificationUri,
              let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
        Haptics.light()
    }

    func copyLinkCode() {
        guard let code = pendingLink?.userCode, !code.isEmpty else { return }
        UIPasteboard.general.string = code
        showSnackbar("Code copied.", style: .success)
    }

    func showSnackbar(_ message: String, style: SnackbarStyle) {
        switch style {
        case .success:
            Haptics.success()
        case .error:
            Haptics.error()
        case .info:
            Haptics.light()
        }

        let payload = SnackbarData(message: message, style: style)
        snackbar = payload

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard let self else { return }
            if self.snackbar?.id == payload.id {
                self.snackbar = nil
            }
        }
    }
}
import Foundation

final class APIClient {
    static let shared = APIClient()

    // Change this if your Fly URL changes.
    private let baseURL = "https://afkbotb.fly.dev"
    private let jsonDecoder = JSONDecoder()

    private init() {}

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        token: String? = nil,
        body: [String: Any]? = nil,
        timeout: TimeInterval = 20
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if !(200 ..< 300).contains(httpResponse.statusCode) {
            if let errorEnvelope = try? jsonDecoder.decode(APIErrorEnvelope.self, from: data),
               let message = errorEnvelope.error,
               !message.isEmpty {
                throw APIError.server(message)
            }

            if let message = String(data: data, encoding: .utf8), !message.isEmpty {
                throw APIError.server(message)
            }

            throw APIError.server("Request failed with status code \(httpResponse.statusCode).")
        }

        do {
            let envelope = try jsonDecoder.decode(APIEnvelope<T>.self, from: data)
            if envelope.success, let payload = envelope.data {
                return payload
            }
            throw APIError.server(envelope.error ?? "Request failed.")
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.decoding("Failed to decode server response.")
        }
    }

    func redeemCode(_ code: String) async throws -> AuthRedeemResponse {
        try await request(path: "/auth/redeem", method: "POST", body: ["code": code])
    }

    func fetchMe(token: String) async throws -> AuthMeResponse {
        try await request(path: "/auth/me", token: token)
    }

    func fetchAccounts(token: String) async throws -> AccountsResponse {
        try await request(path: "/accounts", token: token)
    }

    func startMicrosoftLink(token: String) async throws -> LinkStartResponse {
        try await request(path: "/accounts/link/start", method: "POST", token: token)
    }

    func fetchMicrosoftLinkStatus(token: String) async throws -> LinkStatusResponse {
        try await request(path: "/accounts/link/status", token: token)
    }

    func unlinkAccount(token: String, accountId: String? = nil) async throws -> UnlinkResponse {
        var body: [String: Any]? = nil
        if let accountId {
            body = ["accountId": accountId]
        }
        return try await request(path: "/accounts/unlink", method: "POST", token: token, body: body)
    }

    func startBot(token: String, server: ServerRecord, connectionType: ConnectionType, offlineUsername: String) async throws -> BotStartResponse {
        var body: [String: Any] = [
            "ip": server.ip,
            "port": server.port,
            "connectionType": connectionType.rawValue
        ]

        if connectionType == .offline, !offlineUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body["offlineUsername"] = offlineUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return try await request(path: "/bots/start", method: "POST", token: token, body: body)
    }

    func stopBot(token: String) async throws -> BotActionResponse {
        try await request(path: "/bots/stop", method: "POST", token: token)
    }

    func reconnectBot(token: String) async throws -> BotActionResponse {
        try await request(path: "/bots/reconnect", method: "POST", token: token)
    }

    func fetchBotStatus(token: String) async throws -> BotStatusResponse {
        try await request(path: "/bots", token: token)
    }

    func fetchHealth() async throws -> HealthResponse {
        try await request(path: "/health")
    }
}
import SwiftUI

struct AddServerView: View {
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var ipAddress = ""
    @State private var port = "19132"

    var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("IP Address", text: $ipAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .keyboardType(.URL)

                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Add Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveServer()
                    }
                    .disabled(ipAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Int(port) == nil)
                }
            }
        }
    }

    private func saveServer() {
        let cleanedPort = Int(port) ?? 19132
        appModel.addServer(ip: ipAddress, port: cleanedPort)
        dismiss()
    }
}

    case online = "online"
    case offline = "offline"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .online: return "Online"
        case .offline: return "Offline"
        }
    }
}

struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: String?
}

struct APIErrorEnvelope: Decodable {
    let success: Bool?
    let error: String?
}

struct AuthRedeemResponse: Decodable {
    let token: String
    let userId: String
    let linkedAccounts: [LinkedAccount]?
}

struct AuthMeResponse: Decodable {
    let userId: String
    let createdAt: TimeInterval?
    let lastActive: TimeInterval?
    let connectionType: String
    let bedrockVersion: String
    let linkedAccounts: [LinkedAccount]
    let bot: AuthMeBotSummary?
}

struct AuthMeBotSummary: Decodable {
    let sessionId: String
    let status: String
    let connected: Bool
    let server: String
    let startedAt: TimeInterval
    let uptimeMs: TimeInterval
}

struct LinkedAccount: Decodable, Identifiable {
    let id: String
    let label: String
    let createdAt: TimeInterval?
    let tokenAcquiredAt: TimeInterval?
    let lastUsedAt: TimeInterval?
    let legacy: Bool?
}

struct PendingLink: Decodable {
    let status: String
    let verificationUri: String?
    let userCode: String?
    let accountId: String?
    let error: String?
    let createdAt: TimeInterval?
    let expiresAt: TimeInterval?
}

struct AccountsResponse: Decodable {
    let linked: [LinkedAccount]
    let pendingLink: PendingLink?
}

struct LinkStartResponse: Decodable {
    let status: String
    let verificationUri: String?
    let userCode: String?
    let accountId: String?
}

struct LinkStatusResponse: Decodable {
    let status: String
    let verificationUri: String?
    let userCode: String?
    let accountId: String?
    let error: String?
    let expiresAt: TimeInterval?
}

struct UnlinkResponse: Decodable {
    let removed: Bool
    let accountId: String
}

struct BotStatusResponse: Decodable {
    let sessionId: String?
    let status: String
    let connected: Bool?
    let isReconnecting: Bool?
    let reconnectAttempt: Int?
    let server: String?
    let startedAt: TimeInterval?
    let uptimeMs: TimeInterval?
    let lastConnectedAt: TimeInterval?
    let lastError: String?
    let lastDisconnectReason: String?
    let connectionType: String?
    let accountId: String?
}

struct BotStartResponse: Decodable {
    let sessionId: String
    let status: String
    let server: String
    let connectionType: String
    let bedrockVersion: String
}

struct BotActionResponse: Decodable {
    let stopped: Bool?
    let reconnected: Bool?
    let sessionId: String?
    let status: String?
}

struct HealthResponse: Decodable {
    let status: String
    let uptimeSec: Int
    let bots: Int
    let memoryMb: Int
    let maxBots: Int
}

struct ServerRecord: Codable, Identifiable, Equatable {
    let id: String
    let ip: String
    let port: Int

    init(id: String = UUID().uuidString, ip: String, port: Int) {
        self.id = id
        self.ip = ip
        self.port = port
    }

    var label: String {
        "\(ip):\(port)"
    }
}

enum SnackbarStyle {
    case info
    case success
    case error
}

struct SnackbarData: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: SnackbarStyle
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case server(String)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL."
        case .invalidResponse:
            return "Invalid server response."
        case .server(let message):
            return message
        case .decoding(let message):
            return message
        }
    }
}

extension BotStatusResponse {
    var statusTitle: String {
        switch status.lowercased() {
        case "connected": return "Connected"
        case "reconnecting": return "Reconnecting"
        case "starting": return "Starting"
        case "error": return "Error"
        case "disconnected": return "Disconnected"
        default: return "Offline"
        }
    }
}

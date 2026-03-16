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

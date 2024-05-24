//
//  IPFSStatusView.swift
//  Planet
//

import SwiftUI


struct IPFSStatusView: View {
    @EnvironmentObject private var ipfsState: IPFSState

    static let formatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useAll
        byteCountFormatter.countStyle = .file
        return byteCountFormatter
    }()

    @State private var isDaemonOnline: Bool = IPFSState.shared.online
    @State private var isDaemonFailedToLaunch: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            statusView()
                .padding(.horizontal, 12)
                .padding(.top, 12)

            IPFSTrafficView()
                .environmentObject(ipfsState)
                .frame(height: 120)
                .padding(.horizontal, 12)
                .padding(.top, 12)

            Divider()
                .padding(.top, 12)

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Circle()
                        .frame(width: 11, height: 11, alignment: .center)
                        .foregroundColor(ipfsState.online ? Color.green : Color.red)
                    Text(ipfsState.online ? "Online" : "Offline")
                        .font(.body)
                    Spacer()
                    if ipfsState.isOperating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                    } else {
                        Toggle("", isOn: $isDaemonOnline)
                            .toggleStyle(SwitchToggleStyle())
                            .tint(.green)
                            .onChange(of: isDaemonOnline) { newValue in
                                Task.detached(priority: .userInitiated) {
                                    if newValue {
                                        do {
                                            try await IPFSDaemon.shared.launch()
                                        } catch {
                                            await MainActor.run {
                                                self.isDaemonFailedToLaunch = true
                                            }
                                        }
                                    } else {
                                        try? await IPFSDaemon.shared.shutdown()
                                    }
                                    await IPFSState.shared.updateStatus()
                                    await MainActor.run {
                                        self.isDaemonOnline = newValue
                                    }
                                    UserDefaults.standard.setValue(newValue, forKey: IPFSState.lastUserLaunchState)
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(height: 44)
        }
        .padding(0)
        .frame(width: 280)
        .task {
            Task.detached(priority: .background) {
                do {
                    try await self.ipfsState.calculateRepoSize()
                } catch {
                    debugPrint("failed to calculate repo size: \(error)")
                }
            }
        }
        .alert("Failed to Launch Daemon", isPresented: $isDaemonFailedToLaunch) {
            Button(role: .destructive) {
                Task.detached(priority: .userInitiated) {
                    do {
                        try await IPFSDaemon.shared.launch()
                    } catch {
                        await MainActor.run {
                            self.isDaemonFailedToLaunch = true
                        }
                    }
                }
            } label: {
                Text("Launch Daemon")
            }
            Button(role: .cancel) {
            } label: {
                Text("Dismiss")
            }
        } message: {
            Text("Please wait for a few seconds then try again.")
        }
    }
    
    @ViewBuilder
    private func statusView() -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("Local Gateway")
                Spacer(minLength: 1)
                Link(self.ipfsState.getGateway(), destination: URL(string: self.ipfsState.getGateway())!)
                    .focusable(false)
                    .disabled(!self.ipfsState.online)
            }
            HStack {
                Text("Repo Size")
                Spacer(minLength: 1)
                if ipfsState.isCalculatingRepoSize {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.mini)
                } else {
                    if let repoSize = ipfsState.repoSize {
                        Text(Self.formatter.string(fromByteCount: repoSize))
                    }
                }
            }
            HStack {
                Text("Peers")
                Spacer(minLength: 1)
                if self.ipfsState.online, let peers = self.ipfsState.serverInfo?.ipfsPeerCount {
                    Text(String(peers))
                }
            }
            HStack {
                Text("IPFS Version")
                Spacer(minLength: 1)
                Text(self.ipfsState.serverInfo?.ipfsVersion ?? "")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

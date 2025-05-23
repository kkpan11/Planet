//
//  IPFSStatusView.swift
//  Planet
//

import SwiftUI

struct IPFSStatusView: View {
    @EnvironmentObject private var ipfsState: IPFSState
    @State private var showingGCAlert = false

    static let formatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useAll
        byteCountFormatter.countStyle = .file
        return byteCountFormatter
    }()

    @State private var isDaemonOnline: Bool = IPFSState.shared.online

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
                    if !ipfsState.isOperating {
                        Circle()
                            .frame(width: 11, height: 11, alignment: .center)
                            .foregroundColor(ipfsState.online ? Color.green : Color.red)
                        Text(ipfsState.online ? "Online" : "Offline")
                            .font(.body)
                    }
                    Spacer()
                    if ipfsState.isOperating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .controlSize(.small)
                    }
                    else {
                        Button {
                            showingGCAlert = true
                        } label: {
                            Image(systemName: "arrow.3.trianglepath")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 15)
                                .foregroundStyle(Color.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Run IPFS garbage collection.")
                        .disabled(!ipfsState.online)

                        if !ipfsState.isShowingStatusWindow {
                            Button {
                                IPFSStatusWindowManager.shared.activate()
                            } label: {
                                Image(systemName: "rectangle.inset.filled.on.rectangle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 15)
                                    .foregroundStyle(Color.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Open status in separate window.")
                        }
                        Toggle("", isOn: $isDaemonOnline)
                            .toggleStyle(SwitchToggleStyle())
                            .tint(.green)
                            .onChange(of: isDaemonOnline) { newValue in
                                Task.detached(priority: .userInitiated) {
                                    if newValue {
                                        try? await IPFSDaemon.shared.launch()
                                    }
                                    else {
                                        try? await IPFSDaemon.shared.shutdown()
                                    }
                                    await IPFSState.shared.updateStatus()
                                    await MainActor.run {
                                        self.isDaemonOnline = newValue
                                    }
                                    UserDefaults.standard.setValue(
                                        newValue,
                                        forKey: IPFSState.lastUserLaunchState
                                    )
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(height: 44)
        }
        .background(.regularMaterial)
        .alert(isPresented: $showingGCAlert) {
            Alert(
                title: Text("Are you sure you want to manually run garbage collection?"),
                message: Text("This will free up disk space by removing unused data."),
                primaryButton: .destructive(Text("Run GC")) {
                    Task {
                        do {
                            try await IPFSDaemon.shared.gc()
                        }
                        catch {
                            debugPrint("failed to run gc: \(error)")
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .frame(width: 280)
        .background(.regularMaterial)
        .task {
            Task.detached(priority: .background) {
                do {
                    try await self.ipfsState.calculateRepoSize()
                }
                catch {
                    debugPrint("failed to calculate repo size: \(error)")
                }
            }
        }
    }

    @ViewBuilder
    private func statusView() -> some View {
        VStack(spacing: 4) {
            HStack {
                Text("Local Gateway")
                Spacer(minLength: 1)
                Link(
                    self.ipfsState.getGateway(),
                    destination: URL(
                        string: self.ipfsState.getGateway()
                            + "/ipns/k51qzi5uqu5dibstm2yxidly22jx94embd7j3xjstfk65ulictn2ajnjvpiac7"
                    )!
                )
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
                }
                else {
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

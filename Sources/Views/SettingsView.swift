import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var openaiApiKey = ""
    @State private var geminiApiKey = ""
    @State private var showOpenaiKey = false
    @State private var showGeminiKey = false
    @State private var savedOpenai = false
    @State private var savedGemini = false
    @State private var showClearDataAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // AI Provider Selection
                VStack(alignment: .leading, spacing: 12) {
                    Label("PDF Okuma Modeli", systemImage: "cpu")
                        .font(.headline)

                    Text("Ekstreleri analiz etmek için kullanılacak AI modelini seçin.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("AI Sağlayıcı", selection: Binding(
                        get: { appState.selectedAIProvider },
                        set: { appState.setAIProvider($0) }
                    )) {
                        ForEach(AIProvider.allCases) { provider in
                            Label(provider.rawValue, systemImage: provider.icon)
                                .tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // OpenAI API Key Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("OpenAI API Anahtarı", systemImage: "key.fill")
                            .font(.headline)
                        Spacer()
                        if appState.selectedAIProvider == .openai {
                            Text("Aktif")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }

                    HStack {
                        if showOpenaiKey {
                            TextField("sk-...", text: $openaiApiKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("sk-...", text: $openaiApiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            showOpenaiKey.toggle()
                        } label: {
                            Image(systemName: showOpenaiKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            saveOpenaiApiKey()
                        } label: {
                            if savedOpenai {
                                Label("Kaydedildi", systemImage: "checkmark")
                            } else {
                                Text("Kaydet")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                        Label("OpenAI API anahtarı nasıl alınır?", systemImage: "arrow.up.right")
                            .font(.caption)
                    }
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Gemini API Key Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Google Gemini API Anahtarı", systemImage: "key.fill")
                            .font(.headline)
                        Spacer()
                        if appState.selectedAIProvider == .gemini {
                            Text("Aktif")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                    }

                    HStack {
                        if showGeminiKey {
                            TextField("AIza...", text: $geminiApiKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("AIza...", text: $geminiApiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        Button {
                            showGeminiKey.toggle()
                        } label: {
                            Image(systemName: showGeminiKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            saveGeminiApiKey()
                        } label: {
                            if savedGemini {
                                Label("Kaydedildi", systemImage: "checkmark")
                            } else {
                                Text("Kaydet")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Link(destination: URL(string: "https://aistudio.google.com/apikey")!) {
                        Label("Gemini API anahtarı nasıl alınır?", systemImage: "arrow.up.right")
                            .font(.caption)
                    }
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // About Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Hakkında", systemImage: "info.circle")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("FinansApp")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("v1.0.0")
                                .foregroundStyle(.secondary)
                        }

                        Text("Kredi kartı ekstre analiz uygulaması")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text("Bu uygulama, kredi kartı ekstrelerinizi AI ile analiz ederek harcama alışkanlıklarınızı anlamanıza ve tasarruf fırsatlarını keşfetmenize yardımcı olur.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bu program Fikret Tozak tarafından Claude Code kullanılarak yapılmıştır.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                Image(systemName: "envelope.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Link("fikret.tozak@wpokulu.co", destination: URL(string: "mailto:fikret.tozak@wpokulu.co")!)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Data Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Veri", systemImage: "cylinder.split.1x2")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Veritabanı Konumu")
                                .font(.subheadline)
                            Text(databasePath)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Finder'da Göster") {
                            showInFinder()
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Tüm Verileri Sil")
                                .font(.subheadline)
                            Text("Kartlar, ekstreler ve işlemler silinir. API anahtarı korunur.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Verileri Sil") {
                            showClearDataAlert = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Ayarlar")
        .onAppear {
            openaiApiKey = appState.openaiApiKey
            geminiApiKey = appState.geminiApiKey
        }
        .alert("Tüm Verileri Sil", isPresented: $showClearDataAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                appState.clearAllData()
            }
        } message: {
            Text("Tüm kartlar, ekstreler ve işlemler kalıcı olarak silinecek. Bu işlem geri alınamaz.")
        }
    }

    private var databasePath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("FinansApp/finans.db").path
    }

    private func saveOpenaiApiKey() {
        appState.openaiApiKey = openaiApiKey
        savedOpenai = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedOpenai = false
        }
    }

    private func saveGeminiApiKey() {
        appState.geminiApiKey = geminiApiKey
        savedGemini = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            savedGemini = false
        }
    }

    private func showInFinder() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("FinansApp")
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folder.path)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}

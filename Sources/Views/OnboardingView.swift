import SwiftUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Binding var isOnboardingComplete: Bool

    @State private var currentStep = 0
    @State private var apiKey = ""
    @State private var selectedProvider: AIProvider = .gemini
    @State private var isUploading = false
    @State private var uploadSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)

            Spacer()

            // Content
            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                apiKeyStep.tag(1)
                uploadStep.tag(2)
            }
            .tabViewStyle(.automatic)

            Spacer()

            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Geri") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < 2 {
                    Button("İleri") {
                        withAnimation {
                            if currentStep == 1 && !apiKey.isEmpty {
                                saveApiKey()
                            }
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Başla") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(30)
        }
        .frame(width: 600, height: 500)
        .background(Color(.windowBackgroundColor))
    }

    // MARK: - Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue.gradient)

            Text("FinansApp'e Hoş Geldiniz")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Kredi kartı ekstrelerinizi AI ile analiz edin,\nharcamalarınızı takip edin.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "doc.text.viewfinder", text: "PDF ekstrelerini otomatik okuma")
                featureRow(icon: "chart.pie.fill", text: "Kategori bazlı harcama analizi")
                featureRow(icon: "arrow.left.arrow.right", text: "Aylık karşılaştırma")
                featureRow(icon: "sparkles", text: "AI destekli öneriler")
            }
            .padding(.top, 20)
        }
        .padding(40)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            Text(text)
                .font(.body)
        }
    }

    // MARK: - Step 2: API Key
    private var apiKeyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange.gradient)

            Text("API Anahtarı")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("PDF ekstrelerini okumak için bir AI servisi gerekli.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                // Provider selection
                Picker("AI Servisi", selection: $selectedProvider) {
                    ForEach(AIProvider.allCases) { provider in
                        Label(provider.rawValue, systemImage: provider.icon)
                            .tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                // API Key input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(selectedProvider.rawValue) API Anahtarı")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("(Opsiyonel)")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }

                    SecureField("API anahtarınızı girin", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 400)
                }

                // Help link
                Link(destination: apiHelpURL) {
                    Label("API anahtarı nasıl alınır?", systemImage: "questionmark.circle")
                        .font(.caption)
                }

                Text("Bu adımı atlayıp Ayarlar'dan daha sonra da girebilirsiniz.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(.top, 20)
        }
        .padding(40)
    }

    private var apiHelpURL: URL {
        switch selectedProvider {
        case .openai:
            return URL(string: "https://platform.openai.com/api-keys")!
        case .gemini:
            return URL(string: "https://aistudio.google.com/app/apikey")!
        }
    }

    // MARK: - Step 3: Upload
    private var uploadStep: some View {
        VStack(spacing: 20) {
            if uploadSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green.gradient)

                Text("Ekstre Yüklendi!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("İlk ekstreniz başarıyla işlendi.\nArtık uygulamayı kullanmaya başlayabilirsiniz.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else if isUploading {
                ProgressView()
                    .scaleEffect(2)
                    .padding(.bottom, 20)

                Text("Ekstre İşleniyor...")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("AI ekstrenizi okuyor, lütfen bekleyin.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(.green.gradient)

                Text("İlk Ekstrenizi Yükleyin")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Kredi kartı ekstrenizi PDF olarak yükleyin.\nAI otomatik olarak işlemleri çıkaracak.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    selectAndUploadPDF()
                } label: {
                    Label("PDF Seç", systemImage: "folder")
                        .font(.title3)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 20)

                Text("Bu adımı atlayıp daha sonra da yükleyebilirsiniz.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 10)
            }
        }
        .padding(40)
    }

    // MARK: - Actions
    private func saveApiKey() {
        switch selectedProvider {
        case .openai:
            appState.openaiApiKey = apiKey
        case .gemini:
            appState.geminiApiKey = apiKey
        }
        appState.setAIProvider(selectedProvider)
    }

    private func selectAndUploadPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Kredi kartı ekstrenizi seçin"
        panel.prompt = "Yükle"

        panel.begin { response in
            if response == .OK, let url = panel.url {
                isUploading = true
                Task {
                    await appState.uploadAndParseStatement(pdfURL: url)
                    await MainActor.run {
                        isUploading = false
                        if appState.error == nil {
                            uploadSuccess = true
                        }
                    }
                }
            }
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        isOnboardingComplete = true
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
        .environmentObject(AppState())
}

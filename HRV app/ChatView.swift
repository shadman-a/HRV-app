import SwiftUI
import Combine
import FoundationModels

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false

    private let model = SystemLanguageModel.default
    private let dataProvider: () -> [DataPoint]

    init(dataProvider: @escaping () -> [DataPoint]) {
        self.dataProvider = dataProvider
    }

    func send(_ text: String) async {
        guard !text.isEmpty else { return }

        switch model.availability {
        case .available: break
        case .unavailable(.deviceNotEligible):
            messages.append(.assistant("❌ Device not supported."))
            return
        case .unavailable(.appleIntelligenceNotEnabled):
            messages.append(.assistant("❌ Enable Apple Intelligence in Settings."))
            return
        case .unavailable(.modelNotReady):
            messages.append(.assistant("⌛ Model is downloading—please wait."))
            return
        default:
            messages.append(.assistant("❌ Model is unavailable."))
            return
        }

        messages.append(.user(text))
        isLoading = true

        let context = dataProvider()
            .map { "\($0.title): \($0.value)" }
            .joined(separator: ", ")

        let session = LanguageModelSession(
            model: model,
            instructions: "You are a helpful AI assistant that gives short, friendly advice about HRV and stress management. Use the following user data as context: \(context)"
        )

        do {
            let result = try await session.respond(to: Prompt(text))
            messages.append(.assistant(result.content))
        } catch {
            messages.append(.assistant("❌ Error: \(error.localizedDescription)"))
        }

        isLoading = false
    }
}

struct Message: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let content: String

    static func user(_ text: String) -> Message { .init(role: .user, content: text) }
    static func assistant(_ text: String) -> Message { .init(role: .assistant, content: text) }
}

struct ChatBubbleView: View {
    let message: Message

    var body: some View {
        let attributed = AttributedString(message.content)
        let tint = message.role == .user ? Color.cyan.opacity(0.4) : Color.white.opacity(0.6)
        let shadowColor = message.role == .assistant ? Color.cyan.opacity(0.9) : .clear

        return HStack {
            if message.role == .user { Spacer() }

            Text(attributed)
                .textSelection(.enabled)
                .padding(12)
                .glassEffect(
                    Glass.regular.tint(tint),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .foregroundStyle(message.role == .user ? .primary : Color.white)
                .shadow(color: shadowColor, radius: message.role == .assistant ? 12 : 0)

            if message.role == .assistant { Spacer() }
        }
    }
}

struct InputBar: View {
    @Binding var draft: String
    var sendAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Say something…", text: $draft)
                .padding(10)
                .autocorrectionDisabled(true)
                .glassEffect(
                    Glass.regular
                        .interactive(true)
                        .tint(Color.white.opacity(0.25)),
                    in: RoundedRectangle(cornerRadius: 12)
                )
                .frame(maxWidth: .infinity)
            Spacer()

            Button(action: sendAction) {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .padding(4)
            }
            .buttonStyle(.glass)
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}

struct TypingIndicatorView: View {
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.white.opacity(dotCount == index ? 1 : 0.3))
            }
        }
        .onReceive(timer) { _ in
            dotCount = (dotCount + 1) % 3
        }
    }
}

struct LoadingView: View {
    var body: some View {
        HStack {
            TypingIndicatorView()
                .padding(12)
                .glassEffect(
                    Glass.regular
                        .tint(Color.white.opacity(0.3))
                        .interactive(true),
                    in: Circle()
                )
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ChatView: View {
    @ObservedObject var dataManager: AppDataManager
    @StateObject private var vm: ChatViewModel
    @State private var draft = ""
    @FocusState private var isInputActive: Bool

    init(dataManager: AppDataManager) {
        self.dataManager = dataManager
        _vm = StateObject(wrappedValue: ChatViewModel(dataProvider: { dataManager.dataPoints }))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.3),
                    Color.blue.opacity(0.5),
                    Color.cyan.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GlassEffectContainer(spacing: 16) {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(vm.messages) { msg in
                                    ChatBubbleView(message: msg)
                                        .id(msg.id)
                                }
                                if vm.isLoading {
                                    LoadingView()
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .scrollDismissesKeyboard(.immediately)
                        .frame(maxHeight: .infinity)
                        .onChange(of: vm.messages.count) { _ in
                            if let last = vm.messages.last {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }

                    InputBar(draft: $draft) {
                        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft = ""
                        Task { await vm.send(text) }
                    }
                    .focused($isInputActive)
                }
            }
            .padding(6)
            .onTapGesture { isInputActive = false }
        }
    }
}

#Preview {
    ChatView(dataManager: AppDataManager())
}

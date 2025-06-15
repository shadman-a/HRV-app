import SwiftUI
import FoundationModels

@MainActor
class InsightViewModel: ObservableObject {
    @Published var insight: String = ""
    private let model = SystemLanguageModel.default
    private let dataProvider: () -> [DataPoint]
    private var timer: Timer?

    init(dataProvider: @escaping () -> [DataPoint]) {
        self.dataProvider = dataProvider
        scheduleTimer()
    }

    deinit {
        timer?.invalidate()
    }

    private func scheduleTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { await self?.generateInsight() }
        }
    }

    func generateInsight() async {
        guard model.availability == .available else { return }
        let context = dataProvider()
            .map { "\($0.title): \($0.value)" }
            .joined(separator: ", ")
        let session = LanguageModelSession(
            model: model,
            instructions: "Provide a brief health insight using two sentences or less based on: \(context)"
        )
        do {
            let result = try await session.respond(to: Prompt("Insight"))
            insight = result.content
        } catch {
            // Ignore failures
        }
    }
}

struct InsightCardView: View {
    @StateObject var viewModel: InsightViewModel

    var body: some View {
        VStack(alignment: .leading) {
            if viewModel.insight.isEmpty {
                ProgressView()
            } else {
                Text(viewModel.insight)
                    .font(.body)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .task { await viewModel.generateInsight() }
    }
}

#Preview {
    InsightCardView(viewModel: InsightViewModel(dataProvider: { [] }))
}

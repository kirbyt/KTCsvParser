import SwiftUI
import CsvParser

// MARK: - SwiftUI Integration Examples

/// Main CSV viewer app
@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct CsvViewerApp: View {
    @State private var csvContent = """
    name,age,city,occupation
    John Doe,28,New York,Engineer
    Jane Smith,32,Los Angeles,Designer
    Bob Johnson,45,Chicago,Manager
    Alice Brown,29,Boston,Developer
    Charlie Wilson,38,Seattle,Analyst
    """
    
    @State private var parser: CsvParser?
    @State private var isParsingComplete = false
    
    var body: some View {
        NavigationView {
            VStack {
                // CSV Input Section
                VStack(alignment: .leading) {
                    Text("CSV Data:")
                        .font(.headline)
                    
                    TextEditor(text: $csvContent)
                        .border(Color.gray, width: 1)
                        .frame(height: 150)
                }
                .padding()
                
                // Parse Button
                Button("Parse CSV") {
                    parseCSV()
                }
                .buttonStyle(.borderedProminent)
                .disabled(csvContent.isEmpty)
                
                // Results Section
                if let parser = parser {
                    CsvResultsView(parser: parser)
                        .padding()
                }
                
                Spacer()
            }
            .navigationTitle("CSV Parser Demo")
        }
    }
    
    private func parseCSV() {
        let data = csvContent.data(using: .utf8) ?? Data()
        parser = CsvParser(data: data)
        
        Task {
            await parser?.startParsingAsync()
        }
    }
}

/// Results view showing parsed CSV data
@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
struct CsvResultsView: View {
    let parser: CsvParser
    @State private var rows: [[String]] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            // Status Information
            HStack {
                Text("Lines Processed: \(parser.linesProcessed)")
                Spacer()
                Text("Current Row: \(parser.currentRow.joined(separator: ", "))")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // Data Table
            if !rows.isEmpty {
                ScrollView([.horizontal, .vertical]) {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(rows.indices, id: \.self) { rowIndex in
                            HStack(spacing: 8) {
                                ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                                    Text(rows[rowIndex][colIndex])
                                        .frame(minWidth: 80, alignment: .leading)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            rowIndex == 0 ? Color.blue.opacity(0.1) : Color.clear
                                        )
                                        .border(Color.gray.opacity(0.3), width: 0.5)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        do {
            rows = try await parser.parseAllAsync()
        } catch {
            print("Error loading data: \(error)")
        }
    }
}

/// Legacy SwiftUI support (iOS 13+)
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
struct LegacyCsvViewer: View {
    @StateObject private var observableParser: ObservableCsvParser
    @State private var csvContent = "name,age\nJohn,25\nJane,30"
    
    init() {
        let parser = CsvParser(data: Data())
        self._observableParser = StateObject(wrappedValue: ObservableCsvParser(parser: parser))
    }
    
    var body: some View {
        VStack {
            // Input
            TextEditor(text: $csvContent)
                .border(Color.gray)
                .frame(height: 100)
            
            // Parse Button
            Button("Parse CSV") {
                let data = csvContent.data(using: .utf8) ?? Data()
                let parser = CsvParser(data: data)
                observableParser.parser = parser
                
                Task {
                    await observableParser.parseAsync()
                }
            }
            
            // Status
            VStack {
                Text("Lines: \(observableParser.linesProcessed)")
                Text("Current: \(observableParser.currentRow.joined(separator: ", "))")
                
                if observableParser.isComplete {
                    Text("✅ Parsing Complete")
                        .foregroundColor(.green)
                }
                
                if let error = observableParser.error {
                    Text("❌ Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                }
            }
            .padding()
        }
        .csvParsingProgress(observableParser)
        .padding()
    }
}

/// File picker integration example
@available(iOS 14.0, macOS 11.0, *)
struct CsvFilePickerView: View {
    @State private var showingFilePicker = false
    @State private var parseResults: [[String]] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            Button("Select CSV File") {
                showingFilePicker = true
            }
            .buttonStyle(.borderedProminent)
            
            if isLoading {
                ProgressView("Parsing CSV...")
                    .padding()
            }
            
            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            if !parseResults.isEmpty {
                List {
                    ForEach(parseResults.indices, id: \.self) { index in
                        Text(parseResults[index].joined(separator: " | "))
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            Task {
                await parseFile(url: url)
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func parseFile(url: URL) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let rows = try await CsvParser.parseURLAsync(url: url) { lineCount in
                print("Processed \(lineCount) lines")
            }
            
            await MainActor.run {
                parseResults = rows
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - Example Usage

struct CsvParserExamples_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            if #available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *) {
                CsvViewerApp()
                    .previewDisplayName("Modern CSV Viewer")
            }
            
            if #available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *) {
                LegacyCsvViewer()
                    .previewDisplayName("Legacy CSV Viewer")
            }
            
            if #available(iOS 14.0, macOS 11.0, *) {
                CsvFilePickerView()
                    .previewDisplayName("File Picker")
            }
        }
    }
}
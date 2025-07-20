import Foundation
import Observation

#if canImport(SwiftUI)
import SwiftUI

/// Parsing state for SwiftUI observation
public enum ParsingState {
    case idle
    case parsing
    case completed
    case error(CsvParserError)
}

/// Observable CSV parser with SwiftUI state management
@available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *)
@Observable
public class ObservableCsvParserAdvanced {
    private let parser: CsvParser
    
    /// Current parsing state (observable)
    public private(set) var parsingState: ParsingState = .idle
    
    /// Progress as a percentage (0.0 to 1.0) for long-running operations
    public private(set) var progress: Double = 0.0
    
    /// Current row being processed (for observation)
    public private(set) var currentRow: [String] = []
    
    /// Current parsing progress (number of lines processed)
    public private(set) var linesProcessed: Int = 0
    
    public init(parser: CsvParser) {
        self.parser = parser
    }
    
    public convenience init(data: Data, configuration: CsvConfiguration = CsvConfiguration()) {
        let parser = CsvParser(data: data, configuration: configuration)
        self.init(parser: parser)
    }
    
    /// Start parsing asynchronously with SwiftUI state updates
    /// - Parameter estimatedLineCount: Optional estimated total lines for progress calculation
    @MainActor
    public func startParsingAsync(estimatedLineCount: Int? = nil) async {
        parsingState = .parsing
        progress = 0.0
        
        do {
            var allRows: [[String]] = []
            
            while let row = try await parser.readLineAsync() {
                allRows.append(row)
                currentRow = row
                linesProcessed = parser.linesProcessed
                
                // Update progress if we have an estimate
                if let estimated = estimatedLineCount {
                    progress = Swift.min(Double(linesProcessed) / Double(estimated), 1.0)
                }
                
                // Yield to allow UI updates
                if linesProcessed % 10 == 0 {
                    await Task.yield()
                }
            }
            
            parsingState = .completed
            progress = 1.0
            
        } catch let error as CsvParserError {
            parsingState = .error(error)
        } catch {
            parsingState = .error(.streamError(error.localizedDescription))
        }
    }
    
    /// Reset the parser state
    @MainActor
    public func reset() {
        parsingState = .idle
        progress = 0.0
        linesProcessed = 0
        currentRow = []
    }
}

/// ObservableObject wrapper for compatibility with older SwiftUI versions
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public class ObservableCsvParser: ObservableObject {
    private let parser: CsvParser
    
    @Published public private(set) var currentRow: [String] = []
    @Published public private(set) var linesProcessed: Int = 0
    @Published public private(set) var isComplete: Bool = false
    @Published public private(set) var error: CsvParserError?
    
    public init(parser: CsvParser) {
        self.parser = parser
    }
    
    public convenience init(data: Data, configuration: CsvConfiguration = CsvConfiguration()) {
        let parser = CsvParser(data: data, configuration: configuration)
        self.init(parser: parser)
    }
    
    @MainActor
    public func parseAsync() async {
        error = nil
        isComplete = false
        
        do {
            while let row = try await parser.readLineAsync() {
                currentRow = row
                linesProcessed = parser.linesProcessed
                
                // Yield occasionally for UI updates
                if linesProcessed % 10 == 0 {
                    await Task.yield()
                }
            }
            isComplete = true
        } catch let csvError as CsvParserError {
            error = csvError
        } catch {
            self.error = .streamError(error.localizedDescription)
        }
    }
}

/// View modifier for CSV parsing progress
@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
public struct CsvParsingProgressModifier: ViewModifier {
    let parser: ObservableCsvParser
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if !parser.isComplete && parser.error == nil && parser.linesProcessed > 0 {
                        VStack {
                            ProgressView("Parsing CSV...")
                            Text("\(parser.linesProcessed) lines processed")
                                .font(.caption)
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            )
    }
}

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
extension View {
    /// Add CSV parsing progress indicator
    /// - Parameter parser: The observable parser to monitor
    /// - Returns: View with progress overlay
    public func csvParsingProgress(_ parser: ObservableCsvParser) -> some View {
        self.modifier(CsvParsingProgressModifier(parser: parser))
    }
}

/// SwiftUI View for displaying CSV data in a table-like format
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
public struct CsvTableView: View {
    let rows: [[String]]
    let headers: [String]?
    
    public init(rows: [[String]], headers: [String]? = nil) {
        self.rows = rows
        self.headers = headers
    }
    
    public var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(alignment: .leading, spacing: 2) {
                if let headers = headers {
                    HStack(spacing: 4) {
                        ForEach(headers.indices, id: \.self) { index in
                            Text(headers[index])
                                .font(.headline)
                                .frame(minWidth: 80, alignment: .leading)
                                .padding(4)
                                .background(Color.blue.opacity(0.1))
                        }
                    }
                }
                
                ForEach(rows.indices, id: \.self) { rowIndex in
                    HStack(spacing: 4) {
                        ForEach(rows[rowIndex].indices, id: \.self) { columnIndex in
                            Text(rows[rowIndex][columnIndex])
                                .frame(minWidth: 80, alignment: .leading)
                                .padding(4)
                                .background(Color.gray.opacity(0.05))
                        }
                    }
                }
            }
        }
    }
}

// Helper extension for safe array access
private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#endif
import Foundation

/// Async/await extensions for CsvParser
extension CsvParser {
    /// Asynchronously read the next line
    /// - Returns: Array of field values, or nil if at end of file
    /// - Throws: CsvParserError if parsing fails
    public func readLineAsync() async throws -> [String]? {
        return try await Task {
            try self.readLine()
        }.value
    }
    
    /// Asynchronously parse all lines
    /// - Returns: Array of all rows
    /// - Throws: CsvParserError if parsing fails
    public func parseAllAsync() async throws -> [[String]] {
        return try await Task {
            try self.parseAll()
        }.value
    }
    
    /// Asynchronously parse all lines with progress reporting
    /// - Parameter progressHandler: Called for each line processed with current line number
    /// - Returns: Array of all rows
    /// - Throws: CsvParserError if parsing fails
    public func parseAllAsync(
        progressHandler: @escaping (Int) -> Void
    ) async throws -> [[String]] {
        return try await Task {
            var allRows: [[String]] = []
            var lineNumber = 0
            
            while let row = try self.readLine() {
                allRows.append(row)
                lineNumber += 1
                
                // Report progress every 100 lines to avoid excessive callbacks
                if lineNumber % 100 == 0 {
                    let currentLine = lineNumber
                    await MainActor.run {
                        progressHandler(currentLine)
                    }
                }
            }
            
            // Final progress update
            let finalLine = lineNumber
            await MainActor.run {
                progressHandler(finalLine)
            }
            
            return allRows
        }.value
    }
}

/// Static async convenience methods
extension CsvParser {
    /// Asynchronously parse a single CSV line
    /// - Parameters:
    ///   - csvLine: The CSV line to parse
    ///   - configuration: Parsing configuration
    /// - Returns: Array of field values
    /// - Throws: CsvParserError if parsing fails
    public static func parseCSVLineAsync(
        _ csvLine: String,
        configuration: CsvConfiguration = CsvConfiguration()
    ) async throws -> [String] {
        return try await Task {
            try parseCSVLine(csvLine, configuration: configuration)
        }.value
    }
    
    /// Asynchronously parse CSV content
    /// - Parameters:
    ///   - csvContent: The complete CSV content
    ///   - configuration: Parsing configuration
    /// - Returns: Array of all rows
    /// - Throws: CsvParserError if parsing fails
    public static func parseCSVAsync(
        _ csvContent: String,
        configuration: CsvConfiguration = CsvConfiguration()
    ) async throws -> [[String]] {
        return try await Task {
            try parseCSV(csvContent, configuration: configuration)
        }.value
    }
    
    /// Asynchronously parse CSV from file with progress reporting
    /// - Parameters:
    ///   - path: Path to the CSV file
    ///   - configuration: Parsing configuration
    ///   - progressHandler: Called periodically with number of lines processed
    /// - Returns: Array of all rows
    /// - Throws: CsvParserError if parsing fails
    public static func parseFileAsync(
        path: String,
        configuration: CsvConfiguration = CsvConfiguration(),
        progressHandler: @escaping (Int) -> Void = { _ in }
    ) async throws -> [[String]] {
        let parser = try CsvParser(path: path, configuration: configuration)
        defer { parser.close() }
        
        return try await parser.parseAllAsync(progressHandler: progressHandler)
    }
    
    /// Asynchronously parse CSV from URL with progress reporting
    /// - Parameters:
    ///   - url: URL to the CSV resource
    ///   - configuration: Parsing configuration
    ///   - progressHandler: Called periodically with number of lines processed
    /// - Returns: Array of all rows
    /// - Throws: CsvParserError if parsing fails
    public static func parseURLAsync(
        url: URL,
        configuration: CsvConfiguration = CsvConfiguration(),
        progressHandler: @escaping (Int) -> Void = { _ in }
    ) async throws -> [[String]] {
        let parser = try CsvParser(url: url, configuration: configuration)
        defer { parser.close() }
        
        return try await parser.parseAllAsync(progressHandler: progressHandler)
    }
}

/// AsyncSequence support for streaming CSV parsing
public struct CsvAsyncSequence: AsyncSequence {
    public typealias Element = [String]
    
    private let parser: CsvParser
    
    init(parser: CsvParser) {
        self.parser = parser
    }
    
    public func makeAsyncIterator() -> CsvAsyncIterator {
        return CsvAsyncIterator(parser: parser)
    }
}

public struct CsvAsyncIterator: AsyncIteratorProtocol {
    public typealias Element = [String]
    
    private let parser: CsvParser
    
    init(parser: CsvParser) {
        self.parser = parser
    }
    
    public mutating func next() async throws -> [String]? {
        return try await parser.readLineAsync()
    }
}

extension CsvParser {
    /// Get an AsyncSequence for streaming parsing
    /// - Returns: AsyncSequence that yields each row as it's parsed
    public var asyncSequence: CsvAsyncSequence {
        return CsvAsyncSequence(parser: self)
    }
}
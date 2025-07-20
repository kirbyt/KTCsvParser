import Foundation

/// Sequence and Iterator conformance for CsvParser
extension CsvParser: Sequence {
    public func makeIterator() -> CsvIterator {
        return CsvIterator(parser: self)
    }
}

/// Iterator for CsvParser that enables for-in loops
public class CsvIterator: IteratorProtocol {
    public typealias Element = [String]
    
    private let parser: CsvParser
    private var hasStarted = false
    
    init(parser: CsvParser) {
        self.parser = parser
    }
    
    public func next() -> [String]? {
        do {
            // Ensure the parser is ready
            if !hasStarted {
                if !parser.reader.isOpen {
                    try parser.reader.open()
                }
                hasStarted = true
            }
            
            return try parser.readLine()
        } catch {
            // Iterator protocol doesn't support throwing, so we return nil on error
            // Users should use the throwing methods directly if they need error handling
            return nil
        }
    }
}

/// Collection-like utilities for working with CSV data
extension CsvParser {
    /// Get all rows as an array (convenience for Sequence conformance)
    /// - Returns: Array of all rows
    /// - Note: This will consume the entire stream. Use with caution on large files.
    public var allRows: [[String]] {
        return Array(self)
    }
    
    /// Check if the parser has more data to read
    /// - Returns: true if more data is available
    public var hasMoreData: Bool {
        return !reader.isAtEnd
    }
}

/// LazySequence support for memory-efficient processing
extension CsvParser {
    /// Get a lazy sequence for memory-efficient processing
    /// - Returns: LazySequence that processes rows on-demand
    public var lazySequence: LazySequence<CsvParser> {
        return self.lazy
    }
}

/// Functional programming support
extension CsvParser {
    /// Map each row through a transform function
    /// - Parameter transform: Function to transform each row
    /// - Returns: LazyMapSequence with transformed rows
    public func mapRows<T>(_ transform: @escaping ([String]) -> T) -> LazyMapSequence<CsvParser, T> {
        return self.lazy.map(transform)
    }
    
    /// Filter rows based on a predicate
    /// - Parameter predicate: Function to test each row
    /// - Returns: LazyFilterSequence with filtered rows
    public func filterRows(_ predicate: @escaping ([String]) -> Bool) -> LazyFilterSequence<CsvParser> {
        return self.lazy.filter(predicate)
    }
    
    /// Get the first N rows
    /// - Parameter count: Number of rows to take
    /// - Returns: Array with the first N rows
    public func prefixRows(_ count: Int) -> [[String]] {
        return Array(self.prefix(count))
    }
    
    /// Skip the first N rows
    /// - Parameter count: Number of rows to skip
    /// - Returns: Array with remaining rows
    public func dropFirstRows(_ count: Int = 1) -> [[String]] {
        return Array(self.dropFirst(count))
    }
}

/// Utility methods for common CSV operations
extension CsvParser {
    /// Get the header row (first row) and return a new parser for the data rows
    /// - Returns: Tuple containing the header and a new parser for data rows
    /// - Throws: CsvParserError if reading fails
    public func separateHeader() throws -> (header: [String], dataParser: CsvParser) {
        guard let header = try readLine() else {
            throw CsvParserError.streamError("No header row found")
        }
        
        // Create a new parser for the remaining data
        // Note: This is a simplified approach. In a real implementation,
        // you might want to create a new stream from the remaining data
        return (header: header, dataParser: self)
    }
    
    /// Convert rows to dictionaries using the first row as keys
    /// - Returns: Array of dictionaries where keys are column names
    /// - Throws: CsvParserError if reading fails
    public func parseAsDictionaries() throws -> [[String: String]] {
        guard let headerRow = try readLine() else {
            return []
        }
        
        var dictionaries: [[String: String]] = []
        
        while let row = try readLine() {
            var dict: [String: String] = [:]
            
            for (index, value) in row.enumerated() {
                let key = index < headerRow.count ? headerRow[index] : "column_\(index)"
                dict[key] = value
            }
            
            dictionaries.append(dict)
        }
        
        return dictionaries
    }
}

/// Convenience initializers that return configured sequences
extension CsvParser {
    /// Create a parser that skips empty rows
    /// - Parameters:
    ///   - data: CSV data
    ///   - configuration: Parsing configuration
    /// - Returns: Filtered sequence that skips empty rows
    public static func nonEmptyRows(
        data: Data,
        configuration: CsvConfiguration = CsvConfiguration()
    ) -> LazyFilterSequence<CsvParser> {
        let parser = CsvParser(data: data, configuration: configuration)
        return parser.lazy.filter { !$0.isEmpty && !$0.allSatisfy { $0.isEmpty } }
    }
    
    /// Create a parser that processes only rows with a minimum number of columns
    /// - Parameters:
    ///   - data: CSV data
    ///   - minimumColumns: Minimum number of columns required
    ///   - configuration: Parsing configuration
    /// - Returns: Filtered sequence with rows having minimum columns
    public static func rowsWithMinimumColumns(
        data: Data,
        minimumColumns: Int,
        configuration: CsvConfiguration = CsvConfiguration()
    ) -> LazyFilterSequence<CsvParser> {
        let parser = CsvParser(data: data, configuration: configuration)
        return parser.lazy.filter { $0.count >= minimumColumns }
    }
}
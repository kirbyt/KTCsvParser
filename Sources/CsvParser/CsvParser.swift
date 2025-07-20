import Foundation
import Observation

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Configuration for CSV parsing behavior
public struct CsvConfiguration {
    public let valueSeparator: Character
    public let quoteCharacter: Character?
    public let ignoreLeadingWhitespaces: Bool
    
    public init(
        valueSeparator: Character = ",",
        quoteCharacter: Character? = "\"",
        ignoreLeadingWhitespaces: Bool = false
    ) {
        self.valueSeparator = valueSeparator
        self.quoteCharacter = quoteCharacter
        self.ignoreLeadingWhitespaces = ignoreLeadingWhitespaces
    }
}

/// A CSV parser that reads comma-separated values from various data sources
@Observable
public class CsvParser {
    internal let reader: BufferedStreamReader
    private let configuration: CsvConfiguration
    private var nextCharacter: Character?
    private var currentFields: [String] = []
    
    /// Current parsing progress (number of lines processed)
    public private(set) var linesProcessed: Int = 0
    
    /// Current row being processed (for observation)
    public private(set) var currentRow: [String] = []
    
    /// Initialize parser with data
    /// - Parameters:
    ///   - data: The CSV data to parse
    ///   - configuration: Parsing configuration
    public convenience init(data: Data, configuration: CsvConfiguration = CsvConfiguration()) {
        let inputStream = InputStream(data: data)
        self.init(inputStream: inputStream, configuration: configuration)
    }
    
    /// Initialize parser with file path
    /// - Parameters:
    ///   - path: Path to the CSV file
    ///   - configuration: Parsing configuration
    public convenience init(path: String, configuration: CsvConfiguration = CsvConfiguration()) throws {
        guard let inputStream = InputStream(fileAtPath: path) else {
            throw CsvParserError.streamError("Unable to open file at path: \(path)")
        }
        self.init(inputStream: inputStream, configuration: configuration)
    }
    
    /// Initialize parser with URL
    /// - Parameters:
    ///   - url: URL to the CSV resource
    ///   - configuration: Parsing configuration
    public convenience init(url: URL, configuration: CsvConfiguration = CsvConfiguration()) throws {
        guard let inputStream = InputStream(url: url) else {
            throw CsvParserError.streamError("Unable to open URL: \(url)")
        }
        self.init(inputStream: inputStream, configuration: configuration)
    }
    
    /// Initialize parser with input stream
    /// - Parameters:
    ///   - inputStream: The input stream to read from
    ///   - configuration: Parsing configuration
    public init(inputStream: InputStream, configuration: CsvConfiguration = CsvConfiguration()) {
        self.reader = BufferedStreamReader(inputStream: inputStream)
        self.configuration = configuration
    }
    
    /// Read the next character from the stream
    /// - Returns: The character read, or nil if at end
    private func readNextCharacter() throws -> Character? {
        if let queued = nextCharacter {
            nextCharacter = nil
            return queued
        }
        return try reader.readCharacter()
    }
    
    /// Check if we're at the end of the stream
    private var isAtEnd: Bool {
        return nextCharacter == nil && reader.isAtEnd
    }
    
    /// Check if we're at the end of a line
    /// - Returns: true if at end of line or end of stream
    private func isEndOfLine() throws -> Bool {
        if isAtEnd { return true }
        
        // Peek at the next character without consuming it
        if nextCharacter == nil {
            nextCharacter = try reader.readCharacter()
        }
        
        guard let char = nextCharacter else { return true }
        return char == "\r" || char == "\n"
    }
    
    /// Skip newline characters (\r, \n, or \r\n)
    private func skipNewLineCharacters() throws {
        guard !reader.isAtEnd else { return }
        
        let firstChar = try readNextCharacter()
        if firstChar == "\r" {
            // Check for \r\n sequence
            if let secondChar = try reader.readCharacter(), secondChar != "\n" {
                nextCharacter = secondChar
            }
        }
        // If it was just \n, we've already consumed it
    }
    
    /// Parse a line from the reader using the state machine
    private func readLineFromReader() throws {
        var state = ParserState.unknown
        var field = ""
        
        while !isAtEnd {
            let endOfLine = try isEndOfLine()
            if endOfLine && state.allowsEndOfLine { break }
            guard let character = try readNextCharacter() else { break }
            
            switch state {
            case .unknown:
                field = ""
                if let quote = configuration.quoteCharacter, character == quote {
                    state = .continueWithEmbeddedQuotesOrCommas
                } else if character == configuration.valueSeparator {
                    // Empty field
                    currentFields.append(field)
                    if try isEndOfLine() {
                        currentFields.append("")
                    }
                } else if configuration.ignoreLeadingWhitespaces && character.isWhitespace {
                    // Skip leading whitespace
                } else {
                    // Start of regular field
                    field.append(character)
                    state = .continueWithRegularField
                    if try isEndOfLine() {
                        currentFields.append(field)
                    }
                }
                
            case .continueWithRegularField:
                if character == configuration.valueSeparator {
                    currentFields.append(field)
                    if try isEndOfLine() {
                        currentFields.append("")
                    } else {
                        state = .unknown
                    }
                } else {
                    field.append(character)
                    if try isEndOfLine() {
                        currentFields.append(field)
                    }
                }
                
            case .continueWithEmbeddedQuotesOrCommas:
                if let quote = configuration.quoteCharacter, character == quote {
                    if try !isEndOfLine() {
                        if let next = nextCharacter, next == configuration.valueSeparator {
                            // End of quoted field
                            state = .continueWithRegularField
                        } else {
                            state = .beginningOfEmbeddedQuotes
                        }
                    } else {
                        // End of value at end of line
                        currentFields.append(field)
                        state = .unknown
                    }
                } else {
                    field.append(character)
                }
                
            case .beginningOfEmbeddedQuotes:
                if let quote = configuration.quoteCharacter, character == quote {
                    // Escaped quote
                    field.append(character)
                    state = .continueWithEmbeddedQuotesOrCommas
                } else {
                    // The field has embedded quotes but isn't fully quoted
                    if try !isEndOfLine() {
                        state = .continueWithRegularField
                        if let quote = configuration.quoteCharacter {
                            field = "\(quote)\(field)\(quote)\(character)"
                        }
                    }
                }
            }
        }
        
        try skipNewLineCharacters()
    }
    
    /// Read the next line from the CSV
    /// - Returns: Array of field values, or nil if at end of file
    /// - Throws: CsvParserError if parsing fails
    public func readLine() throws -> [String]? {
        currentFields.removeAll()
        
        if !reader.isOpen {
            try reader.open()
        }
        
        guard !isAtEnd else { return nil }
        
        try readLineFromReader()
        linesProcessed += 1
        currentRow = currentFields
        
        return currentFields.isEmpty ? nil : currentFields
    }
    
    /// Parse all lines and return as an array
    /// - Returns: Array of all rows, where each row is an array of field values
    /// - Throws: CsvParserError if parsing fails
    public func parseAll() throws -> [[String]] {
        var allRows: [[String]] = []
        
        while let row = try readLine() {
            allRows.append(row)
        }
        
        return allRows
    }
    
    /// Close the parser and underlying stream
    public func close() {
        reader.close()
    }
    
    deinit {
        close()
    }
}

// MARK: - Static Convenience Methods

extension CsvParser {
    /// Parse a single CSV line string
    /// - Parameters:
    ///   - csvLine: The CSV line to parse
    ///   - configuration: Parsing configuration
    /// - Returns: Array of field values
    /// - Throws: CsvParserError if parsing fails
    public static func parseCSVLine(
        _ csvLine: String,
        configuration: CsvConfiguration = CsvConfiguration()
    ) throws -> [String] {
        let data = csvLine.data(using: .utf8) ?? Data()
        let parser = CsvParser(data: data, configuration: configuration)
        return try parser.readLine() ?? []
    }
    
    /// Parse CSV string content
    /// - Parameters:
    ///   - csvContent: The complete CSV content as a string
    ///   - configuration: Parsing configuration
    /// - Returns: Array of all rows
    /// - Throws: CsvParserError if parsing fails
    public static func parseCSV(
        _ csvContent: String,
        configuration: CsvConfiguration = CsvConfiguration()
    ) throws -> [[String]] {
        let data = csvContent.data(using: .utf8) ?? Data()
        let parser = CsvParser(data: data, configuration: configuration)
        return try parser.parseAll()
    }
}
import Foundation

/// Result types for CSV parsing operations
public typealias CsvParseResult<T> = Result<T, CsvParserError>

/// Extension to provide convenient Result-based parsing methods
extension CsvParser {
    /// Read the next line safely, returning a Result
    /// - Returns: Result containing the field array or an error
    public func readLineSafely() -> CsvParseResult<[String]?> {
        do {
            let result = try readLine()
            return .success(result)
        } catch let error as CsvParserError {
            return .failure(error)
        } catch {
            return .failure(.streamError(error.localizedDescription))
        }
    }
    
    /// Parse all lines safely, returning a Result
    /// - Returns: Result containing all rows or an error
    public func parseAllSafely() -> CsvParseResult<[[String]]> {
        do {
            let result = try parseAll()
            return .success(result)
        } catch let error as CsvParserError {
            return .failure(error)
        } catch {
            return .failure(.streamError(error.localizedDescription))
        }
    }
}

/// Static Result-based convenience methods
extension CsvParser {
    /// Parse a single CSV line safely
    /// - Parameters:
    ///   - csvLine: The CSV line to parse
    ///   - configuration: Parsing configuration
    /// - Returns: Result containing the field array or an error
    public static func parseCSVLineSafely(
        _ csvLine: String,
        configuration: CsvConfiguration = CsvConfiguration()
    ) -> CsvParseResult<[String]> {
        do {
            let result = try parseCSVLine(csvLine, configuration: configuration)
            return .success(result)
        } catch let error as CsvParserError {
            return .failure(error)
        } catch {
            return .failure(.streamError(error.localizedDescription))
        }
    }
    
    /// Parse CSV content safely
    /// - Parameters:
    ///   - csvContent: The complete CSV content
    ///   - configuration: Parsing configuration
    /// - Returns: Result containing all rows or an error
    public static func parseCSVSafely(
        _ csvContent: String,
        configuration: CsvConfiguration = CsvConfiguration()
    ) -> CsvParseResult<[[String]]> {
        do {
            let result = try parseCSV(csvContent, configuration: configuration)
            return .success(result)
        } catch let error as CsvParserError {
            return .failure(error)
        } catch {
            return .failure(.streamError(error.localizedDescription))
        }
    }
}
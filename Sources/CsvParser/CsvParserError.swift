import Foundation

/// Errors that can occur during CSV parsing
public enum CsvParserError: Error, LocalizedError {
    case streamError(String)
    case encodingError
    case bufferOverflow
    case invalidConfiguration(String)
    
    public var errorDescription: String? {
        switch self {
        case .streamError(let message):
            return "Stream error: \(message)"
        case .encodingError:
            return "Character encoding error occurred while parsing"
        case .bufferOverflow:
            return "Buffer overflow - data exceeds maximum buffer size"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        }
    }
}
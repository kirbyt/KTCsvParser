import Foundation

/// States for the CSV parser state machine
internal enum ParserState {
    case unknown
    case continueWithRegularField
    case continueWithEmbeddedQuotesOrCommas
    case beginningOfEmbeddedQuotes
    
    /// Check if the state allows processing end-of-line
    var allowsEndOfLine: Bool {
        switch self {
        case .continueWithEmbeddedQuotesOrCommas:
            return false
        default:
            return true
        }
    }
}
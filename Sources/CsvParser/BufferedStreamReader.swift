import Foundation

/// A buffered stream reader that efficiently reads UTF-8 encoded text from an InputStream
internal class BufferedStreamReader {
    private static let maxBufferSize = 1024
    
    private let inputStream: InputStream
    private var buffer = Data()
    private var position = 0
    private var isStreamOpen = false
    
    /// Initialize with an input stream
    /// - Parameter inputStream: The stream to read from
    init(inputStream: InputStream) {
        self.inputStream = inputStream
    }
    
    /// Open the underlying input stream
    func open() throws {
        guard !isStreamOpen else { return }
        
        inputStream.open()
        isStreamOpen = true
        
        if inputStream.streamStatus == .error {
            throw CsvParserError.streamError("Failed to open input stream")
        }
    }
    
    /// Close the underlying input stream
    func close() {
        guard isStreamOpen else { return }
        
        inputStream.close()
        isStreamOpen = false
    }
    
    /// Check if the stream is open
    var isOpen: Bool {
        return isStreamOpen
    }
    
    /// Check if we've reached the end of the stream
    var isAtEnd: Bool {
        return position >= buffer.count && !inputStream.hasBytesAvailable
    }
    
    /// Fill the internal buffer with data from the stream
    /// - Returns: true if data was read, false if at end of stream
    private func fillBuffer() throws -> Bool {
        guard inputStream.hasBytesAvailable else { return false }
        
        var tempBuffer = [UInt8](repeating: 0, count: Self.maxBufferSize)
        let bytesRead = inputStream.read(&tempBuffer, maxLength: Self.maxBufferSize)
        
        if bytesRead < 0 {
            throw CsvParserError.streamError("Error reading from input stream")
        }
        
        if bytesRead > 0 {
            buffer.append(contentsOf: tempBuffer[0..<bytesRead])
            return true
        }
        
        return false
    }
    
    /// Read a single character from the stream
    /// - Returns: The character read, or nil if at end of stream
    /// - Throws: CsvParserError if reading fails
    func readCharacter() throws -> Character? {
        // Ensure we have data available
        while position >= buffer.count && inputStream.hasBytesAvailable {
            let didRead = try fillBuffer()
            if !didRead { break }
        }
        
        // Check if we're at the end
        guard position < buffer.count else { return nil }
        
        // Find the end of the current UTF-8 character
        let startPosition = position
        var endPosition = startPosition + 1
        
        // Handle multi-byte UTF-8 characters
        while endPosition < buffer.count {
            let byte = buffer[endPosition]
            // If this is not a continuation byte (0x80-0xBF), we've found the end
            if (byte & 0xC0) != 0x80 {
                break
            }
            endPosition += 1
        }
        
        // If we need more data for a complete character, try to read more
        if endPosition >= buffer.count && inputStream.hasBytesAvailable {
            let didRead = try fillBuffer()
            if didRead {
                // Retry finding the character boundary
                while endPosition < buffer.count {
                    let byte = buffer[endPosition]
                    if (byte & 0xC0) != 0x80 {
                        break
                    }
                    endPosition += 1
                }
            }
        }
        
        // Extract the character bytes
        let characterData = buffer.subdata(in: startPosition..<min(endPosition, buffer.count))
        
        // Convert to string and extract character
        guard let string = String(data: characterData, encoding: .utf8),
              let character = string.first else {
            throw CsvParserError.encodingError
        }
        
        // Advance position by the number of bytes consumed
        position = min(endPosition, buffer.count)
        
        return character
    }
    
    /// Read up to maxLength characters from the stream
    /// - Parameter maxLength: Maximum number of characters to read
    /// - Returns: The string read
    /// - Throws: CsvParserError if reading fails
    func read(maxLength: Int) throws -> String {
        var result = ""
        
        for _ in 0..<maxLength {
            guard let character = try readCharacter() else { break }
            result.append(character)
        }
        
        return result
    }
}
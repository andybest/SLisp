/*
 
 MIT License
 
 Copyright (c) 2016 Andy Best
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

import Foundation

public struct TokenPosition {
    let line: Int
    let column: Int
    let source: String
    
    var sourceLine: String {
        return String(source.split(separator: "\n")[line])
    }
    
    var tokenMarker: String {
        // Creates a "^" marker underneath the source line pointing to the token
        var output = ""
        
        // Add marker at appropriate column
        for _ in 0..<(column - 1) {
            output += " "
        }
        
        output += "^"
        return output
    }
}

public enum TokenType {
    case lParen(TokenPosition)
    case rParen(TokenPosition)
    case lBrace(TokenPosition)
    case rBrace(TokenPosition)
    case symbol(TokenPosition, String)
    case float(TokenPosition, Double)
    case integer(TokenPosition, Int)
    case string(TokenPosition, String)
}

public func ==(a: TokenType, b: TokenType) -> Bool {
    switch (a, b) {
    case (.lParen, .lParen): return true
    case (.rParen, .rParen): return true
    case (.symbol(_, let a), .symbol(_, let b)) where a == b: return true
    case (.float(_, let a), .float(_, let b)) where a == b: return true
    case (.integer(_, let a), .integer(_, let b)) where a == b: return true
    case (.string(_, let a), .string(_, let b)) where a == b: return true
    default: return false
    }
}

protocol TokenMatcher {
    static func isMatch(_ stream:StringStream) -> Bool
    static func getToken(_ stream:StringStream) throws -> TokenType?
}

func characterIsInSet(_ c: Character, set: CharacterSet) -> Bool {
    var found = true
    for ch in String(c).utf16 {
        if !set.contains(UnicodeScalar(ch)!) {
            found = false
        }
    }
    return found
}

func isWhitespace(_ c: Character) -> Bool {
    return characterIsInSet(c, set: CharacterSet.whitespacesAndNewlines)
}

class LParenTokenMatcher: TokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == "("
    }
    
    static func getToken(_ stream: StringStream) -> TokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return TokenType.lParen(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class RParenTokenMatcher: TokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == ")"
    }
    
    static func getToken(_ stream: StringStream) -> TokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return TokenType.rParen(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class LBraceTokenMatcher: TokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == "{"
    }
    
    static func getToken(_ stream: StringStream) -> TokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return TokenType.lBrace(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class RBraceTokenMatcher: TokenMatcher {
    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == "}"
    }
    
    static func getToken(_ stream: StringStream) -> TokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            return TokenType.rBrace(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str))
        }
        return nil
    }
}

class SymbolMatcher: TokenMatcher {
    static var matcherCharacterSet: NSMutableCharacterSet?
    static var matcherStartCharacterSet: NSMutableCharacterSet?

    static func isMatch(_ stream: StringStream) -> Bool {
        return characterIsInSet(stream.currentCharacter!, set: startCharacterSet())
    }
    
    static func getToken(_ stream: StringStream) -> TokenType? {
        if isMatch(stream) {
            var tok = ""
            
            while characterIsInSet(stream.currentCharacter!, set: characterSet()) {
                tok += String(stream.currentCharacter!)
                stream.advanceCharacter()
                if stream.currentCharacter == nil {
                    break
                }
            }
            
            return TokenType.symbol(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str), tok)
        }
        return nil
    }
    
    static func characterSet() -> CharacterSet {
        if matcherCharacterSet == nil {
            matcherCharacterSet = NSMutableCharacterSet.letter()
            matcherCharacterSet!.formUnion(with: CharacterSet.decimalDigits)
            matcherCharacterSet!.formUnion(with: CharacterSet.punctuationCharacters)
            matcherCharacterSet!.formUnion(with: NSMutableCharacterSet.symbol() as CharacterSet)
            matcherCharacterSet!.removeCharacters(in: "(){};")
        }
        return matcherCharacterSet! as CharacterSet
    }

    static func startCharacterSet() -> CharacterSet {
        if matcherStartCharacterSet == nil {
            matcherStartCharacterSet = NSMutableCharacterSet.letter()
            matcherStartCharacterSet!.formUnion(with: CharacterSet.punctuationCharacters)
            matcherStartCharacterSet!.formUnion(with: NSMutableCharacterSet.symbol() as CharacterSet)
            matcherStartCharacterSet!.removeCharacters(in: "(){};")
        }
        return matcherStartCharacterSet! as CharacterSet
    }
}

class StringMatcher: TokenMatcher {
    static var matcherCharacterSet: NSMutableCharacterSet?

    static func isMatch(_ stream: StringStream) -> Bool {
        return stream.currentCharacter == "\""
    }
    
    static func getToken(_ stream: StringStream) throws -> TokenType? {
        if isMatch(stream) {
            stream.advanceCharacter()
            
            var tok = ""
            
            while stream.currentCharacter != nil && !isMatch(stream) {
                let char = stream.currentCharacter!
                
                // Check for escapes
                if char == "\\" {
                    stream.advanceCharacter()
                    
                    guard let escapeChar = stream.currentCharacter else {
                        let pos = TokenPosition(line: stream.currentLine, column: stream.currentColumn + 1, source: stream.str)
                        let msg = """
                        \(pos.line):\(pos.column): Expected escape character:
                            \(pos.sourceLine)
                            \(pos.tokenMarker)
                        """
                        throw LispError.lexer(msg: msg)
                    }
                    
                    let escapeResult: String
                    
                    switch escapeChar {
                    case "n":
                        escapeResult = "\n"
                    case "t":
                        escapeResult = "\t"
                    case "x":
                        stream.advanceCharacter()
                        guard let h1 = stream.currentCharacter else {
                            throw LispError.lexer(msg: "Error in string: unexpected EOF")
                        }
                        
                        stream.advanceCharacter()
                        guard let h2 = stream.currentCharacter else {
                            throw LispError.lexer(msg: "Error in string: unexpected EOF")
                        }
                        
                        guard let hexValue = UInt8(String([h1, h2]), radix: 16) else {
                            throw LispError.lexer(msg: "Error in string: invalid hex escape sequence: \(String([h1, h2]))")
                        }
                        escapeResult = String(Character(UnicodeScalar(hexValue)))
                    case "\"":
                        escapeResult = "\""
                        
                    default:
                        let pos = TokenPosition(line: stream.currentLine, column: stream.currentColumn + 1, source: stream.str)
                        let msg = """
                        \(pos.line):\(pos.column): Unknown escape character in string: \\\(escapeChar)
                            \(pos.sourceLine)
                            \(pos.tokenMarker)
                        """
                        throw LispError.lexer(msg: msg)
                    }
                    
                    tok += escapeResult
                    stream.advanceCharacter()
                    
                } else {
                    tok += String(char)
                    stream.advanceCharacter()
                }
            }
            
            if stream.currentCharacter != "\"" {
                throw LispError.lexer(msg: "Expected '\"'")
            }
            
            stream.advanceCharacter()
            
            return TokenType.string(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str), tok)
        }
        
        return nil
    }
    
    static func characterSet() -> CharacterSet {
        if matcherCharacterSet == nil {
            matcherCharacterSet = NSMutableCharacterSet.letter()
            matcherCharacterSet!.formUnion(with: CharacterSet.decimalDigits)

            let allowedSymbols = NSMutableCharacterSet.symbol()
            allowedSymbols.formIntersection(with:CharacterSet(charactersIn: "\""))

            matcherCharacterSet!.formUnion(with: allowedSymbols as CharacterSet)
        }
        return matcherCharacterSet! as CharacterSet
    }
}

class NumberMatcher: TokenMatcher {
    static var matcherCharacterSet: NSMutableCharacterSet?
    static var matcherStartCharacterSet: NSMutableCharacterSet?

    static func isMatch(_ stream: StringStream) -> Bool {
        var matches: Bool
        if stream.currentCharacter! == "-" {
            if let next = stream.nextCharacter {
                matches = characterIsInSet(next, set: characterSet())
            } else {
                return false
            }
        } else {
            matches = characterIsInSet(stream.currentCharacter!, set: startCharacterSet())
        }
        return matches
    }
    
    static func getToken(_ stream: StringStream) throws -> TokenType? {
        if isMatch(stream) {
            var tok = ""
            
            tok += String(stream.currentCharacter!)
            stream.advanceCharacter()
            
            while stream.currentCharacter != nil &&
                characterIsInSet(stream.currentCharacter!, set: characterSet()) {
                tok += String(stream.currentCharacter!)
                stream.advanceCharacter()
            }
            
            if tok.contains(".") {
                guard let num = Double(tok) else {
                    throw LispError.lexer(msg: "\(tok) is not a valid floating point number.")
                }
                return TokenType.float(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str), num)
            } else {
                guard let num = Int(tok) else {
                    throw LispError.lexer(msg: "\(tok) is not a valid number.")
                }
                return TokenType.integer(TokenPosition(line: stream.currentLine, column: stream.currentColumn, source: stream.str), num)
            }
            
        }
        
        return nil
    }

    static func characterSet() -> CharacterSet {
        if matcherCharacterSet == nil {
            matcherCharacterSet = NSMutableCharacterSet(charactersIn: "0123456789.")
        }
        return matcherCharacterSet! as CharacterSet
    }
    
    static func startCharacterSet() -> CharacterSet {
        if matcherStartCharacterSet == nil {
            matcherStartCharacterSet = NSMutableCharacterSet(charactersIn: "-0123456789.")
        }
        return matcherStartCharacterSet! as CharacterSet
    }
}

// Token matchers in order
let tokenClasses: [TokenMatcher.Type] = [
        LParenTokenMatcher.self,
        RParenTokenMatcher.self,
        LBraceTokenMatcher.self,
        RBraceTokenMatcher.self,
        NumberMatcher.self,
        StringMatcher.self,
        SymbolMatcher.self,
]

class StringStream {
    var str: String
    var position = 0
    var currentCharacter: Character?
    var nextCharacter: Character?
    var currentCharacterIdx: String.Index
    var nextCharacterIdx: String.Index?
    var characterCount: Int
    
    var currentLine: Int
    var currentColumn: Int

    init(source: String) {
        str = source
        characterCount = str.count
        position = 0
        currentCharacterIdx = str.startIndex
        nextCharacterIdx = str.index(after: currentCharacterIdx)
        currentCharacter = str.characters[currentCharacterIdx]
        
        currentLine = 0
        currentColumn = 0
        
        if str.count > 1 {
            nextCharacter = str[nextCharacterIdx!]
        }
    }

    func advanceCharacter() {
        if currentCharacter != nil && currentCharacter! == "\n" {
            currentLine += 1
            currentColumn = 0
        } else {
            currentColumn += 1
        }
        
        position += 1
        
        if position >= characterCount
        {
            currentCharacter = nil
            nextCharacter = nil
            return
        }
        
        currentCharacterIdx = nextCharacterIdx!
        currentCharacter = str[currentCharacterIdx]
        
        if position >= characterCount - 1 {
            nextCharacter = nil
        } else {
            nextCharacterIdx = str.index(after: currentCharacterIdx)
            nextCharacter = str[nextCharacterIdx!]
        }
    }

    func eatWhitespace() -> Int {
        var count = 0
        while position < characterCount {
            if isWhitespace(currentCharacter!) {
                advanceCharacter()
                count += 1
            } else {
                return count
            }
        }
        return count
    }

    func rewind() {
        position = 0
        
        currentCharacterIdx = str.startIndex
        nextCharacterIdx = str.index(after: currentCharacterIdx)
        currentCharacter = str.characters[currentCharacterIdx]
        
        if str.count > 1 {
            nextCharacter = str[nextCharacterIdx!]
        }
    }
}

class Tokenizer {
    let stream: StringStream
    var currentTokenMatcher: TokenMatcher.Type? = nil
    var currentTokenString: String

    init(source: String) {
        self.stream = StringStream(source: source)
        self.currentTokenString = ""
    }

    func tokenizeInput() throws -> [TokenType] {
        var tokens = [TokenType]()
        
        while let t = try getNextToken() {
            tokens.append(t)
        }
        
        return tokens
    }
    
    func getNextToken() throws -> TokenType? {
        if stream.position >= stream.str.count {
            return nil
        }
        
        for matcher in tokenClasses {
            if matcher.isMatch(stream) {
                return try matcher.getToken(stream)
            }
        }
        
        let count = stream.eatWhitespace()
        
        if stream.position >= stream.str.count {
            return nil
        }
        
        if stream.currentCharacter == ";" {
            while stream.currentCharacter != "\n" {
                if stream.position >= stream.str.count {
                    return nil
                }
                stream.advanceCharacter()
            }
            stream.advanceCharacter()
            
            if stream.position >= stream.str.count {
                return nil
            }
        } else {
            if count == 0 {
                let pos = TokenPosition(line: stream.currentLine, column: stream.currentColumn + 1, source: stream.str)
                let msg = """
                    \(pos.line):\(pos.column): Unrecognized character '\(stream.currentCharacter ?? " ".first!)':
                    \t\(pos.sourceLine)
                    \t\(pos.tokenMarker)
                    """
                throw LispError.lexer(msg: msg)
            }
        }
        
        return try getNextToken()
    }
}

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


public enum TokenType: Equatable {
    case lParen
    case rParen
    case symbol(String)
    case float(Double)
    case integer(Int)
    case string(String)
}

public func ==(a: TokenType, b: TokenType) -> Bool {
    switch (a, b) {
    case (.lParen, .lParen): return true
    case (.rParen, .rParen): return true
    case (.symbol(let a), .symbol(let b)) where a == b: return true
    case (.float(let a), .float(let b)) where a == b: return true
    case (.integer(let a), .integer(let b)) where a == b: return true
    case (.string(let a), .string(let b)) where a == b: return true
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
            return TokenType.lParen
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
            return TokenType.rParen
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
            
            return TokenType.symbol(tok)
        }
        return nil
    }
    
    static func characterSet() -> CharacterSet {
        if matcherCharacterSet == nil {
            matcherCharacterSet = NSMutableCharacterSet.letter()
            matcherCharacterSet!.formUnion(with: CharacterSet.decimalDigits)
            matcherCharacterSet!.formUnion(with: CharacterSet.punctuationCharacters)
            matcherCharacterSet!.formUnion(with: NSMutableCharacterSet.symbol() as CharacterSet)
            matcherCharacterSet!.removeCharacters(in: "();")
        }
        return matcherCharacterSet! as CharacterSet
    }

    static func startCharacterSet() -> CharacterSet {
        if matcherStartCharacterSet == nil {
            matcherStartCharacterSet = NSMutableCharacterSet.letter()
            matcherStartCharacterSet!.formUnion(with: CharacterSet.punctuationCharacters)
            matcherStartCharacterSet!.formUnion(with: NSMutableCharacterSet.symbol() as CharacterSet)
            matcherStartCharacterSet!.removeCharacters(in: "();")
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
                tok += String(stream.currentCharacter!)
                stream.advanceCharacter()
            }
            
            if stream.currentCharacter != "\"" {
                throw LispError.lexer(msg: "Expected '\"'")
            }
            
            stream.advanceCharacter()
            
            return TokenType.string(tok)
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
                return TokenType.float(num)
            } else {
                guard let num = Int(tok) else {
                    throw LispError.lexer(msg: "\(tok) is not a valid number.")
                }
                return TokenType.integer(num)
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

    init(source: String) {
        str = source
        characterCount = str.count
        position = 0
        currentCharacterIdx = str.startIndex
        nextCharacterIdx = str.index(after: currentCharacterIdx)
        currentCharacter = str.characters[currentCharacterIdx]
        
        if str.count > 1 {
            nextCharacter = str[nextCharacterIdx!]
        }
    }

    func advanceCharacter() {
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
                throw LispError.lexer(msg: "Unrecognized character '\(stream.currentCharacter ?? " ".first!)'")
            }
        }
        
        return try getNextToken()
    }

}

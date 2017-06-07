/*
 
 MIT License
 
 Copyright (c) 2017 Andy Best
 
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


import XCTest
@testable import SLispCore

class LexerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStringStreamInit() {
        let source = "Test"
        let sstream = StringStream(source: source)
        XCTAssertEqual(sstream.str, source, "Source string must be equal to the provided string")
        
        XCTAssertEqual(sstream.currentCharacter, source.first)
        XCTAssertEqual(sstream.nextCharacter, "e".first)
    }
    
    func testStringStreamAdvanceCharacter() {
        let source = "Test"
        let sstream = StringStream(source:source)
        sstream.advanceCharacter()
        
        XCTAssertEqual(sstream.currentCharacter, "e".first)
        XCTAssertEqual(sstream.nextCharacter, "s".first)
    }
    
    func testStringStreamEatWhiteSpace() {
        let source = "  \t\nTest"
        let sstream = StringStream(source: source)
        let whitespaceCount = sstream.eatWhitespace()
        
        XCTAssertEqual(whitespaceCount, 4)
        XCTAssertEqual(sstream.currentCharacter, "T".first)
        XCTAssertEqual(sstream.nextCharacter, "e".first)
    }
    
    func testStringStreamRewind() {
        let source = "Test"
        let sstream = StringStream(source: source)
        sstream.advanceCharacter()
        sstream.advanceCharacter()
        sstream.rewind()
        
        XCTAssertEqual(sstream.currentCharacter, source.first)
        XCTAssertEqual(sstream.nextCharacter, "e".first)
    }
    
    func testStringStreamEnd() {
        let source = "Test"
        let sstream = StringStream(source: source)
        sstream.advanceCharacter()
        sstream.advanceCharacter()
        sstream.advanceCharacter()
        
        XCTAssertNil(sstream.nextCharacter)
        
        sstream.advanceCharacter()
        XCTAssertNil(sstream.currentCharacter)
        XCTAssertNil(sstream.nextCharacter)
    }
    
    func testLParenTokenMatcher() {
        let source = "()"
        let sstream = StringStream(source: source)
        
        XCTAssertTrue(LParenTokenMatcher.isMatch(sstream))
        XCTAssertEqual(LParenTokenMatcher.getToken(sstream), TokenType.lParen)
        
        XCTAssertFalse(LParenTokenMatcher.isMatch(sstream))
        XCTAssertNil(LParenTokenMatcher.getToken(sstream))
    }
    
    func testRParenTokenMatcher() {
        let source = ")("
        let sstream = StringStream(source: source)
        
        XCTAssertTrue(RParenTokenMatcher.isMatch(sstream))
        XCTAssertEqual(RParenTokenMatcher.getToken(sstream), TokenType.rParen)
        
        XCTAssertFalse(RParenTokenMatcher.isMatch(sstream))
        XCTAssertNil(RParenTokenMatcher.getToken(sstream))
    }
    
    func testSymbolMatcher() {
        let symbolSource = "thisIsASymbol+-=@$%*^"
        let symbolStream = StringStream(source: symbolSource)
        
        XCTAssertTrue(SymbolMatcher.isMatch(symbolStream))
        XCTAssertEqual(SymbolMatcher.getToken(symbolStream), TokenType.symbol(symbolSource))
        
        let notSymbolSource = "12345"
        let notSymbolStream = StringStream(source: notSymbolSource)
        
        XCTAssertFalse(SymbolMatcher.isMatch(notSymbolStream))
        XCTAssertNil(SymbolMatcher.getToken(notSymbolStream))
    }
    
    func testStringMatcher() {
        // Valid String
        let stringSource = "\"This is a string\""
        let stringStream = StringStream(source: stringSource)
        
        XCTAssertTrue(StringMatcher.isMatch(stringStream))
        do {
            let result = try StringMatcher.getToken(stringStream)
            XCTAssertEqual(result, TokenType.string("This is a string"))
        } catch {
            XCTFail("Should not throw an exception")
        }
        
        // Not a String
        let notStringSource = "This is not a string"
        let notStringStream = StringStream(source: notStringSource)
        
        XCTAssertFalse(StringMatcher.isMatch(notStringStream))
        do {
            let result = try StringMatcher.getToken(notStringStream)
            XCTAssertNil(result)
        } catch {
            XCTFail("Should not throw an exception")
        }
        
        // Invalid String
        let invalidStringSource = "\"Invalid string"
        let invalidStringStream = StringStream(source: invalidStringSource)
        
        var invalidStringThrow = false
        do {
            _ = try StringMatcher.getToken(invalidStringStream)
            XCTFail("Should throw an exception")
        } catch {
            invalidStringThrow = true
        }
        
        XCTAssertTrue(invalidStringThrow, "Should throw an exception")
    }
    
    func testNumberMatcher() {
        // Integer
        let intSource = "12345"
        let intStream = StringStream(source: intSource)
        
        XCTAssertTrue(NumberMatcher.isMatch(intStream))
        
        do {
            let result = try NumberMatcher.getToken(intStream)
            XCTAssertEqual(result, TokenType.integer(12345))
        } catch {
            XCTFail("Should not throw an exception")
        }
        
        // Floating point
        let floatSource = "12345.12345"
        let floatStream = StringStream(source: floatSource)
        
        XCTAssertTrue(NumberMatcher.isMatch(floatStream))
        
        do {
            let result = try NumberMatcher.getToken(floatStream)
            XCTAssertEqual(result, TokenType.float(12345.12345))
        } catch {
            XCTFail("Should not throw an exception")
        }
        
        // Invalid floating point syntax
        let notFloatSource = "12345.12345.12345"
        let notFloatStream = StringStream(source: notFloatSource)
        
        var notFloatThrew = false
        do {
            _ = try NumberMatcher.getToken(notFloatStream)
            XCTFail("Should throw an exception")
        } catch {
            notFloatThrew = true
        }
        
        XCTAssertTrue(notFloatThrew, "Should throw an exception")
        
        // Not a number
        let notNumberSource = "This is not a number"
        let notNumberStream = StringStream(source: notNumberSource)
        
        XCTAssertFalse(NumberMatcher.isMatch(notNumberStream))
        
        do {
            let result = try NumberMatcher.getToken(notNumberStream)
            XCTAssertNil(result)
        } catch {
            XCTFail("Should not throw an exception")
        }
    }
    
    func testTokensCorrect(source: String) -> [TokenType] {
        let tokenizer = Tokenizer(source: source)
        do {
            let result = try tokenizer.tokenizeInput()
            return result
        } catch {
            XCTFail("Should not throw an exception")
        }
        
        return []
    }
    
    func testTokenizerInput() {
        XCTAssertEqual(testTokensCorrect(source: "()"), [TokenType.lParen, TokenType.rParen])
        XCTAssertEqual(testTokensCorrect(source: "(test 1234 1234.1234 \"Hello\")"),
                       [TokenType.lParen,
                        TokenType.symbol("test"),
                        TokenType.integer(1234),
                        TokenType.float(1234.1234),
                        TokenType.string("Hello"),
                        TokenType.rParen])
        
        // Test case from Rosetta Code:
        // https://rosettacode.org/wiki/S-Expressions
        XCTAssertEqual(testTokensCorrect(source: "((data \"quoted data\" 123 4.5)\n\t\t(data (!@# (4.5) \"(more\" \"data)\")))"), [
                TokenType.lParen,           TokenType.lParen,
                TokenType.symbol("data"),   TokenType.string("quoted data"),
                TokenType.integer(123),     TokenType.float(4.5),
                TokenType.rParen,           TokenType.lParen,
                TokenType.symbol("data"),   TokenType.lParen,
                TokenType.symbol("!@#"),    TokenType.lParen,
                TokenType.float(4.5),       TokenType.rParen,
                TokenType.string("(more"),  TokenType.string("data)"),
                TokenType.rParen,           TokenType.rParen,
                TokenType.rParen
            ])
    }

}

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
        XCTAssertTrue(sstream.str == source, "Source string must be equal to the provided string")
        
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

}

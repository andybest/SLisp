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

import Foundation

class Repl {

    var environment: Environment

    init?() throws {
        environment = try Environment()!
    }

    func mainLoop() {
        while true {
            Swift.print("user> ", terminator: "")

            if let input: String = readLine(strippingNewline: true), input.characters.count > 0 {
                Swift.print(rep(input))
            }
        }
    }

    func print() {

    }

    func rep(_ input: String) -> String {

        do {
            let form = try Reader.read(input)
            let rv   = try environment.eval(form)
            return String(describing: rv)

        } catch let LispError.runtime(msg:message) {
            return "Runtime Error: \(message)"
        } catch let LispError.general(msg:message) {
            return "Error: \(message)"
        } catch let LispError.lexer(msg:message) {
            return "Syntax Error: \(message)"
        } catch {
            return String(describing: error)
        }
    }
}
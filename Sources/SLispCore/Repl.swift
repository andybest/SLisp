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

public class Repl {

    var environment: Environment

    public init?() throws {
        environment = try Environment()!
    }

    public func mainLoop() {
        while true {
            if let output = getInput() {
                print(output)
            }
        }
    }

    func getInput() -> String? {
        Swift.print("\(environment.currentNamespaceName)> ", terminator: "")

        var input: String = ""

        while true {
            guard let newInput = readLine(strippingNewline: true) else {
                continue
            }

            input += newInput

            if input.characters.count > 0 {

                var rv: LispType? = nil
                do {
                    let form = try Reader.read(input)
                    rv = try environment.eval(form)

                } catch let LispError.runtime(msg:message) {
                    return "Runtime Error: \(message)"
                } catch let LispError.general(msg:message) {
                    return "Error: \(message)"
                } catch let LispError.lexer(msg:message) {
                    return "Syntax Error: \(message)"
                } catch LispError.readerNotEOF {
                    // Input hasn't been completed
                    Swift.print("...\t", terminator: "")
                } catch {
                    return String(describing: error)
                }
                if rv != nil {
                    return String(describing: rv!)
                }
            } else {
                return nil
            }
        }
    }
}

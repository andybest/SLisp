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
import SLispCore
import LineNoise

public class Repl {

    var parser: Parser
    let ln: LineNoise
    var environment: Environment

    public init?() throws {
        parser = try Parser()!
        ln = LineNoise()
        environment = Environment(ns: parser.createOrGetNamespace("user"))
    }

    public func mainLoop() throws {
        while true {
            if let output = try getInput() {
                print(output)
            }
        }
    }

    func getInput() throws -> String? {
        var prompt = "\(environment.namespace.name)> "

        var input: String = ""

        while true {
            let newInput = try ln.getLine(prompt: prompt)
            print("")

            input += newInput

            if input.characters.count > 0 {

                var rv: LispType? = nil
                do {
                    let form = try Reader.read(input)
                    let (lt, e) = try parser.eval(form, environment: environment)
                    environment = e
                    rv = lt
                } catch let LispError.runtime(msg:message) {
                    return "Runtime Error: \(message)"
                } catch let LispError.general(msg:message) {
                    return "Error: \(message)"
                } catch let LispError.lexer(msg:message) {
                    return "Syntax Error: \(message)"
                } catch let LispError.runtimeForm(msg: message, form: form) {
                    var retMsg = "Error: \(message)"
                    if form != nil {
                        retMsg += "\n"
                        retMsg += String(describing: form!)
                    }
                    return retMsg
                } catch LispError.readerNotEOF {
                    // Input hasn't been completed
                    prompt = "...\t"
                } catch {
                    return String(describing: error)
                }
                if rv != nil {
                    print("\n", terminator: "")
                    ln.addHistory(input)
                    return String(describing: rv!)
                }
            } else {
                return nil
            }
        }
    }
}

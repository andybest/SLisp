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

extension Parser {
    func evalFile(path: String, toNamespace namespace: Namespace, environment: Environment) -> LispType? {
        do {
            let cwd = URL(fileURLWithPath: path).deletingLastPathComponent().absoluteString
            pushCWD(workingDir: cwd)
            defer {
                do {
                    try popCWD()
                } catch {
                    print("Unable to change back cwd!")
                }
            }
            
            let readForm = "(read-string (str \"(do \" (slurp \"\(path)\") \")\"))"
            let form     = try Reader.read(readForm)
            let rv       = try eval(form, environment: environment)
            return try eval(rv, environment: environment)
        } catch let LispError.runtime(msg:message) {
            print("Runtime Error: \(message)")
        } catch let LispError.general(msg:message) {
            print("Error: \(message)")
        } catch let LispError.lexer(msg:message) {
            print("Syntax Error: \(message)")
        } catch LispError.readerNotEOF {
            print("Syntax Error: expected ')'")
        } catch let LispError.runtimeForm(msg: message, form: form) {
            var retMsg = "Error: \(message)"
            if form != nil {
                retMsg += "\n"
                retMsg += String(describing: form!)
            }
            print(retMsg)
        } catch {
            print(String(describing: error))
        }
        
        print("evalFile: File could not be loaded!")
        return nil
    }
    
    public func evalFile(path: String, environment: Environment) -> LispType? {
        do {
            let readForm = "(read-string (str \"(do \" (slurp \"\(path)\") \")\"))"
            let form     = try Reader.read(readForm)
            let rv       = try eval(form, environment: environment)
            return try eval(rv, environment: environment)
        } catch let LispError.runtime(msg:message) {
            print("Runtime Error: \(message)")
        } catch let LispError.general(msg:message) {
            print("Error: \(message)")
        } catch let LispError.lexer(msg:message) {
            print("Syntax Error: \(message)")
        } catch LispError.readerNotEOF {
            print("Syntax Error: expected ')'")
        } catch let LispError.runtimeForm(msg: message, form: form) {
            var retMsg = "Error: \(message)"
            if form != nil {
                retMsg += "\n"
                retMsg += String(describing: form!)
            }
            print(retMsg)
        } catch {
            print(String(describing: error))
        }
        
        print("evalFile: File could not be loaded!")
        return nil
    }
    
    public func evalString(_ str: String, environment: Environment) -> LispType? {
        do {
            let form = try Reader.read(str)
            return try eval(form, environment: environment)
        } catch let LispError.runtime(msg:message) {
            print("Runtime Error: \(message)")
        } catch let LispError.general(msg:message) {
            print("Error: \(message)")
        } catch let LispError.lexer(msg:message) {
            print("Syntax Error: \(message)")
        } catch LispError.readerNotEOF {
            print("Syntax Error: expected ')'")
        } catch let LispError.runtimeForm(msg: message, form: form) {
            var retMsg = "Error: \(message)"
            if form != nil {
                retMsg += "\n"
                retMsg += String(describing: form!)
            }
            print(retMsg)
        } catch {
            print(String(describing: error))
        }
        
        print("evalString: File could not be loaded!")
        return nil
    }
}

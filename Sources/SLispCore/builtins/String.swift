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

class StringBuiltins : Builtins {
    
    override init(env:Environment) {
        super.init(env: env)
    }
    
    override func namespaceName() -> String {
        return "string"
    }
    
    override func loadImplementation() {
        // Load core library implemented in SLisp
        let path = "./Lib/string.sl"
        if env.evalFile(path: path) == nil {
            print("String library implementation could not be loaded!")
        }
    }
    
    override func initBuiltins() -> [String: BuiltinDef] {
        addBuiltin("capitalize", docstring: """
        capitalize
        (str)
        Capitalizes the string
        """) { args, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'capitalize' requires one argument")
            }
            
            guard case let .string(str) = args[0] else {
                throw LispError.runtime(msg: "'captitalize' requires a string argument")
            }
            
            return .string(str.capitalized)
        }
        
        addBuiltin("upper-case", docstring: """
        upper-case
        (str)
        Converts the string to upper case
        """) { args, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'upper-case' requires one argument")
            }
            
            guard case let .string(str) = args[0] else {
                throw LispError.runtime(msg: "'upper-case' requires a string argument")
            }
            
            return .string(str.uppercased())
        }
        
        addBuiltin("lower-case", docstring: """
        lower-case
        (str)
        Converts the string to lower case
        """) { args, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'lower-case' requires one argument")
            }
            
            guard case let .string(str) = args[0] else {
                throw LispError.runtime(msg: "'lower-case' requires a string argument")
            }
            
            return .string(str.lowercased())
        }
        
        return builtins
    }
}

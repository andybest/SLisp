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

class Core: Builtins {

    override init(env: Environment) {
        super.init(env: env)
    }

    override func namespaceName() -> String {
        return "core"
    }

    override func loadImplementation() {
        // Load core library implemented in SLisp
        let path = "./Lib/core.sl"
        if env.evalFile(path: path, toNamespace: env.createOrGetNamespace(self.namespaceName())) == nil {
            print("Core library implementation could not be loaded!")
        }
    }
    
    func loadAutoincludeImplementation(toNamespace ns: String) {
        // Load core library implemented in SLisp
        let path = "./Lib/core-autoinclude.sl"
        if env.evalFile(path: path, toNamespace: env.createOrGetNamespace(ns)) == nil {
            print("Core library autoinclude implementation could not be loaded!")
        }
    }

    override func initBuiltins() -> [String: BuiltinDef] {

        
        addBuiltin("print", docstring: "") { args, env throws in
            let strings = args.map { arg -> String in
                switch arg {
                    case .string(let s):
                        return s
                    default:
                        return String(describing: arg)
                }
            }
            print(strings.joined(separator: ","))
            return .nil
        }

        addBuiltin("input", docstring: "") { args, env throws in
            if args.count > 1 {
                throw LispError.general(msg: "'input' expects 0 or 1 argument")
            }

            if args.count == 1 {
                guard case let .string(prompt) = args[0] else {
                    throw LispError.general(msg: "'input' requires the argument to be a string")
                }

                Swift.print(prompt, terminator: "")
            }

            if let input: String = readLine(strippingNewline: true), input.characters.count > 0 {
                return .string(input)
            }

            return .nil
        }

        addBuiltin("read-string", docstring: "") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'read-string' requires 1 string argument")
            }

            guard case let .string(input) = args[0] else {
                throw LispError.general(msg: "'read-string' requires the argument to be a string")
            }

            return try Reader.read(input)
        }

        addBuiltin("slurp", docstring: "") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'slurp' requires 1 string argument")
            }

            guard case let .string(filename) = args[0] else {
                throw LispError.general(msg: "'slurp' requires the argument to be a string")
            }

            do {
                let fileContents = try String(contentsOfFile: filename)
                return .string(fileContents)
            } catch {
                print("File \(filename) not found.")
                return .nil
            }
        }

        addBuiltin("eval", docstring: "") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'eval' requires 1 argument")
            }

            return try env.eval(args[0])
        }

        addBuiltin("str", docstring: "") { args, env throws in
            if args.count == 0 {
                throw LispError.general(msg: "'str' requires at least one argument")
            }

            let strings = args.map { arg -> String in
                if case let .string(s) = arg {
                    return s
                }

                return String(describing: arg)
            }

            return .string(strings.joined())
        }

        addBuiltin("string=", docstring: "") { args, env throws in
            if args.count < 2 {
                throw LispError.general(msg: "'string=' requires at least 2 arguments.")
            }

            let strings = try args.map { arg -> String in
                if case let .string(s) = arg {
                    return s
                }
                throw LispError.runtime(msg: "'string=' expects string arguments. Got \(String(describing: arg))")
            }

            let comp = strings[0]
            for s in strings {
                if s != comp {
                    return .boolean(false)
                }
            }

            return .boolean(true)
        }
        
        initCoreTypeBuiltins()
        initCoreCollectionBuiltins()
        initCoreMathBuiltins()
        initCoreNamespaceBuiltins()

        return builtins
    }
    
    func initCoreNamespaceBuiltins() {
        addBuiltin("in-ns", docstring: "") { args, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'in-ns' expects one argument.")
            }
            
            guard case let .symbol(ns) = args[0] else {
                throw LispError.runtime(msg: "'in-ns' expects a symbol as an argument")
            }
            
            try env.changeNamespace(env.createOrGetNamespace(ns).name)
            return .nil
        }
    }
    
    func initCoreTypeBuiltins() {
        addBuiltin("list?", docstring: """
        list?
        (x)
        Returns true if x is a list
        """) { args, env throws in
            try self.checkArgCount(funcName: "list", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .list(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("symbol?", docstring: """
        symbol?
        (x)
        Returns true is x is a symbol
        """) { args, env throws in
            try self.checkArgCount(funcName: "symbol?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .symbol(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("string?", docstring: """
        string?
        (x)
        Returns true if x is a string
        """) { args, env throws in
            try self.checkArgCount(funcName: "string?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .string(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("number?", docstring: """
        number?
        (x)
        Returns true if x is a number
        """) { args, env throws in
            try self.checkArgCount(funcName: "number?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .number(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("float?", docstring: """
        float?
        (x)
        Returns true if x is a float
        """) { args, env throws in
            try self.checkArgCount(funcName: "float?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .number(let n) = arg else {
                    return .boolean(false)
                }
                
                if n.isInteger {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("integer?", docstring: """
        integer?
        (x)
        Returns true if x is an integer
        """) { args, env throws in
            try self.checkArgCount(funcName: "integer?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .number(let n) = arg else {
                    return .boolean(false)
                }
                
                if n.isFloat {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("function?", docstring: """
        function?
        (x)
        Returns true if x is a function
        """) { args, env throws in
            try self.checkArgCount(funcName: "function?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .function(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("nil?", docstring: """
        nil?
        (x)
        Returns true if x is nil
        """) { args, env throws in
            try self.checkArgCount(funcName: "nil?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .nil = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
    }
    
    func initCoreMathBuiltins() {
        
        addBuiltin("+", docstring: "") { args, env throws in
            return try self.doArithmeticOperation(args, body: LispNumber.add)
        }
        
        addBuiltin("-", docstring: "") { args, env throws in
            if args.count == 1 {
                return try self.doSingleArgArithmeticOperation(args, name: "-", body: LispNumber.negate)
            } else {
                return try self.doArithmeticOperation(args, body: LispNumber.subtract)
            }
        }
        
        addBuiltin("*", docstring: "") { args, env throws in
            return try self.doArithmeticOperation(args, body: LispNumber.multiply)
        }
        
        addBuiltin("/", docstring: "") { args, env throws in
            return try self.doArithmeticOperation(args, body: LispNumber.divide)
        }
        
        addBuiltin("mod", docstring: "") { args, env throws in
            return try self.doArithmeticOperation(args, body: LispNumber.mod)
        }
        
        
        addBuiltin(">", docstring: "") { args, env throws in
            return try self.doBooleanArithmeticOperation(args, body: LispNumber.greaterThan)
        }
        
        addBuiltin("<", docstring: "") { args, env throws in
            return try self.doBooleanArithmeticOperation(args, body: LispNumber.lessThan)
        }
        
        addBuiltin("==", docstring: "") { args, env throws in
            if args.count < 2 {
                throw LispError.runtime(msg: "'==' requires at least 2 arguments")
            }
            
            let comp = args[0]
            for arg in args.dropFirst() {
                if arg != comp {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("&&", docstring: "") { args, env throws in
            return try self.doBooleanOperation(args) { (x: Bool, y: Bool) -> Bool in
                return x && y
            }
        }
        
        addBuiltin("||", docstring: "") { args, env throws in
            return try self.doBooleanOperation(args) { (x: Bool, y: Bool) -> Bool in
                return x || y
            }
        }
        
        addBuiltin("!", docstring: "") { args, env throws in
            return try self.doSingleBooleanOperation(args) { (x: Bool) -> Bool in
                return !x
            }
        }
        
        addBuiltin("doc", docstring: "") { args, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'doc' requires 1 argument")
            }
            
            guard case let .function(_, docstring, _) = args[0] else {
                throw LispError.runtime(msg: "'doc' requires the argument to be a function")
            }
            
            return .string(docstring ?? "")
        }
    }
}

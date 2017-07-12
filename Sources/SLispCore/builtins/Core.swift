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

    override init(parser: Parser) {
        super.init(parser: parser)
    }

    override func namespaceName() -> String {
        return "core"
    }

    override func initBuiltins(environment: Environment) -> [String: BuiltinDef] {
        // MARK: print
        addBuiltin("print", docstring: """
        print
        (x y ...)
            Prints the arguments to the console
        """) { args, parser, env throws in
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
        
        
        // MARK: input
        addBuiltin("input", docstring: """
        input
        (prompt)
            Gets a line of input from the user, printing the optional prompt
        """) { args, parser, env throws in
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
        
        
        // MARK: read-string
        addBuiltin("read-string", docstring: """
        read-string
        (x)
            Converts the string x to a SLisp form
        """) { args, parser, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'read-string' requires 1 string argument")
            }

            guard case let .string(input) = args[0] else {
                throw LispError.general(msg: "'read-string' requires the argument to be a string")
            }

            return try Reader.read(input)
        }
        
        
        // MARK: slurp
        addBuiltin("slurp", docstring: """
        slurp
        (fileName)
            Reads the file at 'fileName' and returns it as a string
        """) { args, parser, env throws in
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
        
        
        // MARK: eval
        addBuiltin("eval", docstring: """
        eval
        (x)
            Evaluates x
        """) { args, parser, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'eval' requires 1 argument")
            }

            return try self.parser.eval(args[0], environment: environment).0
        }
        
        
        // MARK: str
        addBuiltin("str", docstring: """
        str
        (x y ...)
            Converts all of the arguments to strings and concatenates them
        """) { args, parser, env throws in
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
        
        
        // MARK: string=
        addBuiltin("string=", docstring: """
        string=
        (x y ...)
            Returns true if all of the string arguments are equal
        """) { args, parser, env throws in
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
        
        
        // MARK: symbol
        addBuiltin("symbol", docstring: """
        symbol
        (x)
            Converts the string argument to a symbol
        """) { args, parser, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'symbol' requires one argument")
            }
            
            guard case let .string(str) = args[0] else {
                throw LispError.runtime(msg: "'symbol' requires a string argument")
            }
            
            return .symbol(str)
        }
        
        
        // MARK: key
        addBuiltin("keyword", docstring: """
        keyword
        (x)
            Converts the string, symbol or keyword argument to a keyword
        """) { args, parser, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'keyword' requires one argument")
            }
            
            switch args[0] {
            case .key(_):
                return args[0]
                
            case .string(let str):
                return .key(str)
                
            case .symbol(let sym):
                return .key(sym)
                
            default:
                throw LispError.runtime(msg: "'keyword' requires a string, symbol or keyword argument")
            }
        }
        
        
        // MARK: doc
        addBuiltin("doc", docstring: """
        doc
        (f)
            Returns the docstring for the function
        """) { args, parser, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'doc' requires 1 argument")
            }
            
            guard case let .function(_, docstring, _, _) = args[0] else {
                throw LispError.runtime(msg: "'doc' requires the argument to be a function")
            }
            
            print(docstring ?? "")
            
            return .nil
        }
        
        
        // MARK: exit
        addBuiltin("exit", docstring: """
        exit
        (val)
            Exits the process, returning an optional integer
        """) { args, parser, env throws in
            if args.count > 1 {
                throw LispError.runtime(msg: "'exit' accepts a maximum of 1 argument")
            }
            
            if args.count > 0 {
                guard case let .number(.integer(exitVal)) = args[0] else {
                    throw LispError.runtime(msg: "'exit' expects an integer argument")
                }
                exit(Int32(exitVal))
            }
            
            exit(0)
        }
        
        initCoreTypeBuiltins()
        initCoreCollectionBuiltins()
        initCoreMathBuiltins(environment: environment)
        initCoreNamespaceBuiltins()
        initStdioBuiltins()

        return builtins
    }
    
    func initCoreNamespaceBuiltins() {
        // MARK: in-ns
        addBuiltin("in-ns", docstring: """
        in-ns
        (x)
            Move to the namespace indicated by the symbol x
        """) { args, parser, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'in-ns' expects one argument.")
            }
            
            guard case let .symbol(ns) = args[0] else {
                throw LispError.runtime(msg: "'in-ns' expects a symbol as an argument")
            }
            
            env.namespace = parser.createOrGetNamespace(ns)
            return .nil
        }
        
        
        // MARK: refer
        addBuiltin("refer", docstring: """
        refer
        (namespace)
        Imports all symbols in namespace into the current namespace
        """) { args, parser, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'refer' expects one argument.")
            }
            
            guard case let .symbol(ns) = args[0] else {
                throw LispError.runtime(msg: "'refer' expects a symbol as an argument")
            }
            
            guard let namespace = parser.namespaces[ns] else {
                throw LispError.runtime(msg: "Unable to find namespace '\(ns)'")
            }
            
            parser.importNamespace(namespace, toNamespace: env.namespace)
            return .nil
        }
        
        
        // MARK: list-ns
        addBuiltin("list-ns", docstring: "") { args, parser, env throws in
            if args.count != 1 {
                throw LispError.runtime(msg: "'in-ns' expects one argument.")
            }
            
            guard case let .symbol(ns) = args[0] else {
                throw LispError.runtime(msg: "'in-ns' expects a symbol as an argument")
            }
            
            guard let namespace = parser.namespaces[ns] else {
                throw LispError.runtime(msg: "Unable to find namespace '\(ns)'")
            }
            
            var nsmap: [LispType: LispType] = [:]
            
            for (key, value) in namespace.rootBindings {
                nsmap[.symbol(key)] = value
            }
            
            return .dictionary(nsmap)
        }
    }
    
    func initCoreTypeBuiltins() {
        // MARK: list?
        addBuiltin("list?", docstring: """
        list?
        (x)
            Returns true if x is a list
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "list", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .list(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        
        // MARK: symbol?
        addBuiltin("symbol?", docstring: """
        symbol?
        (x)
            Returns true is x is a symbol
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "symbol?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .symbol(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        
        // MARK: string?
        addBuiltin("string?", docstring: """
        string?
        (x)
            Returns true if x is a string
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "string?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .string(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        
        // MARK: number?
        addBuiltin("number?", docstring: """
        number?
        (x)
            Returns true if x is a number
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "number?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .number(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        
        // MARK: float?
        addBuiltin("float?", docstring: """
        float?
        (x)
            Returns true if x is a float
        """) { args, parser, env throws in
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
        
        
        // MARK: integer?
        addBuiltin("integer?", docstring: """
        integer?
        (x)
            Returns true if x is an integer
        """) { args, parser, env throws in
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
        
        
        // MARK: function?
        addBuiltin("function?", docstring: """
        function?
        (x)
            Returns true if x is a function
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "function?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .function(_) = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        
        // MARK: nil?
        addBuiltin("nil?", docstring: """
        nil?
        (x)
            Returns true if x is nil
        """) { args, parser, env throws in
            try self.checkArgCount(funcName: "nil?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .nil = arg else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
    }
    
    func initCoreMathBuiltins(environment: Environment) {
        
        // MARK: +
        addBuiltin("+", docstring: """
        +
        (x y ...)
            Adds the arguments together
        """) { args, parser, env throws in
            return try self.doArithmeticOperation(args, environment: environment, body: LispNumber.add)
        }
        
        
        // MARK: subtract
        addBuiltin("-", docstring: """
        -
        (x y ...)
            Subtracts the arguments from each other
        """) { args, parser, env throws in
            if args.count == 1 {
                return try self.doSingleArgArithmeticOperation(args, name: "-", environment: environment, body: LispNumber.negate)
            } else {
                return try self.doArithmeticOperation(args, environment: environment, body: LispNumber.subtract)
            }
        }
        
        
        // MARK: *
        addBuiltin("*", docstring: """
        *
        (x y ...)
            Multiplies the arguments together
        """) { args, parser, env throws in
            return try self.doArithmeticOperation(args, environment: environment, body: LispNumber.multiply)
        }
        
        
        // MARK: /
        addBuiltin("/", docstring: """
        /
        (x y ...)
            Divides the arguments
        """) { args, parser, env throws in
            return try self.doArithmeticOperation(args, environment: environment, body: LispNumber.divide)
        }
        
        
        // MARK: mod
        addBuiltin("mod", docstring: """
        mod
        (x y ...)
            Perfoms a modulo on the arguments
        """) { args, parser, env throws in
            return try self.doArithmeticOperation(args, environment: environment, body: LispNumber.mod)
        }
        
        
        // MARK: >
        addBuiltin(">", docstring: """
        >
        (x y ...)
            Returns true if x is greater than all of the arguments
        """) { args, parser, env throws in
            return try self.doBooleanArithmeticOperation(args, environment: environment, body: LispNumber.greaterThan)
        }
        
        
        // MARK: <
        addBuiltin("<", docstring: """
        <
        (x y ...)
            Returns true if x is less than all of the arguments
        """) { args, parser, env throws in
            return try self.doBooleanArithmeticOperation(args, environment: environment, body: LispNumber.lessThan)
        }
        
        
        // MARK: ==
        addBuiltin("==", docstring: """
        ==
        (x y ...)
            Returns true if all of the arguments are equal
        """) { args, parser, env throws in
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
        
        
        // MARK: &&
        addBuiltin("&&", docstring: """
        &&
        (x y ...)
            Performs a logical AND on all of the arguments
        """) { args, parser, env throws in
            return try self.doBooleanOperation(args, environment: environment) { (x: Bool, y: Bool) -> Bool in
                return x && y
            }
        }
        
        
        // MARK: ||
        addBuiltin("||", docstring: """
        ||
        (x y ...)
            Performs a logical OR on all of the arguments
        """) { args, parser, env throws in
            return try self.doBooleanOperation(args, environment: environment) { (x: Bool, y: Bool) -> Bool in
                return x || y
            }
        }
        
        
        // MARK: !
        addBuiltin("!", docstring: """
        !
        (x)
            Performs a logical NOT on the argument
        """) { args, parser, env throws in
            return try self.doSingleBooleanOperation(args, environment: environment) { (x: Bool) -> Bool in
                return !x
            }
        }
    }
}

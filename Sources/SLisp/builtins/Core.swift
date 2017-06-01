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
        let path = "./data/core.sl"
        if env.evalFile(path: path, toNamespace: env.createOrGetNamespace(self.namespaceName())) == nil {
            print("Core library implementation could not be loaded!")
        }
    }
    
    override func initBuiltins() -> [String: BuiltinBody] {
        addBuiltin("def") { args, env throws in
            if args.count != 2 {
                throw LispError.runtime(msg: "'def' requires exactly 2 arguments. Got \(args.count).")
            }
            
            guard case let .symbol(name) = args[0] else {
                throw LispError.runtime(msg: "'def' requires the first argument to be a symbol. Got \(String(describing: args[0])) instead.")
            }
            
            let binding = env.bindGlobal(name: name, value: try env.eval(args[1]), toNamespace: env.currentNamespace)
            return LispType.symbol(binding)
        }

        addBuiltin("list") { args, env throws in
            let evaluated = try args.map { try env.eval($0) }
            return .list(evaluated)
        }
        
        addBuiltin("cons") { args, env throws in
            try self.checkArgCount(funcName: "cons", args: args, expectedNumArgs: 2)
            
            let evaluated = try args.map { try env.eval($0) }
            var secondValue: [LispType] = []
            
            switch evaluated[1] {
            case .list(let listVal):
                secondValue = listVal
                break
            case .nil:
                break
            default:
                throw LispError.general(msg: "'cons' requires the second argument to be a list or 'nil'")
            }
            
            secondValue.insert(evaluated[0], at: 0)
            
            return .list(secondValue)
        }
        
        addBuiltin("concat") { args, env throws in
            let evaluated = try args.map { try env.eval($0) }
            
            let transformed: [LispType] = evaluated.flatMap { input -> [LispType] in
                if case let .list(list) = input {
                    return list
                }
                return [input]
            }
            
            return .list(transformed)
        }
        
        addBuiltin("first") { args, env throws in
            try self.checkArgCount(funcName: "first", args: args, expectedNumArgs: 1)
            
            let evaluated = try args.map { try env.eval($0) }
            
            if case let .list(list) = evaluated[0] {
                return list.first ?? .nil
            }
            
            throw LispError.general(msg: "'first' expects an argument that is a list")
        }
        
        addBuiltin("rest") { args, env throws in
            try self.checkArgCount(funcName: "rest", args: args, expectedNumArgs: 1)
            
            let evaluated = try args.map { try env.eval($0) }
            
            if case let .list(list) = evaluated[0] {
                return .list(Array(list.dropFirst(1)))
            }
            
            throw LispError.general(msg: "'rest' expects an argument that is a list")
        }
        
        addBuiltin("last") { args, env throws in
            try self.checkArgCount(funcName: "last", args: args, expectedNumArgs: 1)
            
            let evaluated = try args.map { try env.eval($0) }
            
            if case let .list(list) = evaluated[0] {
                return list.last ?? .nil
            }
            
            throw LispError.general(msg: "'last' expects an argument that is a list")
        }
        
        addBuiltin("function") { args, env throws in
            if args.count < 2 {
                throw LispError.general(msg: "'function' expects a body")
            }
            
            guard case let .list(argList) = args[0] else {
                throw LispError.general(msg: "function arguments must be a list")
            }
            
            let argNames: [String] = try argList.map {
                guard case let .symbol(argName) = $0 else {
                    throw LispError.general(msg: "function arguments must be symbols")
                }
                return argName
            }
            
            let body = FunctionBody.lisp(argnames: argNames, body: Array(args.dropFirst(1)))
            
            return LispType.function(body)
        }
        
        addBuiltin("print") { args, env throws in
            let strings = try args.map { String(describing: try env.eval($0)) }
            print(strings.joined(separator: ","))
            return .nil
        }
        
        addBuiltin("quote") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'quote' expects 1 argument, got \(args.count).")
            }
            
            return args[0]
        }
        
        addBuiltin("if") { args, env throws in
            try self.checkArgCount(funcName: "if", args: args, expectedNumArgs: 3)
            
            guard case let .boolean(condition) = try env.eval(args[0]) else {
                throw LispError.general(msg: "'if' expects the first argument to be a boolean condition")
            }
            
            if condition {
                return try env.eval(args[1])
            }
            
            return try env.doAll([args[2]])
        }
        
        addBuiltin("while") { args, env throws in
            if args.count < 2 {
                throw LispError.general(msg: "'while' requires a body")
            }
            
            guard case var .boolean(condition) = try env.eval(args[0]) else {
                throw LispError.general(msg: "'while' expects the first argument to be a boolean condition")
            }
            
            let body = Array(args.dropFirst())
            
            var rv: LispType = .nil
            while condition {
                rv = try env.doAll(body)
                
                switch try env.eval(args[0]) {
                case .boolean(let cond):
                    condition = cond
                default:
                    throw LispError.general(msg: "'while' expects the first argument to be a boolean condition")
                }
            }
            
            return rv
        }
        
        addBuiltin("list?") { args, env throws in
            try self.checkArgCount(funcName: "list", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .list(_) = try env.eval(arg) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("symbol?") { args, env throws in
            try self.checkArgCount(funcName: "symbol?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .symbol(_) = try env.eval(arg) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("string?") { args, env throws in
            try self.checkArgCount(funcName: "string?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .string(_) = try env.eval(arg) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("float?") { args, env throws in
            try self.checkArgCount(funcName: "float?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .float(_) = try env.eval(arg) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("function?") { args, env throws in
            try self.checkArgCount(funcName: "function?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .function(_) = try env.eval(arg) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("nil?") { args, env throws in
            try self.checkArgCount(funcName: "nil?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .nil = try env.eval(arg) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("do") { args, env throws in
            try self.checkArgCount(funcName: "do", args: args, expectedNumArgs: 1)
            
            return try env.doAll(args)
        }
        
        addBuiltin("let") { args, env throws in
            try self.checkArgCount(funcName: "let", args: args, expectedNumArgs: 2)
            
            guard case let .list(bindings) = args[0] else {
                throw LispError.general(msg: "'let' requires the first argument to be a list of bindings")
            }
            
            if bindings.count % 2 != 0 {
                throw LispError.general(msg: "'let' requires an even number of items in the binding list")
            }
            
            env.pushLocal(toNamespace: env.currentNamespace)
            
            try stride(from: 0, to: bindings.count, by: 2).forEach {
                guard case let .symbol(binding) = bindings[$0] else {
                    throw LispError.general(msg: "let binding must be a symbol. Got \(String(describing: bindings[$0])).")
                }
                _ = try env.bindLocal(name: binding, value: env.eval(bindings[$0 + 1]), toNamespace: env.currentNamespace)
            }
            
            let rv = try env.doAll(Array(args.dropFirst()))
            
            _ = env.popLocal(fromNamespace: env.currentNamespace)
            
            return rv
        }
        
        addBuiltin("input") { args, env throws in
            if args.count > 1 {
                throw LispError.general(msg: "'input' expects 0 or 1 argument")
            }
            
            if args.count == 1 {
                guard case let .string(prompt) = try env.eval(args[0]) else {
                    throw LispError.general(msg: "'input' requires the argument to be a string")
                }
                
                Swift.print(prompt, terminator: "")
            }
            
            if let input: String = readLine(strippingNewline: true), input.characters.count > 0 {
                return .string(input)
            }
            
            return .nil
        }

        addBuiltin("read-string") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'read-string' requires 1 string argument")
            }

            guard case let .string(input) = try env.eval(args[0]) else {
                throw LispError.general(msg: "'read-string' requires the argument to be a string")
            }

            return try env.read(input)
        }

        addBuiltin("slurp") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'slurp' requires 1 string argument")
            }

            guard case let .string(filename) = try env.eval(args[0]) else {
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

        addBuiltin("eval") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'eval' requires 1 argument")
            }

            return try env.eval(env.eval(args[0]))
        }

        addBuiltin("str") { args, env throws in
            if args.count == 0 {
                throw LispError.general(msg: "'str' requires at least one argument")
            }

            let strings = try args.map { arg -> String in
                let evaluated = try env.eval(arg)
                if case let .string(s) = evaluated {
                    return s
                }

                return String(describing: evaluated)
            }

            return .string(strings.joined())
        }
        
        /*
        /* Get input from stdin */
        addBuiltin("input") { args in
            let argList = getArgList(args, env: self.env)
            
            if argList.count > 0 {
                if valueIsString(argList[0]) {
                    let prompt = stringFromValue(argList[0])
                    print(prompt!, terminator: "")
                } else {
                    print("Input requires the first argument to be a string")
                    return LispType.nil
                }
            }
            
            let keyboard = FileHandle.standardInput
            let inputData = keyboard.availableData
            let input = NSString(data: inputData, encoding: String.Encoding.utf8.rawValue)!
                .trimmingCharacters(in: CharacterSet.newlines)
            return LispType.lString(input as String)
        }
        
        addBuiltin("string=") { args in
            var result: Bool = false
            var lastValue: String = ""
            var firstArg = true
            var p: Pair? = checkArgs(args, env: self.env)
            
            while p != nil {
                switch p!.value {
                case .lString(let s):
                    if firstArg {
                        lastValue = s
                        firstArg = false
                    } else {
                        result = s == lastValue
                        lastValue = s
                    }
                    break
                    
                default:
                    print("Invalid argument: \(p!.value)")
                    return LispType.nil
                }
                
                p = p?.next
            }
            
            return LispType.lBoolean(result)
        }
        
        addBuiltin("at") { args in
            let argList = getArgList(args, env: self.env)
            
            if argList.count != 2 {
                print("at requires 2 arguments")
                return LispType.nil
            }
            
            if !valueIsPair(argList[0]) {
                print("at requires the first argument to be a list")
                return LispType.nil
            }
            
            if !valueIsNumber(argList[1]) {
                print("at requires the second argument to be a number")
                return LispType.nil
            }
            
            let list = pairFromValue(argList[0])
            let index = Int(numberFromValue(argList[1]))
            var count = 0
            
            var p: Pair? = list
            
            while count < index && p != nil {
                count += 1
                p = p!.next
            }
            
            if p == nil {
                print("Index '\(index)' is out of range")
                return LispType.nil
            }
            
            return p!.value
        }*/

        addBuiltin("+") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x + y
            }
        }

        addBuiltin("-") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x - y
            }
        }

        addBuiltin("*") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x * y
            }
        }

        addBuiltin("/") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return x / y
            }
        }

        addBuiltin("mod") { args, env throws in
            return try self.doArithmeticOperation(args) { (x: Double, y: Double) -> Double in
                return remainder(x, y)
            }
        }

        addBuiltin(">") { args, env throws in
            return try self.doBooleanArithmeticOperation(args) { (x: Double, y: Double) -> Bool in
                return x > y
            }
        }

        addBuiltin("<") { args, env throws in
            return try self.doBooleanArithmeticOperation(args) { (x: Double, y: Double) -> Bool in
                return x < y
            }
        }

        addBuiltin("==") { args, env throws in
            return try self.doBooleanArithmeticOperation(args) { (x: Double, y: Double) -> Bool in
                return x == y
            }
        }

        addBuiltin("and") { args, env throws in
            return try self.doBooleanOperation(args) { (x: Bool, y: Bool) -> Bool in
                return x && y
            }
        }

        addBuiltin("or") { args, env throws in
            return try self.doBooleanOperation(args) { (x: Bool, y: Bool) -> Bool in
                return x || y
            }
        }

        addBuiltin("not") { args, env throws in
            return try self.doSingleBooleanOperation(args) { (x: Bool) -> Bool in
                return !x
            }
        }

        return builtins
    }
}

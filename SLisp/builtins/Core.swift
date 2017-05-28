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
        let _ = initBuiltins()
    }
    
    func initBuiltins() -> [String: BuiltinBody] {
        addBuiltin("def") { args, env throws in
            if args.count != 2 {
                throw LispError.runtime(msg: "'def' requires exactly 2 arguments. Got \(args.count).")
            }
            
            guard case let .atom(name) = args[0] else {
                throw LispError.runtime(msg: "'def' requires the first argument to be an atom. Got \(String(describing: args[0])) instead.")
            }
            
            let binding = env.currentNamespace.bindGlobal(name: name, value: try env.eval(args[1], env: env))
            return LispType.atom(binding)
        }

        addBuiltin("list") { args, env throws in
            let evaluated = try args.map { try env.eval($0, env: env) }
            return .list(evaluated)
        }
        
        addBuiltin("cons") { args, env throws in
            try self.checkArgCount(funcName: "cons", args: args, expectedNumArgs: 2)
            
            let evaluated = try args.map { try env.eval($0, env: env) }
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
            let evaluated = try args.map { try env.eval($0, env: env) }
            
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
            
            let evaluated = try args.map { try env.eval($0, env: env) }
            
            if case let .list(list) = evaluated[0] {
                return list.first ?? .nil
            }
            
            throw LispError.general(msg: "'first' expects an argument that is a list")
        }
        
        addBuiltin("rest") { args, env throws in
            try self.checkArgCount(funcName: "rest", args: args, expectedNumArgs: 1)
            
            let evaluated = try args.map { try env.eval($0, env: env) }
            
            if case let .list(list) = evaluated[0] {
                return .list(Array(list.dropFirst(1)))
            }
            
            throw LispError.general(msg: "'rest' expects an argument that is a list")
        }
        
        addBuiltin("last") { args, env throws in
            try self.checkArgCount(funcName: "last", args: args, expectedNumArgs: 1)
            
            let evaluated = try args.map { try env.eval($0, env: env) }
            
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
                guard case let .atom(argName) = $0 else {
                    throw LispError.general(msg: "function arguments must be atoms")
                }
                return argName
            }
            
            let body = FunctionBody.lisp(argnames: argNames, body: Array(args.dropFirst(1)))
            
            return LispType.function(body)
        }
        
        addBuiltin("print") { args, env throws in
            let strings = try args.map { String(describing: try env.eval($0, env: env)) }
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
            
            guard case let .boolean(condition) = try env.eval(args[0], env: env) else {
                throw LispError.general(msg: "'if' expects the first argument to be a boolean condition")
            }
            
            if condition {
                return try env.eval(args[1], env: env)
            }
            
            return try env.eval(args[2], env: env)
        }
        
        addBuiltin("while") { args, env throws in
            if args.count < 2 {
                throw LispError.general(msg: "'while' requires a body")
            }
            
            guard case var .boolean(condition) = try env.eval(args[0], env: env) else {
                throw LispError.general(msg: "'while' expects the first argument to be a boolean condition")
            }
            
            let body = Array(args.dropFirst())
            
            var rv: LispType = .nil
            while condition {
                for form in body {
                    rv = try env.eval(form, env: env)
                }
                
                switch try env.eval(args[0], env: env) {
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
                guard case .list(_) = try env.eval(arg, env: env) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("atom?") { args, env throws in
            try self.checkArgCount(funcName: "atom?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .atom(_) = try env.eval(arg, env: env) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("string?") { args, env throws in
            try self.checkArgCount(funcName: "string?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .string(_) = try env.eval(arg, env: env) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("float?") { args, env throws in
            try self.checkArgCount(funcName: "float?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .float(_) = try env.eval(arg, env: env) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("function?") { args, env throws in
            try self.checkArgCount(funcName: "function?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .function(_) = try env.eval(arg, env: env) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("nil?") { args, env throws in
            try self.checkArgCount(funcName: "nil?", args: args, expectedNumArgs: 1)
            
            for arg in args {
                guard case .nil = try env.eval(arg, env: env) else {
                    return .boolean(false)
                }
            }
            
            return .boolean(true)
        }
        
        addBuiltin("do") { args, env throws in
            try self.checkArgCount(funcName: "do", args: args, expectedNumArgs: 1)
            
            var rv: LispType = .nil
            for arg in args {
                rv = try env.eval(arg, env: env)
            }
            
            return rv
        }
        
        /*
        addBuiltin("let") { args in
            
            if(args == nil) {
                print("let requires 2 arguments")
                return LispType.nil
            }
            
            if(!valueIsPair(args!.value)) {
                print("let requires the first argument to be a list")
                return LispType.nil
            }
            
            if(args!.next == nil) {
                print("let requires a body")
                return LispType.nil
            }
            
            var pairArgs = [LispType]()
            var p: Pair? = pairFromValue(args!.value)
            
            while(p != nil) {
                pairArgs.append(p!.value)
                p = p!.next
            }
            
            if(pairArgs.count % 2 != 0) {
                print("let requires an even number of values")
                return LispType.nil
            }
            
            // Iterate through the pairs and put them into a dictionary, so they can be added to the environment stack
            self.env.pushEnvironment([String: LispType]())
            
            for startIdx in stride(from:0, to: pairArgs.count, by: 2) {
                let key = pairArgs[startIdx]
                
                if(!valueIsAtom(key)) {
                    print("let: value \(stringFromValue(key)) is not an atom")
                    return LispType.nil
                }
                
                // Add the values to the local environment after evaluating them
                self.env.addLocalVariable(stringFromValue(key)!, value: self.evaluateOrReturnResult(pairArgs[startIdx + 1]))
            }
            
            let body: Pair? =  args!.next!
            var pair = body
            var rv = LispType.nil
            
            // Evaluate all of the expressions in the body
            while pair != nil {
                rv = self.evaluateOrReturnResult(pair!.value)
                pair = pair!.next
            }
            
            self.env.popEnvironment()
            
            return rv
        }
        
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
        
        return builtins
    }
}

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

        addBuiltin("list") { args, env throws in
            return .list(args)
        }

        addBuiltin("cons") { args, env throws in
            try self.checkArgCount(funcName: "cons", args: args, expectedNumArgs: 2)

            var secondValue: [LispType] = []

            switch args[1] {
                case .list(let listVal):
                    secondValue = listVal
                    break
                case .nil:
                    break
                default:
                    throw LispError.general(msg: "'cons' requires the second argument to be a list or 'nil'")
            }

            secondValue.insert(args[0], at: 0)

            return .list(secondValue)
        }

        addBuiltin("concat") { args, env throws in
            let transformed: [LispType] = args.flatMap { input -> [LispType] in
                if case let .list(list) = input {
                    return list
                }
                return [input]
            }

            return .list(transformed)
        }

        addBuiltin("first") { args, env throws in
            try self.checkArgCount(funcName: "first", args: args, expectedNumArgs: 1)

            if case let .list(list) = args[0] {
                return list.first ?? .nil
            }

            throw LispError.general(msg: "'first' expects an argument that is a list")
        }

        addBuiltin("rest") { args, env throws in
            try self.checkArgCount(funcName: "rest", args: args, expectedNumArgs: 1)

            if case let .list(list) = args[0] {
                return .list(Array(list.dropFirst(1)))
            }

            throw LispError.general(msg: "'rest' expects an argument that is a list")
        }

        addBuiltin("last") { args, env throws in
            try self.checkArgCount(funcName: "last", args: args, expectedNumArgs: 1)

            if case let .list(list) = args[0] {
                return list.last ?? .nil
            }

            throw LispError.general(msg: "'last' expects an argument that is a list")
        }

        addBuiltin("print") { args, env throws in
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

        /*
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
 */

        addBuiltin("list?") { args, env throws in
            try self.checkArgCount(funcName: "list", args: args, expectedNumArgs: 1)

            for arg in args {
                guard case .list(_) = arg else {
                    return .boolean(false)
                }
            }

            return .boolean(true)
        }

        addBuiltin("symbol?") { args, env throws in
            try self.checkArgCount(funcName: "symbol?", args: args, expectedNumArgs: 1)

            for arg in args {
                guard case .symbol(_) = arg else {
                    return .boolean(false)
                }
            }

            return .boolean(true)
        }

        addBuiltin("string?") { args, env throws in
            try self.checkArgCount(funcName: "string?", args: args, expectedNumArgs: 1)

            for arg in args {
                guard case .string(_) = arg else {
                    return .boolean(false)
                }
            }

            return .boolean(true)
        }

        addBuiltin("float?") { args, env throws in
            try self.checkArgCount(funcName: "float?", args: args, expectedNumArgs: 1)

            for arg in args {
                guard case .float(_) = arg else {
                    return .boolean(false)
                }
            }

            return .boolean(true)
        }

        addBuiltin("function?") { args, env throws in
            try self.checkArgCount(funcName: "function?", args: args, expectedNumArgs: 1)

            for arg in args {
                guard case .function(_) = arg else {
                    return .boolean(false)
                }
            }

            return .boolean(true)
        }

        addBuiltin("nil?") { args, env throws in
            try self.checkArgCount(funcName: "nil?", args: args, expectedNumArgs: 1)

            for arg in args {
                guard case .nil = arg else {
                    return .boolean(false)
                }
            }

            return .boolean(true)
        }

        addBuiltin("input") { args, env throws in
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

        addBuiltin("read-string") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'read-string' requires 1 string argument")
            }

            guard case let .string(input) = args[0] else {
                throw LispError.general(msg: "'read-string' requires the argument to be a string")
            }

            return try Reader.read(input)
        }

        addBuiltin("slurp") { args, env throws in
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

        addBuiltin("eval") { args, env throws in
            if args.count != 1 {
                throw LispError.general(msg: "'eval' requires 1 argument")
            }

            return try env.eval(args[0])
        }

        addBuiltin("str") { args, env throws in
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

        addBuiltin("string=") { args, env throws in
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

        addBuiltin("at") { args, env in

            if args.count != 2 {
                throw LispError.runtime(msg: "'at' requires 2 arguments.")
            }

            guard case let .list(list) = args[0] else {
                throw LispError.runtime(msg: "'at' requires the first argument to be a list.")
            }

            guard case let .float(index) = args[1] else {
                throw LispError.runtime(msg: "'at' requires the second argument to be a numerical index.")
            }

            if Int(index) >= list.count || index < 0 {
                throw LispError.runtime(msg: "Index out of range: \(index)")
            }

            return list[Int(index)]
        }

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

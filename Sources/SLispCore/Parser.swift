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

class Environment {
    var currentNamespaceName: String   = ""
    var namespaces                     = [String: Namespace]()
    let coreImports:          [String] = ["core"]

    var currentNamespace: Namespace {
        return namespaces[currentNamespaceName]!
    }

    init?() throws {
        createDefaultNamespace()

        /* Core builtins */
        let coreBuiltins = [Core(env: self)]

        try coreBuiltins.forEach {
            let ns = createOrGetNamespace($0.namespaceName())
            try $0.initBuiltins().forEach { (arg) in
                
                let (name, body) = arg
                _ = try bindGlobal(name: .symbol(name), value: .function(.native(body: body)), toNamespace: ns)
            }

            // Import this namespace to the default namespace
            importNamespace(ns, toNamespace: currentNamespace)
        }

        coreBuiltins.forEach {
            let ns = createOrGetNamespace($0.namespaceName())
            do {
                let oldNS = currentNamespace
                try changeNamespace(ns.name)
                $0.loadImplementation()
                try changeNamespace(oldNS.name)
            } catch {
                print("Error importing builtins: \(error)")
            }
        }

        /* Other builtins */
        let builtins = [MathBuiltins(env: self)]

        try builtins.forEach {
            let ns = createOrGetNamespace($0.namespaceName())
            try $0.initBuiltins().forEach { (arg) in
                
                let (name, body) = arg
                _ = try bindGlobal(name: .symbol(name), value: .function(.native(body: body)), toNamespace: ns)
            }
        }

        builtins.forEach {
            let ns = createOrGetNamespace($0.namespaceName())
            do {
                let oldNS = currentNamespace
                try changeNamespace(ns.name)
                $0.loadImplementation()
                try changeNamespace(oldNS.name)
            } catch {
                print("Error importing builtins: \(error)")
            }
        }
    }

    func eval_form(_ form: LispType) throws -> LispType {
        switch form {
            case .symbol(let symbol):
                switch symbol {
                    case "true":
                        return .boolean(true)
                    case "false":
                        return .boolean(false)
                    case "nil":
                        return .nil
                    default:
                        return try getValue(symbol, fromNamespace: currentNamespace)
                }
            case .list(let list):
                return .list(try list.map {
                    try self.eval($0)
                })
            default:
                return form
        }
    }

    func eval(_ form: LispType) throws -> LispType {
        var tco: Bool   = false
        var mutableForm = form
        var env_push    = 0

        defer {
            while env_push > 0 {
                _ = popLocal(fromNamespace: currentNamespace)
                env_push -= 1
            }
        }

        while true {
            switch mutableForm {
                case .list(let list):
                    if list.count == 0 {
                        return form
                    }
                default:
                    return try eval_form(mutableForm)
            }

            switch mutableForm {
                case .list(let list):
                    let args = Array(list.dropFirst())

                    // Handle special forms
                    switch list[0] {
                        case .symbol("def"):
                            if args.count != 2 {
                                throw LispError.runtime(msg: "'def' requires 2 arguments")
                            }
                            return try bindGlobal(name: list[1], value: try eval(list[2]), toNamespace: currentNamespace)
                        case .symbol("let"):
                            if args.count < 2 {
                                throw LispError.runtime(msg: "'let' requires at least 2 arguments")
                            }

                            guard case let .list(bindings) = args[0] else {
                                throw LispError.general(msg: "'let' requires the first argument to be a list of bindings")
                            }

                            if bindings.count % 2 != 0 {
                                throw LispError.general(msg: "'let' requires an even number of items in the binding list")
                            }

                            pushLocal(toNamespace: currentNamespace)
                            env_push += 1

                            try stride(from: 0, to: bindings.count, by: 2).forEach {
                                _ = try bindLocal(name: bindings[$0], value: self.eval(bindings[$0 + 1]), toNamespace: currentNamespace)
                            }

                            let body: [LispType] = Array(args.dropFirst())

                            for (index, form) in body.enumerated() {
                                if index == body.count - 1 {
                                    mutableForm = form
                                    break
                                }

                                _ = try eval(form)
                            }

                            // TCO
                            mutableForm = body[body.count - 1]

                        case .symbol("apply"):
                            break
                        case .symbol("quote"):
                            if args.count != 1 {
                                throw LispError.general(msg: "'quote' expects 1 argument, got \(args.count).")
                            }

                            return args[0]
                        case .symbol("do"):
                            if args.count < 1 {
                                throw LispError.runtime(msg: "'do' requires at least 1 argument")
                            }

                            for (index, doForm) in args.enumerated() {
                                if index == args.count - 1 {
                                    mutableForm = doForm
                                    break
                                }

                                _ = try eval(doForm)
                            }

                            // TCO
                            mutableForm = args[args.count - 1]

                        case .symbol("function"):
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

                        case .symbol("if"):
                            if args.count != 3 {
                                throw LispError.runtime(msg: "'if' expects 3 arguments.")
                            }

                            guard case let .boolean(condition) = try eval(args[0]) else {
                                throw LispError.general(msg: "'if' expects the first argument to be a boolean condition")
                            }

                            if condition {
                                mutableForm = args[1]
                            } else {
                                mutableForm = args[2]
                            }

                        case .symbol("while"):
                            if args.count < 2 {
                                throw LispError.runtime(msg: "'while' requires a condition and a body")
                            }

                            func getCondition() throws -> Bool {
                                if case let .boolean(b) = try eval(args[0]) {
                                    return b
                                }
                                throw LispError.runtime(msg: "'while' expects the first argument to be a boolean.")
                            }

                            var rv: LispType = .nil
                            var condition = try getCondition()
                            while condition {
                                let body = Array(args.dropFirst())

                                for form in body {
                                    rv = try eval(form)
                                }

                                condition = try getCondition()
                            }

                            // TCO
                            mutableForm = rv

                        default:
                            switch try eval_form(mutableForm) {
                                case .list(let lst):
                                    switch lst[0] {
                                        case .function(let body):
                                            switch body {
                                                case .native(body:let nativeBody):
                                                    let rv = try nativeBody(Array(lst.dropFirst()), self)

                                                    if case let .tcoInvocation(invocation) = rv {
                                                        // Build a new function call list with the returned tco function
                                                        var tcoList = [LispType.function(invocation.function)]
                                                        tcoList.append(contentsOf: invocation.args)
                                                        mutableForm = .list(tcoList)
                                                        tco = true
                                                    } else {
                                                        return rv
                                                    }
                                                case .lisp(argnames:let argnames, body:let lispBody):
                                                    let funcArgs = Array(lst.dropFirst())
                                                    if funcArgs.count != argnames.count {
                                                        throw LispError.general(msg: "Invalid number of args: \(funcArgs.count). Expected \(argnames.count).")
                                                    }

                                                    pushLocal(toNamespace: currentNamespace)

                                                    for i in 0..<argnames.count {
                                                        _ = try bindLocal(name: .symbol(argnames[i]), value: funcArgs[i], toNamespace: currentNamespace)
                                                    }

                                                    var rv: LispType = .nil
                                                    for val in lispBody {
                                                        rv = try eval(val)
                                                    }

                                                    _ = popLocal(fromNamespace: currentNamespace)

                                                    if case let .tcoInvocation(invocation) = rv {
                                                        // Build a new function call list with the returned tco function
                                                        var tcoList = [LispType.function(invocation.function)]
                                                        tcoList.append(contentsOf: invocation.args)
                                                        mutableForm = .list(tcoList)
                                                        tco = true
                                                    }

                                                    return rv
                                            }
                                        default:
                                            throw LispError.runtime(msg: "\(String(describing: list[0])) is not a function.")
                                    }
                                default:
                                    throw LispError.runtime(msg: "Cannot evaluate form.")
                            }
                    }

                default:
                    throw LispError.runtime(msg: "Cannot evaluate form.")
            }
        } // while
    }

    func evalFile(path: String, toNamespace namespace: Namespace) -> LispType? {
        do {
            let oldNS = currentNamespace
            try changeNamespace(namespace.name)
            defer {
                do {
                    try changeNamespace(oldNS.name)
                } catch {
                    print(error)
                }
            }

            let readForm = "(read-string (str \"(do \" (slurp \"\(path)\") \")\"))"
            let form     = try Reader.read(readForm)
            let rv       = try eval(form)
            return try eval(rv)
        } catch let LispError.runtime(msg:message) {
            print("Runtime Error: \(message)")
        } catch let LispError.general(msg:message) {
            print("Error: \(message)")
        } catch let LispError.lexer(msg:message) {
            print("Syntax Error: \(message)")
        } catch LispError.readerNotEOF {
            print("Syntax Error: expected ')'")
        }catch {
            print(String(describing: error))
        }

        print("evalFile: File could not be loaded!")
        return nil
    }
}

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

public class Environment {
    public var currentNamespaceName: String   = ""
    var namespaces                     = [String: Namespace]()
    let coreImports:          [String] = ["core"]
    
    public var currentNamespace: Namespace {
        return namespaces[currentNamespaceName]!
    }
    
    public init?() throws {
        createDefaultNamespace()
        
        let core = Core(env: self)
        /* Core builtins */
        let coreBuiltins = [core]
        
        try coreBuiltins.forEach {
            let ns = createOrGetNamespace($0.namespaceName())
            try $0.initBuiltins().forEach { (arg) in
                
                let (name, builtinDef) = arg
                _ = try bindGlobal(name: .symbol(name),
                                   value: .function(.native(body: builtinDef.body),
                                                    docstring: builtinDef.docstring,
                                                    isMacro: false),
                                   toNamespace: ns)
            }
            
            // Import this namespace to the default namespace
            importNamespace(ns, toNamespace: currentNamespace)
        }
        
        core.loadAutoincludeImplementation(toNamespace: core.namespaceName())
        
        coreBuiltins.forEach {
            $0.loadImplementation()
        }
        
        /* Other builtins */
        let builtins = [MathBuiltins(env: self),
                        StringBuiltins(env: self)]
        
        try builtins.forEach {
            let ns = createOrGetNamespace($0.namespaceName())
            try $0.initBuiltins().forEach { (arg) in
                
                let (name, builtinDef) = arg
                _ = try bindGlobal(name: .symbol(name),
                                   value: .function(.native(body: builtinDef.body),
                                                    docstring: builtinDef.docstring,
                                                    isMacro: false),
                                   toNamespace: ns)
            }
        }
        
        builtins.forEach {
            $0.loadImplementation()
        }
    }
    
    func eval_form(_ form: LispType) throws -> LispType {
        if try is_macro(form) { return form }
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
    
    public func eval(_ form: LispType) throws -> LispType {
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
            
            mutableForm = try macroExpand(mutableForm)
            
            switch mutableForm {
            case .list(let list):
                let args = Array(list.dropFirst())
                
                // Handle special forms
                switch list[0] {
                // MARK: def
                case .symbol("def"):
                    if args.count != 2 {
                        throw LispError.runtime(msg: "'def' requires 2 arguments")
                    }
                    return try bindGlobal(name: list[1], value: try eval(list[2]), toNamespace: currentNamespace)
                    
                // MARK: let
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
                    
                // MARK: set!
                case .symbol("set!"):
                    if args.count != 2 {
                        throw LispError.runtime(msg: "'set!' requires 2 arguments")
                    }
                    
                    guard case let .symbol(name) = args[0] else {
                        throw LispError.runtime(msg: "'set!' requires the variable name to be a symbol")
                    }
                    
                    _ = try setValue(name: name, value: self.eval(args[1]), inNamespace: currentNamespace)
                    return .nil
                    
                // MARK: apply
                case .symbol("apply"):
                    if args.count != 2 {
                        throw LispError.runtime(msg: "'apply' requires 2 arguments")
                    }
                    
                    guard case .function(_) = try eval(args[0]) else {
                        throw LispError.runtime(msg: "'apply' requires the first argument to be a function")
                    }
                    
                    guard case let .list(applyArgs) = try eval(args[1]) else {
                        throw LispError.runtime(msg: "'apply' requires the second argument to be a list")
                    }
                    
                    mutableForm = .list([args[0]] + applyArgs)
                    
                // MARK: quote
                case .symbol("quote"):
                    if args.count != 1 {
                        throw LispError.general(msg: "'quote' expects 1 argument, got \(args.count).")
                    }
                    
                    return args[0]
                    
                // MARK: quasiquote
                case .symbol("quasiquote"):
                    if args.count != 1 {
                        throw LispError.general(msg: "'quasiquote' expects 1 argument, got \(args.count).")
                    }
                    mutableForm = try quasiquote(args[0])
                    
                // MARK: do
                case .symbol("do"):
                    if args.count < 1 {
                        return .nil
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
                    
                // MARK: function
                case .symbol("function"):
                    if args.count < 2 {
                        throw LispError.general(msg: "'function' expects a body")
                    }
                    
                    let argList: [LispType]
                    var docString: String?
                    
                    var fArgs = args
                    
                    // See if the first argument is a String. If it is, then it is a docstring.
                    if case let .string(ds) = args[0] {
                        docString = ds
                        fArgs = Array(args.dropFirst())
                    } else if case let .symbol(argSymb) = args[0] {
                        if case let .string(ds) = try getValue(argSymb, fromNamespace: currentNamespace) {
                            docString = ds
                            fArgs = Array(args.dropFirst())
                        }
                    } else if case .list(_) = args[0] {
                        do {
                            if case let .string(ds) = try eval(args[0]) {
                                docString = ds
                                fArgs = Array(args.dropFirst())
                            }
                        } catch {
                            // Don't do anything, since this doesn't return a string.
                        }
                    }
                    
                    if case let .symbol(argSymb) = fArgs[0] {
                        guard case let .list(argListFromSym) = try getValue(argSymb, fromNamespace: currentNamespace) else {
                            throw LispError.general(msg: "function arguments must be a list")
                        }
                        argList = argListFromSym
                    } else {
                        guard case let .list(argListFromList) = fArgs[0] else {
                            throw LispError.general(msg: "function arguments must be a list")
                        }
                        argList = argListFromList
                    }
                    
                    let argNames: [String] = try argList.map {
                        guard case let .symbol(argName) = $0 else {
                            throw LispError.general(msg: "function arguments must be symbols")
                        }
                        return argName
                    }
                    
                    if (argNames.filter { $0 == "&" }).count > 1 {
                        throw LispError.runtime(msg: "Function arguments must only include one '&'")
                    }
                    
                    let andIdx = argNames.index(of: "&")
                    if andIdx != nil && andIdx != argNames.endIndex.advanced(by: -2) {
                        throw LispError.runtime(msg: "Functions require the '&' to be the second to last argument")
                    }
                    
                    let body = FunctionBody.lisp(argnames: argNames, body: Array(fArgs.dropFirst(1)))
                    return LispType.function(body, docstring: docString, isMacro: false)
                    
                // MARK: if
                case .symbol("if"):
                    if args.count < 2 {
                        throw LispError.runtime(msg: "'if' expects 2 or 3 arguments.")
                    }
                    
                    guard case let .boolean(condition) = try eval(args[0]) else {
                        throw LispError.general(msg: "'if' expects the first argument to be a boolean condition")
                    }
                    
                    if condition {
                        mutableForm = args[1]
                    } else if args.count > 2 {
                        mutableForm = args[2]
                    } else {
                        return .nil
                    }
                    
                // MARK: while
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
                    
                // MARK: defmacro
                case .symbol("defmacro"):
                    if args.count != 2 {
                        throw LispError.runtime(msg: "'defmacro' requires 2 arguments")
                    }
                    
                    guard case let .function(body, docstring: docstring, _) = try eval(list[2]) else {
                        throw LispError.runtime(msg: "'defmacro' requires the 2nd argument to be a function")
                    }
                    
                    return try bindGlobal(name: list[1], value: .function(body, docstring: docstring, isMacro: true), toNamespace: currentNamespace)
                    
                // MARK: macroexpand
                case .symbol("macroexpand"):
                    if args.count != 1 {
                        throw LispError.runtime(msg: "'macroexpand' expects one argument")
                    }
                    return try macroExpand(args[0])
                default:
                    switch try eval_form(macroExpand(mutableForm)) {
                    case .list(let lst):
                        switch lst[0] {
                        case .function(let body, _, isMacro: _):
                            switch body {
                            case .native(body:let nativeBody):
                                let rv = try nativeBody(Array(lst.dropFirst()), self)
                                return rv
                            case .lisp(argnames:let argnames, body:let lispBody):
                                let funcArgs = Array(lst.dropFirst())
                                if funcArgs.count != argnames.count && argnames.index(of: "&") == nil {
                                    throw LispError.general(msg: "Invalid number of args: \(funcArgs.count). Expected \(argnames.count).")
                                }
                                
                                pushLocal(toNamespace: currentNamespace)
                                env_push += 1
                                
                                var bindList = false
                                for i in 0..<argnames.count {
                                    if argnames[i] == "&" {
                                        bindList = true
                                        if i != argnames.count - 2 {
                                            throw LispError.runtime(msg: "Functions require the '&' to be the second to last argument")
                                        }
                                    } else {
                                        if bindList {
                                            // Bind the rest of the arguments as a list
                                            _ = try bindLocal(name: .symbol(argnames[i]), value: .list(Array(funcArgs[(i-1)...])), toNamespace: currentNamespace)
                                        } else {
                                            _ = try bindLocal(name: .symbol(argnames[i]), value: funcArgs[i], toNamespace: currentNamespace)
                                        }
                                    }
                                }
                                
                                for val in lispBody.dropLast() {
                                    _ = try eval(val)
                                }
                                
                                mutableForm = lispBody.last!
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
    
    func quasiquote(_ form: LispType) throws -> LispType {
        // If the argument isn't a list, just return the argument with a regular quote
        guard case let .list(args) = form, args.count > 0 else {
            return .list([.symbol("quote")] + [form])
        }
        
        if case .symbol("unquote") = args[0] {
            if args.count != 2 {
                throw LispError.runtime(msg: "'unquote' requires one argument")
            }
            return args[1]
        }
        
        if case let .list(list) = args[0], list.count > 0 {
            if case .symbol("splice-unquote") = list[0] {
                if list.count != 2 {
                    throw LispError.runtime(msg: "'splice-unquote' requires one argument")
                }
                return .list([.symbol("concat"), list[1], try quasiquote(.list(Array(args.dropFirst())))])
            }
        }
        
        return .list([.symbol("cons"), try quasiquote(args[0]), try quasiquote(.list(Array(args.dropFirst())))])
        
    }
    
    func is_macro(_ form: LispType) throws -> Bool {
        switch form {
        case .list(let list) where list.count > 0:
            let arg = list.first!
            
            switch arg {
            case .symbol(let symbol):
                do {
                    let val = try getValue(symbol, fromNamespace: currentNamespace)
                    if case let .function(_, _, isMacro: isMacro) = val {
                        return isMacro
                    }
                    return false
                } catch {
                    return false
                }
            default:
                return false
            }
        default:
            return false
        }
    }
    
    func macroExpand(_ form: LispType) throws -> LispType {
        var mutableForm = form
        var local_push = 0
        defer {
            while local_push > 0 {
                _ = popLocal(fromNamespace: currentNamespace)
                local_push -= 1
            }
        }
        
        while try is_macro(mutableForm) {
            if case let .list(list) = mutableForm, list.count > 0, case let .symbol(sym) = list.first! {
                let f = try getValue(sym, fromNamespace: currentNamespace)
                if case let .function(body, docstring: _, isMacro: _) = f {
                    if case let .lisp(argList, lispBody) = body {
                        let funcArgs = Array(list.dropFirst())
                        if funcArgs.count != argList.count && argList.index(of: "&") == nil {
                            throw LispError.general(msg: "Invalid number of args: \(funcArgs.count). Expected \(argList.count).")
                        }
                        
                        pushLocal(toNamespace: currentNamespace)
                        local_push += 1
                        
                        var bindList = false
                        for i in 0..<argList.count {
                            if argList[i] == "&" {
                                bindList = true
                                if i != argList.count - 2 {
                                    throw LispError.runtime(msg: "Macros require the '&' to be the second to last argument")
                                }
                            } else {
                                if bindList {
                                    // Bind the rest of the arguments as a list
                                    _ = try bindLocal(name: .symbol(argList[i]), value: .list(Array(funcArgs[(i - 1)...])), toNamespace: currentNamespace)
                                } else {
                                    _ = try bindLocal(name: .symbol(argList[i]), value: funcArgs[i], toNamespace: currentNamespace)
                                }
                            }
                        }
                        
                        for val in lispBody {
                            mutableForm = try eval(val)
                        }
                    } else {
                        throw LispError.runtime(msg: "Builtin cannot be a macro!")
                    }
                } else {
                    throw LispError.runtime(msg: "'macroexpand' expects the first arg to be a function")
                }
            }
        }
        
        return mutableForm
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
    
    func evalFile(path: String) -> LispType? {
        do {
            let oldNS = currentNamespace
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

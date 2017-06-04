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


typealias lFloat = Double

typealias BuiltinBody = ([LispType], Environment) throws -> LispType

indirect enum FunctionBody {
    case native(body: BuiltinBody)
    case lisp(argnames: [String], body: [LispType])
}

struct TCOInvocation {
    let function: FunctionBody
    let args:     [LispType]
}

enum LispType: CustomStringConvertible {
    case list([LispType])
    case symbol(String)
    case float(lFloat)
    case `string`(String)
    case boolean(Bool)
    case `nil`
    case function(FunctionBody)
    case tcoInvocation(TCOInvocation)

    var description: String {
        switch self {
            case .symbol(let str):
                return str
            case .boolean(let bool):
                return String(bool)
            case .float(let f):
                return String(f)
            case .nil:
                return "nil"
            case .string(let str):
                return "\"\(str)\""
            case .list(let list):
                let elements = list.map {
                    String(describing: $0)
                }.joined(separator: " ")
                return "(\(elements))"
            case .function(_):
                return "#<function>"
            case .tcoInvocation(_):
                return "#<TCOInvocation>"
        }
    }

}

class Environment {
    var currentNamespaceName: String = ""
    var namespaces                   = [String: Namespace]()

    let coreImports: [String] = ["core"]

    var currentNamespace: Namespace {
        return namespaces[currentNamespaceName]!
    }

    init?() throws {
        createDefaultNamespace()

        /* Core builtins */
        let coreBuiltins = [Core(env: self)]

        try coreBuiltins.forEach {
            let ns = createOrGetNamespace($0.namespaceName())
            try $0.initBuiltins().forEach { name, body in
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
            try $0.initBuiltins().forEach { name, body in
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

    func createDefaultNamespace() {
        let ns = Namespace(name: "user")
        addNamespace(ns)
        do {
            try changeNamespace(ns.name)
        } catch {
            print("Error when creating default namespace")
        }
    }

    func addNamespace(_ ns: Namespace) {
        namespaces[ns.name] = ns
    }

    func changeNamespace(_ name: String) throws {
        if namespaces[name] != nil {
            currentNamespaceName = name
        } else {
            throw LispError.general(msg: "Invalid namespace: '\(name)'")
        }
    }

    func eval_form(_ form: LispType) throws -> LispType {
        switch form {
        case .symbol(let symbol):
            return try getValue(symbol, fromNamespace: currentNamespace)
        case .list(let list):
            return .list(try list.map { try self.eval($0) })
        default:
            return form
        }
    }

    func eval(_ form: LispType) throws -> LispType {
        var tco: Bool   = false
        var mutableForm = form
        var env_push = 0
        
        defer {
            while env_push > 0 {
                _ = popLocal(fromNamespace: currentNamespace)
                env_push -= 1
            }
        }
        
        while true {
            switch mutableForm {
            case .list(let list):
                if list.count == 0 { return form }
            default:
                return try eval_form(form)
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

                default:
                    switch try eval_form(mutableForm) {
                    case .list(let list):
                        switch list[0] {
                        case .function(let body):
                            switch body {
                            case .native(body:let nativeBody):
                                let rv = try nativeBody(Array(list.dropFirst()), self)
                                
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
                                if args.count != argnames.count {
                                    throw LispError.general(msg: "Invalid number of args: \(args.count). Expected \(argnames.count).")
                                }
                                
                                pushLocal(toNamespace: currentNamespace)
                                env_push += 1
                                
                                for i in 0..<argnames.count {
                                    _ = try bindLocal(name: .symbol(argnames[i]), value: args[i], toNamespace: currentNamespace)
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
}


// Reader
extension Environment {

    func read_token(_ token: TokenType, reader: Reader) throws -> LispType {
        switch token {
            case .lParen:
                return try read_list(reader)
            case .symbol(let str):
                return .symbol(str)
            case .lString(let str):
                return .string(str)
            case .number(let num):
                return .float(num)
            default:
                Swift.print("Error while reading token \(token) at index \(reader.pos)")
                return .nil
        }
    }

    func read_list(_ reader: Reader) throws -> LispType {
        var list: [LispType] = []
        var endOfList        = false

        while let token = reader.nextToken() {
            switch token {
                case .rParen:
                    endOfList = true
                default:
                    list.append(try read_token(token, reader: reader))
            }

            if endOfList {
                break
            }
        }

        if !endOfList {
            throw LispError.lexer(msg: "Expected ')'.")
        }

        return .list(list)
    }

    func read(_ input: String) throws -> LispType {
        let tokenizer = Tokenizer(source: input)
        let tokens    = try tokenizer.tokenizeInput()

        let reader = Reader(tokens: tokens)
        return try read_token(reader.nextToken()!, reader: reader)
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
            let form     = try read(readForm)
            let rv       = try eval(form)
            return try eval(rv)
        } catch let LispError.runtime(msg:message) {
            print("Runtime Error: \(message)")
        } catch let LispError.general(msg:message) {
            print("Error: \(message)")
        } catch let LispError.lexer(msg:message) {
            print("Syntax Error: \(message)")
        } catch {
            print(String(describing: error))
        }

        print("evalFile: File could not be loaded!")
        return nil
    }
}

// Namespaces
extension Environment {
    func getValue(_ name: String, fromNamespace namespace: Namespace) throws -> LispType {
        var targetNamespace: String?
        var binding:   String

        // Split the input on the first forward slash to separate by
        let bindingComponents = name.characters.split(maxSplits: 1, omittingEmptySubsequences: false) {
            $0 == "/"
        }.map(String.init)

        if bindingComponents.count == 1 || bindingComponents[0] == "" {
            if bindingComponents[0] == "" {
                // If the input starts with a slash, it is part of the binding, not a namespace separator.
                // This allows looking up "/" (divide) without a namespace qualifier, for example.
                binding = "/\(bindingComponents[0])"
            } else {
                binding = bindingComponents[0]
            }
        } else {
            targetNamespace = bindingComponents[0]
            binding = bindingComponents[1]
        }

        if targetNamespace != nil {
            // Search for a namespace ref, or namespace with the given name
            if let ns = namespace.namespaceRefs[targetNamespace!] {
                if let val = ns.rootBindings[binding] {
                    return val
                }
            } else if let ns = namespaces[targetNamespace!] {
                if let val = ns.rootBindings[binding] {
                    return val
                }
            }
        } else {
            for index in stride(from: namespace.bindingStack.count - 1, through: 0, by: -1) {
                if let val = namespace.bindingStack[index][name] {
                    return val
                }
            }

            if let val = namespace.rootBindings[name] {
                return val
            }

            for ns in namespace.namespaceImports {
                if let val = ns.rootBindings[name] {
                    return val
                }
            }
        }

        throw LispError.general(msg: "Value \(name) not found.")
    }

    func pushLocal(toNamespace namespace: Namespace) {
        namespace.bindingStack.append([:])
    }

    func popLocal(fromNamespace namespace: Namespace) -> [String: LispType] {
        return namespace.bindingStack.popLast() ?? [:]
    }

    func bindLocal(name: LispType, value: LispType, toNamespace namespace: Namespace) throws -> LispType {
        guard case let .symbol(bindingName) = name else {
            throw LispError.runtime(msg: "Values can only be bound to symbols. Got \(String(describing: name))")
        }
        
        if namespace.bindingStack.count > 0 {
            namespace.bindingStack[namespace.bindingStack.count - 1][bindingName] = value
        } else {
            namespace.rootBindings[bindingName] = value
        }

        return .symbol("\(namespace.name)/\(bindingName)")
    }

    func bindGlobal(name: LispType, value: LispType, toNamespace namespace: Namespace) throws -> LispType {
        guard case let .symbol(bindingName) = name else {
            throw LispError.runtime(msg: "Values can only be bound to symbols. Got \(String(describing: name))")
        }
        
        namespace.rootBindings[bindingName] = value

        return .symbol("\(namespace.name)/\(bindingName)")
    }

    func importNamespace(_ ns: Namespace, toNamespace namespace: Namespace) {
        if ns != namespace {
            namespace.namespaceImports.insert(ns)
        }
    }

    func importNamespace(_ ns: Namespace, as importName: String, toNamespace namespace: Namespace) {
        namespace.namespaceRefs[importName] = ns
    }

    func createOrGetNamespace(_ name: String) -> Namespace {
        if let ns = namespaces[name] {
            return ns
        }

        let ns = Namespace(name: name)
        namespaces[name] = ns

        defer {
            for nsImport in coreImports {
                importNamespace(createOrGetNamespace(nsImport), toNamespace: ns)
            }
        }
        return ns
    }
}

class Namespace: Hashable {
    let name: String
    var rootBindings     = [String: LispType]()
    var bindingStack     = [[String: LispType]]()
    var namespaceRefs    = [String: Namespace]()
    var namespaceImports = Set<Namespace>()

    public private(set) var hashValue: Int = 0

    init(name: String) {
        self.name = name
    }

    public static func ==(lhs: Namespace, rhs: Namespace) -> Bool {
        return lhs.name == rhs.name
    }
}

class Reader {
    let tokens: [TokenType]
    var pos = 0

    init(tokens: [TokenType]) {
        self.tokens = tokens
    }

    func nextToken() -> TokenType? {
        defer {
            pos += 1
        }

        if pos < tokens.count {
            return tokens[pos]
        }

        return nil
    }
}

class Repl {

    var environment: Environment
    
    init?() throws {
        environment = try Environment()!
    }

    func mainLoop() {
        while true {
            Swift.print("user> ", terminator: "")

            if let input: String = readLine(strippingNewline: true), input.characters.count > 0 {
                Swift.print(rep(input))
            }
        }
    }

    func print() {

    }

    func rep(_ input: String) -> String {

        do {
            let form = try environment.read(input)
            let rv   = try environment.eval(form)
            return String(describing: rv)

        } catch let LispError.runtime(msg:message) {
            return "Runtime Error: \(message)"
        } catch let LispError.general(msg:message) {
            return "Error: \(message)"
        } catch let LispError.lexer(msg:message) {
            return "Syntax Error: \(message)"
        } catch {
            return String(describing: error)
        }
    }
}

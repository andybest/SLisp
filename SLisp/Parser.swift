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

    init() {
        createDefaultNamespace()

        /* Core builtins */
        let coreBuiltins = [Core(env: self)]

        coreBuiltins.forEach {
            let ns = createOrGetNamespace($0.namespaceName())
            $0.initBuiltins().forEach { name, body in
                _ = bindGlobal(name: name, value: .function(.native(body: body)), toNamespace: ns)
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

        builtins.forEach {
            let ns = createOrGetNamespace($0.namespaceName())
            $0.initBuiltins().forEach { name, body in
                _ = bindGlobal(name: name, value: .function(.native(body: body)), toNamespace: ns)
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

    func eval(_ form: LispType, env: Environment) throws -> LispType {
        var tco: Bool   = false
        var mutableForm = form

        repeat {
            tco = false
            switch mutableForm {

                case .list(let list):
                    guard let f = list.first else {
                        return mutableForm
                    }

                    var item = LispType.nil

                    if case .function(_) = f {
                        item = f
                    } else {
                        item = try eval(f, env: env)
                    }

                    // If the first item in the list is a symbol, check the environment to see
                    // if it has been bound
                    if case let .symbol(name) = item {
                        if let bind = try env.getValue(name, fromNamespace: currentNamespace) {
                            item = bind
                        }
                    }

                    if case let .function(body) = item {
                        switch body {
                            case .native(body:let nativeBody):
                                let rv = try nativeBody(Array(list.dropFirst()), env)

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
                                let args = try Array(list.dropFirst()).map {
                                    try self.eval($0, env: self)
                                }

                                if args.count != argnames.count {
                                    throw LispError.general(msg: "Invalid number of args: \(args.count). Expected \(argnames.count).")
                                }

                                env.pushLocal(toNamespace: currentNamespace)

                                for i in 0..<argnames.count {
                                    _ = env.bindLocal(name: argnames[i], value: args[i], toNamespace: currentNamespace)
                                }

                                var rv: LispType = .nil
                                for val in lispBody {
                                    rv = try eval(val, env: env)
                                }

                                _ = env.popLocal(fromNamespace: currentNamespace)

                                if case let .tcoInvocation(invocation) = rv {
                                    // Build a new function call list with the returned tco function
                                    var tcoList = [LispType.function(invocation.function)]
                                    tcoList.append(contentsOf: invocation.args)
                                    mutableForm = .list(tcoList)
                                    tco = true
                                } else {
                                    return rv
                                }
                        }
                    } else {
                        throw LispError.runtime(msg: "'\(String(describing: f))' is not a function.")
                    }

                case .symbol(let symbol):
                    if symbol == "nil" {
                        return .nil
                    } else if symbol == "true" {
                        return .boolean(true)
                    } else if symbol == "false" {
                        return .boolean(false)
                    }

                    if let val = try env.getValue(symbol, fromNamespace: env.currentNamespace) {
                        return val
                    }
                    
                    throw LispError.general(msg: "Symbol '\(symbol)' is not currently bound")

                default:
                    return mutableForm
            }

        } while (tco)

        return mutableForm
    }

    func doAll(_ forms: [LispType]) throws -> LispType {
        // Evaluate all forms in a list. If the last form is a function call,
        // return a TCOFunction

        for i in 0..<forms.count {
            if i == forms.count - 1 {
                guard case let .list(list) = forms[i] else {
                    return try self.eval(forms[i], env: self)
                }

                if list.count > 0 {
                    let firstItem = try self.eval(list[0], env: self)
                    guard case let .function(body) = firstItem else {
                        return try self.eval(forms[i], env: self)
                    }

                    // Need to evaluate the args here, since any local bindings won't exist
                    // after the caller returns

                    let evaluatedArgs = try Array(list.dropFirst()).map { arg -> LispType in
                        if case let .symbol(s) = arg {
                            return arg
                        }
                        return try self.eval(arg, env: self)
                    }

                    let invocation = TCOInvocation(function: body, args: evaluatedArgs)
                    return .tcoInvocation(invocation)
                }

                return try self.eval(forms[i], env: self)
            }

            _ = try self.eval(forms[i], env: self)
        }

        return .nil
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
            let rv       = try eval(form, env: self)
            return try eval(rv, env: self)
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
    func getValue(_ name: String, fromNamespace namespace: Namespace) throws -> LispType? {
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

        return nil
    }

    func pushLocal(toNamespace namespace: Namespace) {
        namespace.bindingStack.append([:])
    }

    func popLocal(fromNamespace namespace: Namespace) -> [String: LispType] {
        return namespace.bindingStack.popLast() ?? [:]
    }

    func bindLocal(name: String, value: LispType, toNamespace namespace: Namespace) -> String {
        if namespace.bindingStack.count > 0 {
            namespace.bindingStack[namespace.bindingStack.count - 1][name] = value
        } else {
            namespace.rootBindings[name] = value
        }

        return "\(namespace.name)/\(name)"
    }

    func bindGlobal(name: String, value: LispType, toNamespace namespace: Namespace) -> String {
        namespace.rootBindings[name] = value

        return "\(namespace.name)/\(name)"
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

    let environment = Environment()

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
            let rv   = try environment.eval(form, env: environment)
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

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
    let args: [LispType]
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
            let elements = list.map { String(describing: $0) }.joined(separator: " ")
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
    var namespaces = [String: Namespace]()
    
    var currentNamespace: Namespace {
        return namespaces[currentNamespaceName]!
    }
    
    init() {
        createDefaultNamespace()
        
        let core = Core(env: self)
        core.initBuiltins().forEach { name, body in
            _ = currentNamespace.bindGlobal(name: name, value: .function(.native(body: body)))
        }
        
        let math = MathBuiltins(env: self)
        math.initBuiltins().forEach { name, body in
            _ = currentNamespace.bindGlobal(name: name, value: .function(.native(body: body)))
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
        var tco: Bool = false
        var mutableForm = form
        
        repeat {
            tco = false
            switch mutableForm {
                
            case .list(let list):
                guard let f = list.first else { return mutableForm }
                
                var item = LispType.nil
                
                if case .function(_) = f {
                    item = f
                } else {
                    item = try eval(f, env: env)
                }
                
                // If the first item in the list is a symbol, check the environment to see
                // if it has been bound
                if case let .symbol(name) = item {
                    if let bind = env.currentNamespace.getValue(name: name) {
                        item = bind
                    }
                }
                
                if case let .function(body) = item {
                    switch body {
                    case .native(body: let nativeBody):
                        return try nativeBody(Array(list.dropFirst()), env)
                    case .lisp(argnames: let argnames, body: let lispBody):
                        let args = try Array(list.dropFirst()).map { try self.eval($0, env: self) }
                        
                        if args.count != argnames.count {
                            throw LispError.general(msg: "Invalid number of args: \(args.count). Expected \(argnames.count).")
                        }
                        
                        env.currentNamespace.pushLocal()
                        
                        for i in 0..<argnames.count {
                            _ = env.currentNamespace.bindLocal(name: argnames[i], value: args[i])
                        }
                        
                        var rv: LispType = .nil
                        for val in lispBody {
                            rv = try eval(val, env: env)
                        }
                        
                        _ = env.currentNamespace.popLocal()
                        
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
                
                if let val = env.currentNamespace.getValue(name: symbol) {
                    return val
                }
                
                throw LispError.general(msg: "Symbol '\(symbol)' is not currently bound")
                
            default:
                return mutableForm
            }
            
        } while(tco)
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
                    let firstItem = try self.eval(list[i], env: self)
                    guard case let .function(body) = firstItem else {
                        return try self.eval(forms[i], env: self)
                    }
                    
                    // Need to evaluate the args here, since any local bindings won't exist
                    // after the caller returns
                    
                    let evaluatedArgs = try Array(list.dropFirst()).map { return try self.eval($0, env: self) }
                    
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
        var endOfList = false

        while let token = reader.nextToken() {
            switch token {
                case .rParen:
                    endOfList = true
                default:
                    list.append(try read_token(token, reader: reader))
            }

            if endOfList { break }
        }

        if !endOfList {
            throw LispError.lexer(msg: "Expected ')'.")
        }

        return .list(list)
    }

    func read(_ input: String) throws -> LispType {
        let tokenizer = Tokenizer(source: input)
        let tokens = try tokenizer.tokenizeInput()

        let reader = Reader(tokens: tokens)
        return try read_token(reader.nextToken()!, reader: reader)
    }
}

class Namespace {
    let name: String
    var rootBindings = [String: LispType]()
    var bindingStack = [[String: LispType]]()
    
    init(name: String) {
        self.name = name
    }
    
    func getValue(name: String) -> LispType? {
        for index in stride(from: bindingStack.count - 1, through: 0, by: -1) {
            if let val = bindingStack[index][name] {
                return val
            }
        }
        
        if let val = rootBindings[name] {
            return val
        }
        
        return nil
    }
    
    func pushLocal() {
        bindingStack.append([:])
    }
    
    func popLocal() -> [String: LispType] {
        return bindingStack.popLast() ?? [:]
    }
    
    func bindLocal(name: String, value: LispType) -> String {
        if bindingStack.count > 0 {
            bindingStack[bindingStack.count - 1][name] = value
        } else {
            rootBindings[name] = value
        }
        
        return "\(self.name)/\(name)"
    }
    
    func bindGlobal(name: String, value: LispType) -> String {
        rootBindings[name] = value
        
        return "\(self.name)/\(name)"
    }
}

class Reader {
    let tokens: [TokenType]
    var pos = 0
    
    init(tokens: [TokenType]) {
        self.tokens = tokens
    }
    
    func nextToken() -> TokenType? {
        defer { pos += 1 }
        
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
            let rv = try environment.eval(form, env: environment)
            return String(describing: rv)
            
        } catch let LispError.runtime(msg: message) {
            return "Runtime Error: \(message)"
        } catch let LispError.general(msg: message) {
            return "Error: \(message)"
        } catch let LispError.lexer(msg: message) {
            return "Syntax Error: \(message)"
        } catch {
            return String(describing: error)
        }
    }
}

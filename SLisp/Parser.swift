//
//  Parser.swift
//  SLisp
//
//  Created by Andy Best on 25/05/2017.
//  Copyright © 2017 Andy Best. All rights reserved.
//

import Foundation


typealias lFloat = Double

typealias BuiltinBody = ([LispType], Environment) throws -> LispType

indirect enum FunctionBody {
    case native(body: BuiltinBody)
    case lisp(argnames: [String], body: LispType)
}

enum LispType: CustomStringConvertible {
    case list([LispType])
    case atom(String)
    case float(lFloat)
    case `string`(String)
    case boolean(Bool)
    case `nil`
    case function(FunctionBody)
    
    var description: String {
        switch self {
        case .atom(let str):
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
    
    func bindLocal(name: String, value: LispType) -> String {
        if bindingStack.count > 0 {
            bindingStack[bindingStack.count - 1][name] = value
        }
        
        rootBindings[name] = value
        
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
    
    func read_token(_ token: TokenType, reader: Reader) -> LispType {
        switch token {
        case .lParen:
            return read_list(reader)
        case .atom(let str):
            return .atom(str)
        case .lString(let str):
            return .string(str)
        case .number(let num):
            return .float(num)
        default:
            Swift.print("Error while reading token \(token) at index \(reader.pos)")
            return .nil
        }
    }
    
    func read_list(_ reader: Reader) -> LispType {
        var list: [LispType] = []
        
        while let token = reader.nextToken() {
            switch token {
            case .rParen:
                return LispType.list(list)
            default:
                list.append(read_token(token, reader: reader))
            }
        }
        
        return .list(list)
    }
    
    func read(_ input: String) -> LispType {
        let tokenizer = Tokenizer(source: input)
        let tokens = tokenizer.tokenizeInput()
        
        let reader = Reader(tokens: tokens)
        return read_token(reader.nextToken()!, reader: reader)
    }

    func eval(_ form: LispType, env: Environment) throws -> LispType {
        switch form {
            
        case .list(let list):
            guard let f = list.first else { return form }
            
            var item = f
            
            // If the first item in the list is an atom, check the environment to see
            // if it has been bound
            if case let .atom(name) = item {
                if let bind = env.currentNamespace.getValue(name: name) {
                    item = bind
                }
            }
            
            if case let .function(body) = item {
                switch body {
                case .native(body: let nativeBody):
                    return try nativeBody(Array(list.dropFirst()), env)
                case .lisp(argnames: let argnames, body: let lispBody):
                    return form
                }
            } else {
                throw LispError.runtime(msg: "'\(String(describing: list.first))' is not a function.")
            }
            
        case .atom(let atom):
            if let val = env.currentNamespace.getValue(name: atom) {
                return val
            }
            return form
            
        default:
            return form
        }
    }

    func print() {
        
    }

    func rep(_ input: String) -> String {
        let form = read(input)
        
        do {
            let rv = try eval(form, env: environment)
            return String(describing: rv)
            
        } catch let LispError.runtime(msg: message) {
            return "Runtime Error: \(message)"
        } catch let LispError.general(msg: message) {
            return "Error: \(message)"
        } catch {
            return String(describing: error)
        }
    }
}

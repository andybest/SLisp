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

public class Namespace: Hashable {
    let name: String
    var rootBindings     = [String: LispType]()
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


// Namespaces
extension Parser {

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

    func getValue(_ name: String, withEnvironment env: Environment) throws -> LispType {
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
            if let ns = env.namespace.namespaceRefs[targetNamespace!] {
                if let val = ns.rootBindings[binding] {
                    return val
                }
            } else if let ns = namespaces[targetNamespace!] {
                if let val = ns.rootBindings[binding] {
                    return val
                }
            }
        } else {
            // Search environment
            
            var currentEnv: Environment? = env
            while currentEnv != nil {
                if let val = currentEnv!.localBindings[name] {
                    return val
                }
                
                currentEnv = currentEnv?.parent
            }

            if let val = env.namespace.rootBindings[name] {
                return val
            }

            for ns in env.namespace.namespaceImports {
                if let val = ns.rootBindings[name] {
                    return val
                }
            }
        }

        throw LispError.general(msg: "Value \(name) not found.")
    }
    
    func setValue(name: String, value: LispType, withEnvironment environment: Environment) throws -> LispType {
        // Search binding from the top for target value
        
        var currentEnv: Environment? = environment
        while currentEnv != nil {
            if currentEnv!.localBindings[name] != nil {
                currentEnv!.localBindings[name] = value
                return .string(name)
            }
            
            currentEnv = currentEnv?.parent
        }
        
        throw LispError.runtime(msg: "Unable to set value \(name) as it can't be found")
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
        
        coreImports.forEach {
            if $0 != ns.name {
                importNamespace(createOrGetNamespace($0), toNamespace: ns)
            }
        }
        
        /*pushCWD(workingDir: "stdlib")
        _ = evalFile(path: "autoinclude.sl", environment: Environment(ns: ns))
        do {
            try popCWD()
        } catch {
            print("Unable to pop CWD!")
        }*/
        
        return ns
    }
}

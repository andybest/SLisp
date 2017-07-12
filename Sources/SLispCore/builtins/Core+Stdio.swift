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

extension Core {
    
    func initStdioBuiltins() {
        
        addBuiltin("fopen", docstring: "") { args, parser, env in
            if args.count != 2 {
                throw LispError.runtime(msg: "'fopen' requires 2 arguments.")
            }
            
            guard case let .string(path) = args[0] else {
                throw LispError.runtime(msg: "'fopen' requires the first argument to be a string")
            }
            
            let possibleModes: [String: String] = [
                "read": "r",
                "write": "w",
                "append": "a",
                "read-update": "r+",
                "write-update": "w+",
                "append-update": "a+",
                "read-binary": "rb",
                "write-binary": "wb",
                "append-binary": "ab",
                "read-update-binary": "rb+",
                "write-update-binary": "wb+",
                "append-update-binary": "ab+"
            ]
            
            guard case let .key(mode) = args[1] else {
                throw LispError.runtime(msg: "'fopen' requires the second argument to be a file mode")
            }
            
            guard let modeString = possibleModes[mode] else {
                throw LispError.runtime(msg: "'fopen': Invalid mode: \(String(describing: args[1]))")
            }
            
            guard let file = fopen(path, modeString) else {
                throw LispError.runtime(msg: "Unable to open file")
            }
            
            return .file(file.pointee)
        }
        
        addBuiltin("fclose", docstring: "") { args, parser, env in
            if args.count != 1 {
                throw LispError.runtime(msg: "'fclose' expects one argument")
            }
            
            guard case var .file(f) = args[0] else {
                throw LispError.runtime(msg: "'fclose' expects the argument to be a FILE")
            }
            
            let rv = fclose(&f)
            
            return .boolean(rv == 0)
        }
        
        addBuiltin("fputs", docstring: "") { args, parser, env in
            if args.count != 2 {
                throw LispError.runtime(msg: "'fputs' requires 2 arguments")
            }
            
            guard case let .string(str) = args[0] else {
                throw LispError.runtime(msg: "'fputs' expects the first argument to be a string")
            }
            
            guard case var .file(f) = args[1] else {
                throw LispError.runtime(msg: "'fputs' expects the second argument to be a FILE")
            }
            
            let rv = fputs(str.cString(using: .ascii), &f)
            fflush(&f)
            
            return .boolean(rv >= 0)
        }
        
        addBuiltin("fgets", docstring: "") { args, parser, env in
            if args.count != 2 {
                throw LispError.runtime(msg: "'fgets' requires 2 arguments")
            }
            
            guard case let .number(.integer(len)) = args[0] else {
                throw LispError.runtime(msg: "'fgets' expects the first argument to be an integer")
            }
            
            guard case var .file(f) = args[1] else {
                throw LispError.runtime(msg: "'fgets' expects the second argument to be a FILE")
            }
            
            var buf = [Int8](repeating: 0, count: len)
            guard let cstr = fgets(&buf, Int32(len), &f) else {
                return .nil
            }
            
            let str = cstr.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<CChar>.size * len) {
                return String(cString: $0)
            }
            
            return .string(str)
        }
        
        addBuiltin("rewind", docstring: "") { args, parser, env in
            if args.count != 1 {
                throw LispError.runtime(msg: "'rewind' requires 1 argument")
            }
            
            guard case var .file(f) = args[0] else {
                throw LispError.runtime(msg: "'rewind' expects the argument to be a FILE")
            }
            
            rewind(&f)
            
            return .nil
        }
        
        addBuiltin("fseek", docstring: "") { args, parser, env in
            if args.count != 2 {
                throw LispError.runtime(msg: "'fseek' requires 2 arguments")
            }
            
            guard case let .number(.integer(pos)) = args[0] else {
                throw LispError.runtime(msg: "'fseek' expects the first argument to be an integer")
            }
            
            guard case var .file(f) = args[1] else {
                throw LispError.runtime(msg: "'fseek' expects the second argument to be a FILE")
            }
            
            let rv = fseek(&f, pos, SEEK_SET)
            
            return .boolean(rv == 0)
        }
        
    }
    
}

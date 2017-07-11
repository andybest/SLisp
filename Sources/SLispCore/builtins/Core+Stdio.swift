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
        
        addBuiltin("fopen", docstring: "") { args, env in
            if args.count != 2 {
                throw LispError.runtime(msg: "'fopen' requires 2 arguments.")
            }
            
            guard case let .string(path) = args[0] else {
                throw LispError.runtime(msg: "'fopen' requires the first argument to be a string")
            }
            
            guard case let .list(modeList) = args[1] else {
                throw LispError.runtime(msg: "'fopen' requires the second argument to be a list of modes")
            }
            
            let possibleModes: [String: String] = [
                "read": "r",
                "write": "w",
                "append": "a",
                "read-update": "r+",
                "write-update": "w+",
                "append-update": "a+"
            ]
            
            let modeString: [String] = try modeList.map {
                guard case let .key(mode) = $0, let modeString = possibleModes[mode] else {
                    throw LispError.runtime(msg: "'fopen': Invalid mode: \(String(describing: $0))")
                }
                
                return modeString
            }
            
            guard let file = fopen(path, modeString.joined()) else {
                throw LispError.runtime(msg: "Unable to open file")
            }
            
            return .file(file.pointee)
        }
        
    }
    
}

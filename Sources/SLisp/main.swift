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
import SLispCore

func checkArgs() {
    if CommandLine.arguments.count < 2 {
        runRepl()
    } else {
        let path = CommandLine.arguments[1]
        if FileManager.default.fileExists(atPath: path) {
            do {
                let parser = try Parser()
                _ = parser?.evalFile(path: path, environment: Environment(ns: parser!.currentNamespace))
            } catch {
                print("Uncaught exception:\n\(error)")
            }
            
        } else {
            print("Cannot find SLisp source file at path \(path)")
        }
    }
}

func runRepl() {
    do {
        let repl = try Repl()
        try repl?.mainLoop()
    } catch {
        print(error)
    }
}

checkArgs()

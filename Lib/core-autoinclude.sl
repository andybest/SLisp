; MIT License
;
; Copyright (c) 2016 Andy Best
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

; This file will be included by default into any generated namespace


; Macro for shorthand function declarations
(defmacro defn
    (function
        "defn
(name [docstring] args body)
    Defines a function with the given name. Accepts an optional docstring."
    (fName & body)
        (let (docstring (if (string? (first body)) (first body) nil)
              args (if (nil? docstring) (first body) (at body 1))
              fBody (if (nil? docstring) (rest body) (rest (rest body))))
            (if (nil? docstring)
                `(def ~fName ~(concat `(function ~args) fBody))
                `(def ~fName ~(concat `(function ~docstring ~args) fBody))))))

(defn reduce (f & args)
    (let (argCount (count args))
        (if (|| (< argCount 1) (> argCount 2))
            (do (print "Error: reduce requires 1 or 2 arguments") nil)
            (do (print args) (let (val (if (== argCount 2) (first args) nil)
                  coll (if (== argCount 2) (at args 1) (first args)))
                (if (|| (nil? coll) (empty? coll))  ; If the collection is empty, return the value
                    val
                    (if (nil? val)
                        (reduce f (f (first coll) (at coll 1)) (rest (rest coll)))
                        (reduce f (f val (first coll))))))))))

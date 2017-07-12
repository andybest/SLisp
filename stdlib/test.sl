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

(ns core.test)

;; ANSI Colors

(def *ansi-color-red*       "\x1b[31m")
(def *ansi-color-green*     "\x1b[32m")
(def *ansi-color-yellow*    "\x1b[33m")
(def *ansi-color-blue*      "\x1b[34m")
(def *ansi-color-magenta*   "\x1b[35m")
(def *ansi-color-cyan*      "\x1b[36m")
(def *ansi-color-reset*     "\x1b[0m")

(defn color-text
    (color text)
    (let (ansiColor (case color
                        :red *ansi-color-red*
                        :green *ansi-color-green*
                        :yellow *ansi-color-yellow*
                        :blue *ansi-color-blue*
                        :magenta *ansi-color-magenta*
                        :cyan *ansi-color-cyan*
                        :else ""))
        (str ansiColor text *ansi-color-reset*)))

;; Errors

(def *testAssertionError* :testAssertionError)

;; Assertions

(defn assert
    (x & description)
    (if (! x)
        (if (|| (empty? description) (nil? description))
            (throw :testAssertionError)
            (throw :testAssertionError (first description)))))

(defn assertEqual
    (x y & description)
    (apply assert (concat (== x y) description)))

(defn assertNotEqual
    (x y & description)
    (apply assert (concat (! (== x y)) description)))


(defn testAnsi
    ()
    (print (color-text :red "Red text"))
    (print (color-text :green "Green text"))
    (print (color-text :yellow "Yello text"))
    (print (color-text :blue "Blue text"))
    (print (color-text :magenta "Magenta text"))
    (print (color-text :cyan "Cyan text")))

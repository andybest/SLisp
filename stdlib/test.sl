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
            (do
                (print (first description))
                (throw :testAssertionError (first description))))))

(defn assertEqual
    (x y & description)
    (let (desc (if (|| (nil? description) (empty? description))
                    (str "Assertion failure: " x " is not equal to " y)
                    description))
        (apply assert (concat (== x y) desc))))

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


;; Test function

(defmacro deftest
    #((name & body)
        (concat `(defn ~(symbol (str "test-" name))) body)))


;; Test runner

(defn get-tests
    (ns-list)
    (filter #((x)
        (let (name (first x)
              val (second x))
              (&& (== (take (str name) 5) "test-") (function? val))))
        ns-list))

(defn run-test-file
    (path)
    (let (file-contents (read-string (str "(do " (slurp path) " *ns* )"))
          file-ns (eval file-contents)
          ns-contents (list-ns file-ns)
          tests (get-tests ns-contents))
          (print (str "Running test file " path))

          ; Run each test
          (let (test-results (map #((t) (run-test (second t) (drop (str (first t)) 5))) tests)
                test-count (count tests)
                pass-count (count (filter #((x) x) test-results))
                fail-count (count (filter #((x) (! x)) test-results)))

                (print "Test file completed")
                (when pass-count 
                    (print (color-text :green (str "\t" pass-count " tests passed"))))
                (when fail-count
                    (print (color-text :red (str "\t" fail-count " tests failed"))))
                
                (== fail-count 0))))

(defn run-test-suite
    (& testFiles)
    (print "Running test suite")
    (let (results (map run-test-file testFiles)
          failed-test-files (filter #((x) (! x)) results))
          (if (> (count failed-test-files) 0)
                (do
                    (print (color-text :red "Test suite failed"))
                    (exit 1))
                (do
                    (print (color-text :green "Test suite passed"))
                    (exit 0)))))

(defn run-test
    (test test-name)
    (print (str "Running test: " test-name))
    (try
        (test)
        (print (color-text :green "\tPASS"))
        true
    (catch e
        (print (color-text :red "\tFAIL"))
        false)))

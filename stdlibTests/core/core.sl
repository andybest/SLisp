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

(ns core-tests
    (:refer core.test))

(deftest map-applies-function-to-items ()
    (let (test-input '(1 2 3 4 5 6)
          add-fn #((x) (+ x 1)))

          (assertEqual 
            (map add-fn test-input)
            '(2 3 4 5 6 7))))

(deftest reduce-reduces-values ()
    (let (test-input '(1 2 3 4 5)
          add-fn #((x y) (+ x y)))

          (assertEqual
            (reduce add-fn 0 test-input)
            15)))

(deftest filter-filters-values ()
    (let (test-input '(1 2 3 4 5 6 7 8 9 10)
          test-fn #((x) (== (mod x 2) 0)))

          (assertEqual
            (filter test-fn test-input)
            '(2 4 6 8 10))))

(deftest second-returns-second-item ()
    (assertEqual
        (second '(1 2 3 4))
        2))

(deftest reverse-reverses-list ()
    (assertEqual
        (reverse '(1 2 3 4))
        '(4 3 2 1)))

(deftest reverse-reverses-string ()
    (assertEqual
        (reverse "Hello")
        "olleH"))


(deftest less-than-or-equal ()
    (assert (<= 2 10))
    (assert (<= 2 2))
    (assert (! (<= 10 2))))

(deftest greater-than-or-equal ()
    (assert (>= 10 2))
    (assert (>= 10 10))
    (assert (! (>= 10 20))))

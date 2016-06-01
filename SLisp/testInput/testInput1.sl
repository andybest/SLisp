(def add (function (x y) (+ x y)))

(def sub (function (x y) (- x y)))

(print "Testing (add 1 2):" (add 1 2))

(print "Testing (sub 1 2):" (sub 1 2))

(def powInt (function (val original count)
    (cond (> 0 count)
        (powInt (* val original (- count 1)))
        val)))

(def pow (function (x p)
    (powInt x x p)))

(print "2^2:" (pow 2 2))
(print "2^3:" (pow 2 3))
(print "2^4:" (pow 2 4))
(print "2^100:" (pow 2 100))
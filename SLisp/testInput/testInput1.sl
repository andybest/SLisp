(def equal? (function (a b)
    (cond (== a b)
        true
        false)))

(print "1 and 4 equal: " (equal? 1 4))

(print "1 and 1 equal: " (equal? 1 1))

(print "1 and 2 equal: " (equal? 1 2))

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

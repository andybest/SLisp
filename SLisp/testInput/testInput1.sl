(def equal? (function (a b)
    (cond (== a b)
        true
        false)))

(print "1 and 4 equal: " (equal? 1 4))

(print "1 and 1 equal: " (equal? 1 1))

(print "1 and 2 equal: " (equal? 1 2))
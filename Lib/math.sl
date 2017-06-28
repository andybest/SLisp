(ns math)

(def *pi* 3.14159265358979323846)

(def floor (function (x)
    (- x 1 (mod x 1))))

(def max (function (x y)
    (if (> x y) x y)))

(def min (function (x y)
    (if (< x y) x y)))

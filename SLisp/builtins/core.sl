(def reduce (function (l f val)
    (cond (nil? l)
        val
        (reduce (rest l) f (f val (first l))))))
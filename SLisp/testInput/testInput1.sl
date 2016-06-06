(def reduce (function (l f val)
    (cond (nil? l)
        val
        (let (remaining (rest l)
                head (first l))
                (print "val: " val " head: " head " remaining: " remaining)
                (print "f: " (f val head))
            (reduce remaining f (f val head))))))

(print "reduce 1 2 3: " 
    (reduce (list 1 2 3) (function (a b)
            (+ a b)) 0))
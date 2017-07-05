; Seive of Eratosthenes

(defn seive
    (str"seive"
    "(n)"
    "Find primes from 0 to n")

    (n)

    (let (s (math/range 0 (+ n 1))
          m (math/sqrt n))
        (if (< n 2)
            '()
            (do
                (set-at s 0 1)
                (set-at s 1 1)
                (let (i 2)
                    (while (<= i m)
                        (if (== 0 (at s i))
                            (let (j (* i i))
                                (while (<= j n)
                                    (if (== 0 (at s i))
                                        (set-at s j 1))
                                    (set! j (+ j 1)))
                        (set! i (+ i 1))))))))))
            

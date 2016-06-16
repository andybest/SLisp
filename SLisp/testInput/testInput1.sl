(def rps-name (function (index)
    (cond (== index 0) "Rock"
        (cond (== index 1) "Paper"
            (cond (== index 2) "Scissors"
                nil)))))

(def truth-table (list
                    (list false true false)
                    (list false false true)
                    (list false true false)))

(def outcome (function (p-choice c-choice)
    (at (at truth-table p-choice) c-choice)))

(def rock-paper-scissors (function (q)
    (let (choice (input "(R)ock, (P)aper or (S)cissors?")
          computer-choice (floor (random 0 3))
          player-choice (cond (or (string= choice "R") (string= choice "r")) 0
                            (cond (or (string= choice "P") (string= choice "p")) 1
                                (cond (or (string= choice "S") (string= choice "s")) 2
                                    3))))
    (cond (== 3 player-choice)
        (print "Invalid input: " choice)
        (do
            (print "You chose " (rps-name player-choice) ".")
            (print "The computer chose " (rps-name computer-choice) ".")
                (cond (== player-choice computer-choice)
                    (print "You drew.")
                        (cond (outcome player-choice computer-choice)
                            (print "You win")
                            (print "The computer won"))))))))

(rock-paper-scissors 0)

(def rps-name (function (index)
    (if (== index 0) "Rock"
        (if (== index 1) "Paper"
            (if (== index 2) "Scissors"
                nil)))))

(def truth-table (list
                    (list false true false)
                    (list false false true)
                    (list false true false)))

(def outcome (function (p-choice c-choice)
    (at (at truth-table p-choice) c-choice)))

(def rock-paper-scissors (function ()
    (let (choice (input "(R)ock, (P)aper or (S)cissors? ")
          computer-choice (floor (random 0 2))
          player-choice (if (or (string= choice "R") (string= choice "r")) 0
                            (if (or (string= choice "P") (string= choice "p")) 1
                                (if (or (string= choice "S") (string= choice "s")) 2
                                    3))))
        (if (== 3 player-choice)
            (print "Invalid input: " choice)
            (do
                (print "You chose " (rps-name player-choice) ".")
                (print "The computer chose " (rps-name computer-choice) ".")
                (if (== player-choice computer-choice)
                    (print "You drew.")
                        (if (outcome player-choice computer-choice)
                            (print "You win")
                            (print "The computer won"))))))))

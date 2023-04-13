#!/usr/bin/tclsh
package require wapp

if {![file exists key.pem]} {
    catch {exec openssl genpkey -algorithm RSA -out key.pem}
}

proc check_win {board} {
    set win {{1 2 3} {4 5 6} {7 8 9} {1 4 7} {2 5 8} {3 6 9} {1 5 9} {3 5 7}}
    foreach combo $win {
        foreach player {X O} {
            set count 0
            set index [lindex combo 0]
            foreach cell $combo {
                if {[lindex $board [expr {$cell - 1}]] != $player} {
                    break
                }
                incr count
            }
            if {$count == 3} {
                return $player
            }
        }
    }
    # check if it's a tie
    if {[string first {-} $board] == -1} {
        return {tie}
    }
    return {-}
}

proc computer_make_move {board} {
    set win {{1 2 3} {4 5 6} {7 8 9} {1 4 7} {2 5 8} {3 6 9} {1 5 9} {3 5 7}}
    # check if computer can win
    foreach combo $win {
        set count 0
        set index [lindex combo 0]
        foreach cell $combo {
            if {[lindex $board [expr {$cell - 1}]] eq {O}} {
                incr count
            } else {
                set index [expr $cell - 1]
            }
        }
        if {$count == 2} {
            if {[lindex $board $index] == {-}} {
                lset board $index {O}
                return $board
            }
        }
    }
    # check if human can win, block them if they can
    set played 0
    foreach combo $win {
        set count 0
        set index [lindex combo 0]
        foreach cell $combo {
            if {[lindex $board [expr {$cell - 1}]] eq {X}} {
                incr count
            } else {
                set index [expr $cell - 1]
            }
        }
        if {$count == 2 && [lindex $board $index] == {-}} {
            lset board $index {O}
            set played 1
        }
    }
    if {$played == 1} {
        return $board
    }
    # choose something to play if neither condition holds
    for {set i 0} {$i < 9} {incr i} {
        if {[lindex $board $i] == {-}} {
            lset board $i {O}
            return $board
        }
    }
}

proc sign {msg} {
    return [exec << $msg openssl dgst -sha256 -sign key.pem -hex -r | cut -d { } -f1]
}

proc verify {msg signature} {
    return [expr {[sign $msg] == $signature}]
}

proc valid_move {old_board new_board} {
    # Make sure only one spot was updated and that the spot that was updated was valid
    set diff_count 0
    for {set i 0} {$i < 9} {incr i} {
        if {[lindex $old_board $i] != [lindex $new_board $i]} {
            incr diff_count
            # Make sure space is not already occupied
            if {[lindex $old_board $i] == {X} || [lindex $old_board $i] == {O}} {
                return 0
            }
        }
    }
    return [expr {$diff_count == 1}]
}

proc get_file_contents {filename} {
    set fp [open $filename r]
    set file_data [read $fp]
    close $fp
    return $file_data
}

proc wapp-page-index.js {} {
    wapp-mimetype text/javascript
    # Start with an empty board
    wapp "var gameBoard = \['', '', '', '', '', '', '', '', ''\];\nvar signature = \"[sign {- - - - - - - - -}]\";\n"
    wapp [get_file_contents "static/index.js"]
}

proc wapp-page-index.css {} {
    wapp-mimetype text/css
    wapp [get_file_contents "static/index.css"]
}

proc wapp-default {} {
    wapp [get_file_contents "static/index.html"]
}

proc wapp-page-update_board {} {
    # allow cross-origin requests because otherwise the ssl reverse proxy thing breaks
    wapp-allow-xorigin-params
    # get prev_board, new_board, signature
    set prev_board [wapp-param prev_board]
    set new_board [wapp-param new_board]
    set signature [wapp-param signature]

    # verify previous board signature
    if [verify $prev_board $signature] {
        # verify move
        if [valid_move $prev_board $new_board] {
            set message {}
            set winner [check_win $new_board]
            if {$winner == "tie"} {
                set message "Cat's game!"
            } elseif {$winner == "X"} {
                set flag [get_file_contents "../flag"]
                set message "Impossible! You won against the unbeatable AI! $flag"
            } elseif {$winner == "O"} {
                set message "Haha I win!"
            } else {
                set new_board [computer_make_move $new_board]
                # Check if computer won or it tied the game
                set winner [check_win $new_board]
                if {$winner == "O"} {
                    set message "Haha I win!"
                } elseif {$winner == "tie"} {
                    set message "Cat's game!"
                }
            }
            # compute signature of new board
            set signature [sign $new_board]
            # send the new board, signature, and message
            wapp "$new_board,$signature,$message"
        } else {
            wapp "$prev_board,$signature,Invalid move!"
        }
    } else {
        wapp "$prev_board,$signature,No hacking allowed!"
    }
}

wapp-start $argv

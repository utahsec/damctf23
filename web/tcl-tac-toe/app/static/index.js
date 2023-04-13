// Initialize previous board as a global variable
var prev_board = [];

// Get the game board squares
const squares = document.querySelectorAll('.square');

function board_to_tcl_list(board) {
    let cells = [];
    for (x of board) {
        cells.push(x != "" ? x : "-");
    }
    return cells.join(" ");
}

function tcl_list_to_board(tcl_list) {
    let l = tcl_list.split(" ");
    let res = [];
    for (x of l) {
        res.push(x == "-" ? "" : x);
    }
    return res;
}

function post_board_update(callback) {
    let xhttp = new XMLHttpRequest();
    xhttp.open("POST", "/update_board", true);
    xhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    prev_board_data = encodeURIComponent(board_to_tcl_list(prev_board));
    new_board_data = encodeURIComponent(board_to_tcl_list(gameBoard));
    let data = `prev_board=${prev_board_data}&new_board=${new_board_data}&signature=${encodeURIComponent(signature)}`
    xhttp.onreadystatechange = function() {
        if (xhttp.readyState == 4 && xhttp.status == 200) {
            let resp = this.responseText.split(",");
            let new_board = tcl_list_to_board(resp[0]);
            let new_signature = resp[1];
            let message = resp[2];
            callback(new_board, new_signature, message);
        }
    }
    xhttp.send(data);
}

// Add event listeners to each square
squares.forEach(square => {
    square.addEventListener('click', () => {
        // Get the index of the clicked square
        const index = Array.from(squares).indexOf(square);

        // Check if the square is empty
        if (gameBoard[index] === '') {
            prev_board = Array.from(gameBoard);
            // Update the game board state
            gameBoard[index] = 'X';
            // Update the square content with the player's symbol
            square.textContent = 'X';

            post_board_update((new_board, new_signature, message) => {
                gameBoard = new_board;
                signature = new_signature;
                for (let i = 0; i < squares.length; i++) {
                    squares[i].textContent = gameBoard[i];
                }
                if (message != "") {
                    setTimeout(()=>{
                        alert(message);
                        if (message.startsWith("Impossible") || message.startsWith("Haha") || message.startsWith("Cat")) {
                            location.reload();
                        }
                    }, 250);
                }
            });
        }
    });
});

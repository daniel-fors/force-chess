package main

import "core:math/rand"

// NOTE: There's a lot of cleanup that can be done here
generate_starting_pos :: proc() -> Board {
    board: Board = {}

    // Elephant
    choise := rand.int_max(2) * 4
    board[choise] = u8(Piece.Elephant) | u8(Team.White)
    board[48 - choise] = u8(Piece.Elephant) | u8(Team.Black)

    // Bishop
    choise = rand.int_max(7) * 2 + 1
    board[choise] = u8(Piece.Bishop) | u8(Team.White)
    board[48 - choise] = u8(Piece.Bishop) | u8(Team.Black)

    // Bishop blockers (Pawns)
    if choise == 7 || choise == 13 {
        // White
        board[15] = u8(Piece.Pawn) | u8(Team.White)
        board[19] = u8(Piece.Pawn) | u8(Team.White)

        // Black
        board[48 - 15] = u8(Piece.Pawn) | u8(Team.Black)
        board[48 - 19] = u8(Piece.Pawn) | u8(Team.Black)
    } else if choise == 9 || choise == 11 {
        // White
        board[17] = u8(Piece.Pawn) | u8(Team.White)

        // Black
        board[48 - 17] = u8(Piece.Pawn) | u8(Team.Black)
    }

    // Queen
    choise = rand.int_max((choise == 3 || choise >= 7) ? 4 : 3)
    for i := 0; i <= choise; i += 1 {
        mirror_index := 42 + i - (i / 7) * 14
        if board[i] != 0 || board[mirror_index] != 0 do choise += 1
    }
    assert(choise < 7)
    mirror_choise := 42 + choise - (choise / 7) * 14
    board[choise] = u8(Piece.Queen) | u8(Team.White)
    board[mirror_choise] = u8(Piece.Queen) | u8(Team.Black)

    // King
    options := 7
    for i in 0..<7 {
        mirror_index := 42 + i - (i / 7) * 14
        if board[i] != 0 || board[mirror_index] != 0 do options -= 1
    }
    choise = rand.int_max(options)
    for i := 0; i <= choise; i += 1 {
        mirror_index := 42 + i - (i / 7) * 14
        if board[i] != 0 || board[mirror_index] != 0 do choise += 1
    }
    assert(choise < 7)
    mirror_choise = 42 + choise - (choise / 7) * 14
    board[choise] = u8(Piece.King) | u8(Team.White)
    board[mirror_choise] = u8(Piece.King) | u8(Team.Black)

    // Knight
    options = 14
    for i in 0..<14 {
        mirror_index := 42 + i - (i / 7) * 14
        if board[i] != 0 || board[mirror_index] != 0 do options -= 1
    }
    choise = rand.int_max(options)
    for i := 0; i <= choise; i += 1 {
        mirror_index := 42 + i - (i / 7) * 14
        if board[i] != 0 || board[mirror_index] != 0 do choise += 1
    }
    mirror_choise = 42 + choise - (choise / 7) * 14
    board[choise] = u8(Piece.Knight) | u8(Team.White)
    board[mirror_choise] = u8(Piece.Knight) | u8(Team.Black)

    // Rook
    options = 14
    for i in 0..<14 {
        mirror_index := 42 + i - (i / 7) * 14
        if board[i] != 0 || board[mirror_index] != 0 do options -= 1
    }
    choise = rand.int_max(options)
    for i := 0; i <= choise; i += 1 {
        mirror_index := 42 + i - (i / 7) * 14
        if board[i] != 0 || board[mirror_index] != 0 do choise += 1
    }
    mirror_choise = 42 + choise - (choise / 7) * 14
    board[choise] = u8(Piece.Rook) | u8(Team.White)
    board[mirror_choise] = u8(Piece.Rook) | u8(Team.Black)

    // Third Row Pawns (Forced Rank)
    for i in 7..<14 {
        mirror_index := 42 + i - (i / 7) * 14
        if board[i] != 0 || board[mirror_index] != 0 {
            board[i + 7] = u8(Piece.Pawn) | u8(Team.White)
            board[mirror_index - 7] = u8(Piece.Pawn) | u8(Team.Black)
        }
    }

    // Forced Pawn on backline Bishop
    if (board[1] & 7) == u8(Piece.Bishop) || (board[5] & 7) == u8(Piece.Bishop) {
        third_row := board[17] == 0
        second_row := board[9] == 0 || board[11] == 0
        if third_row && second_row {
            if rand.int_max(2) == 0 {
                board[17] = u8(Piece.Pawn) | u8(Team.White)
                board[48 - 17] = u8(Piece.Pawn) | u8(Team.Black)
            } else {
                if board[9] == 0 do board[9] = u8(Piece.Pawn) | u8(Team.White)
                if board[11] == 0 do board[11] = u8(Piece.Pawn) | u8(Team.White)

                if board[48 - 9] == 0 do board[48 - 9] = u8(Piece.Pawn) | u8(Team.Black)
                if board[48 - 11] == 0 do board[48 - 11] = u8(Piece.Pawn) | u8(Team.Black)
            }
        }
    }

    // Force Pawn on unblocked Queen
    for i in 0..<7 {
        if i == 3 do continue

        if (board[i] & 7) == u8(Piece.Queen) {
            offset := i < 3 ? 8 : 6
            if board[i + offset] == 0 && board[i + offset * 2] == 0 {
                mirror_1 := 42 + (i + offset) - ((i + offset) / 7) * 14
                mirror_2 := 42 + (i + offset * 2) - ((i + offset * 2) / 7) * 14
                assert(board[mirror_1] == 0 && board[mirror_2] == 0)

                first_empty := board[i + offset + 7] == 0
                second_empty := board[i + offset * 2 - 7] == 0

                index: int
                if first_empty && !second_empty {
                    index = i + offset
                } else if !first_empty && second_empty {
                    index = i + offset * 2
                } else {
                    assert(first_empty && second_empty)
                    index = i + offset * (rand.int_max(2) + 1)
                }

                mirror_index := 42 + index - (index / 7) * 14

                board[index] = u8(Piece.Pawn) | u8(Team.White)
                board[mirror_index] = u8(Piece.Pawn) | u8(Team.Black)
            } else {
                mirror_1 := 42 + (i + offset) - ((i + offset) / 7) * 14
                mirror_2 := 42 + (i + offset * 2) - ((i + offset * 2) / 7) * 14
                assert(board[mirror_1] != 0 || board[mirror_2] != 0)
            }
        }
    }

    // Remaining Pawns
    for i in 0..<7 {
        pawn_1 := i + 7
        pawn_2 := i + 14

        // Need pawn
        if board[pawn_1] == 0 && board[pawn_2] == 0 {
            index := rand.int_max(2) == 0 ? pawn_1 : pawn_2
            mirror_index := 42 + index - (index / 7) * 14

            board[index] = u8(Piece.Pawn) | u8(Team.White)
            board[mirror_index] = u8(Piece.Pawn) | u8(Team.Black)
        }
    }

    return board
}

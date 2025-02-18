package main

import "core:fmt"

/* Move Set
* King 1, -7, -1, 7
* Pawn 7, 14, 6, 8
* Knight 9, -5, -13, -15, -9, 5, 13, 15
* Bishop 8x, -6x, -8x, 6x
* Rook 1x, -7x, -1x, 7x
* Queen 1x, -6x, -7x, -8x, -1, 6, 7, 8
* Elephant 16, -12, -16, 12
*/

v2i32 :: [2]i32

KING_MOVES :: []v2i32 { { 1, 0 }, { 0, -1 }, { -1, 0 }, { 0, 1 } }
KNIGHT_MOVES :: []v2i32 { { 2, 1 }, { 2, -1 }, { 1, -2 }, { -1, -2 }, { -2, -1 }, { -2, 1 }, { -1, 2 }, { 1, 2 } }
BISHOP_MOVES :: []v2i32 { { 1, 1 }, { 1, -1 }, { -1, -1 }, { -1, 1 } }
ROOK_MOVES :: []v2i32 { { 1, 0 }, { 0, -1 }, { -1, 0 }, { 0, 1 } }
QUEEN_MOVES :: []v2i32 { { 1, 0 }, { 1, 1 }, { 0, -1 }, { 1, -1 }, { -1, 0 }, { -1, -1 }, { 0, 1 }, { -1, 1 } }
ELEPHANT_MOVES :: []v2i32 { { 2, 2 }, { 2, -2 }, { -2, -2 }, { -2, 2 } }

index :: proc(coord: v2i32) -> i32 {
    return coord.x + coord.y * 7
}

possible_moves :: proc(board: ^Board, pos: i32, allocator := context.temp_allocator) -> [dynamic]i32 {
    assert(in_bounds(pos, 0, 0))

    moves: [dynamic]i32

    piece: Piece = Piece(board[pos] & PIECE_MASK)
    team: Team = Team(board[pos] & TEAM_MASK)

    #partial switch team {
        //case .White: color = LIGHT_PIECE
        //case .Black: color = DARK_PIECE
    }

    // TODO: Check for check

    #partial switch piece {
        case .King:     moves = king_moves(board, pos, team, allocator)
        case .Pawn:     moves = pawn_moves(board, pos, team, allocator)
        case .Elephant: moves = elephant_moves(board, pos, team, allocator)
        case .Knight:   moves = knight_moves(board, pos, team, allocator)
        case .Bishop:   moves = bishop_moves(board, pos, team, allocator)
        case .Rook:     moves = rook_moves(board, pos, team, allocator)
        case .Queen:    moves = queen_moves(board, pos, team, allocator)
    }
    return moves
}

king_moves :: proc(board: ^Board, pos: i32, team: Team, allocator := context.temp_allocator) -> [dynamic]i32 {
    moves := make([dynamic]i32, allocator)

    for move in KING_MOVES {
        if in_bounds(pos, move.x, move.y) {
            delta_pos := index(move)
            if Team(board[pos + delta_pos] & TEAM_MASK) != team {
                append(&moves, pos + delta_pos)
            }
        }
    }

    return moves
}

// TODO: En pesante
pawn_moves :: proc(board: ^Board, pos: i32, team: Team, allocator := context.temp_allocator) -> [dynamic]i32 {
    moves := make([dynamic]i32, allocator)

    // White
    rank_min: i32 = 7
    rank_max: i32 = 14

    forward: v2i32 = { 0, 1 }
    double: v2i32 = { 0, 2 }
    left_capture: v2i32 = { -1, 1 }
    right_capture: v2i32 = { 1, 1 }

    if team == .Black {
        rank_min = 35
        rank_max = 42

        forward = { 0, -1 }
        double = { 0, -2 }
        left_capture = { -1, -1 }
        right_capture = { 1, -1 }
    }

    // move forward
    delta_pos := index(forward)
    if in_bounds(pos, forward.x, forward.y) && board[pos + delta_pos] == 0 {
        append(&moves, pos + delta_pos)
        // can do double
        delta_pos = index(double)
        if pos >= rank_min && pos < rank_max && board[pos + delta_pos] == 0 {
            append(&moves, pos + delta_pos)
        }
    }
    // capture
    delta_pos = index(left_capture)
    if in_bounds(pos, left_capture.x, left_capture.y) && capture(board[pos + delta_pos], team) {
        append(&moves, pos + delta_pos)
    }
    delta_pos = index(right_capture)
    if in_bounds(pos, right_capture.x, right_capture.y) && capture(board[pos + delta_pos], team) {
        append(&moves, pos + delta_pos)
    }

    return moves
}

knight_moves :: proc(board: ^Board, pos: i32, team: Team, allocator := context.temp_allocator) -> [dynamic]i32 {
    moves := make([dynamic]i32, allocator)

    for move in KNIGHT_MOVES {
        if in_bounds(pos, move.x, move.y) {
            delta_pos := index(move)
            if Team(board[pos + delta_pos] & TEAM_MASK) != team {
                append(&moves, pos + delta_pos)
            }
        }
    }

    return moves
}

elephant_moves :: proc(board: ^Board, pos: i32, team: Team, allocator := context.temp_allocator) -> [dynamic]i32 {
    moves := make([dynamic]i32, allocator)

    for move in ELEPHANT_MOVES {
        if in_bounds(pos, move.x, move.y) {
            delta_pos := index(move)
            if Team(board[pos + delta_pos] & TEAM_MASK) != team {
                append(&moves, pos + delta_pos)
            }
        }
    }

    return moves
}

// TODO: bishop_moves, rook_moves, & queen_moves can be merged into one

bishop_moves :: proc(board: ^Board, pos: i32, team: Team, allocator := context.temp_allocator) -> [dynamic]i32 {
    moves := make([dynamic]i32, allocator)

    for dir in BISHOP_MOVES {
        for i: i32 = 1; i <= 5; i += 1 {
            move := v2i32 { dir.x * i, dir.y * i }
            delta_pos := index(move)

            if !in_bounds(pos, move.x, move.y) {
                break
            }

            if Team(board[pos + delta_pos] & TEAM_MASK) == team {
                break
            }

            append(&moves, pos + delta_pos)

            if capture(board[pos + delta_pos], team) {
                break
            }
        }
    }

    return moves
}

rook_moves :: proc(board: ^Board, pos: i32, team: Team, allocator := context.temp_allocator) -> [dynamic]i32 {
    moves := make([dynamic]i32, allocator)

    for dir in ROOK_MOVES {
        for i: i32 = 1; i <= 5; i += 1 {
            move := v2i32 { dir.x * i, dir.y * i }
            delta_pos := index(move)

            if !in_bounds(pos, move.x, move.y) {
                break
            }

            if Team(board[pos + delta_pos] & TEAM_MASK) == team {
                break
            }

            append(&moves, pos + delta_pos)

            if capture(board[pos + delta_pos], team) {
                break
            }
        }
    }

    return moves
}

queen_moves :: proc(board: ^Board, pos: i32, team: Team, allocator := context.temp_allocator) -> [dynamic]i32 {
    moves := make([dynamic]i32, allocator)

    for dir in QUEEN_MOVES {
        for i: i32 = 1; i <= 5; i += 1 {
            move := v2i32 { dir.x * i, dir.y * i }
            delta_pos := index(move)

            if !in_bounds(pos, move.x, move.y) {
                break
            }

            if Team(board[pos + delta_pos] & TEAM_MASK) == team {
                break
            }

            append(&moves, pos + delta_pos)

            if capture(board[pos + delta_pos], team) {
                break
            }
        }
    }

    return moves
}
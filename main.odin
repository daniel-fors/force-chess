package main

import "core:fmt"
import "core:mem"

import rl "vendor:raylib"

SQUARE_SIZE :: 108

WINDOW_WIDTH  :: SQUARE_SIZE * 9
WINDOW_HEIGHT :: SQUARE_SIZE * 9

TEXTURE_SIZE :: 1280

LIGHT_SQUARE: rl.Color = { 229, 228, 206, 255 }
DARK_SQUARE:  rl.Color = { 161, 103,  59, 255 }
LIGHT_PIECE:  rl.Color = { 231, 210, 191, 255 }
DARK_PIECE:   rl.Color = {  75,  44,  26, 255 }

MARKED_LIGHT: rl.Color = { 255, 243, 161, 255 }
MARKED_DARK:  rl.Color = { 201, 138,  24, 255 }

ROWS :: 7
RANKS :: 7
NUM_SQUARES :: ROWS * RANKS
Board :: [NUM_SQUARES]u8

Piece :: enum {
    None,
    King,
    Pawn,
    Knight,
    Bishop,
    Rook,
    Queen,
    Elephant,
}

Team :: enum {
    None,
    White = 8,
    Black = 16,
}

PIECE_MASK :: 0x7
TEAM_MASK  :: 0x18

in_bounds :: proc(pos: i32, dx, dy: i32) -> bool {
    x := (pos % 7) + dx
    y := (pos / 7) + dy
    return x >= 0 && x < 7 && y >= 0 && y < 7
}

capture :: proc(piece: u8, team: Team) -> bool {
    return piece & PIECE_MASK != 0 && Team(piece & TEAM_MASK) != team
}

main :: proc() {
	// Lets wrap the context allocator with a tracking allocator
	// This will track memory leaks from the context.allocator
	track_alloc: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track_alloc, context.allocator)
	context.allocator = mem.tracking_allocator(&track_alloc)
	defer {
		// At the end of the program, lets print out the results
		fmt.eprintf("\n")
		// Memory leaks
		for _, entry in track_alloc.allocation_map {
			fmt.eprintf("- %v leaked %v bytes\n", entry.location, entry.size)
		}
		// Double free etc.
		for entry in track_alloc.bad_free_array {
			fmt.eprintf("- %v bad free\n", entry.location)
		}
		mem.tracking_allocator_destroy(&track_alloc)
		fmt.eprintf("\n")

		// Free the temp_allocator so we don't forget it
		// The temp_allocator can be used to allocate temporary memory
		free_all(context.temp_allocator)
	}

	// --- User code starts here ---
	fmt.println("Hello Odin coder!")

    rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "Force Chess")
    defer rl.CloseWindow()

    load_textures()
    defer unload_textures()

    // BOARD
    board: Board

    selected: Maybe(i32)

    board[7] = u8(Piece.Bishop) | u8(Team.White)
    board[8] = u8(Piece.Queen) | u8(Team.Black)
    board[9] = u8(Piece.Knight) | u8(Team.White)
    board[17] = u8(Piece.King) | u8(Team.White)
    board[18] = u8(Piece.Pawn) | u8(Team.Black)
    board[19] = u8(Piece.Elephant) | u8(Team.White)

    for !rl.WindowShouldClose() {

        if rl.IsKeyPressed(.SPACE) {
            board = generate_starting_pos()
        }

        mouse_pos: rl.Vector2 = rl.GetMousePosition()

        if rl.IsMouseButtonPressed(.LEFT) {
            if mouse_pos.x < SQUARE_SIZE || mouse_pos.x >= WINDOW_WIDTH - SQUARE_SIZE ||
               mouse_pos.y < SQUARE_SIZE || mouse_pos.y >= WINDOW_HEIGHT - SQUARE_SIZE
            {
                selected = nil
            } else {
                x := i32(mouse_pos.x - SQUARE_SIZE) / SQUARE_SIZE
                // Invert y-axis
                y := 6 - i32(mouse_pos.y - SQUARE_SIZE) / SQUARE_SIZE
                index := x + y * 7

                if current_selection, has_selection := selected.(i32); has_selection {
                    current_moves := possible_moves(&board, current_selection)
                    for move in current_moves {
                        if move == index {
                            // MAKING A MOVE!
                            board[move] = board[current_selection]
                            board[current_selection] = 0
                        }
                    }
                    selected = nil
                } else {
                    selected = index
                }
            }
        }

        if rl.IsMouseButtonPressed(.RIGHT) {
            selected = nil
        }

        // Render
        rl.BeginDrawing()

        rl.ClearBackground(rl.BLACK)

        draw_board(selected)
        draw_pieces(&board, selected)

        if hold, is_held := selected.(i32); is_held {
            pos_x := mouse_pos.x - SQUARE_SIZE * 0.5
            pos_y := mouse_pos.y - SQUARE_SIZE * 0.5

            if board[hold] != 0 {
                piece := Piece(board[hold] & PIECE_MASK)
                team := Team(board[hold] & TEAM_MASK)

                // Check possible moves
                moves := possible_moves(&board, hold)
                for move in moves {
                    draw_possible_move(move, board[move] != 0)
                }

                draw_piece(piece, team, pos_x, pos_y)
            }
        }

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
}

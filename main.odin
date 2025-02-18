package main

import "core:fmt"
import "core:mem"
import "core:math/rand"

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

NUM_SQUARES :: 49
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

    // TEXTURES. TODO: #load
    bishop   := rl.LoadTexture("resources/bishop.png")
    elephant := rl.LoadTexture("resources/elephant.png")
    king     := rl.LoadTexture("resources/king.png")
    knight   := rl.LoadTexture("resources/knight.png")
    pawn     := rl.LoadTexture("resources/pawn.png")
    queen    := rl.LoadTexture("resources/queen.png")
    rook     := rl.LoadTexture("resources/rook.png")

    dot      := rl.LoadTexture("resources/dot.png")
    circle   := rl.LoadTexture("resources/circle.png")

    defer rl.UnloadTexture(bishop)
    defer rl.UnloadTexture(elephant)
    defer rl.UnloadTexture(king)
    defer rl.UnloadTexture(knight)
    defer rl.UnloadTexture(pawn)
    defer rl.UnloadTexture(queen)
    defer rl.UnloadTexture(rook)

    // BOARD
    board: Board

    marked_square: Maybe(i32)

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
                marked_square = nil
            } else {
                x := i32(mouse_pos.x - SQUARE_SIZE) / SQUARE_SIZE
                // Invert y-axis
                y := 6 - i32(mouse_pos.y - SQUARE_SIZE) / SQUARE_SIZE
                marked_square = x + y * 7
            }
        }
        if rl.IsMouseButtonPressed(.RIGHT) {
            marked_square = nil
        }

        // Render

        rl.BeginDrawing()

        rl.ClearBackground(rl.BLACK)

        // RENDER CHESS BOARD
        for y: i32 = 0; y < 7; y += 1 {
            for x: i32 = 0; x < 7; x += 1 {

                index := x + y * 7

                render_x := x + 1
                render_y := 7 - y
                // Draw Square
                square_color := (x + y) % 2 == 0 ? DARK_SQUARE : LIGHT_SQUARE

                is_marked: bool
                if marked, ok := marked_square.(i32); ok {
                    is_marked = index == marked
                }

                if is_marked {
                    square_color = (x + y) % 2 == 0 ? MARKED_DARK : MARKED_LIGHT
                }

                rl.DrawRectangle(
                    render_x * SQUARE_SIZE,
                    render_y * SQUARE_SIZE,
                    SQUARE_SIZE,
                    SQUARE_SIZE,
                    square_color)
            }
        }

        // RENDER PIECES
        for y: i32 = 0; y < 7; y += 1 {
            for x: i32 = 0; x < 7; x += 1 {

                index := x + y * 7

                render_x := x + 1
                render_y := 7 - y

                is_marked: bool
                if marked, ok := marked_square.(i32); ok {
                    is_marked = index == marked
                }

                // Draw Piece
                if board[index] != 0 {
                    piece := (Piece)(board[index] & PIECE_MASK)
                    team := (Team)(board[index] & TEAM_MASK)

                    tex: rl.Texture2D
                    color: rl.Color = DARK_PIECE

                    #partial switch piece {
                        case .King:     tex = king
                        case .Pawn:     tex = pawn
                        case .Knight:   tex = knight
                        case .Bishop:   tex = bishop
                        case .Rook:     tex = rook
                        case .Queen:    tex = queen
                        case .Elephant: tex = elephant
                    }

                    #partial switch team {
                        case .White: color = LIGHT_PIECE
                        case .Black: color = DARK_PIECE
                    }

                    source_rect := rl.Rectangle { 0, 0, TEXTURE_SIZE, TEXTURE_SIZE }
                    dest_rect   := rl.Rectangle {
                        f32(render_x) * SQUARE_SIZE,
                        f32(render_y) * SQUARE_SIZE,
                        SQUARE_SIZE,
                        SQUARE_SIZE,
                    }

                    if is_marked {
                        dest_rect.x = mouse_pos.x - SQUARE_SIZE * 0.5
                        dest_rect.y = mouse_pos.y - SQUARE_SIZE * 0.5

                        // Get moves
                        moves := possible_moves(&board, index)

                        dot_rect := rl.Rectangle { 0, 0, f32(dot.width), f32(dot.height) }
                        circle_rect := rl.Rectangle { 0, 0, f32(circle.width), f32(circle.height) }

                        for move in moves {
                            draw_x := (move % 7) + 1
                            draw_y := 7 - (move / 7)

                            move_tex: rl.Texture2D
                            source: rl.Rectangle
                            dest: rl.Rectangle

                            if board[move] != 0 {
                                // capture circle
                                move_tex = circle
                                source = circle_rect
                                dest = {
                                    (f32(draw_x)) * SQUARE_SIZE,
                                    (f32(draw_y)) * SQUARE_SIZE,
                                    SQUARE_SIZE,
                                    SQUARE_SIZE,
                                }
                            } else {
                                // move dot
                                move_tex = dot
                                source = dot_rect
                                dest = {
                                    (f32(draw_x) + 0.25) * SQUARE_SIZE,
                                    (f32(draw_y) + 0.25) * SQUARE_SIZE,
                                    SQUARE_SIZE * 0.5,
                                    SQUARE_SIZE * 0.5,
                                }
                            }

                            rl.DrawTexturePro(
                                move_tex,
                                source,
                                dest,
                                { 0, 0 },
                                0,
                                {200, 200, 200, 200})
                        }
                        //dot_dest := rl.Rectangle {
                            //(f32(render_x)) * SQUARE_SIZE,
                            //(f32(render_y)) * SQUARE_SIZE,
                            //SQUARE_SIZE,
                            //SQUARE_SIZE,
                        //}
                    }

                    rl.DrawTexturePro(
                        tex,
                        source_rect,
                        dest_rect,
                        { 0, 0 },
                        0,
                        color)
                }
            }
        }

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
}

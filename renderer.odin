package main

import rl "vendor:raylib"

Texture_Map :: struct {
    pawn,
    elephant,
    knight,
    bishop,
    rook,
    queen,
    king: rl.Texture2D,

    dot,
    circle: rl.Texture2D,
}

textures: Texture_Map

load_textures :: proc() {
    // TEXTURES. TODO: #load
    textures.pawn     = rl.LoadTexture("resources/pawn.png")
    textures.elephant = rl.LoadTexture("resources/elephant.png")
    textures.knight   = rl.LoadTexture("resources/knight.png")
    textures.bishop   = rl.LoadTexture("resources/bishop.png")
    textures.rook     = rl.LoadTexture("resources/rook.png")
    textures.queen    = rl.LoadTexture("resources/queen.png")
    textures.king     = rl.LoadTexture("resources/king.png")

    textures.dot      = rl.LoadTexture("resources/dot.png")
    textures.circle   = rl.LoadTexture("resources/circle.png")
}

unload_textures :: proc() {
    rl.UnloadTexture(textures.pawn)
    rl.UnloadTexture(textures.elephant)
    rl.UnloadTexture(textures.knight)
    rl.UnloadTexture(textures.bishop)
    rl.UnloadTexture(textures.rook)
    rl.UnloadTexture(textures.queen)
    rl.UnloadTexture(textures.king)

    rl.UnloadTexture(textures.dot)
    rl.UnloadTexture(textures.circle)
}

draw_board :: proc(highlight: Maybe(i32)) {
    // RENDER CHESS BOARD
    for y: i32 = 0; y < RANKS; y += 1 {
        for x: i32 = 0; x < ROWS; x += 1 {

            index := x + y * ROWS

            render_x := x + 1
            render_y := RANKS - y
            // Draw Square
            square_color := (x + y) % 2 == 0 ? DARK_SQUARE : LIGHT_SQUARE

            if marked, ok := highlight.(i32); ok && marked == index {
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
}

draw_pieces :: proc(board: ^Board, ignore: Maybe(i32)) {
    for y: i32 = 0; y < RANKS; y += 1 {
        for x: i32 = 0; x < ROWS; x += 1 {

            index := x + y * ROWS

            if skip_index, skip_ok := ignore.(i32); skip_ok && skip_index == index do continue

            if board[index] != 0 {
                piece := (Piece)(board[index] & PIECE_MASK)
                team := (Team)(board[index] & TEAM_MASK)

                xcoord := f32(x + 1) * SQUARE_SIZE
                ycoord := f32(RANKS - y) * SQUARE_SIZE

                draw_piece(piece, team, xcoord, ycoord)
            }
        }
    }
}

draw_piece :: proc(piece: Piece, team: Team, xcoord: f32, ycoord: f32) {
    tex: rl.Texture2D
    switch piece {
        case .None:     assert(false)
        case .King:     tex = textures.king
        case .Pawn:     tex = textures.pawn
        case .Knight:   tex = textures.knight
        case .Bishop:   tex = textures.bishop
        case .Rook:     tex = textures.rook
        case .Queen:    tex = textures.queen
        case .Elephant: tex = textures.elephant
    }

    color: rl.Color
    switch team {
        case .None:  assert(false)
        case .White: color = LIGHT_PIECE
        case .Black: color = DARK_PIECE
    }

    source_rect := rl.Rectangle { 0, 0, TEXTURE_SIZE, TEXTURE_SIZE }
    dest_rect   := rl.Rectangle {
        xcoord,
        ycoord,
        SQUARE_SIZE,
        SQUARE_SIZE,
    }

    rl.DrawTexturePro(
        tex,
        source_rect,
        dest_rect,
        { 0, 0 },
        0,
        color)
}

draw_possible_move :: proc(pos: i32, capture: bool) {
    draw_x := (pos % ROWS) + 1
    draw_y := ROWS - (pos / ROWS)

    move_tex: rl.Texture2D
    source: rl.Rectangle
    dest: rl.Rectangle

    if capture {
        move_tex = textures.circle
        source = rl.Rectangle { 0, 0, f32(textures.circle.width), f32(textures.circle.height) }
        dest = {
            (f32(draw_x)) * SQUARE_SIZE,
            (f32(draw_y)) * SQUARE_SIZE,
            SQUARE_SIZE,
            SQUARE_SIZE,
        }
    } else {
        move_tex = textures.dot
        source = rl.Rectangle { 0, 0, f32(textures.dot.width), f32(textures.dot.height) }
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
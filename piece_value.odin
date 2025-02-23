package main

// Piece Values
// Pawn     : 1.0
// Elephant : 2.06
// Knight   : 3.16
// Bishop   : 3.21
// Rook     : 4.93
// Queen    : 9.82
// King     : ---

// Square Tables
Lookup_Table :: []u32 {
    42, 43, 44, 45, 46, 47, 48,
    35, 36, 37, 38, 39, 40, 41,
    28, 29, 30, 31, 32, 33, 34,
    21, 22, 23, 24, 25, 26, 27,
    14, 15, 16, 17, 18, 19, 20,
     7,  8,  9, 10, 11, 12, 13,
     0,  1,  2,  3,  4,  5,  6,
}

Pawn_Table :: []f32 {
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    3.0, 3.3, 3.5, 4.0, 3.4, 3.3, 3.0,
    0.8, 1.1, 2.1, 2.8, 2.1, 1.1, 0.8,
    0.3, 0.4, 1.4, 2.3, 1.4, 0.4, 0.3,
    0.0,-0.5, 0.3, 1.0, 0.3,-0.5, 0.0,
    0.4, 0.1,-0.5,-1.0,-0.5, 0.1, 0.4,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
}

Elephant_Table :: []f32 {
    0.0, 0.0,-2.5, 0.0, 0.0, 0.0,-5.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
   -0.5, 0.0, 0.0, 0.0, 2.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 2.0, 0.0, 0.0, 0.0,-0.5,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
   -5.0, 0.0, 0.0, 0.0,-2.5, 0.0, 0.0,
}

Knight_Table :: []f32 {
   -3.8,-2.3,-1.5,-1.5,-1.5,-2.3,-3.8,
   -2.3,-0.3, 0.6, 0.8, 0.6,-0.3,-2.3,
   -1.4, 0.8, 1.5, 1.8, 1.5, 0.8,-1.4,
   -1.4, 0.9, 1.8, 2.0, 1.8, 0.9,-1.4,
   -1.4, 0.8, 1.5, 1.8, 1.5, 0.8,-1.4,
   -2.3,-0.3, 0.6, 0.8, 0.6,-0.3,-2.3,
   -3.8,-2.3,-1.5,-1.5,-1.5,-2.3,-3.8,
}

Bishop_Table :: []f32 {
   -1.0,-0.5,-0.5,-0.5,-0.5,-0.5,-1.0,
   -0.5, 0.1, 0.4, 0.5, 0.4, 0.1,-0.5,
   -0.4, 0.4, 0.8, 1.0, 0.8, 0.4,-0.4,
   -0.4, 0.5, 0.9, 1.0, 0.9, 0.5,-0.4,
   -0.3, 0.8, 1.0, 1.0, 1.0, 0.8,-0.3,
   -0.1, 0.6, 0.5, 0.5, 0.5, 0.6,-0.1,
   -0.9,-0.4,-0.5,-0.5,-0.5,-0.4,-0.9,
}
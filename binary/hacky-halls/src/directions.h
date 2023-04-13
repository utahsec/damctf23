#ifndef DIRECTIONS_H
#define DIRECTIONS_H

// Define the directions as constants
#define NORTH 0
#define EAST 1
#define SOUTH 2
#define WEST 3
#define UP 4
#define DOWN 5

// Define the opposite direction for each direction
const int opposite_direction[] = {SOUTH, WEST, NORTH, EAST, DOWN, UP};

// Define the offsets for each direction
//                n   e   s   w   u   d
const int dx[] = {0,  1,  0, -1,  0,  0};
const int dy[] = {0,  0,  0,  0,  1, -1};
const int dz[] = {1,  0, -1,  0,  0,  0};

#endif
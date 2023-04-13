#ifndef MAZE_GENERATE_H
#define MAZE_GENERATE_H

#include "maze.h"

// Define the function prototypes
void create_maze(maze *game_maze, int x, int y, int z);
void generate_maze(maze *game_maze);
bool is_valid_move(int x, int y, int z);
char *get_unity_json_coords(maze *game_maze);

#endif
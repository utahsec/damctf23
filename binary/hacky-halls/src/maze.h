#ifndef MAZE_H
#define MAZE_H

#include <stdbool.h>

#define MAZE_HEIGHT 10
#define MAZE_WIDTH 10
#define MAZE_LENGTH 10
#define DESCRIPTION_LENGTH 1024

typedef struct coords {
    int x;
    int y;
    int z;
} coords;

// Define a room in the maze
typedef struct room
{
    char description[DESCRIPTION_LENGTH];
    bool north_wall;
    bool east_wall;
    bool south_wall;
    bool west_wall;
    bool up_wall;
    bool down_wall;
    bool visited;
} room;

// Define the structure of the maze
typedef struct maze
{
    room rooms[MAZE_LENGTH][MAZE_HEIGHT][MAZE_WIDTH];
} maze;

// Function for allocating a maze
maze * maze_alloc(int length, int height, int width);

// Function for freeing a maze
void maze_free(maze ** m);

#endif
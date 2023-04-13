#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <time.h>
#include <math.h>
#include <string.h>
#include "maze.h"
#include "maze_generate.h"
#include "directions.h"

maze game_maze;

const char *messages[] = {
    "You're as cold as a penguin's beak! Better bundle up!",
    "It's getting chilly in here. Maybe put on a sweater?",
    "You're about as warm as a snowman's heart. Keep going!",
    "Things are heating up a bit! You're getting closer!",
    "You're on fire! Figuratively speaking, of course.",
    "Whoa, you're getting really warm! The exit must be close.",
    "You're so close, you can almost taste victory!",
    "You're practically on top of the exit. Keep going just a bit more!",
    "You're sizzling with success! The exit is right around the corner. (or maybe behind that wall)",
    "Congratulations, you've found the exit! YOU WIN!\n...\nbut you'll need to try harder than that if you want the flag :-)"
};

void fill_descriptions(maze *game_maze) {

    double max_distance = sqrt(MAZE_LENGTH*MAZE_LENGTH + MAZE_HEIGHT*MAZE_HEIGHT + MAZE_WIDTH*MAZE_WIDTH);
    for (int x = 0; x < MAZE_LENGTH; x++)
    {
        for (int y = 0; y < MAZE_HEIGHT; y++)
        {
            for (int z = 0; z < MAZE_WIDTH; z++)
            {
                double distance = sqrt(x*x + y*y + z*z);
                int index = 9 - (int)(distance / max_distance * 10);
                strcpy(game_maze->rooms[x][y][z].description, messages[index]);
            }
        }
    }
}

void generate_maze(maze *game_maze)
{
    // Initialize all walls
    for (int x = 0; x < MAZE_LENGTH; x++)
    {
        for (int y = 0; y < MAZE_HEIGHT; y++)
        {
            for (int z = 0; z < MAZE_WIDTH; z++)
            {
                game_maze->rooms[x][y][z].north_wall = true;
                game_maze->rooms[x][y][z].east_wall = true;
                game_maze->rooms[x][y][z].south_wall = true;
                game_maze->rooms[x][y][z].west_wall = true;
                game_maze->rooms[x][y][z].up_wall = true;
                game_maze->rooms[x][y][z].down_wall = true;
                game_maze->rooms[x][y][z].visited = false;
            }
        }
    }

    // Generate the maze using the DFS algorithm
    create_maze(game_maze, 0, 0, 0);
    // Fill the descriptions
    fill_descriptions(game_maze);

    // Set all outer walls to be solid, except for the entrance and exit
    for (int x = 0; x < MAZE_LENGTH; x++)
    {
        for (int y = 0; y < MAZE_HEIGHT; y++)
        {
            game_maze->rooms[x][y][0].south_wall = true;
            game_maze->rooms[x][y][MAZE_WIDTH - 1].north_wall = true;
        }
    }
    for (int y = 0; y < MAZE_HEIGHT; y++)
    {
        for (int z = 0; z < MAZE_WIDTH; z++)
        {
            game_maze->rooms[0][y][z].west_wall = true;
            game_maze->rooms[MAZE_LENGTH - 1][y][z].east_wall = true;
        }
    }
    for (int x = 0; x < MAZE_LENGTH; x++)
    {
        for (int z = 0; z < MAZE_WIDTH; z++)
        {
            game_maze->rooms[x][0][z].down_wall = true;
            game_maze->rooms[x][MAZE_HEIGHT - 1][z].up_wall = true;
        }
    }
}

char *get_unity_json_coords(maze *game_maze)
{
    char *json_buf = malloc(0x20000);
    char *current_buf_pos = json_buf;
    // Print the maze as a JSON array
    current_buf_pos += sprintf(current_buf_pos, "[");
    for (int x = 0; x < MAZE_LENGTH; x++)
    {
        current_buf_pos += sprintf(current_buf_pos, "[");
        for (int y = 0; y < MAZE_HEIGHT; y++)
        {
            current_buf_pos += sprintf(current_buf_pos, "[");
            for (int z = 0; z < MAZE_WIDTH; z++)
            {
                current_buf_pos += sprintf(current_buf_pos, "{");
                current_buf_pos += sprintf(current_buf_pos, "\"north_wall\":%s,", game_maze->rooms[x][y][z].north_wall ? "true" : "false");
                current_buf_pos += sprintf(current_buf_pos, "\"east_wall\":%s,", game_maze->rooms[x][y][z].east_wall ? "true" : "false");
                current_buf_pos += sprintf(current_buf_pos, "\"south_wall\":%s,", game_maze->rooms[x][y][z].south_wall ? "true" : "false");
                current_buf_pos += sprintf(current_buf_pos, "\"west_wall\":%s,", game_maze->rooms[x][y][z].west_wall ? "true" : "false");
                current_buf_pos += sprintf(current_buf_pos, "\"up_wall\":%s,", game_maze->rooms[x][y][z].up_wall ? "true" : "false");
                current_buf_pos += sprintf(current_buf_pos, "\"down_wall\":%s", game_maze->rooms[x][y][z].down_wall ? "true" : "false");
                current_buf_pos += sprintf(current_buf_pos, "}%s", z < MAZE_WIDTH - 1 ? "," : "");
            }
            current_buf_pos += sprintf(current_buf_pos, "]%s", y < MAZE_HEIGHT - 1 ? "," : "");
        }
        current_buf_pos += sprintf(current_buf_pos, "]%s", x < MAZE_LENGTH - 1 ? "," : "");
    }
    current_buf_pos += sprintf(current_buf_pos, "]");
    return json_buf;
}

void create_maze(maze *game_maze, int x, int y, int z)
{
    // Mark the current room as visited
    game_maze->rooms[x][y][z].visited = true;

    // Create a list of directions to shuffle
    int directions[6] = {NORTH, EAST, SOUTH, WEST, UP, DOWN};

    // Shuffle the directions
    for (int i = 0; i < 6; i++)
    {
        int j = rand() % (i + 1);
        int temp = directions[i];
        directions[i] = directions[j];
        directions[j] = temp;
    }

    // Try each direction in a random order
    for (int i = 0; i < 6; i++)
    {
        int direction = directions[i];

        // Move to the next room in the given direction
        int nx = x + dx[direction];
        int ny = y + dy[direction];
        int nz = z + dz[direction];

        // Check if the move is valid and if the next room has not been visited
        if (is_valid_move(nx, ny, nz) && !game_maze->rooms[nx][ny][nz].visited)
        {
            // Remove the wall between the current room and the next room
            switch (direction)
            {
            case NORTH:
                game_maze->rooms[x][y][z].north_wall = false;
                game_maze->rooms[nx][ny][nz].south_wall = false;
                break;
            case EAST:
                game_maze->rooms[x][y][z].east_wall = false;
                game_maze->rooms[nx][ny][nz].west_wall = false;
                break;
            case SOUTH:
                game_maze->rooms[x][y][z].south_wall = false;
                game_maze->rooms[nx][ny][nz].north_wall = false;
                break;
            case WEST:
                game_maze->rooms[x][y][z].west_wall = false;
                game_maze->rooms[nx][ny][nz].east_wall = false;
                break;
            case UP:
                game_maze->rooms[x][y][z].up_wall = false;
                game_maze->rooms[nx][ny][nz].down_wall = false;
                break;
            case DOWN:
                game_maze->rooms[x][y][z].down_wall = false;
                game_maze->rooms[nx][ny][nz].up_wall = false;
                break;
            }

            // Recursively generate the maze from the next room
            create_maze(game_maze, nx, ny, nz);
        }
    }
    // Backtrack to the previous room
}

// Check if the given coordinates are within the bounds of the maze
bool is_valid_move(int x, int y, int z)
{
    return x >= 0 && x < MAZE_LENGTH && y >= 0 && y < MAZE_HEIGHT && z >= 0 && z < MAZE_WIDTH;
}

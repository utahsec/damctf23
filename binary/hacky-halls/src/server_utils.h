#ifndef SERVER_UTILS_H
#define SERVER_UTILS_H

#include "maze.h"

#define MESSAGE_TYPE_MAZE 'm'
#define MESSAGE_TYPE_DESCRIPTION 'd'
#define MESSAGE_TYPE_RESET 'r'
#define MESSAGE_TYPE_HANDSHAKE 'h'
#define MESSAGE_TYPE_DISCONNECT 'e'
#define MESSAGE_LEN_TYPE 8

typedef struct server_state {
    maze game_maze;
    char key[16];
    int socket;
    coords input_coords;
    char msg_type;
    char *message;
} server_state;

void send_message(int sockfd, char type, char *message, int length);
void receive_message(int sockfd, char *type, char **message);
void get_coords_from_message(char *message, coords *c);

#endif

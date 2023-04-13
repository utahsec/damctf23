#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include <time.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <openssl/rand.h>
#include <openssl/evp.h>

#include "server_utils.h"
#include "maze_generate.h"

void load_anticheat_key(char key_buf[16]) {
    FILE *key_fd = fopen("anticheat.key", "r");
    fread(key_buf, 16, 1, key_fd);
    fclose(key_fd);
}

char *anticheat_encrypt(char key[16], char message[1024]) {
    unsigned char *encrypted_message = malloc(16 + DESCRIPTION_LENGTH);
    unsigned char *iv = encrypted_message;
    unsigned char *ciphertext = encrypted_message + 16;
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    EVP_CIPHER_CTX_set_padding(ctx, 0);

    RAND_bytes(iv, 16);
    EVP_EncryptInit_ex(ctx, EVP_aes_128_cbc(), NULL, (unsigned char *)key, iv);
    int len;
    EVP_EncryptUpdate(ctx, ciphertext, &len, (unsigned char *)message, DESCRIPTION_LENGTH);
    EVP_EncryptFinal_ex(ctx, ciphertext + len, &len);
    EVP_CIPHER_CTX_free(ctx);
    
    return (char *)encrypted_message;
}

void run_server(int socket, unsigned int timeout) {
    server_state s = {};
    s.socket = socket;
    
    // Load anticheat key
    load_anticheat_key(s.key);

    // Client handshake
    alarm(timeout);
    receive_message(socket, &s.msg_type, &s.message);
    if (s.msg_type != MESSAGE_TYPE_HANDSHAKE) {
        perror("Invalid handshake from client");
        close(socket);
        exit(1);
    }
    free(s.message);

    send_message(socket, MESSAGE_TYPE_HANDSHAKE, "Hello!", strlen("Hello!"));

    while (1) {
        alarm(timeout);
        receive_message(socket, &s.msg_type, &s.message);
        switch (s.msg_type) {
            case MESSAGE_TYPE_MAZE:
            {
                // regenerate maze
                generate_maze(&s.game_maze);
                // send it
                char *maze_message = get_unity_json_coords(&s.game_maze);
                send_message(socket, MESSAGE_TYPE_MAZE, maze_message, strlen(maze_message));
                free(maze_message);
                break;
            }
            case MESSAGE_TYPE_DESCRIPTION:
            {
                // Get coordinates
                get_coords_from_message(s.message, &s.input_coords);
                // Send the description of the requested room
                char *encrypted_description = anticheat_encrypt(s.key, s.game_maze.rooms[s.input_coords.x][s.input_coords.y][s.input_coords.z].description);
                send_message(socket, MESSAGE_TYPE_DESCRIPTION, encrypted_description, 16 + DESCRIPTION_LENGTH);
                free(encrypted_description);
                break;
            }
            case MESSAGE_TYPE_DISCONNECT:
            {
                return;
            }
        }
        free(s.message);
    }
}

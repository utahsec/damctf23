#include "maze.h"
#include "server_utils.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>

void send_message(int sockfd, char type, char *message, int length) {
    // Start with message type
    char msg_type_buf[MESSAGE_LEN_TYPE];
    snprintf(msg_type_buf, MESSAGE_LEN_TYPE, "%c%06d", type, length);
    if (send(sockfd, msg_type_buf, MESSAGE_LEN_TYPE, 0) == -1) {
        perror("Failed to send type/length of message to client");
        exit(1);
    }

    // Send the actual message in blocks of 2048
    int sent_bytes = 0;
    int bytes_to_send;
    char *current_ptr = message;
    while (sent_bytes < length) {
        bytes_to_send = length - sent_bytes > 2048 ? 2048: length - sent_bytes;
        if (send(sockfd, current_ptr, bytes_to_send, 0) == -1) {
            perror("Failed to send message contents to client");
            exit(1);
        }
        sent_bytes += bytes_to_send;
        current_ptr += bytes_to_send;
    }
}

void receive_message(int sockfd, char *type, char **message) {
    int msg_size;
    char msg_type_buf[MESSAGE_LEN_TYPE];

    // Receive message type
    if (recv(sockfd, msg_type_buf, MESSAGE_LEN_TYPE, 0)) {
        msg_type_buf[MESSAGE_LEN_TYPE - 1] = '\x00';
        *type = msg_type_buf[0];
        msg_size = atoi(msg_type_buf + 1);

        // Allocate buffer for message
        *message = malloc(msg_size+1);
        recv(sockfd, *message, msg_size, 0);
        (*message)[msg_size] = '\x00';
    }
    else {
        puts("Client disconnected");
        exit(1);
    }
}

void get_coords_from_message(char *message, coords *c) {
    char *current_num_ptr;
    int *current_coord = (int *)c;

    current_num_ptr = message;

    while(1) {
        sscanf(current_num_ptr, "%d", current_coord);
        if ((current_num_ptr = strchr(current_num_ptr, ',')) == NULL) {
            break;
        }
        current_num_ptr++;
        current_coord++;
    }
}

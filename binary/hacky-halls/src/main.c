#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <getopt.h>
#include <time.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#include "server.h"

#define DEF_PORT 8888   // Default port to listen on
#define DEF_BACKLOG 100 // Default number of pending connections queue will hold
#define DEF_TIMEOUT 30  // Default timeout

int connection_socket;      // Holds the connection socket file descriptor
char connection_addr[1024]; // Holds the client address

void handle_alarm(int signum) {
    printf("Client %s disconnected.\n", connection_addr);
    close(connection_socket);
    exit(0);
}

int main(int argc, char **argv)
{
    int c;
    int port = DEF_PORT;
    int backlog = DEF_BACKLOG;
    int timeout = DEF_TIMEOUT;

    int sockfd;                     // Listen on sock_fd, new connection on connection_socket
    struct sockaddr_in server_addr; // Server address
    struct sockaddr_in client_addr; // Client address
    socklen_t sin_size;

    // Parse command-line arguments
    while ((c = getopt(argc, argv, "p:b:t:h")) != -1) {
        switch (c) {
            case 'p':
                port = atoi(optarg);
                break;
            case 'b':
                backlog = atoi(optarg);
                break;
            case 't':
                timeout = atoi(optarg);
                break;
            case 'h':
                puts(
                    "Usage: ./server [OPTION]...\n"
                    "\n"
                    "Runs the 3d maze server\n"
                    "\n"
                    "  -h            Show this message and exit\n"
                    "  -p <port>     Specify the port the server should listen on (default 8888)\n"
                    "  -b <backlog>  Specify how many connections the queue should hold (default 100)\n"
                    "  -t <timeout>  Close connection after a player has been inactive for the specified number of seconds (default 30)\n"
                );
                return 0;
            case '?':
                if (optopt == 'p' || optopt == 'b' || optopt == 't') {
                    fprintf(stderr, "Option -%c requires an argument.\n", optopt);
                } else {
                    fprintf(stderr, "Unknown option -%c.\n", optopt);
                }
                return 1;
            default:
                abort();
        }
    }

    // Set signal handler
    signal(SIGALRM, handle_alarm);

    // Create a socket
    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) == -1)
    {
        perror("socket");
        exit(1);
    }

    // Set up the server address structure
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(port);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket to the specified port
    if (bind(sockfd, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("bind");
        exit(1);
    }

    // Listen for incoming connections
    if (listen(sockfd, backlog) == -1)
    {
        perror("listen");
        exit(1);
    }

    printf("Listening on port %d\n", port);

    // Accept incoming connections and fork a new process to handle each one
    while (1)
    {
        sin_size = sizeof(client_addr);
        if ((connection_socket = accept(sockfd, (struct sockaddr *)&client_addr, &sin_size)) == -1)
        {
            perror("accept");
            continue;
        }

        if (!fork()) // This is the child process
        {
            // Close the listen socket, as the child only needs the connection socket
            close(sockfd);
            strncpy(connection_addr, inet_ntoa(client_addr.sin_addr), 1024);
            printf("Accepted connection from %s\n", inet_ntoa(client_addr.sin_addr)); // Print the client's IP address
            // Seed the random generator for this child process
            srand(time(0));
            // Run the server
            run_server(connection_socket, timeout);
            // Close the connection socket
            close(connection_socket);
            exit(0);
        }
        else // This is the parent process
        {
            // Close the connection socket, as the parent only needs the listen socket
            close(connection_socket);
        }
    }

    // Close the listen socket
    close(sockfd);
    return 0;
}

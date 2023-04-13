#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LOCATIONS 32
#define MAX_CHOICES 4
#define MAX_STRING 1024

typedef struct _choice choice;
typedef struct _location location;

typedef struct _choice {
    char description[MAX_STRING]; // Description of the choice
    location *location;           // Where to go when this choice is chosen
} choice;

typedef struct _location {
    char description[MAX_STRING]; // Description of the location
    choice choices[MAX_CHOICES];  // List of choices
    int num_choices;              // Number of choices
    int end_location;             // Whether the game should end when reaching this location (0 or 1)
} location;

typedef struct _game {
    location *current_location;
    char input_buf[MAX_STRING];
    location locations[MAX_LOCATIONS];
} game;

void load_game(game *g) {
    int num_locations = 0;
    int index = 0;

    // Open file to read
    FILE *game_file = fopen("./game.dat", "r");
    // Read how many locations there are
    fscanf(game_file, "%d\n", &num_locations);

    for (int i = 0; i < num_locations; ++i) {
        // Read index of this room
        fscanf(game_file, "%d ", &index);
        // Read description of this room
        fgets(g->locations[index].description, MAX_STRING, game_file);
        // Read number of choices
        fscanf(game_file, "%d\n", &g->locations[index].num_choices);
        for (int j = 0; j < g->locations[index].num_choices; ++j) {
            int location_index = 0;
            fscanf(game_file, "%d ", &location_index);
            g->locations[index].choices[j].location = &g->locations[location_index];
            fgets(g->locations[index].choices[j].description, MAX_STRING, game_file);
        }
        // Read value for end_location
        fscanf(game_file, "%d\n", &g->locations[index].end_location);
    }
    fclose(game_file);
    g->current_location = &g->locations[0];
}

void print_intro() {
	puts("  _____ _   _ _____    ____  _   _ _______     _______ ____  __  __ ");
	puts(" |_   _| \\ | |_   _|  / __ \\| \\ | |__   __|   / / ____/ __ \\|  \\/  |");
	puts("   | | |  \\| | | |   | |  | |  \\| |  | |     / /| (___| |  | | \\  / |");
	puts("   | | | . ` | | |   | |  | | . ` |  |_|    / /_ \\___ \\|_|__|_|_|\\/|_|");
	puts("  _| |_| |\\ _|_| |_ _|_|__|_|_|\\__|_______/_____|_____)_____(_)__/ (_)");
	puts(" |_(_)___(_)_____/(_)_/ (_)_____(_)_____/_____(_)_____/_____(_)_/ (_)");
	puts("");
	puts("THE QUEST FOR THE GOLDEN BANANA");
	puts("A text-based adventure game by Bing");
	puts("");
	puts("Description of the ascii art:");
	puts("The ascii art represents a monkey holding a banana in its hand. The monkey is smiling and has a crown on its head. The banana is golden and has a star on it. The ascii art is meant to convey the theme and goal of the game.");
	puts("");
}

void print_location(location *l) {
    printf(l->description);
    if (l->end_location) {
        exit(0);
    }
    for (int i = 0; i < l->num_choices; ++i) {
        printf("%d: %s", i + 1, l->choices[i].description);
    }
}


int find_match(char *input, choice array[], int size) {
  for (int i = 0; i < size; i++) {
    if (strncmp(input, array[i].description, strlen(input)) == 0) {
      return i;
    }
  }
  // Return -1 if no match is found
  return -1;
}

int main() {
    game g = {};
    int choice = -1;

	print_intro();
    load_game(&g);

    setbuf(stdin, NULL);
    setbuf(stdout, NULL);

    while (1) {
        // Print current location
        print_location(g.current_location);
        do {
            // Get choice from user
            gets(g.input_buf);
            // Allow either specifying the number or typing the description
            choice = atoi(g.input_buf) - 1;
            if (choice < 0 || choice >= g.current_location->num_choices) {
                choice = find_match(g.input_buf, g.current_location->choices, g.current_location->num_choices);
            }
            if (choice == -1) {
                printf("Invalid choice, please try again.\n");
            }
        } while (choice == -1);
		g.current_location = g.current_location->choices[choice].location;
    }
    return 0;
}

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define MAX_COUNTRIES 50
#define MAX_NAME_LEN 50

struct Country {
    char name[MAX_NAME_LEN];
    char capital[MAX_NAME_LEN];
};

struct Country countries[MAX_COUNTRIES];
int num_countries = 0;

void load_countries() {
    FILE* fp = fopen("countries.txt", "r");
    if (fp == NULL) {
        printf("Failed to open countries.txt\n");
        exit(1);
    }
    char line[MAX_NAME_LEN*2];
    while (fgets(line, sizeof(line), fp)) {
        char* delim = strchr(line, ',');
        if (delim != NULL) {
            *delim = '\0';
            strcpy(countries[num_countries].name, line);
            strcpy(countries[num_countries].capital, delim+1);
            num_countries++;
        }
    }
    fclose(fp);
}

void read_book(){
    puts("Here's a fun book to read ☺️ ");
    puts("https://a.co/d/2RjFoHb");
    return;
}

void watch_movie(char *your_list){
    puts("Here's a few movies to watch 🎥");
    puts("https://www.youtube.com/watch?v=2bGvWEfLUsc");
    puts("https://www.youtube.com/watch?v=0u1oUsPWWjM");
    puts("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
    puts("https://www.youtube.com/watch?v=Icx4xul9LEE");
    printf(your_list);
    return;
}

void review(){
    char buf[60];
    char review[1000];
    puts("What is the name of the book/movie you would like to review?");
    read(0, buf, 59);
    puts("Okay, write your review below:");
    read(0, review, 1000);
    puts("Thanks! I'll make sure to take note of this review.");
    return;
}

void add_movie(char *your_list){
    puts("Enter your movie link here and I'll add it to the list");
    read(0, your_list, 300);
    if(strstr(your_list, "%n")){
	exit(0);
    }
    return;
}

void menu(){
    char buf[20];
    char mc;
    char your_list[300]; 
    while(1){
	puts("What would you like to do?");
	puts("1. Read a book?");
	puts("2. Watch a movie?");
	puts("3. Review a book/movie");
	puts("4. Exit");
	scanf(" %c", &mc);
	getchar();
	switch(mc){
	    case '1':
		read_book();
		break;
	    case '2':
		watch_movie(&your_list);
		break;
	    case '3':
		review();
		break;
	    case '4':
		puts("Sad to see you go.");
		puts("Could I get your name for my records?");
		read(0, buf, 0x30);
		return;
		break;
	    case '5':
		add_movie(&your_list);
		break;
	    default:
		exit(0);
	}
    }
}

int main() {
    srand(time(NULL));
    load_countries();
    puts("Alright I need to prove you're human so lets do some geography");
    int idx = rand() % num_countries;
    struct Country* country = &countries[idx];
    printf("What is the capital of %s?\n", country->name);
    char answer[MAX_NAME_LEN];
    fgets(answer, sizeof(answer), stdin);
    answer[strcspn(answer, "\r\n")] = '\n'; // remove trailing newline
    if (strcmp(answer, country->capital) == 0) {
	printf("Correct!\n");
    } else {
	printf("Incorrect. The capital of %s is %s.\n", country->name, country->capital);
	exit(0);
    }
    puts("Alright I'll let you through");

    menu();
    
    return 0;
}

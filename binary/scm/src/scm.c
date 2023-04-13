#include <seccomp.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/wait.h>

#define SC_MAX_SIZE 100
#define PAGE_SIZE 0x1000

#define SC_TYPE_SIMPLE 1
#define SC_TYPE_READ 2
#define SC_TYPE_WRITE 3

typedef struct shellcode {
    unsigned int length;
    int type;
    char *code;
} shellcode_t;

#define MAX_SHELLCODES 5
shellcode_t* g_shellcodes[MAX_SHELLCODES] = {0};

void *g_shared_page = NULL;

const char g_mystery[] = "\x6b\x0a\x42\x43\x44\x5e\x0a\x4c\x45\x58\x0a\x5e\x42\x43\x59\x0a\x49\x42\x4b\x46\x46\x4f\x44\x4d\x4f\x0a\x43\x59\x0a\x4b\x5c\x4b\x43\x46\x4b\x48\x46\x4f\x0a\x42\x4f\x58\x4f\x10\x0a\x42\x5e\x5e\x5a\x59\x10\x05\x05\x5e\x43\x44\x53\x5f\x58\x46\x04\x49\x45\x47\x05\x59\x49\x47\x42\x43\x44\x5e";

bool init_seccomp(bool allow_read, bool allow_write) {
    scmp_filter_ctx ctx;

    ctx = seccomp_init(SCMP_ACT_KILL_PROCESS);
    if (!ctx) return false;

    if (seccomp_rule_add_exact(ctx, SCMP_ACT_ALLOW, SCMP_SYS(exit_group), 0) < 0) return false;

    if (allow_read) {
        if (seccomp_rule_add_exact(ctx, SCMP_ACT_ALLOW, SCMP_SYS(read), 0) < 0) return false;
    }
    if (allow_write) {
        if (seccomp_rule_add_exact(ctx, SCMP_ACT_ALLOW, SCMP_SYS(write), 0) < 0) return false;
    }

    if (seccomp_load(ctx) < 0) return false;

    seccomp_release(ctx);

    return true;
}

void exec_shellcode(shellcode_t *sc) {
    int pid, status;
    void (*code_page)(void);

    printf("Running shellcode...");

    // BUG: memory persists after shellcode execution
    code_page = mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    memset(code_page, 0xc3, PAGE_SIZE); // ret
    memcpy(code_page, sc->code, sc->length);

    pid = fork();
    if (pid == 0) {
        bool seccomp_success = true;

        close(2);
        if (sc->type != SC_TYPE_WRITE) close(1);
        if (sc->type != SC_TYPE_READ) close(0);

        // BUG: seccomp isn't set if sc->type isn't one of these
        switch (sc->type) {
            case SC_TYPE_SIMPLE:
                if (!init_seccomp(false, false)) seccomp_success = false;
                break;
            case SC_TYPE_READ:
                if (!init_seccomp(true, false)) seccomp_success = false;
                break;
            case SC_TYPE_WRITE:
                if (!init_seccomp(false, true)) seccomp_success = false;
                break;
        }

        if (seccomp_success) {
            code_page();
        }
        exit(0);
    } else {
        wait(&status);
        puts("done!");
        printf("Execution finished with status code %d\n", status);
    }
}

shellcode_t* get_shellcode() {
    char buf[50] = {0};
    shellcode_t *sc;

    sc = malloc(sizeof(shellcode_t));
    
    printf("Shellcode type (1=simple, 2=read, 3=write): ");
    fgets(buf, sizeof(buf)-1, stdin);
    sc->type = (char)atoi(buf);
    if (!(sc->type >= SC_TYPE_SIMPLE && sc->type <= SC_TYPE_WRITE)) {
        puts("Bad type!");
        free(sc);
        return NULL;
    }

    printf("Size of shellcode: ");
    bzero(buf, sizeof(buf));
    fgets(buf, sizeof(buf)-1, stdin);
    sc->length = atoi(buf);
    if (sc->length < 1 || sc->length > SC_MAX_SIZE-1) {
        puts("Bad size!");
        free(sc);
        return NULL;
    }

    printf("Shellcode: ");
    sc->code = malloc(sc->length);
    read(0, sc->code, sc->length);

    return sc;
}

bool ask_yes_no(const char *prompt) {
    char buf[10] = {0};

    printf("%s (y/n): ", prompt);
    fgets(buf, sizeof(buf)-1, stdin);

    return buf[0] == 'y';
}

bool edit_shellcode(shellcode_t *sc) {
    char buf[50] = {0};
    int new_type, new_length;
    void *new_code;

    if (!sc) return false;

    if (ask_yes_no("Do you want to change the shellcode type?")) {
        printf("Shellcode type (1=simple, 2=read, 3=write): ");
        bzero(buf, sizeof(buf));
        fgets(buf, sizeof(buf)-1, stdin);

        new_type = atoi(buf);
        // BUG: int overflow
        if (!((char)new_type >= SC_TYPE_SIMPLE && (char)new_type <= SC_TYPE_WRITE)) {
            puts("Bad type!");
            return false;
        }

        printf("Changing type to %d\n", new_type);
        sc->type = new_type;
    }
    
    if (ask_yes_no("Do you want to change the shellcode?")) {
        printf("Size of shellcode: ");
        bzero(buf, sizeof(buf));
        fgets(buf, sizeof(buf)-1, stdin);
        new_length = atoi(buf);
        if (new_length < 1 || new_length > SC_MAX_SIZE-1) {
            puts("Bad size!");
            return false;
        }

        printf("Shellcode: ");
        new_code = malloc(new_length);
        read(0, new_code, new_length);

        printf("Changing shellcode to new blob of length %d\n", new_length);
        free(sc->code);
        sc->length = new_length;
        sc->code = new_code;
    }

    return true;
}

bool free_shellcode(shellcode_t *sc) {
    if (!sc) return false;

    if (sc->code) {
        free(sc->code);
        sc->code = NULL;
    }

    free(sc);

    return true;
}

void print_banner() {
    puts("############################################################");
    puts("#                                                          #");
    puts("#            WELCOME TO THE SHELLCODE MANAGER              #");
    puts("#           (where safety is our top priority)             #");
    puts("#                                                          #");
    puts("############################################################");
}

int get_choice() {
    char buf[10] = {0};

    puts("\nPlease choose an operation:");
    puts("1) Add a new shellcode");
    puts("2) Edit a shellcode");
    puts("3) Execute a shellcode");
    puts("4) Show your shellcodes");
    puts("5) Delete a shellcodes");
    puts("6) Exit");
    puts("7) Mystery");

    printf("\nChoice: ");

    fgets(buf, sizeof(buf)-1, stdin);
    return atoi(buf);
}

int get_free_idx() {
    for (int i = 0; i < MAX_SHELLCODES; i++) {
        if (g_shellcodes[i] == NULL) return i;
    }

    return -1;
}

int get_valid_idx() {
    char buf[10] = {0};
    int idx;

    printf("Shellcode index: ");
    fgets(buf, sizeof(buf)-1, stdin);
    idx = atoi(buf);

    if (idx >= 0 && idx < MAX_SHELLCODES && g_shellcodes[idx] != NULL) {
        return idx;
    } else {
        puts("Invalid shellcode index!");
        return -1;
    }
}

void do_new() {
    int idx;
    shellcode_t *sc;

    idx = get_free_idx();
    if (idx == -1) {
        puts("Too many shellcodes!");
        return;
    }

    sc = get_shellcode();
    if (sc) {
        g_shellcodes[idx] = sc;
        puts("Shellcode saved");
    }
}

void do_edit() {
    int idx;

    idx = get_valid_idx();
    if (idx == -1) return;

    if (edit_shellcode(g_shellcodes[idx])) puts("Shellcode edited");
}

void do_execute() {
    int idx;

    idx = get_valid_idx();
    if (idx == -1) return;

    exec_shellcode(g_shellcodes[idx]);
}

void do_show() {
    for (int i = 0; i < MAX_SHELLCODES; i++) {
        if (g_shellcodes[i]) {
            printf("Shellcode #%d: type=%d, length=%d\n", i, g_shellcodes[i]->type, g_shellcodes[i]->length);
        } else {
            printf("Shellcode #%d: <empty>\n", i);
        }
    }
}

void do_delete() {
    int idx;

    idx = get_valid_idx();
    if (idx == -1) return;

    if (free_shellcode(g_shellcodes[idx])) puts("Shellcode deleted");
    g_shellcodes[idx] = NULL;
}

void do_mystery() {
    char buf[100] = {0};

    strncpy(buf, g_mystery, sizeof(buf));
    memfrob(buf, strlen(buf));
    puts(buf);
}

bool interact() {
    int choice;

    choice = get_choice();
    switch (choice) {
        case 1:
            do_new();
            break;
        case 2:
            do_edit();
            break;
        case 3:
            do_execute();
            break;
        case 4:
            do_show();
            break;
        case 5:
            do_delete();
            break;
        case 6:
            return false;
        case 7:
            do_mystery();
            break;
    }

    return true;
}

int main() {
    bool do_loop = true;

    setbuf(stdin, NULL);
    setbuf(stdout, NULL);
    setbuf(stderr, NULL);

    print_banner();

    while (do_loop) {
        do_loop = interact();
    }

    puts("Goodbye!");

    return 0;
}
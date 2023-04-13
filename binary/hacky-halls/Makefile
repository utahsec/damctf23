CC=gcc
C_FLAGS=-Wall
C_LIBS=-lcrypto -lssl -lm

out=server

.PHONY: all
all: $(out)

$(out): src/*.c
	$(CC) $(C_FLAGS) -o $@ -L/usr/local/opt/openssl/lib $^ $(C_LIBS)

.PHONY: container
container: all

.PHONY: clean
clean:
	$(RM) $(out) *.o

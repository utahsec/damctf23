CC=gcc
C_FLAGS=-Wall # disable NX: -z execstack
              # disable canary: -fno-stack-protector
              # disable PIE: -no-pie
C_LIBS= # -lcrypto or something

out=golden-banana

.PHONY: all
all: $(out)

$(out): src/*.c
	$(CC) $(C_FLAGS) -o $@ $^ $(C_LIBS)

# container builds this target
# make sure 'all' builds everything you need
# default container is ubuntu 22.04
.PHONY: container
container: all

.PHONY: clean
clean:
	$(RM) $(out) *.o

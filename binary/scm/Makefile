CC=gcc
C_FLAGS=-Wall -O1 # disable NX: -z execstack
              # disable canary: -fno-stack-protector
              # disable PIE: -no-pie
C_LIBS=-lseccomp -lc # -lcrypto or something

out=scm

.PHONY: all
all: $(out)

$(out): src/*.c
	$(CC) $(C_FLAGS) -o $@ $^ $(C_LIBS)
	strip $@

# container builds this target
# make sure 'all' builds everything you need
# default container is ubuntu 22.04
.PHONY: container
container: all

.PHONY: clean
clean:
	$(RM) $(out) *.o

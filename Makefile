CC = gcc
CFLAGS = -Wall -g -O0
CFLAGS = -I.

#targets
all: qsfpDump

qsfpDump: qsfpDump.o i2cUtils.o
	$(CC) -o qsfpDump qsfpDump.o i2cUtils.o

i2cUtils.o: i2cUtils.c
	$(CC) $(CFLAGS) -c i2cUtils.c

qsfpDump.o: qsfpDump.c
	$(CC) $(CFLAGS) -c qsfpDump.c

clean:
	rm -rf *.o qsfpDump

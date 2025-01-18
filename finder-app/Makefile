# Var
CC = $(CROSS_COMPILE)gcc
CFLAGS = -g -Wall
SRC = writer.c
OBJ = $(SRC:.c=.o)
TARGET = writer

# Targets
all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $(OBJ)
	rm -f $(OBJ)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)
# Optional: Phony targets
.PHONY: all clean


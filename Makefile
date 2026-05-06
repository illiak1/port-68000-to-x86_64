# ----------------------------------------------------------------------
# Project: 68000 Assembly Port to x86_64
# File: Makefile
# Author: Illia Karban
# Description:
#   Build script for assembling and linking a Linux x86_64 NASM assembly program.
#   This Makefile compiles the assembly source into an object file,
#   links it using ld, and provides helper targets for running and cleaning.
#
# Targets:
#   all   - Build executable
#   run   - Rebuild and execute program
#   clean - Remove generated files
# ----------------------------------------------------------------------

ASM = convert_68000_to_x86_64.asm
OBJ = convert_68000_to_x86_64.o
EXE = convert_68000_to_x86_64

# Main target
all: $(EXE)

# Build executable from object file
$(EXE): $(OBJ)
	ld -o $(EXE) $(OBJ)

# Build object file from ASM
$(OBJ): $(ASM)
	nasm -f elf64 -o $(OBJ) $(ASM)

# Remove intermediate files
clean:
	rm -f $(OBJ) $(EXE)

# Rebuild and run
run: clean all
	./$(EXE)

.PHONY: all run clean	
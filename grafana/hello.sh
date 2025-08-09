#!/bin/bash
# read -p "Enter something: " input

# Force reading from the terminal, not the pipe
printf "Enter something: "
IFS= read -r input < /dev/tty

echo "You entered: $input"
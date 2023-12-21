# assembly-primitives-and-macros

*This program is the portfolio project for Computer Architecture and Assembly Language (CS 271) at Oregon State University.*

## Implementation Description

This is a program that prompts the user for integer input.
Each input string is converted character by character
to determine if they are valid integers and stored in an array.
The sum and average of the values in the array are calculated.
The array of inputs as well as the sum and average are converted
back into strings and displayed with the use of macros.

### Macros

`mGetString` displays a prompt for user input and places the input into a memory location.

`mDisplayString` prints the string stored in a specified memory location.

### Procedures

`ReadVal` invokes the `mGetString` macro, converts the string of ASCII digits to its numeric value representation, and stores this value in a memory variable.

`WriteVal` converts a numeric SDWORD valule to a string of ASCII digits and invokes the `mDisplayString` macro to print the ASCII representation of the SDWORD value.
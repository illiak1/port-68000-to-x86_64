#include <stdio.h>    // For printf
#include <stdint.h>   // For int64_t
#include <inttypes.h> // For portable format specifiers (PRId64)

// Declaration of the external assembly function.
// It takes two 64-bit integers and returns their sum.
extern int64_t asm_register_adder(int64_t a, int64_t b);

int main() {
    // Variables to store input values and the result
    int64_t val1, val2, result;

    // Print a header for clarity
    printf("=== Assembly Register Adder Test ===\n");

    // -----------------------------------
    // Test 1: Simple addition
    // -----------------------------------
    val1 = 100;
    val2 = 250;

    // Call the assembly function
    result = asm_register_adder(val1, val2);

    // Print result using portable 64-bit format specifier
    // Expected result: 350
    printf("Test 1: %" PRId64 " + %" PRId64 " = %" PRId64 " -> %s\n",
           val1, val2, result,
           (result == 350) ? "PASS" : "FAIL");

    // -----------------------------------
    // Test 2: Large number addition
    // -----------------------------------
    val1 = 123456789012345;
    val2 = 987654321098765;

    result = asm_register_adder(val1, val2);

    // Expected result: 1111111110111110
    printf("Test 2: %" PRId64 " + %" PRId64 " = %" PRId64 " -> %s\n",
           val1, val2, result,
           (result == 1111111110111110) ? "PASS" : "FAIL");

    // -----------------------------------
    // Test 3: Adding zero
    // -----------------------------------
    val1 = 0;
    val2 = 42;

    result = asm_register_adder(val1, val2);

    // Expected result: 42
    printf("Test 3: %" PRId64 " + %" PRId64 " = %" PRId64 " -> %s\n",
           val1, val2, result,
           (result == 42) ? "PASS" : "FAIL");

    // Return 0 to indicate successful execution
    return 0;
}
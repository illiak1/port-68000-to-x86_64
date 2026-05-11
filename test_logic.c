#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

extern int64_t asm_register_adder(int64_t a, int64_t b);

typedef struct {
    int64_t a;
    int64_t b;
    int64_t expected;
} TestCase;

int main() {
    // Array-based testing for scalability
    TestCase tests[] = {
        {100, 250, 350},
        {123456789012345, 987654321098765, 1111111110111110},
        {0, 42, 42},
        {-50, 20, -30},                     // Negative test
        {9223372036854775807, 1, -9223372036854775808ULL} // Overflow test (wraps)
    };

    uint32_t num_tests = sizeof(tests) / sizeof(tests[0]);
    uint32_t passed = 0;

    printf("=== Assembly Register Adder: Running %u Tests ===\n", num_tests);

    for (uint32_t i = 0; i < num_tests; i++) {
        int64_t res = asm_register_adder(tests[i].a, tests[i].b);
        int success = (res == tests[i].expected);
        
        printf("Test %u: %" PRId64 " + %" PRId64 " = %" PRId64 " [%s]\n",
               i + 1, tests[i].a, tests[i].b, res, success ? "PASS" : "FAIL");
        
        if (success) passed++;
    }

    printf("--- Summary: %u/%u passed ---\n", passed, num_tests);
    
    return (passed == num_tests) ? 0 : 1;
}

# 68000-to-x86_64 Assembly Porting Project

---

## 📌 Overview

This project converts a Motorola 68000 assembly program into an equivalent x86_64 implementation using NASM and Linux system calls.

The program repeatedly accepts two integer inputs, computes their sum, and maintains a running total across three iterations. It demonstrates both register-based and stack-based parameter passing, while improving significantly on the original 68000 implementation in terms of safety, correctness, and structure.

---

## 🎯 Objectives

* Translate 68000 assembly into x86_64 assembly
* Preserve original program logic and behavior
* Demonstrate low-level concepts (registers, stack, syscalls)
* Improve robustness through validation and error handling

---

## 🔄 Key Architectural Differences

| 68000 Concept          | x86_64 Equivalent                              |
| ---------------------- | ---------------------------------------------- |
| Data Registers (D1–D4) | General-purpose registers (RDI, RSI, R12, R15) |
| BSR / RTS              | CALL / RET                                     |
| TRAP #15 (I/O)         | Linux syscalls (`read`, `write`, `exit`)       |
| Stack usage            | Explicit stack frame via RBP                   |

---

## ⚙️ Program Functionality

* Prompts user for two integers
* Adds them using a register-based subroutine
* Adds result to a running total
* Repeats three times
* Prints the final accumulated sum

---

## 🧠 Parameter Passing

### ✅ Register-Based Passing

The function `asm_register_adder` uses the x86_64 calling convention:

* First argument → `RDI`
* Second argument → `RSI`
* Return value → `RAX`

### ✅ Stack-Based Passing

The function `stack_printer` demonstrates stack usage:

* Value is pushed before the function call
* Accessed via `[RBP + 16]`
* Demonstrates manual stack frame setup and navigation

---

## 🧩 Macros

To improve readability and reduce repetition:

* `PRINT_STR` → prints null-terminated strings
* `EXIT` → wraps the `sys_exit` syscall

---

## 🔐 Significant Improvements Over 68000 Version

### Input Validation

* Character-by-character parsing
* Only numeric input (`0–9`) is accepted
* Invalid input triggers retry

### Overflow Detection

* Uses CPU overflow flag (`JO`)
* Detects both multiplication and addition overflow

### Safe Input Handling

* Fixed-size buffers
* Input buffer flushing after errors

### Structured Error Handling

* Centralized handling via `handle_error_print`
* Distinguishes invalid input vs overflow

### System Call Control

* Replaces TRAP instructions with explicit Linux syscalls

---

## ⚠️ Considerations During Conversion

* No direct equivalent for 68000 TRAP → required syscall redesign
* Different calling conventions required register remapping
* Manual string handling (null-terminated, length calculation)
* Explicit overflow detection required
* Low-level input parsing implemented instead of high-level routines

---

## 🛠️ Build & Run Instructions

Two Makefiles are provided to support different workflows:

### ▶️ Run Main Assembly Program

```bash
make run
```

Or step-by-step:

```bash
make
./convert_68000_to_x86_64
```

---

### 🧪 Run C Test Harness

```bash
make -f Makefile2 run
```

This compiles and links the assembly function with a C test program to verify correctness of the `asm_register_adder` function.

---

## 🧪 Testing (C Test Harness)

A C program is used to validate the correctness of the assembly function `asm_register_adder`.

Key test cases:

* Basic addition (100 + 250)
* Large integer handling
* Edge case (0 + value)

This ensures correctness independently from the main assembly program and verifies proper register-based parameter passing.

---

## 📈 Development Progress (Commit Evolution)

The project evolved through incremental development with the following key commits:

* Initial Commit: Ported the 68000 entry point and basic string I/O to x86_64
* Simple Addition Logic: Implemented basic addition and result display
* Loop Implementation: Added loop functionality to process multiple prompts
* Refactored User Input: Refactored assembly code for handling user input and final sum
* Error Handling: Improved assembly code with robust error handling and user-friendly prompts
* Refactor with Macros: Refined assembly structure with reusable macros for better readability
* Empty Input Handling: Fixed bug to reject empty input instead of treating it as zero
* Final Cleanup: Final adjustments, code refactor, and optimization for better stability and readability

---

## 🧪 Test Plan & Test Cases

### 🎯 Objective

To verify correctness, input validation, overflow handling, and stability of the x86_64 implementation.

---

### ✅ Test Approach

Testing was performed manually and via a C test harness.

---

### 📋 Test Cases

| ID   | Scenario            | Input               | Expected Outcome           | Purpose                            |
| ---- | ------------------- | ------------------- | -------------------------- | ---------------------------------- |
| TC1  | Basic addition      | 5, 7                | Output: 12                 | Verify correct arithmetic          |
| TC2  | Larger values       | 100, 250            | Output: 350                | Confirm handling of larger numbers |
| TC3  | Loop execution      | Normal run          | Executes 3 times           | Validate loop control logic        |
| TC4  | Final accumulation  | Multiple runs       | Correct final sum          | Verify running total logic         |
| TC5  | Invalid input       | `abc`               | Error message + retry      | Ensure input validation works      |
| TC6  | Mixed invalid input | `12abc`             | Error message              | Detect partial invalid input       |
| TC7  | Zero values         | 0, 0                | Output: 0                  | Check edge case handling           |
| TC8  | Large values        | Very large numbers  | Correct result or overflow | Test numeric limits                |
| TC9  | Overflow case       | Exceeds 64-bit      | Overflow error             | Validate overflow detection        |
| TC10 | Stability           | Long/repeated input | No crash                   | Ensure program stability           |

---

### ✅ Results

All test cases passed successfully. The program correctly handles valid input, rejects invalid data, detects overflow, and remains stable under repeated and edge-case inputs.

---

## 📈 Limitations

* Only positive integers supported
* No floating-point support
* Very large inputs trigger overflow errors

---

## 📚 Conclusion

This project demonstrates how low-level programs can be translated across architectures while preserving functionality and improving safety.

The x86_64 version enhances the original 68000 program through structured design, explicit error handling, and safer input processing, resulting in a more reliable and maintainable implementation.

---

## 👨‍💻 Author

Illia Karban
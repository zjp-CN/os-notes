# Processor Design

## Two architectural issues

围绕处理器设计有两个架构上的因素：
* 指令集：六七十年代，处理器设计完全是硬件电气工程师的事情，但随着编译器技术的迅速发展，指令集与编译器如何高效生成代码紧密联系，编程语言对指令集设计造成相当大程度的影响。
  * 高级语言：赋值和表达式需要运算和逻辑指令，以及存取指令；数据抽象需要不同精度的运算数和寻址模式；条件语句和循环需要条件和无条件分支指令；过程之类的模块化构造需要处理器架构支持额外的抽象。
  * 应用：七八十年代，产生浮点数运算的需求；2008 年手机和嵌入式系统、音视频等流式应用流行，产生单指令处理一组数据的需求。
  * 低端计算机通过整数指令集，从函数库模拟浮点运算；通用计算机上，某些数学运算（比如求 cos 值）并没有对应的指令集；数学库 (math libaries) 系统软件会将复杂的操作映射到指令集中的更简单指令上。
  * 操作系统：通过调度程序执行，在一个处理器上同时运行多个程序，从而在程序中断和内存管理上影响处理器设计。
* 机器的组织结构。

## What is involved in processor design?

* Hardware resources are like letters
  * logic design such as registers, arithmetic and logic unit, and the datapath that connects all these resources together
  * main memory for holding programs and data
  * multiplexers for selecting from a set of input sources
  * buses for interconnecting the processor resources to the memory
  * drivers for putting information from the resources in the datapath onto the buses
* Instruction set is like words
  * Instruction set is key differentiation between different processors (e.g. Intel x86 & Power PC)
  * Instruction set serves as a contract between the software (i.e., the programs that run on the computer at whatever level) and the actual hardware implementation

The shift from people writing assembly language programs to compilers translating high-
level language programs to machine code is a primary influence on the evolution of the
instruction set architecture. This shift implies that we look to a simple set of instructions
that will result in efficient code for high-level language constructs.

## A Common High-Level Language Feature Set

### Summary

1. Expressions and assignment statements: Compiling such constructs will reveal
many of the nuances in an instruction-set architecture (ISA for short) from the
kinds of arithmetic and logic operations to the size and location of the operands
needed in an instruction.
2. High-level data abstractions: Compiling aggregation of simple variables (usually
called structures or records in a high-level language) will reveal additional
nuances that may be needed in an ISA.
3. Conditional statements and loops: Compiling such constructs result in changing
the sequential flow of execution of the program and would need additional
machinery in the ISA.
4. Procedure calls: Procedures allow the development of modular and maintainable
code. Compiling a procedure call/return brings additional challenges in the
design of an ISA since it requires remembering the state of the program before
and after executing the procedure, as well as in passing parameters to the
procedure and receiving results from the called procedure.

e.g.

* High Level Language Constructs

```
a = b + c; /* add b and c and place in a */
d = e – f; /* subtract f from e and place in d */
x = y & z; /* AND y and z and place in x */
```

* Assembly Language Constructs

```
add a, b, c; a <- b + c
sub d, e, f; d <- e – f
and x, y, z; x <- y & z
```

Such instructions are called binary instructions since they work on two operands to
produce a result. They are also called three operand instructions since there are 3
operands (two source operands and one destination operand). Do we always need 3
operands in such binary instructions? The short answer is no.

Inside the processor there is an arithmetic/logic unit or ALU that performs
the operations such as ADD, SUB, AND, OR, and so on.

### Operands

Where to keep the operands?

move data back and forth between memory and the processor registers:

* load (into registers from memory)
* store (from registers into memory)

```
ld r2, b; r2 ← b
st r1, a; a ← r1
```

```
a = b + c

// assembly:
ld r2, b
ld r3, c
add r1, r2, r3
st r1, a
```

不设计 `add a, b, c` 的原因是，下次利用这些值需要再次从内存中加载到寄存器上，而上面的这些指令只需支付一次加载的成本。

因此对于 `d = a * b + a * c + a + b + c;`，我们可以在 a、b、c 加载到寄存器之后复用它们，而无需从内存中再次读取。

如果有 Accumulator (ACC) 寄存器，`a = b + c` 可以生成三个指令：

```
LD ACC, b
ADD ACC, c
ST a, ACC
```

addressing mode: refers to how the operands are specified in an instruction
* register addressing: the operands are in registers.
* base+offset mode: a memory address is computed in the instruction as the sum 
  of the contents of a register in the processor (called a base register) and
  an offset (contained in the instruction as an immediate value) from that register.

```
// register addressing
add r1, r2, r3; r1 ← r2 + r3
// immediate values: constant values being part of the instruction itself
addi r1, r2, imm; r1 ← r2 + imm

// base+offset mode
ld rdest, offset(rbase); rdest ← MEMORY[rbase + offset]
```

How wide should each operand be?

A.k.a. granularity or the precision of the operands

Base data types in C are short (16 bits), int (32 bits), long, char (8 bits).

To optimize on space and time, it is best if the operand size in
the instruction matches the precision needed by the data type. This is why processors
support multiple precisions in the instruction set: word, half-word, and byte.

Word precision usually refers to the maximum precision the architecture can support in hardware for arithmetic/logic operations.

To optimize on space and time, it is best if the operand size in
the instruction matches the precision needed by the data type. This is why processors
support multiple precisions in the instruction set: word, half-word, and byte.

```
ld r1, offset(rb); load a word at address rb+offset into r1
ldb r1, offset(rb); load a byte at address rb+offset into r1
add r1, r2, r3; add word operands in registers r2 and r3 and place the result in r1
addb r1, r2, r3; add byte operands in registers r2 and r3 and place the result in r1
```

Necessarily there is a correlation between the architectural decision of supporting
multiple precision for the operands and the hardware realization of the processor. The
hardware realization includes specifying the width of the datapath and the width of the
resources in the datapath such as registers.

Word (32 bits) is the maximum precision supported in hardware, then it's convenient to assume
* the datapath is 32-bits wide
* all arithmetic and logic operations take 32-bit operands and manipulate them
* the registers are 32-bits wide to match the datapath width

It should be noted that it is not necessary, but just convenient and more efficient, if the datapath and
the register widths match the chosen word width of the architecture.

### Endianness

Endianness is the ordering of the bytes within the word in a byte-addressable machine.

The endianness of a machine is determined by which byte of the word is at the word
address.
* If it is MSB then it is big endian;
* if it is LSB then it is little endian.

A word in memory:

|            8bits            | 8bits | 8bits |             8bits            |
|:---------------------------:|:-----:|:-----:|:----------------------------:|
| MSB (Most Significant Byte) |       |       | LSB (Least Significant Byte) |


E.g. assume the word at location 100 contains the values 0x11223344:

|    data    |  11 |  22 |  33 |  44 |
|:----------:|:---:|:---:|:---:|:---:|
|    addr    | 100 | 101 | 102 | 103 |
| Big Endian | MSB |     |     |     |

|      data     |  11 |  22 |  33 |  44 |
|:-------------:|:---:|:---:|:---:|:---:|
|      addr     | 103 | 102 | 101 | 100 |
| Little Endian |     |     |     | LSB |

In principle, from the point of view of programming in high-level languages, this should
not matter so long as the program uses the data types in expressions in exactly the same
way as they are declared.

However, in a language like C it is possible to use a data type differently from the way it
was originally declared.

```c
int i = 0x11223344;
char *c;
c = (char *) &i;
printf("endian: i = %x; c = %x\n", i, *c);
// In a big-endian machine, c will be 11hex;
// while in a little-endian machine, c printed will be 44hex.

// The moral of the story is if you declare a datatype of a particular precision
// and access it as another precision then it could be a recipe for disaster
// depending on the endianness of the machine.
```

In general, the endianness of the machine should not
have any bearing on program performance, although one could come up with
pathological examples where a particular endianness may yield a better performance for a
particular program. This particularly occurs during string manipulation.

Endiannesss can come to bite the program behavior. This is particularly true for network
code that necessarily cross machine boundaries. If the sending machine is Little-endian
and the receiving machine is Big-endian there could even be correctness issues in the
resulting network code. It is for this reason, network codes use format conversion
routines between host to network format, and vice versa, to avoid such pitfalls.

### Packing of operands and Alignment of word operands

memory footprint: the amount of space occupied a program in memory

packing operands: laying out the operands in memory ensuring no wasted space

packing may not always be the right approach

alignment restriction of word operands to word addresses: architectures will usually require word operands to start at word addresses

### High-level data abstractions

scalars: The space needed to store such a variable is known a priori.
A compiler has the option of placing a scalar variable in a register or a memory location.

However, when it comes to data abstractions such as
arrays and structures that are usually supported in high-level languages, the compiler may
have no option except to allocate them in memory. 

Structured data types in a high-level language can be supported with base+offset addressing mode:
If the base address of the structure is in some register, then accessing any field within
the structure can be accomplished by providing the appropriate offset relative to the base
register (the compiler knows how much storage is used for each data type and the
alignment of the variables in the memory).

Arrays/Vectors: The storage space required for such
variables may or may not be known at compile time depending on the semantics of the
high-level programming language. Many programming languages allow arrays to be
dynamically sized at run time as opposed to compile time.

For `a[j] = a[j] + 1` in a loop, the offset to the base register is not fixed. It is derived from the
current value of the loop index. Therefore, some computer architectures provide an
additional addressing mode to let the effective address be computed as the sum of the
contents of two registers. This is called the base+index addressing mode.

TODO: base+index versus base+offset
* number of instructions saved
* additional time for execution for a load
* how often base+index is used
* additional hardware is needed to support base+index addressing


Program Counter (PC) registry: contains the memory address
of the instruction immediately following the currently executing instruction.

Conditional statements and loops: 

```
    if (j == k) go to L1;
    a = b + c;
L1: a = a + 1;

beq r1, r2, L1;
```

`beq r1, r2, offset`: The effect of this instruction is as follows:
1. Compare r1 and r2
2. If they are equal then the next instruction to be executed is at address `PC+offset` (PC-relative addressing mode)
3. If they are unequal then the next instruction to be executed is the next one
textually following the beq instruction.

（换句话说）`beq r1, r2, offset` Semantics: if the contents of registers r1 and r2
are equal add the offset to the (already
incremented) PC and store that address in the PC.

The instruction-set architecture may have different flavors of conditional branch
instructions such as BNE (branch on not equal), BZ (branch on zero), and BN (branch on
negative).

`j r`: unconditional jump

```
• C
if(a==b)
  c = d + e;
else
  c = f + g;

• Assembly
beq r1, r2, then
add r3, r6, r7
beq r1, r1, skip*
then add r3, r4, r5
skip …

Assume r1 = a, r2 = b, r3 = c, r4 = d, r5 = e, r6 = f, r7 = g
* Effectively an unconditional branch
```

```
• C

while(j ! = 0)
{
  /* loop body */
  t = t + a[j--];
}
• Assembly

beq r1, r0, done
; loop body
…
done …
```

```c
int main() { foo(); }
```

#### 函数调用 

* caller is the entity that makes the procedure call (main in our example);
* callee is the procedure that is being called (foo in our example)

Steps for compiling a procedure call:

1. Preserve caller state (registers)
2. Pass actual parameters
3. Save the return address
4. Transfer control to callee
5. Allocate space for callee’s local variables
6. Produce return value(s); give to caller
7. Return

stack pointer: The compiler has to maintain a pointer to the stack for saving and restoring state.
Note that this is not an architectural restriction
but just a convenience for the compiler. Besides, each compiler is free to choose a
different register to use as a stack pointer. What this means is that the compiler will not
use this register for hosting program variables since the stack pointer serves a dedicated
internal function for the compiler.

寄存器的状态：谁使用，谁保存。

1. 参数传递：通过寄存器传递少量参数；通过栈，把参数放到 callee 利用栈指针找到的地方传递更多参数。
2. return address（调用处的下一条指令的地址）：`JAL r_target, r_link`
  * Remember the return address in r_link (which can be any processor register)
      * `J r_link`: return from the procedure
  * Set PC to the value in r_target (the start address of the callee)
3. Transfer control to callee
4. Space for callee’s local variables
5. Return values
  * Dedicated registers: compiler reserves some processor registers for the return values
  * Stack: if the number of returned values exceeds the registers reserved by the convention, 
    then the additional return values will be placed on the stack. The software convention will
    establish where exactly on the stack the caller can find the additional return values
    with respect to the stack pointer.
6. Return to the point of call: JAL back through link (J r_link)

#### Software Convention

* Registers s0-s2 are the caller’s s registers
* Registers t0-t2 are the temporary registers
* Registers a0-a2 are the parameter passing registers
* Register v0 is used for return value
* Register ra is used for return address
* Register at is used for target address
* Register sp is used as a stack pointer

大多数编译器遵循的约定：栈从高地址向低地址增长：
* push（压栈）：栈指针自减，并把值放到栈指针指向的内存地址
* pop（弹出）：从栈指针指向的内存地址中取出值，然后栈指针自增

Activation Record:
* The portion of the stack that is relevant to the currently executing procedure 
  is called the activation record for that procedure.
* An activation record is the communication area between the caller and the callee. 
* Used to store
  - Caller saved registers
  - Additional parameters
  - Additional return values
  - Return address
  - Callee saved registers
  - Local variables

Frame pointer: the frame pointer is a fixed harness on the stack (for a given procedure) and points
to the first address of the activation record (AR) of the currently executing procedure. Stack Pointer 
可能在过程执行期间改变，因此建栈时， Callee 将存储前一个 FP ，然后把 SP 的值复制给 FP。

### Additional addressing modes

- Indirect addressing: `ld @(ra)` the contents of the register ra will be used as the
  address of the address of the actual memory operand
- Pseudo-direct addressing: Address is formed from first (top) 6 bits of PC and last
  (bottom) 26 bits of instruction

### Instruction Set Architecture Choices

- Specific set of arithmetic and logic instructions
- Addressing modes
- Architectural style
  - Stack oriented: Burroughs; all the operands are on a stack
  - Memory oriented: IBM s/360; most (if not all) instructions work on memory operands
  - Register oriented: MIPS, Alpha, ARM; most instructions in this architecture deal with operands that are in registers.
    With the maturation of compiler technology, and the efficient use of registers within the
    processor, this style of architecture has come to stay as the instruction-set architecture of choice. 
  - Hybrid: Intel x86 and Power PC of architectures are a hybrid of the memory-oriented and register-oriented styles
- Memory layout of the instruction.
- Drivers
  - Technology trends
  - Implementation feasibility
  - Goal of elegant/efficient support for high-level language constructs.

### Instruction Format

按操作数的数量分：

- Zero Operand Instructions
  - Halt, NOP
  - Stack-oriented machines: implicit operands for most instructions like Add
    (pop top two elements of the stack, add them, and push the result back on to the stack)
- One Operand Instructions: map to unary operations in high-level languages
  - Inc, Dec, Neg, Not
  - Accumulator machines (using 1 implicit operand): Load M (ACC <- operand), Add M (ACC <- ACC+M)
  - Stack-oriented machines: `PUSH <operand>` (pushes the operand on to the stack),
    `POP <operand>` (pops the top element of the stack into the operand)
- Two Operand Instructions: map to binary operations in a high level language
  - Add r1, r2 (i.e. r1 = r1 + r2)
  - Mov r1, r2 (r1 = r2)
- Three Operand Instructions
  - Add r1, r2, r3 (r1 = r2 + r3)
  - Load rd, rb, offset (`rd = MEM[rb + offset]`)

`Opcode | Operand specifiers`

* Fixed Length Instructions: 
  * Pros: Simplifies implementation; Can start interpreting as soon as the instruction is available
  * Cons: May waste space; May need additional logic in datapath; Limits instruction set designer
* Variable Length Instructions:
  * Pros: No wasted space; Less constraints on designer; More flexibility opcodes, addressing modes and operands
  * Cons: Complicates implementation (instructions are discerned only after decoding the opcode,
    leading to sequential interpretation of the instruction and its operands)

## LC-2200 Instruction Set

- 32-bit
- Register-oriented
- Little-endian
- Fixed length instruction format
- 16 general-purpose registers
- Program counter (PC) register
- All addresses are word addresses

[CS 2200 Intro to Systems and Networks Project 2 - LC-2200-32 Processor Reference Manual][LC-2200]

[LC-2200]: https://faculty.cc.gatech.edu/~rama/CS2200-External/projects/p2/LC-2200-32.html

Instruction Format:
- R-type instructions
  - add and nand
- I-type instructions
  - addi, lw, sw, and beq
- J-type instruction
  - jalr
- O-type instruction
  - halt

Issues Influencing Processor Design:
- Instruction Set
  - market pressure/adpotion: software giants, box makers, and builders of embedded systems
  - CISC vs RISC
  - backward compatibility 
- Applications
  - number crunching in scientific and engineering applications: floating-point arithmetic
  - applications that process audio, video, and graphics deal with streaming data require the same operation (such as
    addition) to be applied to corresponding elements of two or more streams (continuous data): Intel MMX instructions (SIMD) 
  - gaming industry (graphics and animation processing in real-time): Graphic Processing Units (GPUs)
- Other
  - Operating system
  - Support for modern languages
  - Memory system
  - Parallelism
  - Debugging
  - Virtualization
  - Fault Tolerance
  - Security

# Summary

Instruction-set serves as a contract between hardware and software.

- High-level language constructs shaps the ISA
- Minimal support needed in the ISA for compiling arithmetic and logic expressions, conditional statements, loops, and procedure calls
- Pragmatic issues (such as addressing and access times) that necessitate use of registers in the ISA
- Addressing modes for accessing memory operands in the ISA commensurate with the needs of efficient compilation of high level language constructs
- Software conventions that guide the use of the limited register set available within the processor
- The concept of a software stack and its use in compiling procedure calls
- Possible extensions to a minimal ISA
- Other important issues guiding processor design in this day and age

# Review Question

> 答案来自 Kimi，仅供参考。

1. Having a large register-file is detrimental to the performance of a processor since it
results in a large overhead for procedure call/return in high-level languages. Do you
agree or disagree? Give supporting arguments.

<details>

<summary> Answer. </summary>

I disagree with the statement that having a large register-file is detrimental to the performance of a processor
due to overhead in procedure call/return.

1. Performance Benefits of Large Register-Files

* Reduced Memory Access: A large register-file can hold more data and variables locally within the processor.
  This means that frequently used data can be accessed much faster compared to fetching it from memory.
  Memory access is usually slower than register access because registers are physically closer to the execution units and have lower latency.
  For example, in a loop where multiple variables are being used and updated repeatedly, having these variables stored in a large register-file can significantly speed up the execution.
* Improved Instruction-Level Parallelism (ILP): Modern processors use techniques like pipelining and superscalar execution to improve performance.
  A large register-file can help in these cases. When there are more registers available, it is easier to avoid data hazards (such as read-after-write hazards).
  The processor can keep more instructions in flight without having to stall due to waiting for data to be written back from memory.
  For instance, in a superscalar processor that can issue multiple instructions per cycle, having a large register-file allows for better scheduling of instructions because there is less chance of register conflicts.
* Enhanced Compiler Optimization: Compilers can take advantage of a large register-file to optimize code more effectively.
  They can allocate more variables to registers, reducing the need for spilling (moving variables to memory when there are not enough registers).
  This leads to more efficient code generation. For example, in a function with many local variables, a compiler can assign most of them to registers if there are enough registers available.
  This reduces the number of memory accesses during the execution of the function.

2. Procedure Call/Return Overhead:

* Efficient Calling Conventions: While it is true that procedure calls and returns involve saving and restoring registers, the overhead can be minimized with efficient calling conventions.
  In many calling conventions, only a subset of registers (callee-saved registers) need to be saved and restored across function calls.
  The rest of the registers (caller-saved registers) can be freely used by the called function without saving them.
  This means that the overhead is not directly proportional to the size of the register-file, but rather to the number of callee-saved registers.
* Context Switching Overhead is Manageable: Even in the case of context switching (which is more extreme than a simple procedure call/return), modern processors and operating systems have mechanisms to handle the overhead.
  For example, in a multitasking operating system, the context switch involves saving the state of the current process and restoring the state of the next process.
  While this does involve saving and restoring registers, the performance impact is mitigated by various techniques such as keeping the context switch overhead low through efficient scheduling algorithms and minimizing the frequency of context switches.

In conclusion, the benefits of having a large register-file in terms of reduced memory access, improved instruction-level parallelism, and enhanced compiler optimization generally outweigh the potential overhead in procedure call/return.
The overhead can be effectively managed through calling conventions and other techniques.

</details>

2. Distinguish between the frame pointer and the stack pointer.

<details>

<summary>Answer.</summary>

The frame pointer and the stack pointer are two important registers used in the context of function calls and stack management in computer systems.
They serve different purposes and have distinct roles in managing the stack during program execution. Here’s a detailed distinction between the two:

1. Stack Pointer (SP)

* Definition: The stack pointer is a special-purpose register that points to the top of the stack. It always points to the most recently pushed item on the stack.
* Purpose:
  * Stack Management: The stack pointer is used to keep track of the current top of the stack.
    It is incremented or decremented as items are pushed onto or popped from the stack.
  * Function Calls: When a function is called, the return address and other data (such as parameters and local variables) are pushed onto the stack.
    The stack pointer is adjusted accordingly.
  * Memory Allocation: The stack pointer is used to allocate memory for local variables within a function.
    When a function is called, space for its local variables is allocated by adjusting the stack pointer.
* Behavior:
  * Dynamic: The stack pointer changes frequently during program execution. It is updated every time a push or pop operation is performed.
  * Volatile: The stack pointer is constantly modified and is not preserved across function calls.

2. Frame Pointer (FP)

* Definition: The frame pointer is a register that points to a fixed location within the current stack frame.
  It typically points to the base of the current function’s stack frame.
* Purpose:
  * Stack Frame Management: The frame pointer provides a stable reference point within the stack frame.
    It allows access to local variables and parameters using a fixed offset.
  * Function Calls: When a function is called, the frame pointer is set to the base of the new stack frame.
    This allows the function to access its local variables and parameters without worrying about changes to the stack pointer.
  * Debugging and Backtracing: The frame pointer is useful for debugging and stack backtracing.
    It provides a consistent reference point for each stack frame, making it easier to reconstruct the call stack.
* Behavior:
  * Stable: The frame pointer remains constant throughout the execution of a function.
    It is only updated when a new function is called or when the current function returns.
  * Non-Volatile: The frame pointer is preserved across function calls and is used to maintain the structure of the stack frames.

3. Key Differences

* Role in Stack Management:
  * Stack Pointer (SP): Dynamic, points to the top of the stack, frequently changes.
  * Frame Pointer (FP): Stable, points to the base of the current stack frame, remains constant during function execution.
* Usage in Function Calls:
  * Stack Pointer (SP): Used to allocate and deallocate memory for local variables and parameters. It is adjusted during function prologue and epilogue.
  * Frame Pointer (FP): Used to access local variables and parameters using fixed offsets. It provides a stable reference point within the stack frame.
* Impact on Performance:
  * Stack Pointer (SP): More flexible but can be less efficient due to frequent updates.
  * Frame Pointer (FP): Provides better stability and easier debugging, but may require additional instructions to maintain.
* Compiler Optimization:
  * Stack Pointer (SP): Modern compilers may optimize away the frame pointer in favor of using the stack pointer directly for stack frame management to save instructions and improve performance.
  * Frame Pointer (FP): Used in debug builds or when debugging information is required. It can be omitted in optimized release builds.
4. Example in Function Prologue and Epilogue

Consider a typical function call sequence:

```c
void callee_function() {
    int local_var1;
    int local_var2;
    // Function body
}

void caller_function() {
    callee_function();
}
```

Prologue:
* Stack Pointer (SP): Adjusted to allocate space for local variables.
* Frame Pointer (FP): Set to the base of the current stack frame.

```assembly
push rbp          ; Save old frame pointer
mov rbp, rsp      ; Set new frame pointer to current stack pointer
sub rsp, 8        ; Allocate space for local variables (e.g., local_var1 and local_var2)
```

Epilogue:
* Stack Pointer (SP): Adjusted to deallocate space for local variables.
* Frame Pointer (FP): Restored to the previous frame pointer.

```assembly
mov rsp, rbp      ; Restore stack pointer to base of stack frame
pop rbp           ; Restore old frame pointer
ret               ; Return to caller
```


</details>

3. In the LC-2200 architecture, where are operands normally found for an add instruction?

<details>

<summary>Answer.</summary>

在 LC-2200 架构中，ADD 指令的运算数通常位于寄存器中。具体来说，ADD 指令的格式如下：
指令格式：

```
ADD DR, SR1, SR2
```

操作数来源：
* 第一个源操作数来自寄存器 SR1。
* 第二个源操作数来自寄存器 SR2。

结果存储：两个操作数相加的结果存储在目标寄存器 DR 中。

这种设计使得 ADD 指令可以直接从寄存器中获取操作数并执行加法操作，从而提高指令执行的效率。

</details>


4. This question pertains to endianness. Let’s say you want to write a program for
comparing two strings. You have a choice of using a 32-bit byte-addressable Big-
endian or Little-endian architecture to do this. In either case, you can pack 4
characters in each word of 32-bits. Which one would you choose and how will you
write such a program? (Hint: Normally, you would do string comparison one
character at a time. If you can do it a word at a time instead of a character at a time,
that implementation will be faster.)

<details>

<summary>Answer.</summary>

Choosing Between Big-Endian and Little-Endian Architectures
When comparing two strings, the choice between a Big-Endian and Little-Endian architecture depends on how you want to handle the data and how you plan to implement the comparison logic.

Big-Endian vs. Little-Endian

Big-Endian:

In Big-Endian, the most significant byte (MSB) is stored at the lowest memory address.
For example, the string "abcd" (in ASCII) would be stored as:

```
Memory Address: 0x0000 -> 'a' (0x61)
                0x0001 -> 'b' (0x62)
                0x0002 -> 'c' (0x63)
                0x0003 -> 'd' (0x64)
```

When packed into a 32-bit word, it would be: 0x61626364

This format is more intuitive for reading and comparing strings because the most significant character is at the beginning of the word.

Little-Endian:

In Little-Endian, the least significant byte (LSB) is stored at the lowest memory address.
For example, the string "abcd" (in ASCII) would be stored as:

```
Memory Address: 0x0000 -> 'd' (0x64)
                0x0001 -> 'c' (0x63)
                0x0002 -> 'b' (0x62)
                0x0003 -> 'a' (0x61)
```

When packed into a 32-bit word, it would be: 0x64636261

This format might require additional logic to handle the reversed order when comparing strings.

Recommendation:
For comparing strings, Big-Endian is generally more straightforward and intuitive. It aligns with the natural way we read and compare strings, where the most significant character (the first character) is at the beginning of the word. This can simplify the comparison logic.

Example Program in C:
Here is an example of how you might write a program to compare two strings in a Big-Endian architecture. This example assumes a 32-bit byte-addressable architecture where each word can hold 4 characters.

```c
#include <stdio.h>
#include <string.h>
#include <stdint.h>

// Function to compare two strings
int compare_strings(const char* str1, const char* str2) {
    // Get the length of both strings
    size_t len1 = strlen(str1);
    size_t len2 = strlen(str2);

    // Compare characters one by one up to the length of the shorter string
    for (size_t i = 0; i < len1 && i < len2; i++) {
        if (str1[i] != str2[i]) {
            return str1[i] - str2[i];
        }
    }

    // If all characters up to the length of the shorter string are equal,
    // the result depends on the lengths of the strings
    return len1 - len2;
}

int main() {
    const char* str1 = "hello";
    const char* str2 = "world";

    int result = compare_strings(str1, str2);

    if (result < 0) {
        printf("'%s' is less than '%s'\n", str1, str2);
    } else if (result > 0) {
        printf("'%s' is greater than '%s'\n", str1, str2);
    } else {
        printf("'%s' is equal to '%s'\n", str1, str2);
    }

    return 0;
}
```

</details>

5. An ISA may support different flavors of conditional branch instructions such as BZ
(branch on Zero), BN (branch on negative), and BEQ (branch on equal). Figure out
the predicate expressions in an “if” statement that may be best served by these
different flavors of conditional branch instructions. Give examples of such predicates
in an “if” statement, and how you will compile them using these different flavors of
branch instructions.

<details>

<summary>Answer.</summary>

* BZ (Branch on Zero): Best suited for predicates like if (x == 0).
* BN (Branch on Negative): Best suited for predicates like if (x < 0).
* BEQ (Branch on Equal): Best suited for predicates like if (x == y).

</details>

6. We said that endianness will not affect your program performance or correctness so
long as the use of a (high level) data structure is commensurate with its declaration.
Are there situations where even if your program does not violate the above rule, you
could be bitten by the endianness of the architecture? (Hint: Think of programs that
cross network boundaries.)

<details>

<summary>Answer.</summary>

Endianness refers to the order in which bytes are stored in memory for multi-byte data types (e.g., integers, floating-point numbers).
While it is true that endianness generally does not affect program performance or correctness as long as data structures are used consistently with their declarations,
there are still some situations where endianness can cause issues or unexpected behavior, even if the program adheres to the rule of using data structures correctly. Here are a few scenarios:

1. Binary File I/O

When reading or writing binary files that are created on a different architecture, endianness can become a problem. For example,
if a binary file is written on a big-endian machine and then read on a little-endian machine,
the byte order of multi-byte data types will be incorrect unless the program explicitly handles the conversion.

Example:

```c
// Writing an integer to a binary file on a big-endian machine
int value = 0x12345678;
fwrite(&value, sizeof(value), 1, file);

// Reading the same file on a little-endian machine
int read_value;
fread(&read_value, sizeof(read_value), 1, file);
// read_value will be 0x78563412 on a little-endian machine
```

To avoid this issue, programs must explicitly convert the byte order when reading or writing binary files across different architectures.

2. Networking

Network protocols typically use big-endian byte order (also known as network byte order) for multi-byte data types.
If a program running on a little-endian machine sends or receives data over a network without converting the byte order,
the data will be interpreted incorrectly.

Example:
```c
// Sending an integer over a network from a little-endian machine
int value = 0x12345678;
send(socket, &value, sizeof(value), 0);

// Receiving the same integer on another little-endian machine
int received_value;
recv(socket, &received_value, sizeof(received_value), 0);
// received_value will be 0x78563412 on a little-endian machine
```

To handle this correctly, programs must use functions like htons() (host to network short) and htonl() (host to network long) 
to convert data to network byte order before sending and convert it back using ntohs() and ntohl() after receiving.

3. Low-Level Programming and Bit Manipulation

In some low-level programming scenarios, such as firmware development or direct hardware interfacing,
endianness can affect how data is interpreted and manipulated.

For example, if a hardware device expects data in a specific byte order, the program must ensure that
the data is correctly formatted according to the device's requirements.

4. Debugging and Reverse Engineering

When debugging or reverse engineering code, especially when dealing with low-level memory dumps or disassembled code, endianness can lead to confusion.

For example, a debugger might display memory contents in a specific byte order, which could be different from the architecture's endianness.

Summary

* Binary File I/O: Data written on one architecture may be read incorrectly on another.
* Networking: Data sent over networks must be converted to network byte order.
* Low-Level Programming: Hardware interfacing and bit manipulation may require explicit handling of byte order.
* Debugging: Endianness can affect how memory contents are interpreted during debugging.

</details>


7. Work out the details of implementing the switch statement of C using jump tables in
assembly using any flavor of conditional branch instruction. (Hint: After ensuring
that the value of the switch variable is within the bounds of valid case values, jump to
the start of the appropriate code segment corresponding to the current switch value,
execute the code and finally jump to exit.)

<details>

<summary>Answer.</summary>

Implementing a switch statement in C using jump tables in assembly is an efficient way to handle multiple cases,
especially when the number of cases is large.
Jump tables allow for constant-time branching, which can be more efficient than a series of conditional branches.

Example C Code

```c
switch (x) {
    case 0:
        // Code for case 0
        break;
    case 1:
        // Code for case 1
        break;
    case 2:
        // Code for case 2
        break;
    default:
        // Default code
}
```

Steps to Implement Using Jump Tables

1. Create a Jump Table: A jump table is an array of addresses, where each address corresponds to the starting address of the code for a particular case.

Index into the Jump Table: Use the value of x to index into the jump table and jump to the corresponding address.

Handle Default Case: If the value of x is out of range, jump to the default case.

Assembly Implementation

Assume the following:
* x is stored in register R1.
* The jump table is stored in memory starting at address JUMP_TABLE.

```assembly
; Assume x is in R1
; Assume JUMP_TABLE is at address 0x1000

; Check if x is within the valid range (0 to 2)
CMP R1, #2       ; Compare R1 with 2
BGT default_case ; Branch to default case if R1 > 2
BLT default_case ; Branch to default case if R1 < 0

; Calculate the address to jump to
MOV R2, #0x1000  ; Load base address of jump table into R2
ADD R2, R2, R1   ; Add the value of x to the base address
LDR R3, [R2]     ; Load the address from the jump table into R3
BX R3            ; Branch to the address in R3

default_case:
    ; Code for default case
    ; ...

; Jump table (addresses of case code blocks)
JUMP_TABLE:
    DCD case_0   ; Address of code for case 0
    DCD case_1   ; Address of code for case 1
    DCD case_2   ; Address of code for case 2

case_0:
    ; Code for case 0
    ; ...
    B end_switch ; Branch to end of switch

case_1:
    ; Code for case 1
    ; ...
    B end_switch ; Branch to end of switch

case_2:
    ; Code for case 2
    ; ...
    B end_switch ; Branch to end of switch

end_switch:
    ; Continue with the rest of the program
```
 
</details>

8. Procedure A has important data in both S and T registers and is about to call
procedure B. Which registers should A store on the stack? Which registers should B
store on the stack?

<details>

<summary>Answer.</summary>

Caller-Saved (T) Registers:
* These registers are typically used for temporary storage and are not guaranteed to be preserved across function calls.
* The calling procedure (Procedure A) is responsible for saving these registers if it needs to preserve their values across the call to Procedure B.

Callee-Saved (S) Registers:
* These registers are expected to be preserved across function calls.
* The called procedure (Procedure B) is responsible for saving and restoring these registers if it modifies them.

</details>

9. Consider the usage of the stack abstraction in executing procedure calls. Do all
actions on the stack happen only via pushes and pops to the top of the stack? Explain
circumstances that warrant reaching into other parts of the stack during program
execution. How is this accomplished?

<details>

<summary>Answer.</summary>

General Actions on the Stack:

In the context of executing procedure calls, most actions on the stack do indeed occur through pushes and pops to the top of the stack.
When a procedure is called, the return address (the address of the instruction to execute after the procedure call returns) is typically
pushed onto the stack. Also, parameters for the procedure may be pushed onto the stack.
When the procedure returns, the return address is popped from the stack to determine where to resume execution.

Circumstances for Reaching into Other Parts of the Stack:

* Accessing Local Variables in Nested Procedures: In some programming languages and calling conventions, local variables of a procedure
  are stored on the stack. If there are nested procedure calls, a procedure might need to access its own local variables or the local
  variables of an outer procedure.
* Error Handling and Exception Handling: In some systems, when an error or exception occurs, the stack needs to be unwound to find
  the appropriate error handler or exception handler. This might involve looking at stack frames other than the top one to determine
  where to transfer control.

How It Is Accomplished:

Using Stack Pointer and Base Pointer: In many implementations, there are two important registers related to the stack:
the stack pointer (SP) and the base pointer (BP, also known as the frame pointer in some architectures).

* The stack pointer points to the top of the stack. When pushing and popping, the stack pointer is adjusted accordingly.
* The base pointer is used to point to the base of the current stack frame. Each procedure can set up its own base pointer when it starts executing.

Direct Address Calculation: In some cases, the address of a specific location in the stack can be calculated directly based on the stack pointer or base pointer and known offsets.

</details>

10. Answer True/False with justification: Procedure call/return cannot be implemented
without a frame pointer.

<details>

<summary>Answer.</summary>

False

Justification:

* Frame Pointer is Not Essential for Procedure Call/Return

The primary purpose of a frame pointer is to provide a stable reference point for accessing local variables and parameters within a stack frame.
However, the stack pointer (SP) alone can be used to manage the stack if the calling convention and procedure implementation are designed carefully.

* Using Only the Stack Pointer

When a procedure is called, the return address is pushed onto the stack. The stack pointer is adjusted accordingly.
The procedure can use the stack pointer to access its parameters and local variables by calculating offsets from the current stack pointer value.
For example, if a procedure expects its first parameter to be at a specific offset from the stack pointer, it can directly access it using the stack pointer without needing a frame pointer.
When the procedure returns, it can pop the return address from the stack using the stack pointer, and execution can resume at the correct location.

* Trade-offs Without a Frame Pointer

  * Complexity: Managing offsets from the stack pointer can be more complex, especially for procedures with many local variables and parameters.
    The offsets need to be carefully calculated and managed.
  * Performance: In some cases, using a frame pointer can improve performance because it provides a stable reference point,
    reducing the need for complex offset calculations.
  * Debugging and Maintenance: Frame pointers make it easier to debug and maintain code, as they provide a clear structure for stack frames.
    Without a frame pointer, debugging stack-related issues can be more challenging.

Example of Procedure Call Without Frame Pointer
```assembly
; Caller code
push return_address
push parameter1
call procedure

; Procedure code
add sp, -4  ; Allocate space for local variable
; Access local variable using sp + 4
add sp, 4   ; Deallocate local variable space
pop return_address
ret
```

</details>

11. DEC VAX has a single instruction for loading and storing all the program visible
registers from/to memory. Can you see a reason for such an instruction pair?
Consider both the pros and cons.

<details>

<summary>Answer.</summary>

优点:
* Context Switching Efficiency：VAX provides instructions like SVPCTX (Save Process Context) and LDPCTX (Load Process Context) that facilitate efficient context switching。这些指令能够快速保存和恢复进程上下文，这对于多任务操作系统尤其重要。通过单条指令完成大量寄存器的保存和恢复，减少了上下文切换的开销。
* Code Density：VAX的指令集设计允许复杂的操作通过单条指令完成，这使得代码更加紧凑。例如，VAX的CALLS和RET指令可以自动化地保存和恢复寄存器状态，减少了代码量。这种高代码密度在内存有限的系统中非常有优势。
* Simplified Programming Model：对于某些编程场景，单条指令完成寄存器的加载和存储可以简化编程模型。程序员可以更直观地处理寄存器的保存和恢复，减少了编写和调试代码的复杂性。

缺点:
* Instruction Complexity：VAX的这种指令设计增加了指令的复杂性。单条指令需要处理多个寄存器的保存和恢复，这可能导致指令执行时间较长，尤其是在寄存器数量较多时。
* Microcode Overhead：这些复杂的指令通常需要更多的微代码支持。微代码的复杂性可能会导致硬件设计更加复杂，并且在某些情况下可能会影响性能。
* Limited Flexibility：单条指令的固定功能可能限制了某些优化的可能性。例如，在某些情况下，可能只需要保存或恢复部分寄存器，但单条指令的设计可能无法灵活地处理这种情况，从而导致不必要的开销。

</details>


<details>

<summary>Answer.</summary>

通过补码和加法实现减法
* 取反加一：将被减数取反后加1，得到其补码。
* 加法操作：将减数与补码相加，结果即为减法的结果。

```assembly
ADDI $a0, $zero, 1
; 假设R2是被减数，R3是减数，结果存储到R1中
NAND R4, R3, $a0  ; R4 = ~(R3 && 1)（取反）
ADD  R4, R4, #1  ; R4 = R4 + 1（补码）
ADD  R1, R2, R4  ; R1 = R2 + R4（加法实现减法）
```

</details>


13. The BEQ instruction restricts the distance you can branch to from the current position
of the PC. If your program warrants jumping to a distance larger than that allowed by
the offset field of the BEQ instruction, show how you can accomplish such “long”
branches using the existing LC-2200 ISA.

<details>

<summary>Answer.</summary>

```assembly
; pos
BEQ $a0, $a1, offset1

; pos + 1 + offset1
JALR $a3, $s0

; $a3
JALR $a4, $s1
```

</details>

14. What is an ISA and why is it important?

<details>

<summary>Answer.</summary>

在计算机系统中，指令集体系结构（Instruction Set Architecture，ISA） 是处理器架构中与编程相关的部分，它定义了处理器能够执行的指令集、数据类型、寄存器、内存组织结构、寻址模式、中断处理以及输入/输出操作等。ISA 是软件和硬件之间的接口，它为程序员提供了一种与硬件交互的方式。

ISA 的重要性
* 软件与硬件的兼容性：ISA 为软件和硬件之间提供了一个标准接口，确保为特定 ISA 编写的软件可以在任何支持该 ISA 的硬件上运行。这种兼容性使得软件开发者能够编写可在多种硬件平台上运行的应用程序，而无需对代码进行大量修改。
* 性能优化：ISA 的设计直接影响处理器的性能。不同的 ISA 设计（如 RISC 和 CISC）在指令执行速度、代码密度和效率方面存在差异。通过优化 ISA，可以提高处理器的执行效率和功耗表现。
* 编译器设计：ISA 定义了编译器需要将高级语言转换成的目标指令集。了解 ISA 的特性可以帮助编译器开发者设计出更高效的代码生成策略，从而提升程序的运行性能。
* 硬件设计的蓝图：ISA 为硬件设计者提供了处理器设计的基本框架，包括寄存器、指令格式和内存组织等。这使得硬件设计者能够开发出高效的流水线和缓存策略，优化微架构以提升性能。
* 生态系统和软件库的开发：一个定义良好的 ISA 可以促进围绕该架构的软件生态系统的发展。这包括各种应用程序、工具和框架的开发，从而增强处理器的功能。

ISA 的类型
* 复杂指令集计算机（CISC）：CISC 架构包含丰富的指令集，旨在通过较少的代码行完成任务，通常用于个人计算机。
* 精简指令集计算机（RISC）：RISC 架构通过简化指令集来优化处理器设计，使用更少的指令来完成任务，常用于对功耗要求较高的设备，如智能手机和平板电脑。
* 超长指令字（VLIW）：VLIW 架构将多个操作编码到单条指令中，适用于需要精确执行时间的应用。
* 显式并行指令计算（EPIC）：EPIC 架构允许软件显式控制可以并行执行的多个操作，主要用于高端计算系统。

ISA 是计算机技术的核心组成部分，它不仅连接了软件和硬件，还为系统设计、性能优化和技术创新提供了基础。

</details>

17. Define the term addressing mode.

<details>

<summary>Answer.</summary>

In computer architecture, an addressing mode refers to the way in which the location of data (operands) is specified in an instruction.
Addressing modes define how the address of the data to be used in an instruction is calculated or determined.
They play a crucial role in determining the flexibility and efficiency of instruction execution in a processor.

Key Concepts of Addressing Modes

* Operand Location: Addressing modes specify where the operands (data) for an instruction are located.
  These operands can be in registers, memory, or even within the instruction itself.
* Address Calculation: Addressing modes determine how the effective address of the operand is calculated.
  This can involve simple direct addressing or more complex calculations involving base registers, offsets, and indexing.
* Instruction Format: The addressing mode affects the format of the instruction and the number of bytes required to specify the operand's location.

Common Addressing Modes

1. Immediate Addressing

Definition: The operand is directly specified within the instruction itself.

Example: ADD R1, #5 (Add the immediate value 5 to register R1).

Usage: Useful for constants and small values.

2. Direct Addressing

Definition: The address of the operand is directly specified in the instruction.

Example: LOAD R1, 0x1000 (Load the value from memory address 0x1000 into register R1).

Usage: Simple and straightforward for accessing specific memory locations.

3. Indirect Addressing

Definition: The address of the operand is stored in a memory location specified by the instruction.

Example: LOAD R1, (0x1000) (Load the value from the memory address stored at location 0x1000 into register R1).

Usage: Useful for accessing data structures like arrays and linked lists.

4. Register Addressing

Definition: The operand is located in a register specified in the instruction.

Example: ADD R1, R2 (Add the value in register R2 to register R1).

Usage: Fast and efficient for operations involving registers.

5. Indexed Addressing

Definition: The address of the operand is calculated by adding an index register value to a base address specified in the instruction.

Example: LOAD R1, 0x1000(R2) (Load the value from memory address 0x1000 + R2 into register R1).

Usage: Useful for accessing elements in arrays or tables.

6. Base Plus Offset Addressing

Definition: The address of the operand is calculated by adding a constant offset to a base register value.

Example: LOAD R1, R2 + 10 (Load the value from memory address R2 + 10 into register R1).

Usage: Commonly used for accessing elements within structures or objects.

7. Relative Addressing

Definition: The address of the operand is calculated relative to the current instruction pointer (PC).

Example: JMP +10 (Jump to the instruction located 10 bytes ahead of the current instruction).

Usage: Useful for implementing loops and conditional branches.

8. Bit-Field Addressing

Definition: The address specifies a portion of a word (bit-field) rather than an entire word.

Usage: Useful for accessing specific bits or fields within a word.

Importance of Addressing Modes

* Flexibility: Different addressing modes provide flexibility in specifying operand locations,
  making it easier to write efficient and readable code.
* Efficiency: By allowing various ways to calculate addresses,
  addressing modes can optimize memory access patterns and reduce the number of instructions needed.
* Complex Data Structures: Addressing modes like indexed and base-plus-offset are essential for efficiently
  accessing complex data structures like arrays and structures.
* Code Density: Some addressing modes allow more compact instruction encoding, which can be crucial for systems 
  with limited memory or instruction cache.

</details>

<details>

18. how exactly modern compilers allocate space for local variables in a procedure call. 

<summary>Answer.</summary>

Modern compilers allocate space for local variables in a procedure call through a combination of stack allocation and register allocation,
depending on various factors such as the availability of registers,
the scope and lifetime of variables, and optimization strategies.

Here’s a detailed explanation of the process:

1. Stack Allocation

When a procedure is called, the compiler typically allocates space for local variables on the stack.

The stack is a Last-In-First-Out (LIFO) data structure that manages the memory for local variables and function calls.
The process involves the following steps:
* Binding: The compiler assigns offsets for local variables relative to the stack pointer (SP).
* Allocation: Space for local variables is allocated by decrementing the stack pointer.
* Access: Local variables are accessed using load (LDR) and store (STR) instructions with offsets from the stack pointer.
* Deallocation: When the procedure ends, the stack space allocated for local variables is automatically reclaimed by adjusting the stack pointer.

2. Register Allocation

Compilers also try to allocate local variables to registers to improve performance, as accessing registers is faster than accessing memory.
The process involves:
* Analysis: The compiler analyzes the usage of variables to determine which sets of variables are live at the same time and estimates the number of accesses for each variable.
* Assignment: If there are enough available registers, the compiler assigns registers to variables.
  If not, some variables are spilled into memory (stack).
  The compiler tries to spill the least-accessed variables to minimize memory accesses.
* Optimization: Modern compilers use sophisticated algorithms to optimize register allocation,
  although achieving the optimal allocation is challenging.

3. Activation Records

When a procedure is called, an activation record (also known as a stack frame) is created on the stack. This record contains:
* Local data: Temporary and intermediate values of expressions.
* Machine status: Information such as register values and program counter status before the procedure call.
* Control link: The address of the activation record of the calling procedure.
* Access link: Information about data outside the local scope.
* Parameters: Input parameters for the procedure, which are often stored in registers for efficiency.
* Return value: The return value of the procedure, preferably stored in registers.

4. Variable-Length Data

For local variables whose sizes are not known at compile time (e.g., variable-length arrays), the compiler uses a special strategy.
The actual storage for these variables is allocated on the heap, but only a pointer to the beginning of the array is stored in the activation record.
The compiler generates code to manage these pointers at runtime.

</details>

19. We use the term abstraction to refer to the stack. What is meant by this term? Does
the term abstraction imply how it is implemented? For example, is a stack used in a
procedure call/return a hardware device or a software device?

<details>

<summary>Answer.</summary>

The term abstraction in the context of computer science and programming refers to the process of hiding the complex reality behind an interface or a model,
exposing only the essential features and behaviors necessary for a particular purpose.

In the case of a stack, abstraction means that the details of how the stack is implemented are hidden from the programmer,
who only needs to know how to interact with the stack through its interface (e.g., push, pop, peek operations).

Abstraction and Implementation

Abstraction does not imply the specific implementation details.
It focuses on the what (the functionality) rather than the how (the implementation).

For example, a stack can be implemented in multiple ways, but the programmer using the stack does not need to know whether it is implemented using an array,
a linked list, or some other data structure. The key idea is that the stack provides a consistent interface (e.g., LIFO behavior) regardless of the underlying implementation.

Stack in Procedure Calls: Hardware vs. Software

In the context of procedure calls and returns, a stack is typically implemented in software using the computer's memory.
However, the concept of a stack is often supported by hardware mechanisms to make it efficient. Here’s a breakdown:

Software Implementation:

The stack is a region of memory that is managed by the operating system and the runtime environment of the program.
The compiler generates code that manipulates the stack pointer (SP) to allocate and deallocate memory for local variables and function call frames.
The stack is implemented using the computer's RAM, and the stack pointer is a register that keeps track of the current top of the stack.

Hardware Support:

Modern CPUs provide special registers and instructions to support stack operations efficiently. For example:
* Stack Pointer (SP): A dedicated register that points to the top of the stack.
* Push and Pop Instructions: Special instructions that automatically update the stack pointer when data is pushed onto or popped from the stack.
  These hardware features make stack operations fast and efficient, but the actual stack itself is still a software-managed data structure in memory.

</details>

20. Given the following instructions
```assembly
BEQ Rx, Ry, offset ; if (Rx == Ry) PC=PC+offset
SUB Rx, Ry, Rz     ; Rx <- Ry - Rz
ADDI Rx, Ry, Imm   ; Rx <- Ry + Immediate value
AND Rx, Ry, Rz     ; Rx <- Ry AND Rz
```

Show how you can realize the effect of the following instruction:

```assembly
BGT Rx, Ry, offset ; if (Rx > Ry) PC=PC+offset
```

Assume that the registers and the Immediate fields are 8-bits wide. You can ignore
overflow that may be caused by the SUB instruction.

<details>

<summary>Answer.</summary>


```assembly
; Step 1: Compute the difference Rx - Ry and store in Rt
SUB Rz, Rx, Ry ; Rz = Rx - Ry
; Step 2: Isolate the MSB of Rt and store in Ru
SUB Ry, Ry, Ry ; Ry = 0
ADDI Rx, Ry, #0b10000000 ; Rx = 128
AND Rz, Rz, Rx ; Rz & 128
; Step 3: Check if Ru is zero (i.e., the result is positive)
BEQ Rz, Ry, offset ; if (Rz == 0) PC += offset
```

</details>

21. Given the following load instruction

```assembly
LW Rx, Ry, OFFSET ; Rx <- MEM[Ry + OFFSET]
```

Show how to realize a new addressing mode, called indirect, for use with the load
instruction that is represented in assembly language as:

```assembly
LW Rx, @(Ry) 
```

The semantics of this instruction is that the contents of register Ry is the address of a
pointer to the memory operand that must be loaded into Rx.

<details>

<summary>Answer.</summary>

```assembly
; Rx <- MEM[MEM[Ry]]
LW Rx, Ry, 0 ; Rx <- MEM[Ry]
LW Rx, Rx, 0 ; Rx <- MEM[Rx]
```

</details>

22. Convert this statement:

```assembly
g = h + A[i];
```

into an LC-2200 assembler with the assumption that the Address of A is located in
$t0, g is in $s1, h is in $s2, and, i is in $t1

<details>

<summary>Answer.</summary>

```assembly
; $s1 = $s2 + *i($t0)
add $t0, $t0, $t1 ; $t0 += $t1 => addr of A[i]
lw $t0, ($t0)     ; $t0 => A[i]
add $s1, $s2, $t0 ; $s1 = $s2 + $t0
```

</details>

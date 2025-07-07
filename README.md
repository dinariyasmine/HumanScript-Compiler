# HumanScript Compiler

**Advanced lexical and syntactic analysis system for custom programming language compilation**

## Overview

A comprehensive compiler implementation for the HumanScript programming language, featuring sophisticated lexical analysis, symbol table management, and syntactic parsing. This project delivers a complete compilation pipeline with optimized data structures and error handling mechanisms through cutting-edge compiler design principles.

## Core Components

```mermaid
graph TB
    subgraph "Compilation Pipeline"
        A[lexical.l - Lexical Analyzer]
        B[syntaxique.y - Syntax Analyzer]
        C[tableSymboles.c - Symbol Table Manager]
        D[analyse_syntaxique.c - Syntax Analysis Engine]
    end
    
    A --> E[Token Recognition]
    B --> F[Grammar Parsing]
    C --> G[Symbol Management]
    D --> H[Error Detection]
    
    E --> I[Flex-generated Scanner]
    F --> J[Bison-generated Parser]
    G --> K[Hash Table Optimization]
    H --> L[Comprehensive Analysis]
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#e8f5e8
    style D fill:#fff3e0
```

| **Lexical Analysis** | **Syntax Analysis** | **Symbol Management** | **Error Handling** |
|:---:|:---:|:---:|:---:|
| `lexical.l` | `syntaxique.y` | `tableSymboles.c` | `analyse_syntaxique.c` |
| Token detection | Grammar validation | Hash table storage | Comprehensive reporting |
| Flex-based scanner | Bison-generated parser | O(1) symbol lookup | Detailed error messages |
| Pattern matching | AST generation | Scope management | Recovery mechanisms |

## Technology Stack

![C](https://img.shields.io/badge/C-A8B9CC?style=for-the-badge&logo=c&logoColor=white)
![Flex](https://img.shields.io/badge/Flex-FF6B35?style=for-the-badge&logo=gnu&logoColor=white)
![Bison](https://img.shields.io/badge/Bison-4CAF50?style=for-the-badge&logo=gnu&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![GCC](https://img.shields.io/badge/GCC-2196F3?style=for-the-badge&logo=gnu&logoColor=white)
![Make](https://img.shields.io/badge/Make-427819?style=for-the-badge&logo=gnu&logoColor=white)

## System Architecture

```mermaid
flowchart TD
    subgraph Input["Source Code Input"]
        SRC[HumanScript Source]
        FILE[Input Files]
    end
    
    subgraph Lexical["Lexical Analysis Layer"]
        LEX[Flex Scanner]
        TOK[Token Generator]
        ERR1[Lexical Error Handler]
    end
    
    subgraph Syntax["Syntax Analysis Layer"]
        PARSE[Bison Parser]
        GRAM[Grammar Rules]
        AST[AST Generator]
        ERR2[Syntax Error Handler]
    end
    
    subgraph Symbol["Symbol Management"]
        HASH[Hash Table]
        SCOPE[Scope Manager]
        LOOKUP[Symbol Lookup]
    end
    
    subgraph Output["Compilation Output"]
        EXEC[Executable Code]
        REPORT[Error Reports]
        TABLE[Symbol Table]
    end
    
    SRC --> LEX
    FILE --> LEX
    
    LEX --> TOK
    TOK --> PARSE
    LEX --> ERR1
    
    PARSE --> GRAM
    GRAM --> AST
    PARSE --> ERR2
    
    TOK --> HASH
    HASH --> SCOPE
    SCOPE --> LOOKUP
    
    AST --> EXEC
    ERR1 --> REPORT
    ERR2 --> REPORT
    LOOKUP --> TABLE
    
    style LEX fill:#ff6b35
    style PARSE fill:#4caf50
    style HASH fill:#2196f3
```

## Installation & Setup

### Prerequisites

```bash
# Install required tools on Ubuntu/Debian
sudo apt update
sudo apt install flex bison gcc make

# For WSL users
wsl --install -d Ubuntu
```

### Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/humanscript-compiler.git
cd humanscript-compiler

# Build the complete compiler
make all

# Or follow manual compilation steps below
```

## Compilation Pipeline

### Automated Build Process

```bash
# Complete build using Makefile
make clean      # Clean previous builds
make all        # Build all components
make test       # Run test suite
```

### Manual Compilation Steps

```mermaid
sequenceDiagram
    participant U as User
    participant F as Flex
    participant B as Bison
    participant G as GCC
    participant C as Compiler
    
    U->>F: flex lexical.l
    F->>F: Generate lex.yy.c
    U->>B: bison -d syntaxique.y
    B->>B: Generate syntaxique.tab.c/h
    U->>G: gcc compilation
    G->>C: Create executable
    C->>U: Ready for execution
```

#### Step-by-Step Instructions

1. **Activate Linux Environment**:
   ```bash
   wsl  # Windows Subsystem for Linux
   ```

2. **Generate Lexical Analyzer**:
   ```bash
   flex lexical.l
   # Generates: lex.yy.c (scanner implementation)
   ```

3. **Generate Syntax Analyzer**:
   ```bash
   bison -d syntaxique.y
   # Generates: syntaxique.tab.c, syntaxique.tab.h (parser implementation)
   ```

4. **Compile Main Compiler**:
   ```bash
   gcc lex.yy.c syntaxique.tab.c -o compiler
   # Creates: compiler executable
   ```

5. **Execute Compiler**:
   ```bash
   ./compiler
   # Runs the complete compilation pipeline
   ```

6. **Build Syntax Analysis Tool**:
   ```bash
   gcc analyse_syntaxique.c tableSymboles.c -o analyse_syntaxique
   # Creates: analyse_syntaxique executable
   ```

7. **Run Syntax Analysis**:
   ```bash
   ./analyse_syntaxique
   # Executes detailed syntax analysis
   ```

## Language Features

### HumanScript Token Categories

```mermaid
mindmap
  root((HumanScript Tokens))
    Keywords
      Data Types
        int, float, string, bool
      Control Flow
        if, else, while, for
      Functions
        function, return
      Scope
        global, local
    Operators
      Arithmetic
        +, -, *, /, %
      Comparison
        ==, !=, <, >, <=, >=
      Logical
        &&, ||, !
      Assignment
        =, +=, -=, *=, /=
    Literals
      Numbers
        integers, decimals
      Strings
        "quoted text"
      Booleans
        true, false
    Identifiers
      Variables
        user-defined names
      Functions
        procedure names
```


## Performance Optimization


### Performance Metrics

| **Component** | **Time Complexity** | **Space Complexity** | **Optimization** |
|:---:|:---:|:---:|:---:|
| **Lexical Analysis** | O(n) | O(1) | Pattern matching optimization |
| **Symbol Lookup** | O(1) avg | O(n) | Hash table with chaining |
| **Syntax Parsing** | O(n) | O(h) | LR parsing with stack |
| **Error Recovery** | O(1) | O(1) | Panic mode recovery |


## Error Handling

```mermaid
graph TD
    subgraph "Error Detection"
        A[Lexical Errors]
        B[Syntax Errors]
        C[Semantic Errors]
    end
    
    subgraph "Error Recovery"
        D[Panic Mode]
        E[Phrase Level]
        F[Error Productions]
    end
    
    subgraph "Error Reporting"
        G[Line Numbers]
        H[Error Messages]
        I[Suggestions]
    end
    
    A --> D
    B --> E
    C --> F
    
    D --> G
    E --> H
    F --> I
    
    style A fill:#ffcdd2
    style B fill:#ffe0b2
    style C fill:#fff3e0
```

## Testing & Validation

### Test Suite

```bash
# Run comprehensive tests
make test

# Individual component testing
./test_lexical.sh      # Lexical analysis tests
./test_syntax.sh       # Syntax analysis tests
./test_symbols.sh      # Symbol table tests
```

### Example Programs

```humanscript
// Sample HumanScript program
function main() {
    int x = 10;
    float y = 3.14;
    string message = "Hello, World!";
    
    if (x > 5) {
        print(message);
    }
    
    return 0;
}
```

## Contact

**Academic Project - Systems and Software Engineering**

**Institution:** Higher Scholl Of Computer Science Algiers
**Academic Year:** 2024/2025  
**Contact:** ly_dinari@esi.dz

## Contributing

```bash
# Fork the repository
git clone https://github.com/yourusername/humanscript-compiler.git

# Create feature branch
git checkout -b feature/improvement-name

# Make changes and commit
git commit -m "Add: description of changes"

# Push and create pull request
git push origin feature/improvement-name
```

## Acknowledgments

**Built with industry-standard tools:**
- **[GNU Flex](https://github.com/westes/flex)** - Fast lexical analyzer generator
- **[GNU Bison](https://www.gnu.org/software/bison/)** - Parser generator
- **[GCC](https://gcc.gnu.org/)** - GNU Compiler Collection
- **[Linux](https://www.linux.org/)** - Development environment
- **[Make](https://www.gnu.org/software/make/)** - Build automation tool

---

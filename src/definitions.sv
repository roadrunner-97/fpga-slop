package definitions;

    // instruction opcodes
    typedef enum logic [7:0] {
        OP_ADD  = 8'h01,
        OP_SUB  = 8'h02,
        OP_AND  = 8'h03,
        OP_OR   = 8'h04,
        OP_XOR  = 8'h05,
        OP_SHL  = 8'h06,
        OP_SHR  = 8'h07,
        OP_ADDI = 8'h11,
        OP_LUI  = 8'h12,
        OP_LD   = 8'h20,
        OP_ST   = 8'h21,
        OP_BEQ  = 8'h30,
        OP_BLT  = 8'h31,
        OP_JMP  = 8'h32,
        OP_JAL  = 8'h33,
        OP_HALT = 8'hFF
    } opcode_t;

    // word and register types
    typedef logic [63:0] word_t;
    typedef logic [3:0]  reg_addr_t;
    typedef logic [7:0]  opcode_raw_t;
    typedef logic [43:0] imm_t;

    // instruction fields (unpacked from a 64-bit instruction word)
    typedef struct packed {
        opcode_raw_t opcode;
        reg_addr_t   rd;
        reg_addr_t   ra;
        reg_addr_t   rb;
        imm_t        imm;
    } instr_t;

    // CPU parameters
    localparam int REG_COUNT = 16;
    localparam int REG_SIZE  = 64;

endpackage
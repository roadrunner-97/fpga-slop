`timescale 1ns/1ps

module instruction_decoder_tb;
    import definitions::*;

    instruction_t         in;
    decoded_instruction_t out;

    instruction_decoder dut (
        .in  (in),
        .out (out)
    );

    // fields that always pass straight through
    task check_base(input string label);
        if (out.opcode          !== in.opcode)          $fatal(1, "FAIL [%s]: opcode mismatch", label);
        if (out.reg_destination !== in.reg_destination) $fatal(1, "FAIL [%s]: rd mismatch",     label);
        if (out.reg_a           !== in.reg_a)           $fatal(1, "FAIL [%s]: ra mismatch",     label);
    endtask

    // assert the full set of control flags at once
    task check_ctrl(
        input string label,
        input logic exp_use_imm, exp_mem_read, exp_mem_write,
                    exp_branch, exp_jump, exp_halt, exp_writeback
    );
        if (out.use_immediate !== exp_use_imm)   $fatal(1, "FAIL [%s]: use_immediate exp %0b got %0b", label, exp_use_imm,   out.use_immediate);
        if (out.mem_read      !== exp_mem_read)  $fatal(1, "FAIL [%s]: mem_read exp %0b got %0b",      label, exp_mem_read,  out.mem_read);
        if (out.mem_write     !== exp_mem_write) $fatal(1, "FAIL [%s]: mem_write exp %0b got %0b",     label, exp_mem_write, out.mem_write);
        if (out.branch        !== exp_branch)    $fatal(1, "FAIL [%s]: branch exp %0b got %0b",        label, exp_branch,    out.branch);
        if (out.jump          !== exp_jump)      $fatal(1, "FAIL [%s]: jump exp %0b got %0b",          label, exp_jump,      out.jump);
        if (out.halt          !== exp_halt)      $fatal(1, "FAIL [%s]: halt exp %0b got %0b",          label, exp_halt,      out.halt);
        if (out.reg_writeback !== exp_writeback) $fatal(1, "FAIL [%s]: reg_writeback exp %0b got %0b", label, exp_writeback, out.reg_writeback);
    endtask

    // R-type ALU op: reg_b comes from the rb field, no immediate.
    task check_alu_reg(input opcode_t op, input string label);
        in.opcode          = op;
        in.reg_destination = 4'h1;
        in.reg_a           = 4'h2;
        in.operand.r.rb    = 4'h3;
        in.operand.r.unused= '0;
        #1;
        check_base(label);
        //                use_imm mem_rd mem_wr br jmp halt wb
        check_ctrl(label,   0,      0,     0,    0,  0,  0,  1);
        if (out.reg_b    !== 4'h3)  $fatal(1, "FAIL [%s]: reg_b should pass through rb field", label);
        if (out.immediate !== '0)   $fatal(1, "FAIL [%s]: immediate should be 0", label);
    endtask

    // I-type ALU op: immediate used, reg_b forced to 0.
    task check_alu_imm(input opcode_t op, input string label);
        in.opcode          = op;
        in.reg_destination = 4'h1;
        in.reg_a           = 4'h2;
        in.operand.imm     = 16'hABCD;
        #1;
        check_base(label);
        check_ctrl(label,   1,      0,     0,    0,  0,  0,  1);
        if (out.immediate !== 16'hABCD) $fatal(1, "FAIL [%s]: immediate value wrong", label);
        if (out.reg_b     !== 4'h0)     $fatal(1, "FAIL [%s]: reg_b should be 0 for immediate op", label);
    endtask

    initial begin
        $dumpfile("build/instruction_decoder.vcd");
        $dumpvars(0, instruction_decoder_tb);

        in = '0;

        // register ALU ops
        check_alu_reg(OP_ADD, "ADD");
        check_alu_reg(OP_SUB, "SUB");
        check_alu_reg(OP_AND, "AND");
        check_alu_reg(OP_OR,  "OR");
        check_alu_reg(OP_XOR, "XOR");
        check_alu_reg(OP_SHL, "SHL");
        check_alu_reg(OP_SHR, "SHR");

        // immediate ALU ops
        check_alu_imm(OP_ADDI, "ADDI");
        check_alu_imm(OP_SUBI, "SUBI");
        check_alu_imm(OP_ANDI, "ANDI");
        check_alu_imm(OP_ORI,  "ORI");
        check_alu_imm(OP_XORI, "XORI");
        check_alu_imm(OP_SHLI, "SHLI");
        check_alu_imm(OP_SHRI, "SHRI");

        // LD: immediate address, reads memory, writes back
        in = '0;
        in.opcode      = OP_LD;
        in.operand.imm = 16'h0100;
        #1;
        //               use_imm mem_rd mem_wr br jmp halt wb
        check_ctrl("LD",   1,      1,     0,    0,  0,  0,  1);
        if (out.immediate !== 16'h0100) $fatal(1, "FAIL [LD]: immediate wrong");

        // ST: immediate address, writes memory, no writeback
        in = '0;
        in.opcode      = OP_ST;
        in.operand.imm = 16'h0200;
        #1;
        check_ctrl("ST",   1,      0,     1,    0,  0,  0,  0);
        if (out.immediate !== 16'h0200) $fatal(1, "FAIL [ST]: immediate wrong");

        // Branches: PC-relative immediate, no writeback, and reg_b is
        // sourced from the reg_destination field (decoder workaround),
        // NOT from use_immediate (which stays 0 for branches).
        in = '0;
        in.opcode          = OP_BEQ;
        in.reg_destination = 4'h7;
        in.operand.imm     = 16'h00FF;
        #1;
        check_ctrl("BEQ",  0,      0,     0,    1,  0,  0,  0);
        if (out.immediate !== 16'h00FF) $fatal(1, "FAIL [BEQ]: immediate wrong");
        if (out.reg_b     !== 4'h7)     $fatal(1, "FAIL [BEQ]: reg_b should come from rd field");

        in = '0;
        in.opcode          = OP_BLT;
        in.reg_destination = 4'h5;
        in.operand.imm     = 16'h00AA;
        #1;
        check_ctrl("BLT",  0,      0,     0,    1,  0,  0,  0);
        if (out.immediate !== 16'h00AA) $fatal(1, "FAIL [BLT]: immediate wrong");
        if (out.reg_b     !== 4'h5)     $fatal(1, "FAIL [BLT]: reg_b should come from rd field");

        // JMP: absolute immediate target, no writeback
        in = '0;
        in.opcode      = OP_JMP;
        in.operand.imm = 16'h0042;
        #1;
        check_ctrl("JMP",  1,      0,     0,    0,  1,  0,  0);
        if (out.immediate !== 16'h0042) $fatal(1, "FAIL [JMP]: immediate wrong");

        // JAL: like JMP but writes the return address back to Rd
        in = '0;
        in.opcode      = OP_JAL;
        in.operand.imm = 16'h0042;
        #1;
        check_ctrl("JAL",  1,      0,     0,    0,  1,  0,  1);

        // NOP: inert, no writeback
        in = '0;
        in.opcode = OP_NOP;
        #1;
        check_ctrl("NOP",  0,      0,     0,    0,  0,  0,  0);

        // HALT: stop, nothing else asserted
        in = '0;
        in.opcode = OP_HALT;
        #1;
        check_ctrl("HALT", 0,      0,     0,    0,  0,  1,  0);

        $display("instruction_decoder_tb: all checks passed");
        $finish(0);
    end

endmodule

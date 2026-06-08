`timescale 1ns/1ps

module alu_tb;
    import definitions::*;

    word_t    input_a;
    word_t    input_b;
    opcode_t  opcode;
    word_t    result;
    logic     equal;
    logic     less_than;

    alu dut (
        .input_a   (input_a),
        .input_b   (input_b),
        .opcode    (opcode),
        .result    (result),
        .equal     (equal),
        .less_than (less_than)
    );

    task check(
        input opcode_t op,
        input word_t a, b, expected,
        input string label
    );
        opcode  = op;
        input_a = a;
        input_b = b;
        #1;
        if (result !== expected)
            $fatal(1, "FAIL [%s]: a=%0h b=%0h expected=%0h got=%0h",
                   label, a, b, expected, result);
    endtask

    // The equal/less_than flags are combinational on a and b and
    // independent of the opcode, so drive a/b and check them directly.
    task check_flags(
        input word_t a, b,
        input logic  exp_equal, exp_less_than,
        input string label
    );
        input_a = a;
        input_b = b;
        #1;
        if (equal !== exp_equal)
            $fatal(1, "FAIL [%s]: a=%0h b=%0h expected equal=%0b got=%0b",
                   label, a, b, exp_equal, equal);
        if (less_than !== exp_less_than)
            $fatal(1, "FAIL [%s]: a=%0h b=%0h expected less_than=%0b got=%0b",
                   label, a, b, exp_less_than, less_than);
    endtask

    initial begin
        $dumpfile("build/alu.vcd");
        $dumpvars(0, alu_tb);

        // ADD (and its immediate twin share the datapath)
        check(OP_ADD,  16'h0001, 16'h0002, 16'h0003, "ADD basic");
        check(OP_ADD,  16'hFFFF, 16'h0001, 16'h0000, "ADD overflow wrap");
        check(OP_ADD,  16'h0000, 16'h0000, 16'h0000, "ADD zero");
        check(OP_ADDI, 16'h0010, 16'h0022, 16'h0032, "ADDI basic");
        check(OP_ADDI, 16'hFFFF, 16'h0001, 16'h0000, "ADDI overflow wrap");

        // SUB
        check(OP_SUB,  16'h0005, 16'h0003, 16'h0002, "SUB basic");
        check(OP_SUB,  16'h0000, 16'h0001, 16'hFFFF, "SUB underflow wrap");
        check(OP_SUB,  16'h000A, 16'h000A, 16'h0000, "SUB to zero");
        check(OP_SUBI, 16'h0032, 16'h0010, 16'h0022, "SUBI basic");

        // AND
        check(OP_AND,  16'h00FF, 16'h000F, 16'h000F, "AND basic");
        check(OP_AND,  16'hFFFF, 16'h0000, 16'h0000, "AND with zero");
        check(OP_AND,  16'hAAAA, 16'h5555, 16'h0000, "AND no overlap");
        check(OP_ANDI, 16'hF0F0, 16'h0FF0, 16'h00F0, "ANDI basic");

        // OR
        check(OP_OR,   16'h00F0, 16'h000F, 16'h00FF, "OR basic");
        check(OP_OR,   16'h0000, 16'h0000, 16'h0000, "OR zero");
        check(OP_OR,   16'hAAAA, 16'h5555, 16'hFFFF, "OR full");
        check(OP_ORI,  16'hF000, 16'h000F, 16'hF00F, "ORI basic");

        // XOR
        check(OP_XOR,  16'h00FF, 16'h00FF, 16'h0000, "XOR same");
        check(OP_XOR,  16'hAAAA, 16'h5555, 16'hFFFF, "XOR alternating");
        check(OP_XOR,  16'h0000, 16'h0000, 16'h0000, "XOR zero");
        check(OP_XORI, 16'hFF00, 16'h0FF0, 16'hF0F0, "XORI basic");

        // SHL
        check(OP_SHL,  16'h0001, 16'h0001, 16'h0002, "SHL by 1");
        check(OP_SHL,  16'h0001, 16'h0008, 16'h0100, "SHL by 8");
        check(OP_SHL,  16'h0001, 16'h000F, 16'h8000, "SHL to MSB");
        check(OP_SHLI, 16'h0003, 16'h0004, 16'h0030, "SHLI by 4");

        // SHR — logical, no sign extension
        check(OP_SHR,  16'h0100, 16'h0001, 16'h0080, "SHR by 1");
        check(OP_SHR,  16'h8000, 16'h000F, 16'h0001, "SHR from MSB");
        check(OP_SHR,  16'hFFFF, 16'h0001, 16'h7FFF, "SHR logical no sign extend");
        check(OP_SHRI, 16'h00F0, 16'h0004, 16'h000F, "SHRI by 4");

        // unrecognised opcode produces zero
        check(OP_NOP,  16'h1234, 16'h5678, 16'h0000, "NOP/default zero");

        // equal / less_than flags (less_than is unsigned)        eq    lt
        check_flags(16'h0000, 16'h0000, 1'b1, 1'b0, "FLAGS zero equal");
        check_flags(16'h0005, 16'h0005, 1'b1, 1'b0, "FLAGS equal nonzero");
        check_flags(16'hFFFF, 16'hFFFF, 1'b1, 1'b0, "FLAGS equal max");
        check_flags(16'h0003, 16'h0005, 1'b0, 1'b1, "FLAGS a less than b");
        check_flags(16'h0005, 16'h0003, 1'b0, 1'b0, "FLAGS a greater than b");
        check_flags(16'h0000, 16'h0001, 1'b0, 1'b1, "FLAGS zero less than one");
        check_flags(16'hFFFF, 16'h0000, 1'b0, 1'b0, "FLAGS max not less than zero (unsigned)");
        check_flags(16'h0000, 16'hFFFF, 1'b0, 1'b1, "FLAGS zero less than max (unsigned)");

        $display("alu_tb: all checks passed");
        $finish(0);
    end

endmodule

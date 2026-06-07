`timescale 1ns/1ps

module alu_tb;
    import definitions::*;

    word_t    input_a;
    word_t    input_b;
    opcode_t  opcode;
    word_t    result;

    alu dut (
        .input_a (input_a),
        .input_b (input_b),
        .opcode  (opcode),
        .result  (result)
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

    initial begin
        $dumpfile("build/alu.vcd");
        $dumpvars(0, alu_tb);

        // ADD
        check(OP_ADD, 64'h1, 64'h2, 64'h3,                        "ADD basic");
        check(OP_ADD, 64'hFFFFFFFFFFFFFFFF, 64'h1, 64'h0,          "ADD overflow wrap");
        check(OP_ADD, 64'h0, 64'h0, 64'h0,                        "ADD zero");

        // SUB
        check(OP_SUB, 64'h5, 64'h3, 64'h2,                        "SUB basic");
        check(OP_SUB, 64'h0, 64'h1, 64'hFFFFFFFFFFFFFFFF,         "SUB underflow wrap");
        check(OP_SUB, 64'hA, 64'hA, 64'h0,                        "SUB to zero");

        // AND
        check(OP_AND, 64'hFF, 64'h0F, 64'h0F,                     "AND basic");
        check(OP_AND, 64'hFFFFFFFFFFFFFFFF, 64'h0, 64'h0,         "AND with zero");
        check(OP_AND, 64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555, 64'h0, "AND no overlap");

        // OR
        check(OP_OR, 64'hF0, 64'h0F, 64'hFF,                      "OR basic");
        check(OP_OR, 64'h0, 64'h0, 64'h0,                         "OR zero");
        check(OP_OR,  64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555, 64'hFFFFFFFFFFFFFFFF, "OR full");

        // XOR
        check(OP_XOR, 64'hFF, 64'hFF, 64'h0,                      "XOR same");
        check(OP_XOR, 64'hAAAAAAAAAAAAAAAA, 64'h5555555555555555, 64'hFFFFFFFFFFFFFFFF, "XOR alternating");
        check(OP_XOR, 64'h0, 64'h0, 64'h0,                        "XOR zero");

        // SHL
        check(OP_SHL, 64'h1, 64'h1, 64'h2,                        "SHL by 1");
        check(OP_SHL, 64'h1, 64'h8, 64'h100,                      "SHL by 8");
        check(OP_SHL, 64'h1, 64'h3F, 64'h8000000000000000,        "SHL to MSB");

        // SHR
        check(OP_SHR, 64'h100, 64'h1, 64'h80,                     "SHR by 1");
        check(OP_SHR, 64'h8000000000000000, 64'h3F, 64'h1,        "SHR from MSB");
        check(OP_SHR, 64'hFFFFFFFFFFFFFFFF, 64'h1, 64'h7FFFFFFFFFFFFFFF, "SHR logical no sign extend");

        $finish(0);
    end

endmodule
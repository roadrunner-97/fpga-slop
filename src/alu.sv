import definitions::*;

module alu 
#(
    parameter int BIT_WIDTH = 64
)(
    input word_t input_a,
    input word_t input_b,
    input opcode_t opcode,
    output word_t result
);

    always_comb begin
        case (opcode)
            OP_ADD:
            default: output = '0;
        endcase
    end

endmodule
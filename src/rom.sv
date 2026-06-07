module rom #(
    parameter int BIT_WIDTH = 64,
    parameter int WORD_COUNT = 256,
    parameter string FILE = "sim/rom.hex"
)(
    input logic clock,
    input logic [$clog2(WORD_COUNT)-1:0] address,
    output logic [BIT_WIDTH-1:0] data
);

    logic [BIT_WIDTH-1:0] memory [WORD_COUNT];

    initial $readmemh(FILE, memory);

    always_ff @(posedge clock) begin
        data <= memory[address];
    end
endmodule
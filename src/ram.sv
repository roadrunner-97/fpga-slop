module ram #(
    parameter int BIT_WIDTH = 64,
    parameter int WORD_COUNT = 256
)(
    input logic clock,

    input logic [$clog2(WORD_COUNT)-1:0] write_address,
    input logic [BIT_WIDTH-1:0] write_data,
    input logic write_enable,

    input logic [$clog2(WORD_COUNT)-1:0] read_address,
    output logic [BIT_WIDTH-1:0] read_data
);

    logic [BIT_WIDTH-1:0] memory [WORD_COUNT];

    always_ff @(posedge clock) begin
        if(write_enable) begin
            memory[write_address] <= write_data;
        end
        read_data <= memory[read_address];
    end

endmodule
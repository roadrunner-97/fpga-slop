import definitions::*;

module mmap #(
    parameter int RAM_SIZE = 1024,
    parameter string FILE = "src/program.hex"
)(
    input logic clock,

    input addr_t memory_address,
    input word_t memory_write_data,
    output word_t memory_read_data,
    input logic write_enable
);

    word_t memory [RAM_SIZE];
    initial $readmemh(FILE, memory);

    always_ff @(posedge clock) begin
        if (memory_address < RAM_SIZE) begin
            if(write_enable) begin
                memory[memory_address] <= memory_write_data;
            end else begin
                memory_read_data <= memory[memory_address];
            end
        end
    end

endmodule
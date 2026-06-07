module registers #(
    parameter int REG_COUNT = 16,
    parameter int REG_SIZE = 64
)(
    input logic clock,
    
    input logic [$clog2(REG_COUNT)-1:0] read_1_select,
    output logic [REG_SIZE-1:0] read_1_data,

    input logic [$clog2(REG_COUNT)-1:0] read_2_select,
    output logic [REG_SIZE-1:0] read_2_data,

    input logic [$clog2(REG_COUNT)-1:0] write_select,
    input logic [REG_SIZE-1:0] write_data,
    input logic write_enable
);

    //minus 1 because the 0th register doesn't need backing
    logic [REG_SIZE-1:0] registers[REG_COUNT];

    assign read_1_data = !read_1_select ? '0 : registers[read_1_select];
    assign read_2_data = !read_2_select ? '0 : registers[read_2_select];

    always_ff @(posedge clock) begin
        if(write_enable) begin
            if(write_select) begin
                registers[write_select] <= write_data;
            end
        end
    end
endmodule
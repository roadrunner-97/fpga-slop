module clock_synchroniser(
    input logic dest_clock,
    input logic signal_in,
    output wire signal_out
);
    logic history_cycle_1;
    logic history_cycle_2;
    assign signal_out = history_cycle_2;

    always_ff @(posedge dest_clock) begin
        history_cycle_2 <= history_cycle_1;
        history_cycle_1 <= signal_in;
    end
endmodule
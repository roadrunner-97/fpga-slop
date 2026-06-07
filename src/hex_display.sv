module hex_display(
    input logic reset,
    input logic clock,
    input logic[7:0] data,
    input logic[1:0] display_blank,
    output logic[6:0] segments,
    output logic segment_select
);

    //gives us around a 95hz clock which we can just use directly
    //as our digit selector
    clock_divider
        #(.downclock_ratio(4)) digit_selecter(
        // #(.downclock_ratio(524288)) digit_selecter(
            .in_clock(clock),
            .reset(reset),
            .out_clock(segment_select)
        );

    // segments: bit order is gfedcba (bit 0 = a, bit 6 = g)
    // 1 = segment on, 0 = segment off
    always_comb begin
        if(display_blank[segment_select]) begin
            segments = 7'b0000000;
        end else begin
            case (segment_select ? data[3:0] : data[7:4])
                4'h0: segments = 7'b0111111; // 0
                4'h1: segments = 7'b0000110; // 1
                4'h2: segments = 7'b1011011; // 2
                4'h3: segments = 7'b1001111; // 3
                4'h4: segments = 7'b1100110; // 4
                4'h5: segments = 7'b1101101; // 5
                4'h6: segments = 7'b1111101; // 6
                4'h7: segments = 7'b0000111; // 7
                4'h8: segments = 7'b1111111; // 8
                4'h9: segments = 7'b1101111; // 9
                4'ha: segments = 7'b1110111; // A
                4'hb: segments = 7'b1111100; // b
                4'hc: segments = 7'b0111001; // C
                4'hd: segments = 7'b1011110; // d
                4'he: segments = 7'b1111001; // E
                4'hf: segments = 7'b1110001; // F
                default: segments = 7'b0000000; // blank
            endcase
        end
    end
endmodule
`timescale 1ns/1ps

module registers_tb;
    import definitions::*;

    logic      clock;
    reg_addr_t read_1_select;
    word_t     read_1_data;
    reg_addr_t read_2_select;
    word_t     read_2_data;
    reg_addr_t write_select;
    word_t     write_data;
    logic      write_enable;

    registers dut (
        .clock         (clock),
        .read_1_select (read_1_select),
        .read_1_data   (read_1_data),
        .read_2_select (read_2_select),
        .read_2_data   (read_2_data),
        .write_select  (write_select),
        .write_data    (write_data),
        .write_enable  (write_enable)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    // Drive a write for exactly one cycle (synchronous, latches on posedge).
    task write_reg(input reg_addr_t reg_sel, input word_t data);
        @(posedge clock);
        write_select <= reg_sel;
        write_data   <= data;
        write_enable <= 1;
        @(posedge clock);
        write_enable <= 0;
    endtask

    // Reads are combinational: select, settle, compare.
    task check_read_1(input reg_addr_t reg_sel, input word_t expected, input string label);
        read_1_select = reg_sel;
        #1;
        if (read_1_data !== expected)
            $fatal(1, "FAIL [%s]: port1 reg[%0d] expected %0h got %0h",
                   label, reg_sel, expected, read_1_data);
    endtask

    task check_read_2(input reg_addr_t reg_sel, input word_t expected, input string label);
        read_2_select = reg_sel;
        #1;
        if (read_2_data !== expected)
            $fatal(1, "FAIL [%s]: port2 reg[%0d] expected %0h got %0h",
                   label, reg_sel, expected, read_2_data);
    endtask

    integer i;

    initial begin
        $dumpfile("build/registers.vcd");
        $dumpvars(0, registers_tb);

        write_enable  = 0;
        write_select  = '0;
        write_data    = '0;
        read_1_select = '0;
        read_2_select = '0;

        // --- power-on state: every register reads zero -------------------
        for (i = 0; i < REG_COUNT; i++)
            check_read_1(i[3:0], 16'h0000, "init zero");

        // --- basic write/readback ----------------------------------------
        write_reg(4'h1, 16'hAAAA);
        check_read_1(4'h1, 16'hAAAA, "R1 readback");

        // highest register index still addressable
        write_reg(4'hF, 16'h1234);
        check_read_1(4'hF, 16'h1234, "R15 readback");

        // writing R1 must not disturb R15
        check_read_1(4'h1, 16'hAAAA, "R1 untouched by R15 write");

        // --- write_enable gating -----------------------------------------
        // attempt a write with write_enable held low: must be ignored
        @(posedge clock);
        write_select <= 4'h2;
        write_data   <= 16'hBEEF;
        write_enable <= 0;
        @(posedge clock);
        check_read_1(4'h2, 16'h0000, "write_enable=0 ignored");

        // now actually write R2
        write_reg(4'h2, 16'hBEEF);
        check_read_1(4'h2, 16'hBEEF, "R2 readback");

        // --- two independent read ports ----------------------------------
        read_1_select = 4'h1;
        read_2_select = 4'h2;
        #1;
        if (read_1_data !== 16'hAAAA)
            $fatal(1, "FAIL: dual read port1 expected AAAA got %0h", read_1_data);
        if (read_2_data !== 16'hBEEF)
            $fatal(1, "FAIL: dual read port2 expected BEEF got %0h", read_2_data);

        // both ports can address the same register at once
        check_read_1(4'h2, 16'hBEEF, "same reg port1");
        check_read_2(4'h2, 16'hBEEF, "same reg port2");

        // --- overwrite ----------------------------------------------------
        write_reg(4'h1, 16'hCCCC);
        check_read_1(4'h1, 16'hCCCC, "R1 overwrite");

        // --- synchronous timing: write is visible only after the edge -----
        // R3 starts at zero
        check_read_1(4'h3, 16'h0000, "R3 pre-write");
        @(posedge clock);
        write_select <= 4'h3;
        write_data   <= 16'h5555;
        write_enable <= 1;
        read_1_select = 4'h3;
        #1; // mid-cycle, before next posedge: old value must still be read
        if (read_1_data !== 16'h0000)
            $fatal(1, "FAIL [sync]: R3 updated before clock edge, got %0h", read_1_data);
        @(posedge clock);   // latch the write
        write_enable <= 0;
        #1;
        if (read_1_data !== 16'h5555)
            $fatal(1, "FAIL [sync]: R3 not updated after clock edge, got %0h", read_1_data);

        $display("registers_tb: all checks passed");
        $finish(0);
    end

endmodule

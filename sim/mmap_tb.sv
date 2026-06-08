`timescale 1ns/1ps

module mmap_tb;
    import definitions::*;

    logic         clock;
    addr_t        write_address;
    word_t        write_data;
    logic         write_enable;
    addr_t        read_address;
    word_t        read_data;
    addr_t        instruction_pointer;
    instruction_t instruction_data;

    // ROM loaded from a known 4-word fixture: rom[0..3] = AAAA BBBB 1234 5678,
    // mapped to absolute addresses ROM_START + 0..3.
    mmap #(
        .FILE ("sim/mmap.hex")
    ) dut (
        .clock               (clock),
        .write_address       (write_address),
        .write_data          (write_data),
        .write_enable        (write_enable),
        .read_address        (read_address),
        .read_data           (read_data),
        .instruction_pointer (instruction_pointer),
        .instruction_data    (instruction_data)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    task write_mem(input addr_t addr, input word_t data);
        @(posedge clock);
        write_address <= addr;
        write_data    <= data;
        write_enable  <= 1;
        @(posedge clock);
        write_enable  <= 0;
    endtask

    task check_read(input addr_t addr, input word_t expected, input string label);
        read_address = addr;
        #1;
        if (read_data !== expected)
            $fatal(1, "FAIL [%s]: mem[%0d] expected %0h got %0h", label, addr, expected, read_data);
    endtask

    task check_instr(input addr_t ip, input instruction_t expected, input string label);
        instruction_pointer = ip;
        #1;
        if (instruction_data !== expected)
            $fatal(1, "FAIL [%s]: instr@%0d expected %0h got %0h", label, ip, expected, instruction_data);
    endtask

    initial begin
        $dumpfile("build/mmap.vcd");
        $dumpvars(0, mmap_tb);

        write_enable        = 0;
        write_address       = '0;
        write_data          = '0;
        read_address        = '0;
        instruction_pointer = '0;

        // --- ROM reads (last ROM_SIZE words of the address space) ---------
        check_read(ROM_START[15:0],       16'hAAAA, "ROM word 0");
        check_read(ROM_START[15:0] + 16'd1, 16'hBBBB, "ROM word 1");
        check_read(ROM_START[15:0] + 16'd2, 16'h1234, "ROM word 2");
        check_read(ROM_START[15:0] + 16'd3, 16'h5678, "ROM word 3");

        // --- ROM is read-only: writes into ROM range are dropped ----------
        write_mem(ROM_START[15:0], 16'hDEAD);
        check_read(ROM_START[15:0], 16'hAAAA, "ROM write ignored");

        // --- RAM write / readback -----------------------------------------
        // (RAM is not zero-initialised, so establish known values by writing.)
        write_mem(16'd10, 16'hDEAD);
        check_read(16'd10, 16'hDEAD, "RAM readback");

        // a write to a different address leaves addr 10 untouched
        write_mem(16'd20, 16'h3333);
        check_read(16'd20, 16'h3333, "RAM second addr");
        check_read(16'd10, 16'hDEAD, "RAM addr 10 untouched by addr 20 write");

        // write_enable gating: a disabled write must not change addr 20
        @(posedge clock);
        write_address <= 16'd20;
        write_data    <= 16'hBEEF;
        write_enable  <= 0;
        @(posedge clock);
        check_read(16'd20, 16'h3333, "write_enable=0 ignored");

        // --- instruction fetch: two consecutive words form one 32-bit word -
        // From ROM: {rom[0], rom[1]} = AAAA_BBBB
        check_instr(ROM_START[15:0], 32'hAAAABBBB, "instr from ROM");

        // From RAM: write two adjacent words, fetch the pair
        write_mem(16'd30, 16'h1111);
        write_mem(16'd31, 16'h2222);
        check_instr(16'd30, 32'h11112222, "instr from RAM");

        $display("mmap_tb: all checks passed");
        $finish(0);
    end

endmodule

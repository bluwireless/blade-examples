`timescale 1ns/1ps

module testbench();

// -----------------------------------------------------------------------------
// Signals
// -----------------------------------------------------------------------------
reg clk;
reg rst;

reg  [ 31:0] paddr;
reg          psel;
reg          penable;
reg          pwrite;
reg  [ 31:0] pwdata;
reg  [  3:0] pstrb;
wire         pready;
wire [ 31:0] prdata;
wire         pslverr;

// -----------------------------------------------------------------------------
// Clock and Reset Generation
// -----------------------------------------------------------------------------
initial begin : i_clk_gen
    clk = 1'b0;
    repeat (1000) #5 clk = ~clk;
end

initial begin : i_rst_gen
    rst = 1'b1;
    repeat (20) @(posedge clk);
    rst = 1'b0;
end

`include "timer_controller_reg_defs.vh"

initial begin : i_test_seq
    reg rd_error, wr_error;
    reg [31:0] rd_data;

    // Wait for reset to elapse
    @(posedge clk);
    while (rst == 1'b1) @(posedge clk);
    @(posedge clk);

    // Read back the timer's ID register
    $display($stime, ": Reading DUT ID register");
    apb_read(`TIMER_REGISTERS_ID_0_OFFSET, rd_data, rd_error);
    if (rd_error || rd_data != `TIMER_REGISTERS_ID_0_VALUE_RESET) begin
        $display($stime, ": ERROR: DUT ID register returned 0x%x", rd_data);
        $finish;
    end

    // Read back the timer's version register
    $display($stime, ": Reading DUT version register");
    apb_read(`TIMER_REGISTERS_VERSION_0_OFFSET, rd_data, rd_error);
    if (
        rd_error ||
        rd_data != (
            (`TIMER_REGISTERS_VERSION_0_MAJOR_RESET << `TIMER_REGISTERS_VERSION_0_MAJOR_LSB) |
            (`TIMER_REGISTERS_VERSION_0_MINOR_RESET << `TIMER_REGISTERS_VERSION_0_MINOR_LSB)
        )
    ) begin
        $display($stime, ": ERROR: DUT version register returned 0x%x", rd_data);
        $finish;
    end

    // Check the timer is currently inactive
    $display($stime, ": Reading DUT status register");
    apb_read(`TIMER_REGISTERS_STATE_0_OFFSET, rd_data, rd_error);
    if (rd_error || rd_data != `TIMER_REGISTERS_STATE_0_STATE_ENUM_STOPPED) begin
        $display($stime, ": ERROR: DUT status register returned 0x%x", rd_data);
        $finish;
    end

    // Check the timer is currently at zero
    $display($stime, ": Reading DUT current register");
    apb_read(`TIMER_REGISTERS_CURRENT_0_OFFSET, rd_data, rd_error);
    if (rd_error || rd_data != 0) begin
        $display($stime, ": ERROR: DUT current register returned 0x%x", rd_data);
        $finish;
    end

    // Load the timer
    $display($stime, ": Loading the timer with a value");
    apb_write(`TIMER_REGISTERS_LOAD_0_OFFSET, 32'h12345678, 4'hF, wr_error);
    if (wr_error) begin
        $display($stime, ": ERROR: Failed to load timer");
        $finish;
    end
    apb_read(`TIMER_REGISTERS_CURRENT_0_OFFSET, rd_data, rd_error);
    if (rd_error || rd_data != 32'h12345678) begin
        $display($stime, ": ERROR: DUT current register returned 0x%x", rd_data);
        $finish;
    end

    // Start the timer running
    $display($stime, ": Starting the timer");
    apb_write(`TIMER_REGISTERS_CONTROL_0_OFFSET, (1 << `TIMER_REGISTERS_CONTROL_0_START_LSB), 4'hF, wr_error);
    if (wr_error) begin
        $display($stime, ": ERROR: Failed to start timer");
        $finish;
    end
    apb_read(`TIMER_REGISTERS_STATE_0_OFFSET, rd_data, rd_error);
    if (rd_error || rd_data != `TIMER_REGISTERS_STATE_0_STATE_ENUM_RUNNING) begin
        $display($stime, ": ERROR: DUT status register returned 0x%x", rd_data);
        $finish;
    end

    // Stop the timer
    $display($stime, ": Stopping the timer");
    apb_write(`TIMER_REGISTERS_CONTROL_0_OFFSET, (1 << `TIMER_REGISTERS_CONTROL_0_STOP_LSB), 4'hF, wr_error);
    if (wr_error) begin
        $display($stime, ": ERROR: Failed to stop timer");
        $finish;
    end
    apb_read(`TIMER_REGISTERS_STATE_0_OFFSET, rd_data, rd_error);
    if (rd_error || rd_data != `TIMER_REGISTERS_STATE_0_STATE_ENUM_STOPPED) begin
        $display($stime, ": ERROR: DUT status register returned 0x%x", rd_data);
        $finish;
    end
    apb_read(`TIMER_REGISTERS_CURRENT_0_OFFSET, rd_data, rd_error);
    if (rd_error || rd_data < 32'h12345678 || rd_data > 32'h12346000) begin
        $display($stime, ": ERROR: DUT current register returned 0x%x", rd_data);
        $finish;
    end

    // All checks ok
    $display($stime, ": All checks passed");
end

// -----------------------------------------------------------------------------
// DUT Instance
// -----------------------------------------------------------------------------
Timer m_timer (
      .clk                  (clk    )
    , .rst                  (rst    )
    , .m_cfg_in_m_paddr_0   (paddr  )
    , .m_cfg_in_m_psel_0    (psel   )
    , .m_cfg_in_m_penable_0 (penable)
    , .m_cfg_in_m_pwrite_0  (pwrite )
    , .m_cfg_in_m_pwdata_0  (pwdata )
    , .m_cfg_in_m_pstrb_0   (pstrb  )
    , .m_cfg_out_m_pready_0 (pready )
    , .m_cfg_out_m_prdata_0 (prdata )
    , .m_cfg_out_m_pslverr_0(pslverr)
);

// -----------------------------------------------------------------------------
// APB Register Access Functions
// -----------------------------------------------------------------------------

task apb_write;
    input [31:0] address;
    input [31:0] data;
    input  [3:0] strobe;
    output       error;
    begin
        $display("Writing to register 0x%x = 0x%x", address, data);
        @(posedge clk);
        #0;
        // Cycle 1: Setup for write while keeping PENABLE low
        paddr   = address;
        pwdata  = data;
        pwrite  = 1'b1;
        pstrb   = strobe;
        psel    = 1'b1;
        penable = 1'b0;
        @(posedge clk);
        #0;
        // Cycle 2: Raise PENABLE while keeping all other signals constant
        penable = 1'b1;
        @(posedge clk);
        // Cycle 3+: Wait until the write is accepted
        $display("Writing for write to be accepted");
        while (pready == 1'b0) begin
            @(posedge clk);
        end
        // Capture the write response
        error = pslverr;
        // Deassert PSEL and PENABLE to complete transaction
        #0;
        psel    = 1'b0;
        penable = 1'b0;
        @(posedge clk);
    end
endtask

task apb_read;
    input  [31:0] address;
    output [31:0] data;
    output        error;
    begin
        $display("Reading from register 0x%x", address);
        @(posedge clk);
        #0;
        // Cycle 1: Setup for read while keeping PENABLE low
        paddr   = address;
        pwrite  = 1'b0;
        psel    = 1'b1;
        penable = 1'b0;
        @(posedge clk);
        #0;
        // Cycle 2: Raise PENABLE while keeping all other signals constant
        penable = 1'b1;
        @(posedge clk);
        // Cycle 3+: Wait until the write is accepted
        $display("Waiting for read to be accepted");
        while (pready == 1'b0) begin
            @(posedge clk);
        end
        // Capture the read response
        error = pslverr;
        data  = prdata;
        // Deassert PSEL and PENABLE to complete transaction
        #0;
        psel    = 1'b0;
        penable = 1'b0;
        @(posedge clk);
    end
endtask

// -----------------------------------------------------------------------------
// VCD Tracing
// -----------------------------------------------------------------------------

initial begin : i_trace
    $dumpfile("waves.vcd");
    $dumpvars(0, m_timer);
end

endmodule
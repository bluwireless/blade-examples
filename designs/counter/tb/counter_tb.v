// Copyright (C) 2019 Blu Wireless Ltd.
// All Rights Reserved.
//
// This file is part of BLADE.
//
// BLADE is free software: you can redistribute it and/or modify it under the
// terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// BLADE is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along with
// BLADE.  If not, see <https://www.gnu.org/licenses/>.
//

`timescale 1ns/1ns
`include "counter_ctrl_reg_defs.vh"

module counter_tb();

reg clk;
reg rst;

reg          m_cfg_in_m_awvalid_0 = 'd0;
reg  [  2:0] m_cfg_in_m_awprot_0  = 'd0;
reg  [ 31:0] m_cfg_in_m_awaddr_0  = 'd0;
reg          m_cfg_in_m_wvalid_0  = 'd0;
reg  [ 31:0] m_cfg_in_m_wdata_0   = 'd0;
reg  [  3:0] m_cfg_in_m_wstrb_0   = 'd0;
reg          m_cfg_in_m_bready_0  = 'd0;
reg          m_cfg_in_m_arvalid_0 = 'd0;
reg  [ 31:0] m_cfg_in_m_araddr_0  = 'd0;
reg  [  2:0] m_cfg_in_m_arprot_0  = 'd0;
reg          m_cfg_in_m_rready_0  = 'd0;

wire         m_cfg_out_m_awready_0;
wire         m_cfg_out_m_wready_0;
wire [  1:0] m_cfg_out_m_bresp_0;
wire         m_cfg_out_m_bvalid_0;
wire         m_cfg_out_m_arready_0;
wire         m_cfg_out_m_rvalid_0;
wire [  1:0] m_cfg_out_m_rresp_0;
wire [ 31:0] m_cfg_out_m_rdata_0;

reg m_clear_in_m_bit_0 = 'd0;

initial begin : run_sim
    // Setup VCD tracing
    $dumpfile("waves.vcd");
    $dumpvars(0, counter_tb);

    // Trigger initial reset pulse
    $display($stime, ": Starting simulation");
    clk = 1'b0;
    rst = 1'b1;
    #10;
    $display($stime, ": De-asserting reset");
    rst = 1'b0;
    #10;

    #1000;
    $display($stime, ": Finished simulation");
    $finish;
end

initial begin : run_test_seq
    reg [31:0] rdata;
    reg        rerror;
    reg        werror;

    // Wait for reset sequence to elapse
    #30;

    // Try to read the identifier
    $display("Reading the block identifier");
    axi_read(`COUNTER_GENERAL_ID_0_OFFSET, rdata, rerror);
    $display("===============================================================");

    // Try to read the version number
    $display("Reading the block version data");
    axi_read(`COUNTER_GENERAL_VERSION_0_OFFSET, rdata, rerror);
    $display("===============================================================");

    // Write to the scratch register
    $display("Writing to the scratch register");
    axi_write(`COUNTER_GENERAL_SCRATCH_0_OFFSET, 32'hDEADCAFE, 4'hF, werror);
    $display("Reading back the scratch register");
    axi_read(`COUNTER_GENERAL_SCRATCH_0_OFFSET, rdata, rerror);
    if (rdata != 32'hDEADCAFE) begin
        $display("ERROR: Scratch register returned the wrong value!");
        $finish;
    end
    $display("===============================================================");

    // Try invalid transactions
    $display("Trying to read from an invalid address");
    axi_read(32'hFFFFFFF0, rdata, rerror);
    if (rerror != 1'b1) begin
        $display("ERROR: Invalid read did not flag an error");
        $finish;
    end
    $display("===============================================================");

    $display("Trying to write to an invalid address");
    axi_write(32'h12345670, 32'hFEEDB33F, 4'hF, werror);
    if (werror != 1'b1) begin
        $display("ERROR: Invalid write did not flag an error");
        $finish;
    end
    $display("===============================================================");

    $display("Trying to write with a partial strobe");
    axi_write(`COUNTER_GENERAL_SCRATCH_0_OFFSET, 32'hFEEDB33F, 4'h2, werror);
    if (werror != 1'b1) begin
        $display("ERROR: Partial strobe write did not flag an error");
        $finish;
    end
    $display("===============================================================");

    $display("Trying to write with an all-zero strobe");
    axi_write(`COUNTER_GENERAL_SCRATCH_0_OFFSET, 32'hDEADCAFE, 4'hF, werror);
    axi_write(`COUNTER_GENERAL_SCRATCH_0_OFFSET, 32'hFEEDB33F, 4'h0, werror);
    axi_read(`COUNTER_GENERAL_SCRATCH_0_OFFSET, rdata, rerror);
    if (werror == 1'b1) begin
        $display("ERROR: Writing with an all-zero strobe raised an error");
        $finish;
    end
    if (rdata != 32'hDEADCAFE) begin
        $display("ERROR: Writing with an all-zero strobe changed the data");
        $finish;
    end
    $display("===============================================================");

    // Start timer 0

    // Start timer 0
    $display("Starting timer 0");
    axi_write(`CTRL_0_CTRL_0_CONTROL_0_OFFSET, 32'h1, 4'hF, werror);
    #100;
    $display("Reading back from timer 0: STATUS");
    axi_read(`CTRL_0_CTRL_0_STATUS_0_OFFSET, rdata, rerror);
    $display("Reading back from timer 0: CURRENT");
    axi_read(`CTRL_0_CTRL_0_CURRENT_0_OFFSET, rdata, rerror);
    if (rdata == 32'd0) begin
        $display("ERROR: Timer 0 returned a value of 0");
        $finish;
    end
    $display("===============================================================");

    // Load an start timer 3
    $display("Loading timer 3");
    axi_write(`CTRL_3_CTRL_3_LOAD_0_OFFSET, 32'h12345678, 4'hF, werror);
    $display("Starting timer 3");
    axi_write(`CTRL_3_CTRL_3_CONTROL_0_OFFSET, 32'h1, 4'hF, werror);
    #100;
    $display("Reading back from timer 3: STATUS");
    axi_read(`CTRL_3_CTRL_3_STATUS_0_OFFSET, rdata, rerror);
    $display("Reading back from timer 3: CURRENT");
    axi_read(`CTRL_3_CTRL_3_CURRENT_0_OFFSET, rdata, rerror);
    if (rdata <= 32'h12345678) begin
        $display("ERROR: Timer 3 returned a value that was too low");
        $finish;
    end
    $display("===============================================================");

    // Stopping both timers
    $display("Stopping both timers");
    axi_write(`CTRL_0_CTRL_0_CONTROL_0_OFFSET, 32'h2, 4'hF, werror);
    axi_write(`CTRL_3_CTRL_3_CONTROL_0_OFFSET, 32'h2, 4'hF, werror);
    #10;

    // Reset timer state within the register block to zero
    $display("Resetting all timers to zero");
    #0;
    m_clear_in_m_bit_0 = 1'b1;
    #10;
    #0;
    m_clear_in_m_bit_0 = 1'b0;
    #10;
    $display("===============================================================");

    // Read back registers again
    $display("Reading back from timer 0: CURRENT");
    axi_read(`CTRL_0_CTRL_0_CURRENT_0_OFFSET, rdata, rerror);
    if (rdata != 32'd0) begin
        $display("ERROR: Timer 0 returned a non-zero value");
        $finish;
    end
    $display("Reading back from timer 3: CURRENT");
    axi_read(`CTRL_3_CTRL_3_CURRENT_0_OFFSET, rdata, rerror);
    if (rdata != 32'd0) begin
        $display("ERROR: Timer 0 returned a non-zero value");
        $finish;
    end
    $display("===============================================================");

end

task axi_write;
    input [31:0] address;
    input [31:0] data;
    input  [3:0] strobe;
    output       error;
    begin
        $display("Writing to register 0x%x = 0x%x", address, data);
        @(posedge clk);
        #0;
        m_cfg_in_m_awaddr_0  = address;
        m_cfg_in_m_awvalid_0 = 1'b1;
        m_cfg_in_m_wdata_0   = data;
        m_cfg_in_m_wstrb_0   = strobe;
        m_cfg_in_m_wvalid_0  = 1'b1;
        m_cfg_in_m_bready_0  = 1'b0;
        @(posedge clk);
        // Wait until the write is accepted
        $display("Writing for write to be accepted");
        while (m_cfg_in_m_awvalid_0 == 1'b1 || m_cfg_in_m_wvalid_0 == 1'b1) begin
            #0;
            if (m_cfg_out_m_awready_0 == 1'b1) m_cfg_in_m_awvalid_0 = 1'b0;
            if (m_cfg_out_m_wready_0  == 1'b1) m_cfg_in_m_wvalid_0  = 1'b0;
            @(posedge clk);
        end
        #0;
        // Capture the write response
        $display("Waiting for write response");
        m_cfg_in_m_bready_0 = 1'b1;
        while (m_cfg_out_m_bvalid_0 == 1'b0) @(negedge clk);
        if (m_cfg_out_m_bresp_0 == 2'd0) begin
            $display("Write to register 0x%x successful", address);
            error = 1'b0;
        end else begin
            $display("Write to register 0x%x failed", address);
            error = 1'b1;
        end
    end
endtask

task axi_read;
    input  [31:0] address;
    output [31:0] data;
    output        error;
    begin
        $display("Reading from register 0x%x", address);
        @(posedge clk);
        #0;
        m_cfg_in_m_araddr_0  = address;
        m_cfg_in_m_arvalid_0 = 1'b1;
        m_cfg_in_m_rready_0  = 1'b1; // Always accept response
        // Wait until the read is accepted
        $display("Waiting for read to be accepted");
        @(posedge clk);
        while (m_cfg_out_m_arready_0 == 1'b0) @(posedge clk);
        #0;
        m_cfg_in_m_arvalid_0 = 1'b0;
        // Wait for read response
        while (m_cfg_out_m_rvalid_0 == 1'b0) @(posedge clk);
        if (m_cfg_out_m_rresp_0 == 2'd0) begin
            data  = m_cfg_out_m_rdata_0;
            error = 1'b0;
            $display("Read from register 0x%x successful = 0x%x", address, data);
        end else begin
            data  = 32'd0;
            error = 1'b1;
            $display("Read from register 0x%x failed", address);
        end
    end
endtask

always begin
    #1 clk = !clk;
end

Counter my_counter (
    .clk(clk),
    .rst(rst),
    // Reset all timers
    .m_clear_in_m_bit_0   (m_clear_in_m_bit_0   ),
    // AXI4-Lite Configuration Port
    .m_cfg_in_m_awvalid_0 (m_cfg_in_m_awvalid_0 ),
    .m_cfg_in_m_awprot_0  (m_cfg_in_m_awprot_0  ),
    .m_cfg_in_m_awaddr_0  (m_cfg_in_m_awaddr_0  ),
    .m_cfg_in_m_wvalid_0  (m_cfg_in_m_wvalid_0  ),
    .m_cfg_in_m_wdata_0   (m_cfg_in_m_wdata_0   ),
    .m_cfg_in_m_wstrb_0   (m_cfg_in_m_wstrb_0   ),
    .m_cfg_in_m_bready_0  (m_cfg_in_m_bready_0  ),
    .m_cfg_in_m_arvalid_0 (m_cfg_in_m_arvalid_0 ),
    .m_cfg_in_m_araddr_0  (m_cfg_in_m_araddr_0  ),
    .m_cfg_in_m_arprot_0  (m_cfg_in_m_arprot_0  ),
    .m_cfg_in_m_rready_0  (m_cfg_in_m_rready_0  ),
    .m_cfg_out_m_awready_0(m_cfg_out_m_awready_0),
    .m_cfg_out_m_wready_0 (m_cfg_out_m_wready_0 ),
    .m_cfg_out_m_bresp_0  (m_cfg_out_m_bresp_0  ),
    .m_cfg_out_m_bvalid_0 (m_cfg_out_m_bvalid_0 ),
    .m_cfg_out_m_arready_0(m_cfg_out_m_arready_0),
    .m_cfg_out_m_rvalid_0 (m_cfg_out_m_rvalid_0 ),
    .m_cfg_out_m_rresp_0  (m_cfg_out_m_rresp_0  ),
    .m_cfg_out_m_rdata_0  (m_cfg_out_m_rdata_0  ),
    // Interrupt Lines
    .m_irq_out_m_bit_0(m_irq_out_m_bit_0),
    .m_irq_out_m_bit_1(m_irq_out_m_bit_1),
    .m_irq_out_m_bit_2(m_irq_out_m_bit_2),
    .m_irq_out_m_bit_3(m_irq_out_m_bit_3),
    .m_irq_out_m_bit_4(m_irq_out_m_bit_4),
    .m_irq_out_m_bit_5(m_irq_out_m_bit_5),
    .m_irq_out_m_bit_6(m_irq_out_m_bit_6),
    .m_irq_out_m_bit_7(m_irq_out_m_bit_7)
);

endmodule
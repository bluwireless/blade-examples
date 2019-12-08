<%doc>
Copyright (C) 2019 Blu Wireless Ltd.
All Rights Reserved.

This file is part of BLADE.

BLADE is free software: you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

BLADE is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
BLADE.  If not, see <https://www.gnu.org/licenses/>.

--------------------------------------------------------------------------------

Template    :   verilog_axi4.v
Description :   Base modules for AXI4 register blocks
</%doc>\
<%namespace name="filters" module="helpers.filters"/>\
<%namespace name="blademod" module="helpers.mod_common"/>\
<%namespace name="regmod" file="regmod.v"/>\

`include "axi4_defines_defs.vh"

<%def name="mod(block, cfg_port)">\
<%regmod:mod block="${block}">\
// =============================================================================
// AXI4-Lite Register Decode
// =============================================================================

// Enumeration of AXI4-Lite response codes
`define AXI4L_RESP_OKAY   2'd0
`define AXI4L_RESP_EXOKAY 2'd1
`define AXI4L_RESP_SLVERR 2'd2
`define AXI4L_RESP_DECERR 2'd3

reg [`AXI4_ADDR_WIDTH-1:0]  axi4l_awaddr;
reg                         axi4l_awvalid;
reg [`AXI4_WDATA_WIDTH-1:0] axi4l_wdata;
reg                         axi4l_wvalid;
reg [`AXI4_WSTRB_WIDTH-1:0] axi4l_write_strobe;

reg         m_cfg_out_m_awready_0;
reg         m_cfg_out_m_wready_0;
reg [  1:0] m_cfg_out_m_bresp_0;
reg         m_cfg_out_m_bvalid_0;
reg         m_cfg_out_m_arready_0;
reg         m_cfg_out_m_rvalid_0;
reg [  1:0] m_cfg_out_m_rresp_0;
reg [ 31:0] m_cfg_out_m_rdata_0;

always @(posedge ${clock} or posedge ${reset}) begin : axi4_lite_decode
    reg [`AXI4_ADDR_WIDTH-1:0]  curr_awaddr;
    reg                         curr_awvalid;
    reg [`AXI4_WDATA_WIDTH-1:0] curr_wdata;
    reg                         curr_wvalid;
    reg [`AXI4_WSTRB_WIDTH-1:0] curr_write_strobe;
    reg [1:0]                   curr_write_error;
    reg [1:0]                   curr_read_error;
    reg [`AXI4_RDATA_WIDTH-1:0] curr_read_data;
    if (${reset} == 1'b1) begin
        // Reset the registers
        register_reset();

        // Initialise the AXI4-Lite port response
        ${ports[cfg_port].arready} <= 1'b1;
        ${ports[cfg_port].awready} <= 1'b1;
        ${ports[cfg_port].wready}  <= 1'b1;
        ${ports[cfg_port].bresp}   <= `AXI4L_RESP_OKAY;
        ${ports[cfg_port].bvalid}  <= 1'b0;
        ${ports[cfg_port].rvalid}  <= 1'b0;
        ${ports[cfg_port].rdata}   <= `AXI4_RDATA_WIDTH'd0;
        ${ports[cfg_port].rresp}   <= `AXI4L_RESP_OKAY;

        // Reset state
        axi4l_awaddr  <= `AXI4_ADDR_WIDTH'd0;
        axi4l_awvalid <= 1'b0;
        axi4l_wdata   <= `AXI4_WDATA_WIDTH'd0;
        axi4l_wvalid  <= 1'b0;
    end else begin
        // If the write response was accepted, clear the signals
        if (${ports[cfg_port].bvalid} == 1'b1 && ${ports[cfg_port].bready} == 1'b1) begin
            ${ports[cfg_port].bvalid}  <= 1'b0;
            ${ports[cfg_port].bresp}   <= `AXI4L_RESP_OKAY;
            ${ports[cfg_port].awready} <= 1'b1;
            ${ports[cfg_port].wready}  <= 1'b1;
        end

        // If the read response was accepted, clear the signals
        if (${ports[cfg_port].rvalid} == 1'b1 && ${ports[cfg_port].rready} == 1'b1) begin
            ${ports[cfg_port].rvalid}  <= 1'b0;
            ${ports[cfg_port].rresp}   <= `AXI4L_RESP_OKAY;
            ${ports[cfg_port].arready} <= 1'b1;
        end

        // Clear read and write strobes
        clear_bus_strobes();

        // ---------------------------------------------------------------------
        // Write Requests
        // ---------------------------------------------------------------------

        // Handle incoming write address phase
        if (${ports[cfg_port].awvalid} == 1'b1 && ${ports[cfg_port].awready} && 1'b1) begin
            curr_awaddr  = ${ports[cfg_port].awaddr};
            curr_awvalid = 1'b1;
        end else begin
            curr_awaddr  = axi4l_awaddr;
            curr_awvalid = axi4l_awvalid;
        end

        // Handle incoming write data phase
        if (${ports[cfg_port].wvalid} == 1'b1 && ${ports[cfg_port].wready} == 1'b1) begin
            curr_wdata        = ${ports[cfg_port].wdata};
            curr_write_strobe = ${ports[cfg_port].wstrb};
            curr_wvalid       = 1'b1;
        end else begin
            curr_wdata        = axi4l_wdata;
            curr_write_strobe = axi4l_write_strobe;
            curr_wvalid       = axi4l_wvalid;
        end

        // Handle complete write requests
        if (curr_awvalid && curr_wvalid) begin
            curr_awvalid     = 1'b0;
            curr_wvalid      = 1'b0;
            curr_write_error = 1'b0;

            // Only accept transactions where all byte lanes active
            if (curr_write_strobe == {`AXI4_WSTRB_WIDTH{1'b1}}) begin
                curr_write_error = register_write(curr_awaddr, curr_wdata);
            // If only some write strobes are set, raise an error
            // NOTE: Allow an all-zero write strobe as this can be emitted by a NoC
            end else if (curr_write_strobe != `AXI4_WSTRB_WIDTH'd0) begin
                $display($time, ": ERROR: Register block does not accept partial writes");
                curr_write_error = `AXI4L_RESP_DECERR;
            end

            // Setup response
            ${ports[cfg_port].bvalid} <= 1'b1;
            ${ports[cfg_port].bresp}  <= curr_write_error; // Has the same decoding
        end

        // Store the state of the write handling variables
        axi4l_awaddr       <= curr_awaddr;
        axi4l_awvalid      <= curr_awvalid;
        axi4l_wdata        <= curr_wdata;
        axi4l_wvalid       <= curr_wvalid;
        axi4l_write_strobe <= curr_write_strobe;

        // ---------------------------------------------------------------------
        // Read Requests
        // ---------------------------------------------------------------------

        if (${ports[cfg_port].arvalid} == 1'b1 && ${ports[cfg_port].arready} == 1'b1) begin
            // NOTE: This only allows a request to be accepted every other cycle
            //       but it makes response handling much simpler
            ${ports[cfg_port].arready} <= 1'b0;

            // Perform the read
            {curr_read_data, curr_read_error} = register_read(${ports[cfg_port].araddr});

            // Setup response
            ${ports[cfg_port].rvalid} <= 1'b1;
            ${ports[cfg_port].rdata}  <= curr_read_data;
            ${ports[cfg_port].rresp}  <= curr_read_error; // Has the same decoding
        end

    end
end

## Implementation
${caller.body()}
</%regmod:mod>\
</%def>\

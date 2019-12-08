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

module CounterCore (
    input             clk,
    input             rst,
    input             start,
    input             stop,
    input      [31:0] load_val,
    input             load_en,
    output reg        active,
    output reg [31:0] counter
);

always @(posedge clk or posedge rst) begin
    if (rst == 1'b1) begin
        active  <= 1'b0;
        counter <= 32'd0;
    end else begin
        // Activate the counter when the start signal is strobed
        if (start) begin
            active <= 1'b1;
        // Halt the counter when the stop signal is strobed
        end else if (stop) begin
            active <= 1'b0;
        // When the load enable signal is strobed, adopt the load value
        end else if (load_en) begin
            counter <= load_val;
        // Otherwise, when active, just count normally
        end else if (active) begin
            counter <= (counter + 32'd1);
        end
    end
end

endmodule
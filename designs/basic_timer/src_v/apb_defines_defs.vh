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
`define APB_PADDR_WIDTH 32 // Width of the address component
`define APB_PDATA_WIDTH 32 // Width of read and write data components
`define APB_PSEL_WIDTH  1  // Width of the slave selection signal
`define APB_PSTRB_WIDTH 4  // Width of the byte strobe signal for write data
`define APB_PPROT_WIDTH 3  // Width of the protection signal

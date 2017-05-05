// ***************************************************************************
// ***************************************************************************
// Copyright 2014 - 2017 (c) Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsabilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

`timescale 1ns/100ps

module axi_ad9625 #(

  parameter ID = 0) (

  // jesd interface
  // rx_clk is (line-rate/40)

  input                   rx_clk,
  input       [  3:0]     rx_sof,
  input                   rx_valid,
  input       [255:0]     rx_data,
  output                  rx_ready,

  // dma interface

  output                  adc_clk,
  output                  adc_rst,
  output                  adc_valid,
  output                  adc_enable,
  output      [255:0]     adc_data,
  input                   adc_dovf,
  input                   adc_dunf,
  output      [ 15:0]     adc_sref,
  input       [  3:0]     adc_raddr_in,
  output      [  3:0]     adc_raddr_out,

  // axi interface

  input                   s_axi_aclk,
  input                   s_axi_aresetn,
  input                   s_axi_awvalid,
  input       [ 15:0]     s_axi_awaddr,
  output                  s_axi_awready,
  input                   s_axi_wvalid,
  input       [ 31:0]     s_axi_wdata,
  input       [  3:0]     s_axi_wstrb,
  output                  s_axi_wready,
  output                  s_axi_bvalid,
  output      [  1:0]     s_axi_bresp,
  input                   s_axi_bready,
  input                   s_axi_arvalid,
  input       [ 15:0]     s_axi_araddr,
  output                  s_axi_arready,
  output                  s_axi_rvalid,
  output      [  1:0]     s_axi_rresp,
  output      [ 31:0]     s_axi_rdata,
  input                   s_axi_rready,
  input       [  2:0]     s_axi_awprot,
  input       [  2:0]     s_axi_arprot);

  // internal registers

  reg         [ 31:0]     up_rdata = 'd0;
  reg                     up_rack = 'd0;
  reg                     up_wack = 'd0;

  // internal signals

  wire                    up_rstn;
  wire                    up_clk;
  wire        [191:0]     adc_data_s;
  wire                    adc_or_s;
  wire                    adc_status_s;
  wire                    adc_sref_sync_s;
  wire                    up_adc_pn_err_s;
  wire                    up_adc_pn_oos_s;
  wire                    up_adc_or_s;
  wire        [ 31:0]     up_rdata_s[0:1];
  wire                    up_rack_s[0:1];
  wire                    up_wack_s[0:1];
  wire                    up_wreq_s;
  wire        [ 13:0]     up_waddr_s;
  wire        [ 31:0]     up_wdata_s;
  wire                    up_rreq_s;
  wire        [ 13:0]     up_raddr_s;

  // signal name changes

  assign up_clk = s_axi_aclk;
  assign up_rstn = s_axi_aresetn;

  // defaults

  assign rx_ready = 1'b1;

  // processor read interface

  always @(negedge up_rstn or posedge up_clk) begin
    if (up_rstn == 0) begin
      up_rdata <= 'd0;
      up_rack <= 'd0;
      up_wack <= 'd0;
    end else begin
      up_rdata <= up_rdata_s[0] | up_rdata_s[1];
      up_rack <= up_rack_s[0] | up_rack_s[1] ;
      up_wack <= up_wack_s[0] | up_wack_s[1] ;
    end
  end

  // main (device interface)

  assign adc_valid = 1'b1;

  axi_ad9625_if #(
    .ID (ID))
  i_if (
    .rx_clk (rx_clk),
    .rx_sof (rx_sof),
    .rx_data (rx_data),
    .adc_clk (adc_clk),
    .adc_rst (adc_rst),
    .adc_data (adc_data_s),
    .adc_or (adc_or_s),
    .adc_status (adc_status_s),
    .adc_sref (adc_sref),
    .adc_sref_sync (adc_sref_sync_s),
    .adc_raddr_in (adc_raddr_in),
    .adc_raddr_out (adc_raddr_out));

  // channel

  axi_ad9625_channel i_channel (
    .adc_clk (adc_clk),
    .adc_rst (adc_rst),
    .adc_data (adc_data_s),
    .adc_or (adc_or_s),
    .adc_dfmt_data (adc_data),
    .adc_enable (adc_enable),
    .up_adc_pn_err (up_adc_pn_err_s),
    .up_adc_pn_oos (up_adc_pn_oos_s),
    .up_adc_or (up_adc_or_s),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s[0]),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s[0]),
    .up_rack (up_rack_s[0]));

  // common processor control

  up_adc_common #(.ID(ID)) i_up_adc_common (
    .mmcm_rst (),
    .adc_clk (adc_clk),
    .adc_rst (adc_rst),
    .adc_r1_mode (),
    .adc_ddr_edgesel (),
    .adc_pin_mode (),
    .adc_status (adc_status_s),
    .adc_sync_status (1'd0),
    .adc_status_ovf (adc_dovf),
    .adc_status_unf (adc_dunf),
    .adc_clk_ratio (32'd16),
    .adc_start_code (),
    .adc_sync (),
    .adc_sref_sync (adc_sref_sync_s),
    .up_adc_ce (),
    .up_status_pn_err (up_adc_pn_err_s),
    .up_status_pn_oos (up_adc_pn_oos_s),
    .up_status_or (up_adc_or_s),
    .up_drp_sel (),
    .up_drp_wr (),
    .up_drp_addr (),
    .up_drp_wdata (),
    .up_drp_rdata (32'd0),
    .up_drp_ready (1'd0),
    .up_drp_locked (1'd1),
    .up_usr_chanmax_out (),
    .up_usr_chanmax_in (8'd1),
    .up_adc_gpio_in (32'd0),
    .up_adc_gpio_out (),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s[1]),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s[1]),
    .up_rack (up_rack_s[1]));

  // up bus interface

  up_axi i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata),
    .up_rack (up_rack));

endmodule

// ***************************************************************************
// ***************************************************************************


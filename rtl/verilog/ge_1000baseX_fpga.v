//////////////////////////////////////////////////////////////////////
////                                                              ////
////  File name "ge_1000baseX_core.v"                             ////
////                                                              ////
////  This file is part of the :                                  ////
////                                                              ////
//// "1000BASE-X IEEE 802.3-2008 Clause 36 - PCS project"         ////
////                                                              ////
////  http://opencores.org/project,1000base-x                     ////
////                                                              ////
////  Author(s):                                                  ////
////      - D.W.Pegler Cambridge Broadband Networks Ltd           ////
////                                                              ////
////      { peglerd@gmail.com, dwp@cambridgebroadand.com }        ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2009 AUTHORS. All rights reserved.             ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// This module is based on the coding method described in       ////
//// IEEE Std 802.3-2008 Clause 36 "Physical Coding Sublayer(PCS) ////
//// and Physical Medium Attachment (PMA) sublayer, type          ////
//// 1000BASE-X"; see :                                           ////
////                                                              ////
//// http://standards.ieee.org/about/get/802/802.3.html           ////
//// and                                                          ////
//// doc/802.3-2008_section3.pdf, Clause/Section 36.              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`include "timescale.v"

module ge_1000baseX_fpga
(
  // --- Resets ---
  input             reset_pin,
 
 // --- Clocks --
 input             ckpin,
 
 // --- GE 125MHz reference clock
 input             GE_125MHz_ref_ckpin,
 
 // --- FO TBI 125MHz Rx clk
 input             fo_tbi_rx_ckpin,

 // --- CU GMII 125MHz Rx and Tx clk
 input             cu_gmii_rx_ckpin,
 input             cu_gmii_tx_ckpin,
 
 // --- Fibre-Optic (fo) GE TBI Interface
 input       [9:0] fo_tbi_rxd,
 output      [9:0] fo_tbi_txd,

`ifdef MODEL_TECH
 // -- Route GMII from IEEE 802.3 1000BaseLX out - for testing
 output      [7:0] fo_gmii_rxd,
 output            fo_gmii_rx_dv, 
 output            fo_gmii_rx_er, 
 output            fo_gmii_col, 
 output            fo_gmii_cs,
 
 input       [7:0] fo_gmii_txd,
 input             fo_gmii_tx_en, 
 input             fo_gmii_tx_er,
`endif //  `ifdef MODEL_TECH
 
 //  --- Fibre-Optic (fo) ctrl signals
 output            fo_sync_en,
 output            fo_loop_en,
 output            fo_prbs_en,
 
 input             fo_signal_detect,
 input             fo_sync,
 
 // ---  Copper GE GMII Interface ---
 input       [7:0] cu_gmii_rxd,
 input             cu_gmii_rx_dv,
 input             cu_gmii_rx_er,
 
 output      [7:0] cu_gmii_txd,
 output            cu_gmii_tx_en,
 output            cu_gmii_tx_er,

 input             cu_gmii_cs,
 input             cu_gmii_col,
 
 // --- MDIO interface
 output            mdio,
 input             mdc_in,
 output            mdc_out
 );
  
   //----------------------------------------------------------------------------
   // GE 125MHz reference clock
   //----------------------------------------------------------------------------
   
   IBUFG GE_125MHz_ref_ckpin_bufi(.I(GE_125MHz_ref_ckpin), .O(GE_125MHz_ref_ckpin_buf));

   wire GE_125MHz_ref_fbclk, GE_125MHz_ref_ck_locked;
   
   DCM #(
    .CLKIN_PERIOD(8.0),         // Specify period of input clock in ns
    .CLKFX_MULTIPLY(5),
    .CLKFX_DIVIDE(8)            
   ) GE_125MHz_ref_ck_DCMi(
    //.CLK0(GE_125MHz_ref_fbclk),
    .CLK0(GE_125MHz_ref_ck_unbuf),			   
    .CLK180(),
    .CLK270(),
    .CLK2X(),
    .CLK2X180(),
    .CLK90(),
    //.CLKDV(GE_125MHz_ref_ck_unbuf),
    .CLKDV(),
    .CLKFX(core_ck_unbuf),
    .CLKFX180(),
    .LOCKED(GE_125MHz_ref_ck_locked),
    .PSDONE(),
    .STATUS(),
    //.CLKFB(GE_125MHz_ref_fbclk),
    .CLKFB(GE_125MHz_ref_ck),			   
    .CLKIN(GE_125MHz_ref_ckpin_buf),
    .DSSEN(1'b0),
    .PSCLK(1'b0),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .RST(reset_pin)
  );

   //----------------------------------------------------------------------------
   // 125MHz refence clock
   //----------------------------------------------------------------------------
`ifdef MODEL_TECH  
    BUFG GE_125MHz_ref_ck_bufi(.I(GE_125MHz_ref_ck_unbuf), .O(GE_125MHz_ref_ck));
`else
    BUFGMUX GE_125MHz_ref_ck_bufi(.I1(GE_125MHz_ref_ck_unbuf), .O(GE_125MHz_ref_ck), .S(1'b1));
`endif
     
   //----------------------------------------------------------------------------
   // 25MHz Copper (CU) MII TX clock - TX clk pin when CU interface in MII mode
   //----------------------------------------------------------------------------
   IBUFG cu_mii_tx_ckpin_bufi(.I(cu_mii_tx_ckpin), .O(cu_mii_tx_ckpin_buf));

`ifdef MODEL_TECH  
   BUFG cu_gmii_tx_ck_bufi(.I(GE_125MHz_ref_ck_unbuf),.O(cu_gmii_tx_ck));
`else   
   BUFGMUX cu_gmii_tx_ck_bufi(.I0(GE_125MHz_ref_ck_unbuf), .I1(cu_mii_tx_ckpin_buf), .O(cu_gmii_tx_ck), .S(cu_125MHz_tx_clk_en));
`endif
   
   //----------------------------------------------------------------------------
   // Fibre-Optic (FO) TBI RX clock.
   //----------------------------------------------------------------------------
   
   IBUFG fo_tbi_rx_ckpin_bufi(.I(fo_tbi_rx_ckpin), .O(fo_tbi_rx_ckpin_buf));
   
   wire      cpu_mii_ref_ck_unbuf;
   
   DCM #(
    .CLKIN_PERIOD(8.0),  
    .CLKFX_DIVIDE(5)              
   ) fo_tbi_rx_ck_DCMi(
    //.CLK0(fo_tbi_rx_fbclk),
    .CLK0(fo_tbi_rx_ck_unbuf),	       
    .CLK180(),
    .CLK270(),
    .CLK2X(),
    .CLK2X180(),
    .CLK90(),
    //.CLKDV(fo_tbi_rx_ck_unbuf),
    .CLKDV(),		       
    .CLKFX(cpu_mii_ref_ck_unbuf),
    .CLKFX180(),
    .LOCKED(fo_tbi_rx_ck_locked),
    .PSDONE(),
    .STATUS(),
    //.CLKFB(fo_tbi_rx_fbclk),
    .CLKFB(fo_tbi_rx_ck),		       
    .CLKIN(fo_tbi_rx_ckpin_buf),
    .DSSEN(1'b0),
    .PSCLK(1'b0),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .RST(reset_pin)
  );	
   
   // FO TBI 125MHz rx clock
   BUFG fo_tbi_rx_ck_bufi( .I(fo_tbi_rx_ck_unbuf), .O(fo_tbi_rx_ck));		   
	   
   //----------------------------------------------------------------------------
   // 125/25MHz Copper(CU) GMII RX clock
   //----------------------------------------------------------------------------
   
   IBUFG cu_gmii_rx_ckpin_bufi(.I(cu_gmii_rx_ckpin), .O(cu_gmii_rx_ckpin_buf));
   
   wire cu_gmii_rx_ck_locked;
   
   DCM #(
    .CLKIN_PERIOD(8.0)       
   ) cu_gmii_rx_ck_DCMi(
    //.CLK0(cu_gmii_rx_fbclk),
    .CLK0(cu_gmii_rx_ck_unbuf),			
    .CLK180(),
    .CLK270(),
    .CLK2X(),
    .CLK2X180(),
    .CLK90(),
    //.CLKDV(cu_gmii_rx_ck_unbuf),
    .CLKDV(), 			
    .CLKFX(),
    .CLKFX180(),
    .LOCKED(cu_gmii_rx_ck_locked),
    .PSDONE(),
    .STATUS(),
    //.CLKFB(cu_gmii_rx_fbclk),
    .CLKFB(cu_gmii_rx_ck),		
    .CLKIN(cu_gmii_rx_ckpin_buf),
    .DSSEN(1'b0),
    .PSCLK(1'b0),
    .PSEN(1'b0),
    .PSINCDEC(1'b0),
    .RST(reset_pin)
  );
   
   BUFG cu_gmii_rx_ck_bufi(.I(cu_gmii_rx_ck_unbuf), .O(cu_gmii_rx_ck));
   
   //----------------------------------------------------------------------------
   // 78MHz BUFG core clock
   //----------------------------------------------------------------------------
   
   BUFG core_ck_bufi(.I(core_ck_unbuf), .O(core_ck));
   
   //----------------------------------------------------------------------------
   // Reset Cleaners
   //----------------------------------------------------------------------------
   
   wire  cu_gmii_ctrl_reset, fo_gmii_ctrl_reset;
   
   wire  main_clocks_locked =  GE_125MHz_ref_ck_locked;
   
   wire  reset_in              = reset_pin | ~main_clocks_locked;
  
   wire  cu_gmii_txck_reset_in = reset_pin | ~main_clocks_locked | cu_gmii_ctrl_reset;
   wire  cu_gmii_rxck_reset_in = reset_pin | ~main_clocks_locked | cu_gmii_ctrl_reset;
   wire  fo_tbi_rxck_reset_in  = reset_pin | ~main_clocks_locked | fo_gmii_ctrl_reset;
   wire  GE_125MHz_reset_in    = reset_pin | ~main_clocks_locked | fo_gmii_ctrl_reset;
   
   wire  reset, cu_gmii_tx_reset, cu_gmii_rx_reset, GE_125MHz_reset,fo_tbi_rx_reset;

   reset_cleaner             reset_cleaneri(.ck(core_ck),          .reset_in(reset_in),              .reset_out(reset));    
   reset_cleaner   GE_125MHz_reset_cleaneri(.ck(GE_125MHz_ref_ck), .reset_in(GE_125MHz_reset_in),    .reset_out(GE_125MHz_reset));
   reset_cleaner   fo_tbi_rx_reset_cleaneri(.ck(fo_tbi_rx_ck),     .reset_in(fo_tbi_rxck_reset_in),  .reset_out(fo_tbi_rx_reset));
   reset_cleaner  cu_gmii_tx_reset_cleaneri(.ck(cu_gmii_tx_ck),    .reset_in(cu_gmii_txck_reset_in), .reset_out(cu_gmii_tx_reset));
   reset_cleaner  cu_gmii_rx_reset_cleaneri(.ck(cu_gmii_rx_ck),    .reset_in(cu_gmii_rxck_reset_in), .reset_out(cu_gmii_rx_reset));
      
   //----------------------------------------------------------------------------
   // Core
   //----------------------------------------------------------------------------
   
   genie_ge_x_test_core genie_ge_x_test_corei(

      // --- Clocks --			 
      .core_ck(core_ck),					  
  
       // --- Resets ---		   
      .reset(reset),  
      	  
      //		  
      .fo_tbi_tx_reset(GE_125MHz_reset),
      .fo_tbi_rx_reset(fo_tbi_rx_reset),
      .cu_gmii_tx_reset(cu_gmii_tx_reset),
      .cu_gmii_rx_reset(cu_gmii_rx_reset),
								  		  
       // --- FO TBI 125MHz Rx and Tx clks						  
      .fo_tbi_rx_ck(fo_tbi_rx_ck),
      .fo_tbi_tx_ck(GE_125MHz_ref_ck),
							  
      // --- CU GMII 125MHz Rx and Tx clks
      .cu_gmii_rx_ck(cu_gmii_rx_ck),  							   
      .cu_gmii_tx_ck(cu_gmii_tx_ck),
							  		  
      // --- TLK1221 transmit TBI bus ---		     
      .fo_tbi_rxd(fo_tbi_rxd),
      .fo_tbi_txd(fo_tbi_txd),

`ifdef MODEL_TECH
      // --- IEEE 802.3 1000BaseLX Receive GMII bus --- 
      .fo_gmii_rxd(fo_gmii_rxd),
      .fo_gmii_rx_dv(fo_gmii_rx_dv),
      .fo_gmii_rx_er(fo_gmii_rx_er),
      .fo_gmii_col(fo_gmii_col),
      .fo_gmii_cs(fo_gmii_cs),
	
       // --- Transmit GMII bus ---		     
      .fo_gmii_tx_en(fo_gmii_tx_en),
      .fo_gmii_tx_er(fo_gmii_tx_er),
      .fo_gmii_txd(fo_gmii_txd),
`endif			  
      //  --- Fibre-Optic (FO) ctrl signals
      .fo_sync_en(fo_sync_en),
      .fo_loop_en(fo_loop_en),
      .fo_prbs_en(fo_prbs_en),			 
      .fo_signal_detect(fo_signal_detect),
      .fo_sync(fo_sync),

      // ---  Copper GE GMII Interface ---
      .cu_gmii_rxd(cu_gmii_rxd),
      .cu_gmii_rx_dv(cu_gmii_rx_dv),
      .cu_gmii_rx_er(cu_gmii_rx_er),
      // 
      .cu_gmii_txd(cu_gmii_txd),
      .cu_gmii_tx_en(cu_gmii_tx_en),
      .cu_gmii_tx_er(cu_gmii_tx_er),
      // 
      .cu_gmii_cs(cu_gmii_cs),
      .cu_gmii_col(cu_gmii_col),
					      
      // --- MDIO interface ---
      .mdio(mdio),
      .mdc_in(mdc_in),		    
      .mdc_out(mdc_out)
					   
   );
    
endmodule



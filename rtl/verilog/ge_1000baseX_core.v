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

module ge_1000baseX_core
(
 // --- Clocks --
 input             core_ck,

 // --- Resets ---
 input             reset,

 //
 input             fo_tbi_tx_reset,
 input             fo_tbi_rx_reset,
 input             cu_gmii_tx_reset,
 input             cu_gmii_rx_reset,
 
 // --- FO TBI 125MHz Rx and Tx clks	
 input             fo_tbi_rx_ck,
 input             fo_tbi_tx_ck,
 
 // --- CU GMII 125MHz Rx and Tx clks
 input             cu_gmii_rx_ck,
 input             cu_gmii_tx_ck,

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
`endif
 
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
 //
 output      [7:0] cu_gmii_txd,
 output            cu_gmii_tx_en,
 output            cu_gmii_tx_er,
 //
 input             cu_gmii_cs,
 input             cu_gmii_col,
 
 // --- MDIO interface
 output            mdio,
 input             mdc_in,
 output            mdc_out
 );

   assign   fo_sync_en = 1'b0;
   assign   fo_loop_en = 1'b0;
   assign   fo_prbs_en = 1'b0;
   
   //-------------------------------------------------------------------------------
   // --- IEEE 802.3-2005 1000baseLX PCS interface (gmii <-> tbi)
   //-------------------------------------------------------------------------------

   wire [3:0] 	   status_leds;
 	   
   wire 	   repeater_mode;

   // Not in repeater mode!
   assign 	   repeater_mode = 1'b0;
   
   ge_1000baseX ge_1000baseXi(
    
      // --- Clocks ---
      .ck(core_ck),  .rx_ck(fo_tbi_rx_ck), .tx_ck(fo_tbi_tx_ck),
		   
      // --- reset --- 
      .reset(reset), .tx_reset(fo_tbi_tx_reset), .rx_reset(fo_tbi_rx_reset),		       
			  
      // --- Startup interface. ---
      .startup_enable(~reset),

       // --- Signal detect from FO transceiver 
      .signal_detect(fo_signal_detect),
			
      // --- Receive GMII bus --- 
      .gmii_rxd(fo_gmii_rxd),
      .gmii_rx_dv(fo_gmii_rx_dv),
      .gmii_rx_er(fo_gmii_rx_er),
      //		      
      .gmii_col(fo_gmii_col),
      .gmii_cs(fo_gmii_cs),
		    
       // --- Transmit GMII bus ---		     
      .gmii_tx_en(fo_gmii_tx_en),
      .gmii_tx_er(fo_gmii_tx_er),
      .gmii_txd(fo_gmii_txd),
  
      // --- RLK1221 receive TBI bus ---
      .tbi_rxd(fo_tbi_rxd),
		      
      // --- TLK1221 ransmit TBI bus ---		     
      .tbi_txd(fo_tbi_txd),
      
      // --- Mode of operation ---
      .repeater_mode(repeater_mode),
		      
      // --- MDIO interface ---	      
      .mdio(mdio),
      .mdc_in(mdc_in),		    
      .mdc_out(mdc_out),
		      
      // --- Data interface. ---
      .data_cs(data_cs_ethernet),
      .data_wr_rq(data_wr_rq),
      .data_rd_rq(data_rd_rq),
      .data_addr(data_addr),
      .data_bus_wr(data_bus_wr),
      .data_bus_rd(wor_data_bus_rd_0),
      .data_grant(wor_data_grant_0),
		     
      // --- Status LEDS. ---
      .status_leds(status_leds),

      // --- Debugging ---
      .debug()      	      
   );		    
   
endmodule


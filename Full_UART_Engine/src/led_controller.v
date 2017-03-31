`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Author:         Victor Espinoza
// Email:          victor.alfonso94@gmail.com
// Project #:      Project 2 - PicoBlaze Integration with Interrupts 
// Course:         CECS 460
// Create Date:    20:10:05 10/12/2013
//
// Module Name:    led_controller 
// File Name:      led_controller.v
//
// Description:    This is an LED controller based on Professor Allison's CECS
//                 301 class. The purpose of this module is to choose which 
//                 anodes on the 7-segment displays are asserted and when they 
//                 should be asserted. This is determined according to the LED 
//                 clock within the Display Controller module.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module led_controller(clk, rstb, a3, a2, a1, a0, seg_sel);

   //Input and Output Declarations
   input            clk, rstb;
   output reg       a3, a2, a1, a0;
   output reg [1:0] seg_sel;   

   //************************************************************************
   // state register and next_state variables
   //************************************************************************
   reg      [1:0] present_state;
   reg      [1:0] next_state;

   //************************************************************************
   // Next State Combinational Logic
   //(next state values can change anytime but will only be "clocked" below)
   //************************************************************************

   always @(present_state)
      case (present_state) 
         //next state combinations for present states
         2'b00 : next_state = 2'b01;
         2'b01 : next_state = 2'b10;
         2'b10 : next_state = 2'b11;
         2'b11 : next_state = 2'b00;
         
         //next state combinations for all other present states
         default: next_state = 2'b00;      
      endcase   

   //************************************************************************
   // State Register Logic (Sequential Logic)
   //************************************************************************

   always @(posedge clk, negedge rstb)
      if (!rstb)
         //Got a rstb, so set state register to all 0's
         present_state <= 2'b00;         
      else
         //Got a posedge, so update state register with next state
         present_state <= next_state;
               
   //************************************************************************
   // Output Combinational Logic and Segment Select Logic
   //(output values can change only when a present state changes)
   //************************************************************************
      
   always @(present_state)
      case (present_state)         
         //output combinations for present states
         2'b00  : {seg_sel, a3, a2, a1, a0} = 6'b00_1110;   //a[0] seg_sel asserted
         2'b01  : {seg_sel, a3, a2, a1, a0} = 6'b01_1101;   //a[1] seg_sel asserted
         2'b10  : {seg_sel, a3, a2, a1, a0} = 6'b10_1011;   //a[2] seg_sel asserted
         2'b11  : {seg_sel, a3, a2, a1, a0} = 6'b11_0111;   //a[3] asserted
         
         //output combinations for all other present states
         default : {seg_sel, a3, a2, a1, a0} = 6'b00_1110;
      endcase


endmodule

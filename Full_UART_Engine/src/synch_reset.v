`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Author:        Victor Espinoza
// Email:         victor.alfonso94@gmail.com
// Project #:     Project 3 - Transmit Engine plus PicoBlaze
// Course:        CECS 460
// Create Date:   19:08:36 04/09/2015 
//
// Module Name:   synch_reset
// File Name:     synch_reset.v 
//
// Description:   This is the Syncronization Circuit module that has an 
//                asynchronous input and a synchronous output. The purpose of this 
//                module is to take the asyncronous reset input and make it low-
//                leveled active when pressed. This means that the reset value 
//                should be zero whenever the button is activated. When the reset 
//                button is pressed on the Nexys 2 board, its value comes into
//                this module as the rstb input. However, in this module there are 
//                flip-flops that are designed with asynchronous (low active) 
//                resets. Also in this module, there is a synchronous reset that  
//                will neglect the asynchronous rstb input and force the 2 
//                flip-flops to zero at the posedge of the clock. This is how the 
//                rstb input turns from an input of 1 to an output of 0 and 
//                vice-versa. In other words, this is how the asynchronous rstb
//                input turns into the synchronous rstsb output.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module synch_reset(clk, rstb, rstsb);
   
   //Input and Output declarations
   input       clk, rstb;
   output wire rstsb;

   //local variables / flip-flop declarations
   reg         rst_reg_delay;
   reg         rst_synch_out;

   assign rstsb = rst_synch_out;
   always@(posedge clk, posedge rstb)begin
      if(rstb)begin //force rstb to be low when activated instead of being high
         rst_reg_delay <= 1'b0;
         rst_synch_out <= 1'b0;
      end
      else begin //Synchronize the output
         rst_reg_delay <= 1'b1;
         rst_synch_out <= rst_reg_delay; 
      end
   end
endmodule

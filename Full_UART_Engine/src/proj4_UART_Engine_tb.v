`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Author:        Victor Espinoza
// Email:         victor.alfonso94@gmail.com
// Project #:     Project 3 - Transmit Engine plus PicoBlaze
// Course:        CECS 460
//
// Create Date:    17:46:56 11/14/2015 
//
// Module Name:   proj4_UART_Engine_tb  
// File Name:     proj4_UART_Engine_tb .v
//
// Description:   This test bench makes sure that my UART engine is able to
//                both recieve and transmit data.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module proj4_UART_Engine_tb;

   //Inputs
   reg clk;
   reg rstb;
   reg bit8;
   reg parity_en;
   reg odd_n_even;
   reg [3:0] baud_val;
   reg Rx;
   wire Tx;
   
   //Instantiate the Unit Under Test (UUT)
   //proj4_UART_Engine(clk, rstb, bit8, parity_en, odd_n_even, baud_val, Rx, tx);
   proj4_UART_Engine uut(
      .clk(clk), 
      .rstb(rstb), 
      .bit8(bit8),
      .parity_en(parity_en),
      .odd_n_even(odd_n_even),
      .baud_val(baud_val),
      .Rx(Rx),
      .tx(Tx),
   );
   //vary the clk signal every 10ns to mimick a 
   //period of 20ns (which is the period of our boards)
   always #10 clk = ~clk;
   //always #20 tx_Write = ~tx_Write;
   

   initial begin

      //Initialize Inputs
      clk = 0;
      rstb = 1; //low active reset
      //8O1 (300 Baud) Transmitting 0x65 = 110_0101
      bit8 = 1; //8 bits of data
      parity_en = 1; //parity enabled
      odd_n_even = 1; //odd parity
      baud_val = 4'h4; //baud = 9600
      Rx = 1'b1; //data to be transmitted   
      
      //Wait 100 ns for global reset to finish
      #100  @(posedge clk) rstb = 0; // have reset become unactive.
      #20 @(posedge clk)
      Rx = 1'b0; //data to be transmitted
      //Receive 0x5D
      
      //d0
      wait (uut.receive.btu == 1);
      wait (uut.receive.btu == 0);
      Rx = 1'b1;
      
      //d1
      wait (uut.receive.btu == 1);
      wait (uut.receive.btu == 0);
      Rx = 1'b0;

      //d2
      wait (uut.receive.btu == 1);
      wait (uut.receive.btu == 0);
      Rx = 1'b1;

      //d3
      wait (uut.receive.btu == 1);
      wait (uut.receive.btu == 0);
      Rx = 1'b1;
      
      //d4
      wait (uut.receive.btu == 1);
      wait (uut.receive.btu == 0);
      Rx = 1'b1;

      //d5
      wait (uut.receive.btu == 1);
      wait (uut.receive.btu == 0);
      Rx = 1'b0;
      
      //d6
      wait (uut.receive.btu == 1);
      wait (uut.receive.btu == 0);
      Rx = 1'b1;

      //d7
      wait (uut.receive.btu == 1);
      wait (uut.receive.btu == 0);
      Rx = 1'b0;
      

      //parity/stop
      wait (uut.receive.btu == 1);
      wait (uut.receive.btu == 0);
      Rx = 1'b1;


      wait (uut.receive.btu == 1);  //wait until byte is done being received.
      wait (uut.receive.btu == 6);
      $stop;      
   
   end



endmodule

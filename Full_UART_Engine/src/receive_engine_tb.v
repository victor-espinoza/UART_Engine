`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Author:        Victor Espinoza
// Email:         victor.alfonso94@gmail.com
// Project #:     Project 4 - Full UART Engine
// Course:        CECS 460
// 
// Create Date:   18:56:08 11/13/2015 
//  
// Module Name:   receive_engine_tb 
// File Name:     receive_engine_tb.v
// 
// Description:   I verified that my Receive Engine was working correctly by using 
//                a simple test bench. In the Receive Engine test bench, I 
//                initialized my UART format to transfer at a baud rate of 300 
//                and have a format of 8O1. I then made sure that the receive 
//                engine correctly received the data of 0xAE. Since I extensively 
//                tested the Transmit Engine to make sure that I was able to 
//                successfully run at all of the different baud-rates and data 
//                formats (7N1, 7O1, 7E1, 8N1, 8O1m 8E1) for my project, I was 
//                convinced that the Receive Engine would yield the same results 
//                because the baud rate and format logic is almost identical 
//                between both engines. This is why I came to the conclusion that 
//                I did not need to test every possible baud-rate and data format 
//                combination for my Receive Engine. After I received the start bit 
//                from the receive data, I then waited for the bit time up to occur 
//                before I changed the Rx input value to the Receive Engine. This 
//                was so that I wasn't disturbing the Receive Engine while it was 
//                waiting for a bit time to begin collecting data. After a bit was 
//                shifted into the shift register, I then changed the Rx input in a 
//                way that would yield me receiving a byte of 0xAE. After all of the 
//                data bits were shifted into the shift register, I then loaded 
//                this data into a flop and sent the data to the PicoBlaze. As 
//                expected, the end result was that 0xAE was loaded into the flop 
//                and outputted to the PicoBlaze decoder (which selects what data 
//                is going to the In_Port of the PicoBlaze) I also made sure that 
//                my Parity Error logic was correctly detecting a parity error by 
//                assigning the wrong parity to my byte of data. The 8O1 format 
//                should have an odd parity value of 0, but I gave the parity value 
//                a value of 1. As expected, The PARITY_ERR status flag was set high 
//                and sent to the PicoBlaze decoder. I also made sure that all of my 
//                signals were changing correctly and that there were no surprises 
//                between the different states in my Receive Engine State Machine. 
//                This sums up what I did to verify the correctness of my Receive 
//                Engine. Note that I did not make a top level test bench for this 
//                project due to the sheer amount of transmits that I have to make 
//                for displaying the banner (it is a lot of characters!). Also, it 
//                is difficult to simulate the PicoBlaze receiving data because 
//                there is no terminal to display data through. This sums up how I 
//                verified the correctness of my Receive Engine.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module receive_engine_tb;

   //Inputs
   reg        clk;
   reg        rstb;
   reg        bit8;
   reg        parity_en;
   reg        odd_n_even;
   reg [3:0]  baud_val;
   reg [1:0]  READ;   
   reg        Rx;
   wire [2:0] status;
   
   //Outputs
   wire [7:0] data;
   //Instantiate the Unit Under Test (UUT)
   //receive_engine(clk, rstb, bit8, parity_en, odd_n_even, baud_val, READ, 
   // Rx, status, data);
   receive_engine uut(
      .clk(clk), 
      .rstb(rstb), 
      .bit8(bit8),
      .parity_en(parity_en),
      .odd_n_even(odd_n_even),
      .baud_val(baud_val),
      .READ(READ),
      .Rx(Rx),
      .status(status),
      .data(data)
   );
   //vary the clk signal every 10ns to mimick a 
   //period of 20ns (which is the period of our boards)
   always #10 clk = ~clk;
   //always #20 tx_Write = ~tx_Write;
   

   initial begin

      //Initialize Inputs
      clk        = 0;
      rstb       = 0; //low active reset
      //8O1 (460800 Baud) Transmitting 0xAE = 1010_1110
      bit8       = 1; //8 bits of data
      parity_en  = 1; //parity enabled
      odd_n_even = 1; //odd parity
      baud_val   = 4'hA; //baud = 460800
      Rx         = 1'b0; //data to be transmitted
      READ       = 2'b00;
      
      
      
      //Wait 100 ns for global reset to finish
      #100  @(posedge clk) rstb = 1; // have reset become unactive.
      READ = 2'b10;
      #20 @(posedge clk)
      READ = 2'b00;
      
      //Receive 0xAE
      
      wait (uut.btu == 1);
      wait (uut.btu == 0);
      Rx = 1'b1;
      
      //d0
      wait (uut.btu == 1);
      wait (uut.btu == 0);
      Rx = 1'b0;

      //d1
      wait (uut.btu == 1);
      wait (uut.btu == 0);
      Rx = 1'b1;

      //d2
      wait (uut.btu == 1);
      wait (uut.btu == 0);
      Rx = 1'b1;
      
      //d3
      wait (uut.btu == 1);
      wait (uut.btu == 0);
      Rx = 1'b1;

      //d4
      wait (uut.btu == 1);
      wait (uut.btu == 0);
      Rx = 1'b0;
      
      //d5
      wait (uut.btu == 1);
      wait (uut.btu == 0);
      Rx = 1'b1;

      //d6
      wait (uut.btu == 1);
      wait (uut.btu == 0);
      Rx = 1'b0;
      

      //d7 / Parity / Stop
      wait (uut.btu == 1);
      wait (uut.btu == 0);
      Rx = 1'b1;


      wait (uut.done == 1);  //wait until byte is done being received.
      #200
      $stop;      
   
   end



endmodule

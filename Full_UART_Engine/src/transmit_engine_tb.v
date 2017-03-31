`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Author:        Victor Espinoza
// Email:         victor.alfonso94@gmail.com
// Project #:     Project 3 - Transmit Engine plus PicoBlaze
// Course:        CECS 460
// 
// Create Date:   14:41:51 10/15/2015 
//  
// Module Name:   transmit_engine_tb 
// File Name:     transmit_engine_tb.v
//  
// Description:   For this test bench I first initialized my Transmit Engine
//                to be running at a 300 Baud Rate and at a 7N1 format. I then
//                made sure that the correct value was getting loaded into my
//                shift register and outputted the result of this comparison
//                to the console. I then waited until the Done bit was set high,
//                which signified that I was finished transmitting the 12 bits 
//                of data. I then loaded up the next byte of data, changed the
//                baud rate to 1200, kept the 7N1 format, and repeated the 
//                process mentioned above. I made sure to transmit different 
//                combinations of data and to test out every format and 
//                baud rate available in my design. Once I verified that all
//                of the data was being loaded and shifted out correctly at 
//                each of the different baud rates and data formats, I then
//                concluded that my transmit engine was working correctly.
//     
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module transmit_engine_tb;

   //Inputs
   reg       clk;
   reg       rstb;
   reg       bit8;
   reg       parity_en;
   reg       odd_n_even;
   reg [3:0] baud_val;
   reg       tx_Write;
   reg [7:0] in_data;

   //Outputs
   wire      tx; //transferLimitReached;
   wire      TxRdy;
   //Instantiate the Unit Under Test (UUT)
   //module transmit_engine(clk, rstb, bit8, parity_en, odd_n_even, baud_val, txWrite, 
   //inData, tx, TxRdy);
   transmit_engine uut(
      .clk(clk), 
      .rstb(rstb), 
      .bit8(bit8),
      .parity_en(parity_en),
      .odd_n_even(odd_n_even),
      .baud_val(baud_val),
      .txWrite(tx_Write),
      .inData(in_data),
      .tx(tx),
      .TxRdy(TxRdy)
   );
   //vary the clk signal every 10ns to mimick a 
   //period of 20ns (which is the period of our boards)
   always #10 clk = ~clk;
   //always #20 tx_Write = ~tx_Write;

   initial begin

      //Initialize Inputs
      clk        = 0;
      rstb       = 0; //low active reset
      //7N1 (300 Baud) Transmitting 0x65 = 110_0101
      bit8       = 0; //7 bits of data
      parity_en  = 0; //parity disabled
      odd_n_even = 0; //no parity
      baud_val   = 4'h0; //baud = 300
      in_data    = 8'h65; //data to be transmitted
      
      
      //Wait 100 ns for global reset to finish
      #100  @(posedge clk) rstb = 1; // have reset become unactive.
      tx_Write = 1; //assert tx_Write after reset.
      #20 @(posedge clk) tx_Write = 0;
      
      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'hf95) //7N1 tx -> 0x65 = f95
            $display("Incorrect Data! Expected: 0xf95 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0xf95 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end
      

      wait (uut.Done == 1); //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.
      wait (uut.Done == 0);  //wait until byte is done being transmitted.
      
      //7N1 (1200 Baud) Transmitting 0x54 = 101_0100
      bit8       = 0; //7 bits of data
      parity_en  = 0; //parity disabled
      odd_n_even = 1; //no parity   
      baud_val   = 4'h1; //baud = 1200
      in_data    = 8'h54; //data to be transmitted
      tx_Write   = 1; //assert tx_Write       
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write
      
      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'hf51) //7N1 tx -> 0x54 = f51
            $display("Incorrect Data! Expected: 0xf51 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0xf51 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end
      
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.
      wait (uut.Done == 0);  //wait until byte is done being transmitted.
            
      //7E1 (2400 Baud) Transmitting 0x72 = 111_0010
      bit8       = 0; //7 bits of data
      parity_en  = 1; //parity enabled
      odd_n_even = 0; //even parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'h2; //baud = 2400
      in_data    = 8'h72; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write
      
      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'hdc9) //7E1 tx -> 0x72 = dc9
            $display("Incorrect Data! Expected: 0xdc9 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0xdc9 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end
               
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.
      wait (uut.Done == 0);  //wait until byte is done being transmitted.
      
      
      //7O1 (4800 Baud) Transmitting 0x4F = 100_1111
      bit8       = 0; //7 bits of data
      parity_en  = 0; //parity disabled
      odd_n_even = 1; //no parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'h3; //baud = 4800
      in_data    = 8'h4F; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write
      
            
      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'hf3d) //7O1 tx -> 0x4f = f3d
            $display("Incorrect Data! Expected: 0xf3d , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0xf3d , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end
      
            
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.
      wait (uut.Done == 0);                           
                             
      //8N1 (9600 Baud) Transmitting 0x4F = 0100_1111   
      bit8       = 1; //8 bits of data
      parity_en  = 0; //parity enabled
      odd_n_even = 0; //no parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'h4; //baud = 9600
      in_data    = 8'h4F; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write
      
      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'hd3d) //8N1 tx -> 0x4f = d3d
            $display("Incorrect Data! Expected: 0xd3d , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0xd3d , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end         
         
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.
      wait (uut.Done == 0);  
                             
      //8N1 (19200 Baud) Transmitting 0xAE = 1010_1110   
      bit8       = 1; //8 bits of data
      parity_en  = 0; //parity enabled
      odd_n_even = 1; //no parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'h5; //baud = 19200
      in_data    = 8'hAE; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write
      
      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'heb9) //8N1 tx -> 0xAE = eb9
            $display("Incorrect Data! Expected: 0xeb9 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0xeb9 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end
      
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.      
      wait (uut.Done == 0); 
      
      //8E1 (38400 Baud) Transmitting 0xBD = 1011_1101   
      bit8       = 1; //8 bits of data
      parity_en  = 1; //parity enabled
      odd_n_even = 0; //even parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'h6; //baud = 38400
      in_data    = 8'hBD; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write

      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'haf5) //8E1 tx -> 0xBD = af5
            $display("Incorrect Data! Expected: 0xaf5 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0xaf5 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end
                  
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.   
      wait (uut.Done == 0);                               
      
      //8O1 (57600 Baud) Transmitting 0x4F = 0000_1000   
      bit8       = 1; //8 bits of data
      parity_en  = 1; //parity enabled
      odd_n_even = 1; //odd parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'h7; //baud = 57600
      in_data    = 8'h08; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write      
   
      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'h821) //8O1 tx -> 0x08 = 821
            $display("Incorrect Data! Expected: 0x821 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0x821 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end   
            
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.   
      wait (uut.Done == 0);                            
      
      //8O1 (115200 Baud) Transmitting 0x4F = 0100_1111   
      bit8       = 1; //8 bits of data
      parity_en  = 1; //parity enabled
      odd_n_even = 1; //odd parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'h8; //baud = 115200
      in_data    = 8'h4F; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write      
      
      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'h93d) //8O1 tx -> 0x4F = 93d
            $display("Incorrect Data! Expected: 0x93d , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0x93d , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end      
   
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.   
      wait (uut.Done == 0);                              
      
      //8O1 (230400 Baud) Transmitting 0x00 = 0000_0000   
      bit8       = 1; //8 bits of data
      parity_en  = 1; //parity enabled
      odd_n_even = 1; //odd parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'h9; //baud = 230400
      in_data    = 8'h00; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write      

      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'hc01) //8O1 tx -> 0x00 = c01
            $display("Incorrect Data! Expected: 0xc01 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0xc01 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end      
            
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.
      wait (uut.Done == 0);  
      
      //8O1 (460800 Baud) Transmitting 0x55 = 0101_0101   
      bit8       = 1; //8 bits of data
      parity_en  = 1; //parity enabled
      odd_n_even = 1; //odd parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'hA; //baud = 460800
      in_data    = 8'h55; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write            
      

      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'hd55) //8O1 tx -> 0x55 = d55
            $display("Incorrect Data! Expected: 0xd55 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0xd55 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end
      
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.
      wait (uut.Done == 0);  
      
      //8O1 (921600 Baud) Transmitting 0x4F = 0010_0000   
      bit8       = 1; //8 bits of data
      parity_en  = 1; //parity enabled
      odd_n_even = 1; //odd parity   
      tx_Write   = 1; //assert tx_Write 
      baud_val   = 4'hB; //baud = 921600
      in_data    = 8'h20; //data to be transmitted
      #20 @(posedge clk) tx_Write = 0; //deassert tx_Write      
      
      @(posedge clk) if(uut.write1Delay == 1)begin
         #20; //wait for next clock cycle (when data is updated)
         if (uut.sreg_data != 12'h881) //8O1 tx -> 0x20 = 881
            $display("Incorrect Data! Expected: 0x881 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
         else
            $display("Correct Data! Expected: 0x881 , Actual: 0x%h", 
             uut.sreg_data[11:0]);
      end
      
      wait (uut.Done == 1);  //wait until byte is done being transmitted.
      wait (uut.TxRdy == 1); //wait until transmit engine is ready
                             //to receive another byte.
      wait (uut.Done == 0);  
      $stop;      
   
   end

endmodule 
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Author:        Victor Espinoza
// Email:         victor.alfonso94@gmail.com
// Project #:     Project 3 - Transmit Engine plus PicoBlaze
// Course:        CECS 460
// 
// Create Date:   15:34:08 10/18/2015 
//  
// Module Name:   proj3_TransmitEngine_tb 
// File Name:     proj3_TransmitEngine_tb.v
//  
// Description:   This test bench is really simple. I simply initialize my clk
//                and rstb inputs, set my baud rate to 9600, create a format
//                of 8O1 for transmitting data through the UART, and then 
//                deactivate my low active rstb input. I then checked the 
//                waveform data to make sure that my program was continually 
//                transmitting the "CSULB CECS 460<CR><LF>" sequence. The 
//                PicoBlaze was in charge of providing the right character 
//                data at the appropriate intervals (when the TxRdy bit of the
//                status registe was set high). This was done using assembly 
//                code which is provided in my report. I verified that the 
//                correct data was being sent out by checking the waveform
//                data and making sure that the proper data was being loaded
//                into the shift register and that the bits were shifting out
//                in the correct order. Once I verified this, I then concluded
//                that my program worked exactly how I intended it to.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module proj3_TransmitEngine_tb;

   //Inputs
	reg clk;
	reg rstb;
	reg bit8;
	reg parity_en;
	reg odd_n_even;
	reg [3:0] baud_val;

	//Outputs
	wire         tx;
	//Instantiate the Unit Under Test (UUT)
	//module proj3_TransmitEngine(clk, rstb, bit8, parity_en, odd_n_even, baud_val, 
	//tx);
	proj3_TransmitEngine uut(
		.clk(clk), 
		.rstb(rstb), 
		.bit8(bit8),
		.parity_en(parity_en),
		.odd_n_even(odd_n_even),
		.baud_val(baud_val),
		.tx(tx)
	);
	//vary the clk signal every 10ns to mimick a 
	//period of 20ns (which is the period of our boards)
	always #10 clk = ~clk;
	//always #20 tx_Write = ~tx_Write;

   initial begin

		//Initialize Inputs
		clk = 0;
		rstb = 1; //low active reset
		bit8 = 1; //8 bits of data
		parity_en = 1; //parity enabled
		odd_n_even = 1; //odd parity
		baud_val = 4'h4; //baud = 9600	
		
		//Wait 100 ns for global reset to finish
		#100  @(posedge clk) rstb = 0; // have reset become unactive.
		
	end
	

endmodule

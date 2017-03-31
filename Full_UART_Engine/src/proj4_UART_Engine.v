`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Author:        Victor Espinoza
// Email:         victor.alfonso94@gmail.com
// Project #:     Project 3 - Transmit Engine plus PicoBlaze
// Course:        CECS 460
//
// Create Date:   23:38:35 11/09/2015 
//  
// Module Name:   proj4_UART_Engine 
// File Name:     proj4_UART_Engine.v
//  
// Description:   This top_level module basically ties in all of the other  
//                modules that I made and connects them together. It takes the 
//                primary inputs of clk, rstb, bit8, parity_en, odd_n_even,
//                baud_val[3:0], and Rx. This project has one output called tx. 
//                This tx output goes to P9, which is a port that connects to 
//                the RS-232 serial connector that connects to a UART terminal 
//                on a computer via a serial cable. The clk input comes from the 
//                clock on the Nexys 2 board, while the rstb input is a push
//                button. The bit8, parity_en, odd_n_even, and baud_val[3:0] 
//                inputs are all switches on the Nexys 2 board. The rstb input
//                is synchronized and distributed to all of the other modules in
//                this project. This synchronized rstb value (rstbs) is also
//                negated and then used as the reset input to the PicoBlaze
//                processor. Inside of the PicoBlaze, I display my banner and
//                my newline prompt and I then wait for a byte of data to be
//                received by checking the RxRdy bit in the status register.
//                Once the RxRdy bit is set, I then know that the Receive Engine
//                has received a byte and is ready to receive another byte. I
//                then load the received byte into a flop and send that data to
//                a decoder (which uses read[0] to determine whether I am 
//                reading in the status of the UART engine or reading in the
//                received data. I then output the received byte of data to the 
//                PicoBlaze. On the second clk cycle of the output instruction,
//                I decode the Write_Strobe value by using the Write_Strobe and
//                the Port_Id port of the picoblaze. I then put these values
//                into my write[255:0] register (because there are 2^8 registers
//                that can be written to the PicoBlaze: 00 - FF). For my design,
//                I output my values to the Port_ID of 01, so I needed to pass
//                my write[1] value into my transmit engine to let it know
//                that it should load in the appropriate data bits (Out_Port)
//                into the shift register. I use the same logic flow for the 
//                Read_Strobe (I have a read[255:0] register and I use read[0]
//                and read[1] in my design. read[0] is used to read in the 
//                status flags to the PicoBlaze while read[1] is used to 
//                notify the Receive Engine that it is going to receive the 
//                data coming from the terminal window. The baud_val[3:0] bits 
//                determine the baud rate at which the Program is going to be 
//                receiving and transmitting characters. The bit8, parity_en and 
//                odd_n_even inputs determine the format of the data bits being 
//                received and transmitted (7N1, 7E1, 7O1, 8N1, 8O1, and 8E1). 
//                All of these inputs (minus the Rx input) go into my Transmit 
//                Engine where I update my shift register and baud
//                counter accordingly. These inputs (including the Rx input)
//                also go into my Receive Engine where I shift in the data one
//                bit at a time. Once I establish the desired baud rate
//                and data format, I then open a terminal window under the same
//                baud rate and data format and then I am ready to start 
//                receiving/transmitting characters to the UART terminal. In 
//                the PicoBlaze I display my banner and then I transmit my
//                prompt (*>). I then wait to receive a character from the
//                terminal, where I then process the data and either 
//                issue a newline command and a new prompt (carriage return
//                or newline characters), display my hometown (asterisk
//                character), delete the previous character (delete/
//                backspace character), or echo the character. I also added my
//                Seven-Segment display to this lab so that I can display
//                my character counter value on the upper 2 Seven-Segment 
//                displays and the data being received by the Receive Engine
//                in the lower 2 Seven-Segment displays. This helped me out 
//                tremendously in verifying that I was receiving the proper 
//                character data.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module proj4_UART_Engine(clk, rstb, bit8, parity_en, odd_n_even, baud_val, Rx, tx,
 a, b, c, d, e, f, g, a3, a2, a1, a0, LED);

   //Input and Output Declarations
   input        clk, rstb, bit8, parity_en, odd_n_even, Rx;
   input [3:0]  baud_val;
   
   output       tx, a, b, c, d, e, f, g, a3, a2, a1, a0;
   wire         tx, a, b, c, d, e, f, g, a3, a2, a1, a0;
   output [7:0] LED;
   wire   [7:0] LED;


   //Local Declarations
   //wire rstsb, TxSet, TxRst, Done, sSet, sRst, ld, btu, shift;
   wire         rstsb, tx_out, TxRdy;
   wire [7:0]   in_port, RxData;
   wire [2:0]   RxStatus;
   wire         interrupt, read_strobe, write_strobe, interrupt_ack;
   wire [7:0]   out_port;
   wire [7:0]   port_id;
   reg  [255:0] write, read;
   reg  [7:0]   charCounter;

   assign LED = {1'b0, bit8, parity_en, odd_n_even, baud_val[3:0]};
   assign tx  = tx_out;
   
   //synch_reset module instantiation
   //module synch_reset(clk, rstb, rstsb);
   synch_reset Synchronizer_Circuit(
      .clk(clk), 
      .rstb(rstb),
      .rstsb(rstsb)
   );
   
   
   //instantiate the RxStatusblaze
   embedded_kcpsm3 ekcp3(
      .port_id(port_id),
      .write_strobe(write_strobe),
      .read_strobe(read_strobe),
      .out_port(out_port),
      .in_port(in_port),
      .interrupt(interrupt),
      .interrupt_ack(interrupt_ack),
      .reset(!rstsb),
      .clk(clk)
   );
   
   assign interrupt = 0;
   //write strobe and read strobe decode   
   always@(*)begin
      write = 0;
      write[port_id] = write_strobe;
      read = 0;
      read[port_id] = read_strobe;
   end   

   //transmit_engine module instantiation   
   //module transmit_engine(clk, rstb, bit8, parity_en, odd_n_even, baud_val, 
   //txWrite, inData, tx, TxRdy);

   transmit_engine transmit(
      .clk(clk), 
      .rstb(rstsb),
      .bit8(bit8),
      .parity_en(parity_en),
      .odd_n_even(odd_n_even),
      .baud_val(baud_val),
      .txWrite(write[1]),
      .inData(out_port),
      .tx(tx_out),
      .TxRdy(TxRdy)
   );   
   
   //module receive_engine(clk, rstb, bit8, parity_en, odd_n_even, baud_val, READ, 
   // Rx, status, data);
   receive_engine receive(
      .clk(clk), 
      .rstb(rstsb),
      .bit8(bit8),
      .parity_en(parity_en),
      .odd_n_even(odd_n_even),
      .baud_val(baud_val),
      .READ(read[1:0]),
      .Rx(Rx),
      .status(RxStatus),
      .data(RxData)
   );   
   
   always@(posedge clk, negedge rstsb)
      if(!rstsb)
         charCounter <= 8'b00;
      else if (write[5])
         charCounter <= out_port;
      else
         charCounter <= charCounter;
   
   //Display Controller instantiation
   //module display_controller(clk, rstb, annode3, annode2, annode1, annode0,  
   // a3, a2, a1, a0, a, b, c, d, e, f, g);
   display_controller Display_Controller(
      .clk(clk),
      .rstb(rstsb),
      .annode3(charCounter[7:4]),
      .annode2(charCounter[3:0]),
      .annode1(RxData[7:4]),
      .annode0(RxData[3:0]),
      .a3(a3),
      .a2(a2),
      .a1(a1),
      .a0(a0),
      .a(a),
      .b(b),
      .c(c),
      .d(d),
      .e(e),
      .f(f),
      .g(g)   
   );
   
   assign in_port[7:0] = (read[0]) ? {2'b0, RxStatus[2:1], 2'b0, TxRdy, RxStatus[0]} 
	 : RxData;
   
endmodule

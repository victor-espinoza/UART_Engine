`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Author:        Victor Espinoza
// Email:         victor.alfonso94@gmail.com
// Project #:     Project 3 - Transmit Engine plus PicoBlaze
// Course:        CECS 460
// 
// Create Date:   11:37:29 10/15/2015 
//  
// Module Name:   transmit_engine 
// File Name:     transmit_engine.v
// 
// Description:   My transmit engine module contains all of the logic needed to
//                communicate with a computer via universal asynchronous 
//                receiver/transmitter (UART) communication. In order to create
//                a stable UART connection, I needed to make sure that I could 
//                run my program at different baud rates and different data 
//                formats (7N1, 7O1, 7E1, 8N1, 8O1, 8E1). For this program, I
//                am shifting out the data in 12-bit data packets. I use a 
//                shift register to determine what data gets shifted out. I am
//                able to load in the data that is going to be shifted out
//                by delaying the write[1] strobe from the PicoBlaze by 1 clock
//                cycle (this is because the data on the out_port of the 
//                PicoBlaze is not available until the next clock cycle). If
//                my write1Delay variable is set high, I then load my shift 
//                register with the out_port data of the PicoBlaze. I then 
//                update the remaining values in the shift register to make
//                sure that I have accounted for the right parity, stop, and
//                start bits. This is done using the bit8, parity_en, and 
//                odd_n_even inputs. Once all of the data in the shift register
//                is accurate, I then start shifting out the bits 1 bit at a 
//                time. I fill the most significant bit of my shift register 
//                with a 1 (which is equivalent to filling up the register
//                with a bunch of stop bits). I keep track of when I am done
//                shifting out all of the bits in my shift register by using
//                a bit counter. In order to know when a bit is done being 
//                shifted out, I also needed to use a baud-rate counter.
//                I first decoded the baud rate by reading in the data on my
//                four baud_rate switches. The next step was to determine what
//                baud-rate I was running at based on those four switches. After
//                determining the baud rate, I then needed to determine the 
//                amount of ticks I would need to achieve that specified baud-rate.
//                I did this by using the formula baudCountNum = (1/baud rate) / 
//                (1/50MHz). This gave me the terminal count number that I needed
//                to achieve the desired baud rate. I then assigned my baudCountNum
//                variable to this terminal count. Once that value was reached, I
//                then knew that I had finished transmitting one byte via UART
//                communication. Now the next step was to increment my Bit Counter.
//                I repeated this process until my Bit Counter reached 11, meaning
//                that I had finished transmitting all 12 bits of data in the 
//                data packet. For this project, we are always going to end up
//                transmitting 12 bits of data per data packet. That is why my 
//                bit time counter limit is always 11 (0 - (12-1)). Once all 12
//                bits of data have been shifted out, I then set my Done variable 
//                to 1, which also sets my TxRdy variable to a 1. I then output
//                this TxRdy variable, along with the other status variables
//                to the PicoBlaze. These status variables are concatenated and
//                represent the status register of the Transmit Engine. The 
//                TxRdy bit lets the PicoBlaze know that the Transmit Engine is
//                ready to transmit another byte, at which point the PicoBlaze
//                will output the next character being transmitted in the 
//                sequence to the Transmit Engine.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module transmit_engine(clk, rstb, bit8, parity_en, odd_n_even, baud_val, txWrite, 
 inData, tx, TxRdy);

   //Input and Output Declarations
   input       clk, rstb, bit8, parity_en, odd_n_even, txWrite;
   input [3:0] baud_val;
   input [7:0] inData;
   output      tx;
   output reg  TxRdy;
   //output transferLimit;
   

   //Local Declarations
   wire        TxSet, TxRst, Done, sSet, sRst, ld, btu, shift;
   reg  [7:0]  data;
   reg  [17:0] baudCountNum, baudCount, nBaudCount;
   reg  [3:0]  bitCount, nBitCount;
   reg         start, write1Delay;   
   
   reg [11:0]  sreg_data;
   reg         b7, b8;
   
   
   assign TxSet = Done;
   assign TxRst = txWrite;
   //R-S Flop that controlls the TxRdy input 
   //for the UART
   always@(posedge clk, negedge rstb)
      if(!rstb) 
         TxRdy <= 1'b1;
      else if(TxSet) 
         TxRdy <= 1'b1;
      else if(TxRst) 
         TxRdy <= 1'b0;
      else 
         TxRdy <= TxRdy;
         
         
   //assign pico_data[7:0] = {6'b0, TxRdy, 1'b0};
   

   assign sSet = txWrite;
   assign sRst = Done;
   //R-S Flop that controlls the start input 
   //for the UART
   always@(posedge clk, negedge rstb)
      if(!rstb) 
         start <= 1'b0;
      else if(sSet) 
         start <= 1'b1;
      else if(sRst) 
         start <= 1'b0;
      else 
         start <= start;
         
      
   assign ld = txWrite;
   //register that holds the outport data
   always@(posedge clk, negedge rstb)
      if(!rstb)
         data <= 8'b00;
      else if (ld)
         data <= inData;
      else 
         data <= data;
   
   

//********************************************************************************   
   //Shift register logic
   
   //register that delays the write strobe 
   //for one clock cycle
   always@(posedge clk, negedge rstb)
      if(!rstb)
         write1Delay <= 1'b0;
      else 
         write1Delay <= txWrite;
      

   //logic used to determine b7 and b8 of the shift register (value changes
   //depending on what bit8, parity_en, and odd_n_even is).
   always @(*) 
      case ({bit8,parity_en,odd_n_even})
         3'b000: {b8,b7} = 2'b11; //7N1
         3'b001: {b8,b7} = 2'b11; //7N1
         3'b010: {b8,b7} = {1'b1, ^data[6:0]}; //7E1
         3'b011: {b8,b7} = {1'b1, ~(^data[6:0])}; //7O1
         3'b100: {b8,b7} = {1'b1, data[7]}; //8N1
         3'b101: {b8,b7} = {1'b1, data[7]}; //8N1
         3'b110: {b8,b7} = {(^data[7:0]), data[7]}; //8E1
         3'b111: {b8,b7} = {~(^data[7:0]), data[7]}; //8O1
         default: {b8,b7} = 2'b00; //no bits
      endcase


   //update shift register value uf write1Delay is set high   
   always @( posedge clk, negedge rstb)
      if (!rstb)
         sreg_data <=12'hFFF; //load with all 1's
      else if (write1Delay)
         sreg_data <= {1'b1,b8,b7,data[6:0], 1'b0, 1'b1};//load data into sreg
      else if (shift)begin
         sreg_data <=  sreg_data >> 1; //shift data right by 1
         sreg_data [11] <= 1; //fill msb of shift register with a 1
      end
         
   assign tx = sreg_data[0];

//********************************************************************************   
   


//********************************************************************************   
   //BAUD TIME COUNTER LOGIC:
   
   //baud rate count decoder:
   //values are derived using (1/baud rate) / (1/50MHz)
   always@(*)
      case(baud_val)
      
         4'b0000: baudCountNum = 166667 -1;  //300 BAUD Rate
         4'b0001: baudCountNum = 41667 - 1;  //1200 BAUD Rate
         4'b0010: baudCountNum = 20833 - 1;  //2400 BAUD Rate
         4'b0011: baudCountNum = 10417 - 1;  //4800 BAUD Rate
         
         4'b0100: baudCountNum = 5208 - 1;   //9600 BAUD Rate
         4'b0101: baudCountNum = 2604 - 1;   //19200 BAUD Rate
         4'b0110: baudCountNum = 1302 - 1;   //38400 BAUD Rate
         4'b0111: baudCountNum = 868 - 1;    //57600 BAUD Rate
         
         4'b1000: baudCountNum = 434 - 1;    //115200 BAUD Rate
         4'b1001: baudCountNum = 217 - 1;    //230400 BAUD Rate
         4'b1010: baudCountNum = 109 - 1;    //460800 BAUD Rate
         4'b1011: baudCountNum = 54 - 1;     //921600 BAUD Rate
         
         default: baudCountNum = 166667 - 1; //300 BAUD Rate
      
      endcase 
      
      
   //assign btu output tick and shift wire
   assign btu = (baudCount == baudCountNum) ? 1'b1 : 1'b0;
   assign shift = btu;
   
   //Determine next state of baudCount
   always@(*)
      case({btu, start})
         2'b00 : nBaudCount = 18'b00;
         2'b01 : nBaudCount = baudCount + 1;
         2'b10 : nBaudCount = 18'b00;
         2'b11 : nBaudCount = 18'b00;
         default : nBaudCount = 18'b00;
      
      endcase
   
   //update baudCount accordingly
   always @(posedge clk, negedge rstb)
      if(!rstb) //check reset bit
         baudCount <= 18'b0; //reset counter
      else 
         baudCount <= nBaudCount; //update baudCount

//********************************************************************************   



//********************************************************************************   
   //BIT COUNTER LOGIC:
   //For this lab we are always going to be transmitting 12 bits of data at a
   //time. Once our counter has established that all 12 bits have been 
   //transmitted, we then set the Done variable high.
   //assign Done output tick
   assign Done = (bitCount == 11) ? 1'b1 : 1'b0;
   
   //Determine next state of bitCount
   always@(*)
      case({btu, start})
         2'b00 : nBitCount = 4'b00;
         2'b01 : nBitCount = (Done) ? 4'b00 : bitCount;
         2'b10 : nBitCount = 4'b00;
         2'b11 : nBitCount = bitCount + 1;
         default : nBitCount = 4'b00;
      
      endcase
   
   //update bitCount accordingly
   always @(posedge clk, negedge rstb)
      if(!rstb) //check reset bit
         bitCount <= 4'b0; //reset counter
      else 
         bitCount <= nBitCount; //update bitCount
   
//********************************************************************************   

endmodule

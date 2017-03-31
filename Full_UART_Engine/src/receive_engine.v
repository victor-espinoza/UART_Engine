`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// 
// Author:        Victor Espinoza
// Email:         victor.alfonso94@gmail.com
// Project #:     Project 4 - Full UART Engine
// Course:        CECS 460
// 
// Create Date:   11:37:29 10/15/2015 
//  
// Module Name:   receive_engine 
// File Name:     receive_engine.v
// 
// Description:   My receive engine module contains all of the logic needed to
//                receive information from a computer via universal asynchronous 
//                receiver/transmitter (UART) communication. In order to create
//                a stable UART connection, I needed to make sure that I could 
//                run my program at different baud rates and different data 
//                formats (7N1, 7O1, 7E1, 8N1, 8O1, 8E1). For this program, I
//                am shifting in the data from the receive engine 1-bit at a time. 
//                I use a shift register to store the receive engine data bits. 
//                Each data bit gets shifted in one bit at a time. For the receive 
//                engine we have a state diagram that consists of four different 
//                states: IDLE, S1, S2, and S3. The state machine starts off in 
//                the IDLE state at reset. In this state, it waits for a start bit
//                (which is agreed to be a zero). We then move to the S1 state, 
//                where the state machine waits for half a bit-time. If the Rx
//                input changes to a 1 during this half bit-time interval, I then
//                move back to the IDLE state where we reset the bit-time interval
//                and wait to receive a start bit value (0). If the Rx input 
//                stays the same (0) for the entirety of the half-bit time, this 
//                means that we actually received a start bit and I then move on to 
//                the next state, S2. I now know that we need to start collecting
//                the data bits, so in S2, I wait wait for an entire bit time. 
//                After the bit time is achieved, I am know in the middle of the 
//                first data bit. I then move on to state S3, where I shift the 
//                data bit value into my shift register. I then check to see if
//                all of the data bits have been shifted in to my shift register
//                by checking the status of my bcu variable. This variable is set
//                high for one clock cycle whenever all of the data bits have
//                been received. If the bcu variable is set high, then I go back
//                to the idle state where I wait until another bit is received.
//                If the variable is not set high, then I go back to S2 and wait
//                for another bit time so that I can shift in the next bit into
//                the receive engine. Once all of the data bits have been 
//                shifted into the receive engine, I then send these data bits
//                to the PicoBlaze so that it can process the received character
//                and determine what to do with that data.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module receive_engine(clk, rstb, bit8, parity_en, odd_n_even, baud_val, READ, 
 Rx, status, data);

   //Input and Output Declarations
   input        clk, rstb, bit8, parity_en, odd_n_even, Rx;
   input [1:0]  READ;
   input [3:0]  baud_val;
   
   output [7:0] data;
   reg [7:0]    data;
   output [2:0] status;
   wire [2:0]   status;

   //Local Declarations
   
   //symbolic state declaration
   localparam [2:0]   
      idle      = 2'b00,
      state_1   = 2'b01,
      state_2   = 2'b10,
      state_3   = 2'b11;
   
   wire        RxSet, RxRst, sSet, sRst, SEVEN, btu, bcu, done;//shift;
   wire        parSet, parRst;
   reg         START, DOIT, LOAD, nSTART, nDOIT, nLOAD;
   wire [17:0] finalBaudCountNum;
   reg  [17:0] baudCountNum, baudCount, nBaudCount;
   reg  [3:0]  bitCount, nBitCount;
   reg  [1:0]  present_state, next_state;
   reg         RxRdy, OVERFLOW, doneDelay;
   
   reg [8:0]   sreg_data;
   wire        b7, receivedParity, computedParity, generatedParity;
   wire        combinedParities, parityResult;
   reg         PARITY_ERR;
   
   
   assign RxSet = doneDelay & !RxRdy;
   assign RxRst = READ[1];
   //R-S Flop that controlls the RxRdy input 
   //for the UART
   always@(posedge clk, negedge rstb)
      if(!rstb) 
         RxRdy <= 1'b1;
      else if(RxSet) 
         RxRdy <= 1'b1;
      else if(RxRst) 
         RxRdy <= 1'b0;
      else 
         RxRdy <= RxRdy;
         
         
   assign sSet = LOAD & RxRdy;
   assign sRst = READ[0];
   //R-S Flop that controlls the overflow output
   //for the UART
   always@(posedge clk, negedge rstb)
      if(!rstb) 
         OVERFLOW <= 1'b0;
      else if(sSet) 
         OVERFLOW <= 1'b1;
      else if(sRst) 
         OVERFLOW <= 1'b0;
      else 
         OVERFLOW <= OVERFLOW;
         
//********************************************************************************   
   //Finite State Machine for RX system
   //For the receive engine we have a state diagram that consists of four different 
   //states: IDLE, S1, S2, and S3. The state machine starts off in 
   //the IDLE state at reset. In this state, it waits for a start bit
   //(which is agreed to be a zero). We then move to the S1 state, 
   //where the state machine waits for half a bit-time. If the Rx
   //input changes to a 1 during this half bit-time interval, I then
   //move back to the IDLE state where we reset the bit-time interval
   //and wait to receive a start bit value (0). If the Rx input 
   //stays the same (0) for the entirety of the half-bit time, this 
   //means that we actually received a start bit and I then move on to 
   //the next state, S2. I now know that we need to start collecting
   //the data bits, so in S2, I wait wait for an entire bit time. 
   //After the bit time is achieved, I am know in the middle of the 
   //first data bit. I then move on to state S3, where I shift the 
   //data bit value into my shift register. I then check to see if
   //all of the data bits have been shifted in to my shift register
   //by checking the status of my bcu variable. This variable is set
   //high for one clock cycle whenever all of the data bits have
   //been received. If the bcu variable is set high, then I go back
   //to the idle state where I wait until another bit is received.
   //If the variable is not set high, then I go back to S2 and wait
   //for another bit time so that I can shift in the next bit into
   //the receive engine. Once all of the data bits have been 
   //shifted into the receive engine, I then send these data bits
   //to the PicoBlaze so that it can process the received character
   //and determine what to do with that data.
   
   always@(posedge clk, negedge rstb)begin
      if(!rstb)begin
         present_state  <= idle;
         {START, DOIT, LOAD} <= 3'b000; //Reset outputs
      end
      else begin
         present_state  <= next_state; //update the present state
         {START, DOIT, LOAD} <= {nSTART, nDOIT, nLOAD}; //update present outputs
      end
   end
   
   always@(*)begin
      next_state = present_state; //default state: the same
      {nSTART, nDOIT, nLOAD}  = 3'b000; //wait for start bit
      case(present_state)
         idle : begin
            {nSTART, nDOIT, nLOAD}  = 3'b000; //wait for start bit
            next_state = (Rx) ? idle : state_1;
         end
         state_1 : begin
            {nSTART, nDOIT, nLOAD}  = 3'b110; //wait for half bit-time
            next_state = (Rx) ? idle : ((btu) ? state_2 : state_1 );   
         end
         state_2 : begin
            {nSTART, nDOIT, nLOAD}  = 3'b010; //wait for full bit-time
            next_state = (btu) ? state_3 : state_2;   
         end
         state_3 : begin
            {nSTART, nDOIT, nLOAD}  = 3'b011; //load bit into shift register
            next_state = (bcu) ? idle : state_2;         
         end
         default : begin
            {nSTART, nDOIT, nLOAD}  = 3'b000; //wait for start bit
            next_state = idle;
         end   
      endcase
   end
   
//********************************************************************************   


//********************************************************************************   
   //update shift register value until it contains all of the receive data
   always @(posedge clk, negedge rstb)
      if (!rstb)
         sreg_data <=9'hFFF; //load with all 1's
      else if (!START & !DOIT & !LOAD)
         sreg_data <=9'hFFF; //load with all 1's      
      else if (LOAD & !START)begin
         sreg_data <=  sreg_data >> 1; //shift data right by 1
         sreg_data [8] <= Rx; //fill msb of shift register with Rx input
      end
      
   assign SEVEN = !bit8;
   
   //generate the parity error result
   assign b7               = (SEVEN) ? 1'b0 : sreg_data[7];
   assign receivedParity   = (SEVEN) ? sreg_data[7] : sreg_data[8];
   assign computedParity   = ^{b7,sreg_data[6:0]};
   assign generatedParity  = (odd_n_even) ? ~computedParity : computedParity;
   assign combinedParities = ^{receivedParity, generatedParity};
   assign parityResult     = doneDelay & parity_en & combinedParities;
   
   
   assign parSet = parityResult;
   assign parRst = READ[0];
   //R-S Flop that controlls the Parity Error output for the UART
   always@(posedge clk, negedge rstb)
      if(!rstb) 
         PARITY_ERR <= 1'b0;
      else if(parSet) 
         PARITY_ERR <= 1'b1;
      else if(parRst) 
         PARITY_ERR <= 1'b0;
      else 
         PARITY_ERR <= PARITY_ERR;

   //data to picoblaze
   always @(posedge clk, negedge rstb)
      if(!rstb)
         data <= 8'b0;
      else if (doneDelay)
         data <= {b7, sreg_data[6:0]};   


   //status to picoblaze
   assign status = {OVERFLOW, PARITY_ERR, RxRdy};
         
      
      
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
   //The START signal determines whether I am counting for a full bit time
   //or half of a bit time. When START is high, I assign the count value to
   //half of the original value (by shifting it to the right once). This 
   //means that I am looking for the start bit of the received data (0)
   //and as a result I am only waiting for half of a bit-time. When START 
   //is low, I assign te count value to the original value (meaning that I 
   //am waiting for a full bit-time).
   assign finalBaudCountNum = (START) ? (baudCountNum >> 1) :   baudCountNum;
   
	//assign btu output tick and shift wire
   assign btu = (baudCount == finalBaudCountNum) ? 1'b1 : 1'b0;
   //assign shift = btu;
   
   //Determine next state of baudCount
   always@(*)
      case({btu, DOIT})
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
   assign bcu  = (bitCount == 11) ? 1'b1 : 1'b0;
   assign done = bcu;
   //Determine next state of bitCount
   always@(*)
      case({btu, DOIT})
         2'b00 : nBitCount = 4'b00;
         2'b01 : nBitCount = (done) ? 4'b00 : bitCount;
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
         
   //done delay (allows time to load the bit into the shift register)
   always@(posedge clk, negedge rstb)
      if(!rstb) //check reset bit
         doneDelay <= 1'b0;
      else 
         doneDelay <= done;

//********************************************************************************   

endmodule

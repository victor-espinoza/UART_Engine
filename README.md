Project Overview:   

Fully functional Universal Asynchronous Receiver/Transmitter Interface using Verilog and Assembly.    
      
The SOC is using a Universal Asynchronous Receiver Transmitter (UART) interface to receive and transmit data. The user sets up an agreed upon connection with the SOC and then opens up a terminal window. Upon reset, a banner is displayed and so is a command prompt (*>). The user can then enter a character on the keyboard and its data is sent to the PicoBlaze (an 8-bit microcontroller) to process the data.   
  
If the character is a carriage return or a line feed character, then the PicoBlaze will have the UART Engine transmit a new line command and re-issue the prompt to the terminal window. If the character is an asterisk (*), then the  PicoBlaze will have the UART Engine transmit the hometown of the developer (Porterville, CA) to the terminal window.   
  
Any other valid ASCII character that the user enters on the keyboard will be echoed to the terminal. The PicoBlaze is also able to process the status of the UART engine and informs the user whenever an overflow error or a parity error occurs within the UART communication. The status flags are cleared every time that the PicoBlaze reads the status of the UART engine.   
      
The project consists of six different blocks. The first block in the Block Diagram is the Asynchronous In, Synchronous Out Synchronization Circuit. This makes it so that the reset button on the Nexys 2 Board (which is high-active) generates a low signal every time it is activated. This is because all of the reset logic in the system (excluding the external PicoBlaze microcontroller is low-active). The output of my AISO (rstsb) goes to all of the other blocks in the design. Because the PicoBlaze has a high-active reset, I needed to invert the rstsb output before I connected the rstsb signal to the PicoBlaze. 
    
The second block in the design is the PicoBlaze. I use the PicoBlaze to process all of the data coming in from the Universal Asynchronous Receiver Transmitter interface terminal. I also use the PicoBlaze to determine what data is going to be transmitted to the terminal. The port_id, write_strobe, and read_strobe outputs go into the third block, which is a decoder that I use to determine what data to write to the terminal and what data to read from the UART interface. 
     
The fourth block consists of the transmit engine, where I format the data bits in the correct sequence and determine the parity, number of bits, and baud rate at which to transmit the data. I then shift load this data into a shift register and shift out the data bits individually until all of the bits have been transmitted to the terminal. The transmit engine also outputs a TxRdy flag to let the PicoBlaze know when it is ready to transmit another byte. 
     
The fifth block consists of the receive engine. This block receives data from the terminal by determining the parity, number of bits, and baud rate at which the data is being received. The data bits are shifted into a shift register. Once all data bits have been shifted in, the receive engine then loads the received byte into a register and calculates the parity error. The receive engine also continually updates the overflow flag to make sure that an overflow does not occur (when the receive engine starts receiving another byte before it finishes receiving the previous byte). The receive engine outputs both the received byte of data and its status flags (Overflow, Parity Error, and RxRdy). The received byte of data is then sent over to the PicoBlaze so it can process it and figure out what to transmit to the terminal. 
     
Both the receive engine status flags and the transmit engine status flags are concatenated together and they then go into the sixth and final block, which is a multiplexer. The multiplexer decides what 8 bits of data to send to the in_port of the PicoBlaze based on whether read[0] is set high. If it is, then the in_port of the PicoBlaze gets the status flags {2'b0, Overflow, ParityError, 2'b0, TxRdy, RxRdy}, otherwise it gets the received byte data from the receive engine. That sums up the top-level design of my project.
      
Project Block-Diagram:     
![ScreenShot](https://cloud.githubusercontent.com/assets/14812721/24987680/1d4b0f92-1fb6-11e7-883b-ec809a44c085.jpg)   
     
Project Assembly Code:      

             ;UART Full
             ; ;================================================================
             ; data constants
             ;================================================================
             ;selected ASCII codes
             CONSTANT ASCII_CR , 0D            ; carriage return <CR>
             CONSTANT ASCII_LF , 0A            ; line feed <LF>
             CONSTANT ASCII_Space , 20         ; Space 
             CONSTANT ASCII_Asterisk , 2A      ; *(Asterisk) character
             CONSTANT ASCII_Greater_Than, 3E   ; >(Greater Than) character  
             CONSTANT ASCII_bslash , 2F        ; /(Backslash) character
             CONSTANT ASCII_colon , 3A         ; :(colon) character
             CONSTANT ASCII_comma , 2C         ; ,(comma) character
             CONSTANT ASCII_dash , 2D          ; -(dash) character
             CONSTANT ASCII_exclamation , 21   ; !(exclamation point) character
             CONSTANT ASCII_backspace , 08     ; BS(backspace) character
             CONSTANT ASCII_delete , 7F        ; DEL(descructive delete) character

             CONSTANT ASCII_C_U , 43           ; Uppercase C
             CONSTANT ASCII_E_U , 45           ; Uppercase E
             CONSTANT ASCII_S_U , 53           ; Uppercase S
             CONSTANT ASCII_4 , 34             ; number 4
             CONSTANT ASCII_6 , 36             ; number 6
             CONSTANT ASCII_0 , 30             ; number 0

             CONSTANT ASCII_V_U , 56           ; Uppercase V
             CONSTANT ASCII_i , 69             ; Lowercase i
             CONSTANT ASCII_c , 63             ; Lowercase c
             CONSTANT ASCII_t , 74             ; Lowercase t
             CONSTANT ASCII_o , 6F             ; Lowercase o
             CONSTANT ASCII_r , 72             ; Lowercase r
             CONSTANT ASCII_s , 73             ; Lowercase s
             CONSTANT ASCII_p , 70             ; Lowercase p
             CONSTANT ASCII_n , 6E             ; Lowercase n
             CONSTANT ASCII_z , 7A             ; Lowercase z
             CONSTANT ASCII_a , 61             ; Lowercase a


             CONSTANT ASCII_F_U , 46           ; Uppercase F
             CONSTANT ASCII_u , 75             ; Lowercase u
             CONSTANT ASCII_l , 6C             ; Lowercase l
             CONSTANT ASCII_U_U , 55           ; Uppercase U
             CONSTANT ASCII_A_U , 41           ; Uppercase A
             CONSTANT ASCII_R_U , 52           ; Uppercase R
             CONSTANT ASCII_T_U , 54           ; Uppercase T

             CONSTANT ASCII_D_U , 44           ; Uppercase D
             CONSTANT ASCII_e , 65             ; Lowercase e
             CONSTANT ASCII_1 , 31             ; number 1
             CONSTANT ASCII_9 , 39             ; number 9
             CONSTANT ASCII_5 , 35             ; number 5

             CONSTANT ASCII_H_U , 48           ; Uppercase H
             CONSTANT ASCII_m , 6D             ; Lowercase m
             CONSTANT ASCII_w , 77             ; Lowercase w
             CONSTANT ASCII_P_U , 50           ; Uppercase P
             CONSTANT ASCII_v , 76             ; Lowercase v

             CONSTANT ASCII_I_U , 49           ; Uppercase I
             CONSTANT ASCII_Y_U , 59           ; Uppercase Y
             CONSTANT ASCII_O_U , 4F           ; Uppercase O
             CONSTANT ASCII_L_U , 4C           ; Uppercase L
             CONSTANT ASCII_W_U , 57           ; Uppercase W


             ;================================================================
             ; port aliases
             ;================================================================
             ;____________________________input port definitions_____________________________________
              
             CONSTANT rd_flag_port, 00    ;status of transmit engine
             CONSTANT rx_data_port, 01    ;received data from receive engine
             NAMEREG s0, tx_data          ;data to be transmitted by uart
             NAMEREG s2, rx_data          ;data to be received by uart
             NAMEREG s3, char_counter     ;keeps track of how many characters have been
                                          ;transmitted on the current line (for destructive 
                                          ;delete)

             ;____________________________output port definitions____________________________________

             CONSTANT uart_tx_port, 01    ;outputs to register 1 (Write_Strobe[1])
             ;================================================================
             ; Main Program
             ;================================================================
             main_program: 
                    load char_counter, 00     ;zero out the character counter
                    call display_banner       ;Display the banner at the beginning of the program

             infinite_loop: 
                    call proc_uart ;receive uart characters
             JUMP infinite_loop
             
             
             ;================================================================
             ; routine : check_status_flags
             ;       function : check the status flags of the UART engine and inform the user of
             ;                  any errors that have occurred (parity, overflow)
             ;       Input Register :  s1 - read port flags
             ;       Temp Register :   s5 - check for parity/overflow error
             ;      Output Register : tx_data (s0) - data to be transmitted by uart
             ;================================================================     
             check_status_flags:   
                    load s5, s1                         ;copy status register value into s5
                    and s5, 20                          ;isolate overflow bit
	                  sub s5, 20                          ;check to see if Overflow bit is set high
                    jump nz, check_parity_errror        ;if it isn't, check the parity error flag
                    call display_overflow_error         ;display overflow error
                    jump done_error_checking            ;jump to the end of the error checking          
             check_parity_errror :   
                    load s5, s1                         ;copy status register value into s5
                    and s5, 10                          ;isolate parity error bit
	                  sub s5, 10                          ;check to see if Parity Error bit is set high
                    jump nz, done_error_checking        ;if it isn't, jump to the end of the error checking
                    call display_pairty_error           ;display overflow error
             done_error_checking:  
                    return                 
                    
                    
             ;================================================================
             ; routine : tx_one_byte
             ;       function : Wait until uart TxRdy bit is set, which signifies that the UART is
             ;                  ready to transmit another byte. Then transmit another byte to
             ;                  the UART.
             ;       Input Register :    s1 - read port flags
             ;      Output Register : tx_data (s0) - data to be transmitted by uart
             ;================================================================     
             tx_one_byte :
                    input s1, rd_flag_port             ;read in status of the Transmit Engine
                    call check_status_flags            ;check for overflow/parity errors
                    and s1, 02                         ;isolate TxRdy bit 
	 sub s1, 02                                          ; check to see if TxRdy bit is set high
                    jump nz, tx_one_byte               ;if it isn't, keep on waiting until it is set high
                    output tx_data, uart_tx_port       ;If it is set high, then transmit byte to uart
                    compare tx_data, ASCII_delete      ;check to see if data is a destructive delete
                    jump nz, increment_counter         
                    sub char_counter, 01               ;decrement character counter
                    jump done_updating_counter    
             increment_counter:	
                    add char_counter, 01               ;increment character counter
             done_updating_counter:
                    output char_counter, 05            ;output character counter value
                    return
                    
                    
             ;================================================================
             ; routine: proc_uart
             ;       function : receive UART input character and process it:
             ;                  CR - transmit a new line (CR/LF) and prompt
             ;                  LF - transmit a new line (CR/LF) and prompt
             ;                  * - Display the hometown of user
             ;                  other - echo character
             ;       Input Register :   rx_data(s2) - received data, 
             ;                                      s1 - read port flags, 
             ;      Output Register : tx_data (s0) - data to be transmitted by uart 
             ;================================================================
             proc_uart:
                    input rx_data ,  rx_data_port         ;receive data from terminal
            receive_byte:
                    input s1, rd_flag_port                ;read in status of the Receive Engine
                    call check_status_flags               ;check for overflow/parity errors
                    and s1, 01                            ;isolate RxRdy bit 
	                  sub s1, 01                            ; check to see if RxRdy bit is set high
                    jump nz, receive_byte                 ;if it isn't, keep on waiting until it is set high
	                  input rx_data ,  03                   ;store received data in register
	                  compare rx_data, ASCII_CR             ;see if carriage return was received
	                  jump nz, compare_lf                   ;if not, check for line feed
	                  call new_prompt                       ;trigger the newline prompt
                    jump  uart_receive_byte_done 
            compare_lf:
                    compare rx_data, ASCII_LF             ;see if line feed was received
	                  jump nz, compare_asterisk             ;if not, check for asterisk
	                  call new_prompt                       ;trigger the newline prompt
                    jump  uart_receive_byte_done 
            compare_asterisk:
                    compare rx_data, ASCII_Asterisk    ;see if asterisk was received
                    jump nz, compare_backspace         ;if not, check for backspace
	                  call transmit_hometown             ;transmit hometown
                    jump  uart_receive_byte_done 
            compare_backspace:
                    compare rx_data, ASCII_backspace  ;see if backspace was received
                    jump nz,  compare_delete          ;if not, check for destructive delete
	                  compare char_counter, 04          ;check to see if there are any bits to delete
                    jump z, uart_receive_byte_done    ;if there are no characters available to delete, do nothing
	                  load rx_data, ASCII_delete        ;load with a destructive delete if backspace pressed
                    jump  transmit_received_char      ;delete the character
            compare_delete:
                    compare rx_data, ASCII_delete     ;see if delete was received
                    jump nz, echo_character           ;if not, echo character
	                  compare char_counter, 04          ;check to see if there are any bits to delete
                    jump z, uart_receive_byte_done    ;if there are no characters available to delete, do nothing
                    jump transmit_received_char       ;transmit the destructive delete
            echo_character:
                    compare char_counter, AA             ;check to see if counter limit has been reached
                    jump nz, transmit_received_char      ;if it isn't, transmit the character
                    call new_prompt                      ;otherwise start a new line
            transmit_received_char:
                    load tx_data , rx_data 
	                  call tx_one_byte                    ; echo received character
             uart_receive_byte_done :
                    return
                    
                    
             ;================================================================
             ; routine: display_banner
             ;       function : Transmits the beginning banner onto the terminal screen:
             ; ****************************
             ; *   CECS 460      
             ; *   Victor Espinoza
             ; *   Full UART
             ; *   Due: 11/19/15
             ; ****************************
             ;================================================================
             display_banner: 
                    call transmit_top_of_banner      ;transmit asterisks
                    call transmit_class              ;transmit class name
                    call transmit_student_name       ;transmit my name
                    call transmit_project_name       ;transmit project name
                    call transmit_due_date           ;transmit due date
                    call transmit_top_of_banner      ;transmit asterisks
                    load tx_data , ASCII_CR
                    call tx_one_byte                 ; transmit CR (Carriage Return)
                    load tx_data , ASCII_LF
                    call tx_one_byte                 ; transmit LF (Line Feed)
 	                  call new_prompt                  ;transmit prompt
	                  return
                    
                    
             ;================================================================
             ; routine: new_prompt
             ;       function : Transmits the new prompt (*>) whenever a CR or LF chacacter
             ;                  are received or when the terminal issues a new line command.
             ;================================================================
             new_prompt:
                    load char_counter, 00                       ;zero out the character counter
                    load tx_data , ASCII_CR
                    call tx_one_byte                            ; transmit CR (Carriage Return)
                    load tx_data , ASCII_LF
                    call tx_one_byte                            ; transmit LF (Line Feed)
                    load tx_data , ASCII_Asterisk
                    call tx_one_byte                            ; transmit * (Asterisk)  
                    load tx_data , ASCII_Greater_Than
                    call tx_one_byte                            ; transmit >(Greater Than)	
                    return
                    
                    
             ;================================================================
             ; routine: transmit_top_of_banner
             ;       function : Transmits the top part of the banner (30 asterisks)
             ; ******************************
             ;================================================================
             transmit_top_of_banner:
                    load tx_data , ASCII_CR
                    call tx_one_byte                            ; transmit CR (Carriage Return)
                    load tx_data , ASCII_LF
                    call tx_one_byte                            ; transmit LF (Line Feed)
	                  load sF, 1D ;
             asterisk_loop:
	                  compare sF, 00                              ; check to see if loop is done transmitting
                    jump z, done_transmitting_asterisks         ; if it is, jump to end of loop
                    load tx_data , ASCII_Asterisk   
	                  call tx_one_byte                            ; transmit * (Asterisk)  
                    sub sF, 01                                  ; decrement loop counter
                   JUMP asterisk_loop
             done_transmitting_asterisks:
                    return
                    
                    
             ;================================================================
             ; routine: transmit_class
             ;       function : Transmits the class name (CECS 460)
             ;================================================================
             transmit_class:
                    load tx_data , ASCII_CR
                    call tx_one_byte                            ; transmit CR (Carriage Return)
                    load tx_data , ASCII_LF
                    call tx_one_byte                            ; transmit LF (Line Feed)
                    load tx_data , ASCII_Asterisk   
	                  call tx_one_byte                            ; transmit * (Asterisk)       
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_C_U
                    call tx_one_byte                            ; transmit C
                    load tx_data , ASCII_E_U
                    call tx_one_byte                            ; transmit E
                    load tx_data , ASCII_C_U
                    call tx_one_byte                            ; transmit C
                    load tx_data , ASCII_S_U
                    call tx_one_byte                            ; transmit S
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_4
                    call tx_one_byte                            ; transmit 4
                    load tx_data , ASCII_6
                    call tx_one_byte                            ; transmit 6
                    load tx_data , ASCII_0
                    call tx_one_byte                            ; transmit 0
                    return
                    
                    
             ;================================================================
             ; routine: transmit_student_name
             ;       function : Transmits the student name (Victor Espinoza)
             ;================================================================
             transmit_student_name:
                    load tx_data , ASCII_CR
                    call tx_one_byte                            ; transmit CR (Carriage Return)
                    load tx_data , ASCII_LF
                    call tx_one_byte                            ; transmit LF (Line Feed)
                    load tx_data , ASCII_Asterisk   
	                  call tx_one_byte                            ; transmit * (Asterisk)       
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data ,  ASCII_V_U
                    call tx_one_byte                            ; transmit V
                    load tx_data , ASCII_i
                    call tx_one_byte                            ; transmit i
                    load tx_data , ASCII_c
                    call tx_one_byte                            ; transmit c
                    load tx_data , ASCII_t
                    call tx_one_byte                            ; transmit t
                    load tx_data , ASCII_o
                    call tx_one_byte                            ; transmit o
                    load tx_data , ASCII_r
                    call tx_one_byte                            ; transmit r
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_E_U
                    call tx_one_byte                            ; transmit E
                    load tx_data , ASCII_s
                    call tx_one_byte                            ; transmit s
                    load tx_data , ASCII_p
                    call tx_one_byte                            ; transmit p
                    load tx_data , ASCII_i
                    call tx_one_byte                            ; transmit i
                    load tx_data , ASCII_n
                    call tx_one_byte                            ; transmit n
                    load tx_data , ASCII_o
                    call tx_one_byte                            ; transmit o
                    load tx_data , ASCII_z
                    call tx_one_byte                            ; transmit z
                    load tx_data , ASCII_a
                    call tx_one_byte                            ; transmit a
                    return
                    
                    
             ;================================================================
             ; routine: transmit_project_name
             ;       function : Transmits the project name (Full UART)
             ;================================================================
             transmit_project_name:
                    load tx_data , ASCII_CR
                    call tx_one_byte                            ; transmit CR (Carriage Return)
                    load tx_data , ASCII_LF
                    call tx_one_byte                            ; transmit LF (Line Feed)
                    load tx_data , ASCII_Asterisk   
	                  call tx_one_byte                            ; transmit * (Asterisk)       
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_F_U
                    call tx_one_byte                            ; transmit F
                    load tx_data , ASCII_u
                    call tx_one_byte                            ; transmit u
                    load tx_data , ASCII_l
                    call tx_one_byte                            ; transmit l
                    load tx_data , ASCII_l
                    call tx_one_byte                            ; transmit l
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_U_U
                    call tx_one_byte                            ; transmit U
                    load tx_data , ASCII_A_U
                    call tx_one_byte                            ; transmit A
                    load tx_data , ASCII_R_U
                    call tx_one_byte                            ; transmit R
                    load tx_data , ASCII_T_U
                    call tx_one_byte                            ; transmit T
                    return
                    
                    
             ;================================================================
             ; routine: transmit_due_date
             ;       function : Transmits the project due date (Due: 11/19/15)
             ;================================================================
             transmit_due_date:
                    load tx_data , ASCII_CR
                    call tx_one_byte                            ; transmit CR (Carriage Return)
                    load tx_data , ASCII_LF
                    call tx_one_byte                            ; transmit LF (Line Feed)
                    load tx_data , ASCII_Asterisk   
	                  call tx_one_byte                            ; transmit * (Asterisk)       
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_D_U
                    call tx_one_byte                            ; transmit D
                    load tx_data , ASCII_u
                    call tx_one_byte                            ; transmit u
                    load tx_data , ASCII_e
                    call tx_one_byte                            ; transmit e      
                    load tx_data , ASCII_colon 
                    call tx_one_byte                            ; transmit : (Colon)     
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_1
                    call tx_one_byte                            ; transmit 1
                    load tx_data , ASCII_1
                    call tx_one_byte                            ; transmit 1
                    load tx_data , ASCII_bslash
                    call tx_one_byte                            ; transmit / (Backslash)
                    load tx_data , ASCII_l
                    call tx_one_byte                            ; transmit l
                    load tx_data , ASCII_9
                    call tx_one_byte                            ; transmit 9
                    load tx_data , ASCII_bslash
                    call tx_one_byte                            ; transmit / (Backslash)
                    load tx_data , ASCII_l
                    call tx_one_byte                            ; transmit l
                    load tx_data , ASCII_5
                    call tx_one_byte                            ; transmit 5
                    return
                    
                    
             ;================================================================
             ; routine: transmit_hometown
             ;       function : Transmits the student's hometown (Hometown - Porterville, CA)
             ;================================================================
             transmit_hometown:
 	                  call new_prompt                             ; transmit prompt 
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_H_U
                    call tx_one_byte                            ; transmit H
                    load tx_data , ASCII_o
                    call tx_one_byte                            ; transmit o
                    load tx_data , ASCII_m
                    call tx_one_byte                            ; transmit m
                    load tx_data , ASCII_e
                    call tx_one_byte                            ; transmit e
                    load tx_data , ASCII_t
                    call tx_one_byte                            ; transmit t
                    load tx_data , ASCII_o
                    call tx_one_byte                            ; transmit o
                    load tx_data , ASCII_w
                    call tx_one_byte                            ; transmit w
                    load tx_data , ASCII_n
                    call tx_one_byte                            ; transmit n
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_dash
                    call tx_one_byte                            ; transmit dash
                    load tx_data , ASCII_Space 
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_P_U
                    call tx_one_byte                            ; transmit P
                    load tx_data , ASCII_o
                    call tx_one_byte                            ; transmit o
                    load tx_data , ASCII_r
                    call tx_one_byte                            ; transmit r
                    load tx_data , ASCII_t
                    call tx_one_byte                            ; transmit t
                    load tx_data , ASCII_e
                    call tx_one_byte                            ; transmit e
                    load tx_data , ASCII_r
                    call tx_one_byte                            ; transmit r
                    load tx_data , ASCII_v
                    call tx_one_byte                            ; transmit v
                    load tx_data , ASCII_i
                    call tx_one_byte                            ; transmit i
                    load tx_data , ASCII_l
                    call tx_one_byte                            ; transmit l
                    load tx_data , ASCII_l
                    call tx_one_byte                            ; transmit l
                    load tx_data , ASCII_e
                    call tx_one_byte                            ; transmit e
                    load tx_data , ASCII_comma
                    call tx_one_byte                            ; transmit comma
                    load tx_data , ASCII_Space
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_C_U
                    call tx_one_byte                            ; transmit C
                    load tx_data , ASCII_A_U
                    call tx_one_byte                            ; transmit A
                    return


             ;================================================================
             ; routine: display_pairty_error
             ;       function : Informs user of parity error (PARITY ERROR!)
             ;================================================================
             display_pairty_error:
                    load tx_data , ASCII_P_U
                    call tx_one_byte                            ; transmit P
                    load tx_data , ASCII_A_U
                    call tx_one_byte                            ; transmit A
                    load tx_data , ASCII_R_U
                    call tx_one_byte                            ; transmit R
                    load tx_data , ASCII_I_U
                    call tx_one_byte                            ; transmit I
                    load tx_data , ASCII_T_U
                    call tx_one_byte                            ; transmit T
                    load tx_data , ASCII_Y_U
                    call tx_one_byte                            ; transmit Y
                    load tx_data , ASCII_Space
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_E_U
                    call tx_one_byte                            ; transmit E
                    load tx_data , ASCII_R_U
                    call tx_one_byte                            ; transmit R
                    load tx_data , ASCII_R_U
                    call tx_one_byte                            ; transmit R
                    load tx_data , ASCII_O_U
                    call tx_one_byte                            ; transmit O
                    load tx_data , ASCII_R_U
                    call tx_one_byte                            ; transmit R
                    load tx_data , ASCII_exclamation
                    call tx_one_byte                            ; transmit exclamation
 	                  call new_prompt                             ; transmit prompt 
                    return


             ;================================================================
             ; routine: display_overflow_error
             ;       function : Informs user of overflow error (OVERFLOW ERROR!)
             ;================================================================
             display_overflow_error:
                    load tx_data , ASCII_O_U
                    call tx_one_byte                            ; transmit O
                    load tx_data , ASCII_V_U
                    call tx_one_byte                            ; transmit V
                    load tx_data , ASCII_E_U
                    call tx_one_byte                            ; transmit E
                    load tx_data , ASCII_R_U
                    call tx_one_byte                            ; transmit R
                    load tx_data , ASCII_F_U
                    call tx_one_byte                            ; transmit F
                    load tx_data , ASCII_L_U
                    call tx_one_byte                            ; transmit L
                    load tx_data , ASCII_O_U
                    call tx_one_byte                            ; transmit O
                    load tx_data , ASCII_W_U
                    call tx_one_byte                            ; transmit W
                    load tx_data , ASCII_Space
                    call tx_one_byte                            ; transmit space
                    load tx_data , ASCII_E_U
                    call tx_one_byte                            ; transmit E
                    load tx_data , ASCII_R_U
                    call tx_one_byte                            ; transmit R
                    load tx_data , ASCII_R_U
                    call tx_one_byte                            ; transmit R
                    load tx_data , ASCII_O_U
                    call tx_one_byte                            ; transmit O
                    load tx_data , ASCII_R_U
                    call tx_one_byte                            ; transmit R
                    load tx_data , ASCII_exclamation
                    call tx_one_byte                            ; transmit exclamation
 	                  call new_prompt                             ; transmit prompt 
                    return

     
Dependencies:      
This project was created using the Xilinx ISE Project Navigator Version: 14.7.    
    
Project Verification:     
Transmit Engine Verification:   
For this Transmit Engine verification I created a test bench module for both my top_level and my transmit_engine files. For the top_level test bench, all I did was initialize my inputs and set my baud-rate / data format to be 9600 / 8O1. I then ran the simulation and used the waveforms to verify that my Transmit Engine was storing/shifting the correct values out and that the PicoBlaze was outputting the character values at the appropriate times.   
    
The Transmit Engine test bench was a lot more involved than my top_level test bench. In the Transmit Engine test bench, I made sure to test out a variety of data values and I also made sure that I was able to successfully run at all of the different baud-rates specified for my project. I also made sure that each data format (7N1, 7O1, 7E1, 8N1, 8O1m 8E1) worked correctly as well.    
    
I verified this by making sure that each 12-bit packet was transmitted in the correct order and by making sure that the appropriate values were being loaded into my shift register I also compared the desired shift register values to the actual shift register values and outputted the result to the console in order to help me debug my shift register and make sure that it was working properly.    
    
For a more detailed version of each test bench and its verification, refer to the header section of each test bench module within the source code. It is there that I go into further detail about how I verified the completeness of my design.

Receive Engine Verification:      
I verified that my Receive Engine was working correctly by using a simple test bench. In the Receive Engine test bench, I initialized my UART format to transfer at a baud rate of 460800 and have a format of 8O1. I then made sure that the receive engine correctly received the data of 0xAE.     
      
Since I extensively tested the Transmit Engine to make sure that I was able to successfully run at all of the different baud-rates and data formats (7N1, 7O1, 7E1, 8N1, 8O1m 8E1) for my project, I was convinced that the Receive Engine would yield the same results because the baud rate and format logic is almost identical between both engines.     
      
This is why I came to the conclusion that I did not need to test every possible baud-rate and data format combination for my Receive Engine. After I received the start bit from the receive data, I then waited for the bit time up to occur before I changed the Rx input value to the Receive Engine. This was so that I wasn't disturbing the Receive Engine while it was waiting for a bit time to begin collecting data.    
    
After a bit was shifted into the shift register, I then changed the Rx input in a way that would yield me receiving a byte of 0xAE. After all of the data bits were shifted into the shift register, I then loaded this data into a flop and sent the data to the PicoBlaze.    
    
As expected, the end result was that 0xAE was loaded into the flop and outputted to the PicoBlaze decoder (which selects what data is going to the In_Port of the PicoBlaze) I also made sure that my Parity Error logic was correctly detecting a parity error by assigning the wrong parity to my byte of data. The 8O1 format should have an odd parity value of 0, but I gave the parity value a value of 1. As expected, The PARITY_ERR status flag was set high and sent to the PicoBlaze decoder.    
     
I also made sure that all of my signals were changing correctly and that there were no surprises between the different states in my Receive Engine State Machine. This sums up what I did to verify the correctness of my Receive Engine.    
     
Note that I did not make a top level test bench for this project due to the sheer amount of transmits that I have to make for displaying the banner (it is a lot of characters!). Also, it is difficult to simulate the PicoBlaze receiving data because there is no terminal to display data through. This sums up how I verified the correctness of my Receive Engine.    
     
     
Chip Level Test:     
For the Chip Level test, I downloaded the project to a Nexys 2 board and confirmed the correctness of my design. I did this by opening up a terminal window and then making sure that all of the UART communication data was similar. I then pushed reset on the Nexys 2 board and this initialized the system. I then observed the banner being displayed on the terminal window and the command prompt being displayed as well. I then entered different characters on my keyboard and observed them being echoed onto the terminal (or performing the appropriate actions based on the chip requirements).     
     
After verifying the different character inputs and making sure that they accurately processed by the PicoBlaze, I then concluded that everything worked exactly as it was expected to.     



// Taken reference from: https://nandland.com/uart-serial-port-module/

module uart_tx 
  #(parameter FREQUENCY = 10000000, parameter BAUD_RATE = 9600)
  (
   input       clk,
   input       reset,
   input       tx_dv,
   input [7:0] tx_byte, 
   output      tx_active,
   output reg  tx_serial,
   output      tx_done
   );
  
  parameter s_IDLE         = 3'b000;
  parameter s_TX_START_BIT = 3'b001;
  parameter s_TX_DATA_BITS = 3'b010;
  parameter s_TX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;

  parameter CLKS_PER_BIT = FREQUENCY/(16*BAUD_RATE);
   
  reg [2:0]    r_SM_Main     = 0;
  reg [7:0]    r_Clock_Count = 0;
  reg [2:0]    r_Bit_Index   = 0;
  reg [7:0]    r_Tx_Data     = 0;
  reg          r_Tx_Done     = 0;
  reg          r_Tx_Active   = 0;

  always@(posedge clk) begin
    if(reset) begin
        r_SM_Main <= s_IDLE;
    end
  end
     
  always @(posedge clk) begin
       
      case (r_SM_Main)
        s_IDLE :
          begin
            tx_serial   <= 1'b1;         // Drive Line High for Idle
            r_Tx_Done     <= 1'b0;
            r_Clock_Count <= 0;
            r_Bit_Index   <= 0;
             
            if (tx_dv == 1'b1) begin
                r_Tx_Active <= 1'b1;
                r_Tx_Data   <= tx_byte;
                r_SM_Main   <= s_TX_START_BIT;
            end
            else
              r_SM_Main <= s_IDLE;
          end // case: s_IDLE
         
         
        // Send out Start Bit. Start bit = 0
        s_TX_START_BIT :
          begin
            tx_serial <= 1'b0;
             
            // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1) begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_START_BIT;
            end
            else begin
                r_Clock_Count <= 0;
                r_SM_Main     <= s_TX_DATA_BITS;
            end
          end // case: s_TX_START_BIT
         
         
        // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
        s_TX_DATA_BITS :
          begin
            tx_serial <= r_Tx_Data[r_Bit_Index];
             
            if (r_Clock_Count < CLKS_PER_BIT-1) begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_DATA_BITS;
            end
            else begin
                r_Clock_Count <= 0;
                 
                // Check if we have sent out all bits
                if (r_Bit_Index < 7)
                  begin
                    r_Bit_Index <= r_Bit_Index + 1;
                    r_SM_Main   <= s_TX_DATA_BITS;
                  end
                else
                  begin
                    r_Bit_Index <= 0;
                    r_SM_Main   <= s_TX_STOP_BIT;
                  end
            end
          end // case: s_TX_DATA_BITS
         
         
        // Send out Stop bit.  Stop bit = 1
        s_TX_STOP_BIT :
          begin
            tx_serial <= 1'b1;
             
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1) begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_TX_STOP_BIT;
            end
            else begin
                r_Tx_Done     <= 1'b1;
                r_Clock_Count <= 0;
                r_SM_Main     <= s_CLEANUP;
                r_Tx_Active   <= 1'b0;
            end
          end // case: s_Tx_STOP_BIT
         
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
            r_Tx_Done <= 1'b1;
            r_SM_Main <= s_IDLE;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
         
      endcase
    end
 
  assign tx_active = r_Tx_Active;
  assign tx_done   = r_Tx_Done;
   
endmodule

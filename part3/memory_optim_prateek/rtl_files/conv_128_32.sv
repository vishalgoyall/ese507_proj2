//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 2 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description: This is the top level module for convolution of X (128) and F (32)
// Input X memory and Output overlapped in execution
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module conv_128_32 #(parameter DATA_WIDTH_X = 8, parameter DATA_WIDTH_F = 8, parameter X_SIZE = 128, parameter F_SIZE = 32, parameter ACC_SIZE = 21) (
	input clk, 
	input reset, 
	input s_valid_x, 
	input s_valid_f, 
	input m_ready_y,
	input signed [DATA_WIDTH_X-1:0] s_data_in_x, 
	input signed [DATA_WIDTH_F-1:0] s_data_in_f, 
	output logic s_ready_f, 
	output logic s_ready_x,
	output logic m_valid_y, 
	output logic signed [ACC_SIZE-1:0] m_data_out_y
);

//logic and parameter declarations
localparam X_MEM_ADDR_WIDTH = $clog2(X_SIZE);  //bus width for x mem addr
localparam F_MEM_ADDR_WIDTH = $clog2(F_SIZE);  //bus width for f mem addr

logic xmem_full;
logic xmem_wr_en;
logic signed [DATA_WIDTH_X-1:0] xmem_data [F_SIZE-1:0];

logic fmem_full;
logic [F_MEM_ADDR_WIDTH-1 :0] fmem_addr;
logic fmem_wr_en;
logic fmem_reset;
logic signed [DATA_WIDTH_F-1:0] fmem_data [F_SIZE-1:0];

logic conv_start;
logic conv_done;

logic signed [DATA_WIDTH_X+DATA_WIDTH_F-1:0] x_mult_f [F_SIZE-1:0];
logic signed [ACC_SIZE-1:0] accum_in [F_SIZE-1:0];


//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Control Module to 
// 1. write data from Master to Slave using AXI
// 2. generate m_valid signal for output
// 3. allows overlap between xmem input and y output
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //ctrl module instantiation
  ctrl_xmem_plus_output #(.X_MEM_ADDR_WIDTH(X_MEM_ADDR_WIDTH), .X_SIZE(X_SIZE), .F_SIZE(F_SIZE)) ctrl_inst (
	  .clk               (clk),  
	  .reset             (reset),
	  .conv_done         (conv_done),
	  .s_valid           (s_valid_x),
	  .s_ready           (s_ready_x),
	  .conv_start        (conv_start),
	  .m_valid           (m_valid_y),
	  .xmem_full         (xmem_full),
	  .m_ready           (m_ready_y),
	  .xmem_wr_en        (xmem_wr_en)
  );

  
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// X_MEM instantiation
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
 x_memory #(.WIDTH(DATA_WIDTH_X), .SIZE(F_SIZE),  .LOGSIZE(F_MEM_ADDR_WIDTH)) xmem_inst (
          .clk        (clk),
          .data_in    (s_data_in_x),
          .data_out   (xmem_data),
          .wr_en      (xmem_wr_en)
   );

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Control Module to write data from Master into  F_MEM using AXI
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //Reset generation. 
  //Conv_done is a one cycle pulse generated after convolution is complete
  assign fmem_reset = reset || conv_done;   
   
  //ctrl module instantiation
  ctrl_mem_write #(.MEM_ADDR_WIDTH(F_MEM_ADDR_WIDTH), .MEM_SIZE(F_SIZE)) ctrl_fmem_write_inst (
	  .clk               (clk),  
	  .reset             (fmem_reset),
	  .s_valid           (s_valid_f),
	  .s_ready           (s_ready_f),
	  .mem_addr          (fmem_addr),
	  .en_ext_ctrl       (conv_start),
	  .mem_wr_en         (fmem_wr_en)
  );

  assign fmem_full = ~s_ready_f;
  
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// F_MEM instantiation
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  memory #(.WIDTH(DATA_WIDTH_F), .SIZE(F_SIZE),  .LOGSIZE(F_MEM_ADDR_WIDTH)) fmem_inst (
          .clk        (clk),
          .data_in    (s_data_in_f),
          .data_out   (fmem_data),
          .addr       (fmem_addr),
          .wr_en      (fmem_wr_en)
   );

 assign conv_start = xmem_full && fmem_full;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Arithmetic unit
// Fixed multiplier connections and Adder Connections
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

   genvar i;
   generate for(i=0; i<F_SIZE; i++) begin : multiplier
	assign x_mult_f[i] = xmem_data[i]*fmem_data[i];  
   end
   endgenerate

   // Logic to add down x_mult_f[n] for all n
   integer j;
   always_comb begin
	  for(j=0; j<F_SIZE; j++) begin
		  if (j == 0)
			  accum_in[0] = signed'({{(ACC_SIZE-DATA_WIDTH_X-DATA_WIDTH_F){x_mult_f[0][$left(x_mult_f[0])]}} , x_mult_f[0]});
		  else
			  accum_in[j] = accum_in[j-1] + signed'({{(ACC_SIZE-DATA_WIDTH_X-DATA_WIDTH_F){x_mult_f[j][$left(x_mult_f[j])]}} , x_mult_f[j]});
	  end
   end
  
assign m_data_out_y = accum_in[F_SIZE-1];

endmodule


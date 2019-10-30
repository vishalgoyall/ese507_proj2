//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 2 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description: This is the top level module for convolution of X (128) and F (32)
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
localparam logic [F_MEM_ADDR_WIDTH-1:0] load_faddr_val = 0;

logic xmem_full;
logic [X_MEM_ADDR_WIDTH-1:0] xmem_addr;
logic xmem_wr_en;
logic xmem_reset;
logic [X_MEM_ADDR_WIDTH-1:0] load_xaddr_val;
logic signed [DATA_WIDTH_X-1:0] xmem_data [X_SIZE-1:0];

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
// Control Module to write data from Master into  X MEM using AXI
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  //Reset generation. 
  //Conv_done is a one cycle pulse generated after convulation is complete
  assign xmem_reset = reset || conv_done;   
  
  //ctrl module instantiation
  ctrl_mem_write #(.MEM_ADDR_WIDTH(X_MEM_ADDR_WIDTH), .MEM_SIZE(X_SIZE)) ctrl_xmem_write_inst (
	  .clk               (clk),  
	  .reset             (xmem_reset),
	  .s_valid           (s_valid_x),
	  .s_ready           (s_ready_x),
	  .mem_addr          (xmem_addr),
	  .en_ext_ctrl       (conv_start),
	  .mem_wr_en         (xmem_wr_en)
  );

  assign xmem_full = ~s_ready_x;
  
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// X_MEM instantiation
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  memory #(.WIDTH(DATA_WIDTH_X), .SIZE(X_SIZE),  .LOGSIZE(X_MEM_ADDR_WIDTH)) xmem_inst (
          .clk        (clk),
          .data_in    (s_data_in_x),
          .data_out   (xmem_data),
          .addr       (xmem_addr),
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

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Control Module for Convulation and AXI on output with master
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
 assign conv_start = xmem_full && fmem_full;

  ctrl_conv_output #(.F_MEM_SIZE(F_SIZE), .X_MEM_SIZE(X_SIZE), .X_MEM_ADDR_WIDTH(X_MEM_ADDR_WIDTH), .F_MEM_ADDR_WIDTH(F_MEM_ADDR_WIDTH))
  ctrl_conv_output_inst (
          .clk             (clk),
	  .reset           (reset),
	  .conv_start      (conv_start),
	  .conv_done       (conv_done),
	  .load_xaddr_val  (load_xaddr_val),
	  .m_ready_y       (m_ready_y),
	  .m_valid_y       (m_valid_y)
  );

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// MAC unit of design
// It uses signals coming from control convolution module to accumulate and reset
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// multiply xmem data with f mem data
// in case of parallel execution, getting values from different memory locations at the same time

   genvar i;
   generate for(i=0; i<F_SIZE; i++) begin : multiplier
	assign x_mult_f[i] = xmem_data[i+load_xaddr_val]*fmem_data[i];  
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


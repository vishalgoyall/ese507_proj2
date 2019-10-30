//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 2 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
// Description: This is the top level module for convolution of X (128) and F (32)
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module conv_128_32 
#(      parameter DATA_WIDTH_X = 8, 
	parameter DATA_WIDTH_F = 8, 
	parameter X_SIZE = 128, 
	parameter F_SIZE = 32, 
	parameter PLINE_STAGES = 5,
	parameter ACC_SIZE = 21
)(
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
parameter X_MEM_ADDR_WIDTH = $clog2(X_SIZE);  //bus width for x mem addr
parameter F_MEM_ADDR_WIDTH = $clog2(F_SIZE);  //bus width for f mem addr
parameter logic [F_MEM_ADDR_WIDTH-1:0] load_faddr_val = 0;

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

logic en_pline_stages;

logic signed [DATA_WIDTH_X+DATA_WIDTH_F-1:0] x_mult_f_int [F_SIZE-1:0];
logic signed [DATA_WIDTH_X+DATA_WIDTH_F-1:0] x_mult_f [F_SIZE-1:0];

logic signed [ACC_SIZE-1:0] adder_stage1 [(F_SIZE>>1)-1:0];
logic signed [ACC_SIZE-1:0] adder_stage2 [(F_SIZE>>2)-1:0];
logic signed [ACC_SIZE-1:0] adder_stage3 [(F_SIZE>>3)-1:0];
logic signed [ACC_SIZE-1:0] adder_stage4 [(F_SIZE>>4)-1:0];


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

  ctrl_conv_output #(.F_MEM_SIZE(F_SIZE), 
	             .X_MEM_SIZE(X_SIZE), 
	             .X_MEM_ADDR_WIDTH(X_MEM_ADDR_WIDTH), 
	             .F_MEM_ADDR_WIDTH(F_MEM_ADDR_WIDTH), 
	             .PLINE_STAGES(PLINE_STAGES))
  ctrl_conv_output_inst (
          .clk             (clk),
	  .reset           (reset),
	  .conv_start      (conv_start),
	  .conv_done       (conv_done),
	  .load_xaddr_val  (load_xaddr_val),
	  .m_ready_y       (m_ready_y),
	  .en_pline_stages (en_pline_stages),
	  .m_valid_y       (m_valid_y)
  );

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Arithmetic Unit of Design
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

// Multiplying XMEM and FMEM data
// For parallel execution, getting values from different memory locations at the same time
// Pipelining added after multiplier stage

   logic reset_pline;
   assign reset_pline = (!conv_start || conv_done || reset);

   genvar i;
   generate for(i=0; i<F_SIZE; i++) begin : multiplier
	assign x_mult_f_int[i] = xmem_data[i+load_xaddr_val]*fmem_data[i];  

	always @(posedge clk)  begin 
		if (reset_pline) begin
			x_mult_f[i] <= 0; 
		end 
		else begin
			if (en_pline_stages)
			x_mult_f[i] <= x_mult_f_int[i];
		end
	end
   end
   endgenerate

   //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   // Adding adder logic and relevant pipelining stages
   
   //Stage 1
   genvar j;
   generate for(j=0; j<F_SIZE>>1; j=j+1) begin : adder_stage_1
	   always @ (posedge clk) begin
		   if (reset_pline)
			   adder_stage1[j] <= 0;
		   else
			   if (en_pline_stages)
			   adder_stage1[j] <=  signed'({{(ACC_SIZE-DATA_WIDTH_X-DATA_WIDTH_F){x_mult_f[2*j][$left(x_mult_f[2*j])]}} , x_mult_f[2*j]}) + 
		                               signed'({{(ACC_SIZE-DATA_WIDTH_X-DATA_WIDTH_F){x_mult_f[2*j+1][$left(x_mult_f[2*j+1])]}} , x_mult_f[2*j+1]}); 
	   end
   end
   endgenerate
 
   //Stage 2
   generate for(j=0; j<F_SIZE>>2; j=j+1) begin : adder_stage_2
	   always @ (posedge clk) begin
		   if (reset_pline == 1'b1)
			   adder_stage2[j] <= 0;
		   else
			   if (en_pline_stages)
			   adder_stage2[j] <= adder_stage1[2*j] + adder_stage1[2*j+1]; 
	   end
   end
   endgenerate

   //Stage 3
   generate for(j=0; j<F_SIZE>>3; j=j+1) begin : adder_stage_3
	   always @ (posedge clk) begin
		   if (reset_pline == 1'b1)
			   adder_stage3[j] <= 0;
		   else
			   if (en_pline_stages)
			   adder_stage3[j] <= adder_stage2[2*j] + adder_stage2[2*j+1]; 
	   end
   end
   endgenerate

   //Stage 4
   generate for(j=0; j<F_SIZE>>4; j=j+1) begin : adder_stage_4
	   always @ (posedge clk) begin
		   if (reset_pline == 1'b1)
			   adder_stage4[j] <= 0;
		   else
			   if(en_pline_stages)
			   adder_stage4[j] <= adder_stage3[2*j] + adder_stage3[2*j+1]; 
	   end
   end
   endgenerate


//Final output data stage from final set of adders 
assign m_data_out_y = adder_stage4[0] + adder_stage4[1];

endmodule


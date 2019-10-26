//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ESE 507 : Project 1 (Convolution)
// Authors : Prateek Jain and Vishal Goyal
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module conv_8_4 #(parameter DATA_WIDTH_X = 8, parameter DATA_WIDTH_F = 8, parameter X_SIZE = 8, parameter F_SIZE = 4) (
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
	output logic signed [DATA_WIDTH_X+DATA_WIDTH_F+1:0] m_data_out_y
);

//logic and parameter declarations
parameter X_MEM_ADDR_WIDTH = $clog2(X_SIZE);  //bus width for x mem addr
parameter F_MEM_ADDR_WIDTH = $clog2(F_SIZE);  //bus width for f mem addr

logic xmem_full;
logic xmem_addr_wr_ctrl;
logic xmem_addr_rd_ctrl;
logic [X_MEM_ADDR_WIDTH-1:0] xmem_addr;
logic xmem_wr_en;
logic xmem_reset;
logic [X_MEM_ADDR_WIDTH-1:0] load_xaddr_val;
logic signed [DATA_WIDTH_X-1:0] xmem_data;

logic fmem_full;
logic fmem_addr_wr_ctrl;
logic fmem_addr_rd_ctrl;
logic [F_MEM_ADDR_WIDTH-1 :0] fmem_addr;
logic fmem_wr_en;
logic fmem_reset;
logic signed [DATA_WIDTH_F-1:0] fmem_data;

logic conv_start;
logic conv_done;

logic signed [DATA_WIDTH_X+DATA_WIDTH_F-1:0] x_mult_f;
logic signed [DATA_WIDTH_X+DATA_WIDTH_F+1:0] accum_in;
logic signed [DATA_WIDTH_X+DATA_WIDTH_F+1:0] accum_out;


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
	  .ext_load_addr     (load_xaddr),
	  .ext_load_addr_val (load_xaddr_val),
	  .ext_incr_addr     (en_xaddr_incr),
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
   
  parameter logic [F_MEM_ADDR_WIDTH-1:0] load_faddr_val = 0;
  //ctrl module instantiation
  ctrl_mem_write #(.MEM_ADDR_WIDTH(F_MEM_ADDR_WIDTH), .MEM_SIZE(F_SIZE)) ctrl_fmem_write_inst (
	  .clk               (clk),  
	  .reset             (fmem_reset),
	  .s_valid           (s_valid_f),
	  .s_ready           (s_ready_f),
	  .mem_addr          (fmem_addr),
	  .en_ext_ctrl       (conv_start),
	  .ext_load_addr     (load_faddr),
	  .ext_load_addr_val (load_faddr_val),
	  .ext_incr_addr     (en_faddr_incr),
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
	  .load_xaddr      (load_xaddr),
	  .en_xaddr_incr   (en_xaddr_incr),
	  .load_faddr      (load_faddr),
	  .en_faddr_incr   (en_faddr_incr),
	  .load_xaddr_val  (load_xaddr_val),
	  .reset_accum     (reset_accum),
	  .en_accum        (en_accum),
	  .fmem_addr       (fmem_addr),
	  .m_ready_y       (m_ready_y),
	  .m_valid_y       (m_valid_y)
  );

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// MAC unit of design
// It uses signals coming from control convolution module to accumulate and reset
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
assign x_mult_f = xmem_data*fmem_data;  //multiply xmem data with f mem data
assign accum_in = accum_out + {{2{x_mult_f[$left(x_mult_f)]}} , x_mult_f};  //sign extending multiplier output to match adder dimensions

always_ff @(posedge clk) begin
	if (reset == 1'b1 || reset_accum == 1'b1) begin
		accum_out = 0;
	end
	else if (en_accum == 1'b1) begin
		accum_out = accum_in;
	end
end

assign m_data_out_y = accum_out;   //send output data from accumulator output


endmodule


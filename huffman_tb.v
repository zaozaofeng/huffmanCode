/* test bench */
`timescale 1ns / 1ns

module Huffman_tb;

  // Inputs
	reg clock;
	reg [2:0] data_in;
	reg data_enable;

	// Outputs
    wire [bit_width:0]data_out_symbol,    //输出-符号
    wire [3:0]data_out_length,        //输出-码长
    wire [bit_width:0]data_out_code,  //输出-码字

    wire data_out_state,
   
	integer i,handle;
	integer seed = 1;
	
	// Instantiate the Unit Under Test (UUT)
	Huffman_encoder #(2,8,20) uut (
		.clock(clock), 
		.data_in(data_in), 
		.data_enable(data_enable), 
		.data_out_symbol(data_out_symbol), 
		.data_out_length(data_out_length), 
		.data_out_code(data_out_code),
        .data_out_state(data_out_state)
	);


	initial begin 
	forever #10 clock = ~clock;
	end
	
	initial begin
		// Initialize Inputs
		
		$log("verilog.log");
		clock = 0;
		data_in = 0;
		data_enable = 0;
		
		handle = $fopen ("Output.txt");
		handle = handle | 1;
		
		$fmonitor(1,"clock:",clock,"data_enable:", data_enable,"data_in:%b",data_in," data_out_state:",data_out_state,"  
         data_out_code: %b",data_out_code,"data_out_symbol:%b",data_out_symbol);
		
		for(i=0;i<22;i=i+1) begin 
				#20 data_enable=1;
				data_in = $random(seed);
		end
		
		#10
		data_in = 'bz;
		data_enable = 0;
		
		#2100;
		$finish;
		$fclose(handle);

	end
      
endmodule

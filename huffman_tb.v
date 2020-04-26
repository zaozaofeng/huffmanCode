/* test bench */
`timescale 1ns / 1ns

module Huffman_tb;

  // Inputs
	reg clock;
	reg [7:0] data_in;
	reg data_enable;

	reg [8:0]data[99:0];
	reg [7:0]reg1,reg2,reg3 = 8'b0;
	integer count = 0;

	// Outputs
    wire [7:0]data_out_symbol;    //输出-符号
    wire [3:0]data_out_length;        //输出-码长
    wire [7:0]data_out_code;  //输出-码字
	wire [2:0]out_state;

    wire data_out_state;
   
	integer i,handle;
	integer seed = 1;

	integer fp_r;
	integer fp_w;
	
	// Instantiate the Unit Under Test (UUT)
	Huffman_encoder #(7,255,1024) uut (
		.clock(clock), 
		.data_in(data_in), 
		.data_enable(data_enable), 
		.data_out_symbol(data_out_symbol), 
		.data_out_length(data_out_length), 
		.data_out_code(data_out_code),
        .data_out_state(data_out_state),
		.out_state(out_state)
		//.fp_r(fp_r)
	);


	initial begin 
	forever #10 clock = ~clock;
	end
	
	initial begin
		// Initialize Inputs
		
		//$log("verilog.log");
		clock = 0;
		data_in = 0;
		data_enable = 0;
		
		
		//handle = $fopen ("Output.txt");
		//handle = handle | 1;
		//$readmemh("TEST.txt",data);
	//	for(i=0;i<18;i=i+1)begin
		//	$display("i=%d",i,"		data=%b",data[i]);
	//	end
		fp_r=$fopen("TEST4.txt","r");//以读的方式打开文件
		//fp_w=$fopen("data_out2.dat","w");//以写的方式打开文件

		//$display("fp_r=",fp_r,"fp_w=",fp_w);
		//	while(! $feof(fp_r))begin
					//$fscanf(fp_r,"%h" ,reg1) ;//每次读一行
					//$display("::::%b",reg1) ;//打印输出
					//$fwrite(fp_w,"%h",reg1,) ;//写入文件
		//			reg1 = $fgetc(fp_r);
					//$display("reg1=%b",reg1);
		//			if(reg1 != 8'b11111111)begin
		//			$display("char = %c",reg1,"	b=%b",reg1);
		//			$fwrite(fp_w,"%c",reg1);//ascii
		//			end
					
					//$fwrite(fp_w,"%b",reg1);


		//	end
			//$fclose(fp_r);//关闭已打开的文件
			//$fclose(fp_w);

		
		$fmonitor(1,"clock:",clock,"  data_enable:", data_enable,"  data_in:%b",data_in,"  data_out_state:",data_out_state,"  data_out_code: %b",data_out_code,"  data_out_symbol:%b",data_out_symbol);
		
		/*for(i=0;i<22;i=i+1) begin 
				#20 data_enable=1;
				//data_in = $random(seed);
				reg1 = $fgetc(fp_r);
				$display("reg1=%b",reg1);
				if(reg1 != 8'b11111111)begin
					data_in = reg1;
				end
		end
		*/
		while(! $feof(fp_r))begin
			#20 data_enable=1;
			reg1 = $fgetc(fp_r);
			if(reg1 != 8'b11111111)begin
				$display("char = %c",reg1,"	b=%b",reg1,"	ascii=%d",reg1);

				data_in = reg1;
			end
		end
		
		#10
		data_in = 'bz;
		data_enable = 0;
		
		#5000;
		$finish;
		$fclose(handle);

	end
      
endmodule


//状态值
`define INIT 3'b111 //初始化
`define FREQ_COUNT 3'b000  	//频次统计
`define BUILD_TREE 3'b001	//构建哈夫曼树
`define GEN_CODE 3'b010	//由哈夫曼树获得编码表

//压缩后文件头格式：符号+码长+码字
`define SEND_SYMBOLS 3'b011	//发送符号
`define SEND_CODE 3'b100	//发送编码
`define SEND_LENGTH 3'b101	//发送长度


module huff_encoder(
			input wire clock,//时钟
			input wire [bit_width:0]data_in,//从其他模块输入至此的数据
			input wire data_enable,	//置高才可接收数据

            input wire rst,//重置信号

			output reg [2*bit_width+2:0]data_out,//本模块的输出数据
			
			);	

						
parameter bit_width = 7;//每个符号的位宽
parameter max_symbol = 255;//符号上限数
parameter length_of_Data = 100;//数据长度

reg [2:0]state = `INIT;	//当前状态值

reg [bit_width:0]symbol_list[max_symbol:0];//符号表
integer symbol_count = 0;//符号数
reg [bit_width:0]freq_list[max_symbol:0];//频次表
reg [bit_width:0]symbol_list_index = 'b0;	//符号表指针

reg [bit_width:0]data[length_of_Data:0];//数据寄存器

//哈夫曼树结构体存储
reg [bit_width:0]huffmantree_node_symbol[max_symbol*2 : 0]//节点-符号
reg [bit_width:0]huffmantree_node_lchild[max_symbol*2 : 0]//节点-左子
reg [bit_width:0]huffmantree_node_rchild[max_symbol*2 : 0]//节点-右子
reg [bit_width:0]huffmantree_node_parent[max_symbol*2 : 0]//节点-父
reg [bit_width:0]huffmantree_node_weight[max_symbol*2 : 0]//节点-权重



reg [bit_width:0]sym,temp1,temp2;//临时存放变量

reg [0:2*bit_width+2]code_list[max_symbol:0];//码字表
reg [bit_width:0]code_length[max_symbol:0];//码长表


integer step = 0;								//Number of steps of tree building algorithm	构建哈夫曼树所用步数
reg [bit_width:0]pos,newpos = 0;				//Variables to hold values of positions in pair table


integer i= 32'h0;	
integer j= 32'h0;
integer k= 32'h0;//循环变量

reg flag_exist = 0;//当前符号是否存在于表中的标志位 1=存在 0=不存在
integer pair_count= 0;


always @(posedge clock) begin

	case(state)
	
	//进行初始化
	`INIT: begin
    //各表初始化
	for(j=0;j<max_symbol;j=j+1) begin
	code_list[j] = 'bz;
	freq_list[j] = 'b0;
	symbol_list[j] = 'bz;
	code_length[j] = 'b0;

    huffmantree_node_symbol[j] = 'b0;
    huffmantree_node_lchild[j] = 'b0;
    huffmantree_node_rchild[j] = 'b0;
    huffmantree_node_parent[j] = 'b0;
    huffmantree_node_weight[j] = 'b0;
	end
	
	
	data_out = 'bz;
	state = `FREQ_COUNT;//切换状态至频次统计
	end
	
	
	`FREQ_COUNT: begin
	if(data_enable) begin
		data[i] = data_in;
		i=i+1'b1;
		
			for(j=0;j<=max_symbol; j=j+1) begin
				if(data_in == symbol_list[j]) begin
                    //在表中寻得相同符号记录时，频次加1
					freq_list[j] = freq_list[j] + 1;
					flag_exist=1;
				end	//End of if 
			end		//End of for loop
			
			//如果表中不存在此符号的记录
			if(!flag_exist) begin
				symbol_list[symbol_list_index] = data_in;

				freq_list[symbol_list_index] = 'b1;
				symbol_list_index = symbo l_list_index + 1;
			end		
			
			flag_exist = 0;
			
		if(i == length_of_Data)	begin	
		state = `BUILD_TREE;
		symbol_count = symbol_list_index;
		//$display("symbol_list_index:",symbol_list_index);
		//for(i=0;i<symbol_length;i=i+1)
		
		symbol_list_index = symbol_list_index -1 ;
		end
	end
	end
	
	
	`BUILD_TREE: begin
    //对符号频次进行冒泡排序
    for(i=0;i<=symbol_count;i++)begin
        for(j=0;j<=symbol_count-i-1;j++)begin
            if(freq_list[j] > freq_list[j+1])begin
                temp1 = freq_list[j];
                temp2 = symbol_list[j];
                freq_list[j+1] = freq_list[j];
                symbol_list[j+1] = symbol_list[j];
                freq_list[j] = temp1;
                symbol_list[j] = temp2;
            end
        end
    end
    //for(i=0;i<symbol_count;i=i+1)
    //$display("symbol_list:",symbol_list[i]);

    //
    for(i=1;i<=symbol_count+1;i++)begin
        huffmantree_node_symbol[i] = symbol_list[i];
        huffmantree_node_weight[i] = freq_list[i];
    end
    //for(i=1;i<symbol_count+1;i=i+1)
    //$display("huffmantree node :",huffmantree_node_symbol[i]);
		
    
	end
	
	
	`GEN_CODE: begin
		
	end

    `SEND_SYMBOLS: begin
	
	end
	`SEND_LENGTH: begin
	
	end
	
	`SEND_CODE: begin
	
	end
	
	
	
	endcase
end



endmodule
		

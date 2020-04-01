
//各种状态的宏定义
`define INIT 3'b000 //初始化0
`define FREQ_COUNT 3'b001  	//频次统计1
`define SORT 3'b010//排序2
`define BUILD_TREE 3'b011	//构建哈夫曼树3
`define GEN_CODE 3'b100	//由哈夫曼树获得编码表4

//压缩后文件头格式：符号8bit+码长3bit+码字1-8bit
//`define SEND_SYMBOLS 3'b101//发送符号
`define SEND_CODE 3'b110	//发送编码6
`define IDLE 3'b111 //休息状态
//`define SEND_LENGTH 3'b111	//发送长度


module Huffman_encoder(
			input wire clock,//时钟
			input wire [bit_width:0]data_in,//从其他模块输入至此的数据
			input wire data_enable,	//置高才可接收数据

            input wire rst,//重置信号
            
            //本模块的输出数据
			output reg [bit_width:0]data_out_symbol,    //输出-符号
            output reg [3:0]data_out_length,        //输出-码长
            output reg [2*bit_width+2:0]data_out_code,  //输出-码字
            output reg data_out_state,//输出状态位。当开始输出符号码长码字时会被置高
			output reg[2:0]out_state //debug用，用于观察state的变化情况
			);	

						
parameter bit_width = 7;//每个符号的位宽
parameter max_symbol = 255;//符号上限数
parameter length_of_Data = 100;//数据长度

reg [2:0]state = `INIT;	//当前状态值

reg [bit_width:0]symbol_list[max_symbol:0];//符号表
integer symbol_count = 0;//符号数
reg [9:0]freq_list[max_symbol:0];//频次表
reg [255:0]symbol_list_index = 'b0;	//符号表指针

reg [bit_width:0]data[length_of_Data:0];//数据寄存器

//  哈夫曼树结构体存储。从OOP的角度看每个哈夫曼树的节点（node）都是个包含符号、左孩子、右孩子、父亲、权重
//等属性的对象。受限于verilog特性，此处用几个不同的memory型来表示对象中的不同属性。
reg [bit_width:0]huffmantree_node_symbol[max_symbol*2 : 0];//节点-符号
reg [bit_width+1:0]huffmantree_node_lchild[max_symbol*2 : 0];//节点-左子（存储的是数组下标的值，下同）
reg [bit_width+1:0]huffmantree_node_rchild[max_symbol*2 : 0];//节点-右子
reg [bit_width+1:0]huffmantree_node_parent[max_symbol*2 : 0];//节点-父
reg [9:0]huffmantree_node_weight[max_symbol*2 : 0];//节点-权重
reg huffmantree_node_tag[max_symbol*2 : 0];//节点-是否已被添加进树中

//reg [bit_width+1:0]min1,min2;//最小的两个
integer min1,min2;  //构建哈夫曼树时每次选取的最小两项

reg [bit_width:0]sym,temp1,temp2;       //临时存放变量

reg [2*bit_width+2:0]code_list[max_symbol:0];   //码字表
reg [bit_width:0]code_length[max_symbol:0]; //码长表

reg [bit_width+1:0]temp_parent,temp_child;  //生成哈夫曼代码时用到的临时变量

integer i= 32'h0;	
integer j= 32'h0;
integer k= 32'h0;//循环变量

reg flag_exist = 0;//当前符号是否存在于表中的标志位 1=存在 0=不存在



always @(posedge clock) begin

	case(state)
	
	//进行初始化
	`INIT: begin
    //各表初始化
	for(j=0;j<max_symbol;j=j+1) begin
	code_list[j] = 'bx;
	freq_list[j] = 'b0;
	symbol_list[j] = 'bz;
	code_length[j] = 'b0;

    huffmantree_node_symbol[j] = 'b0;
    huffmantree_node_lchild[j] = 'b0;
    huffmantree_node_rchild[j] = 'b0;
    huffmantree_node_parent[j] = 'b0;
    huffmantree_node_weight[j] = 'b0;
    huffmantree_node_tag[j] = 1'b0;
	end
	
	data_out_symbol='bz;   //输出-符号
    data_out_length='bz;        //输出-码长
    data_out_code='bz;  //输出-码字
	data_out_state = 'b0;
	state = `FREQ_COUNT;//切换状态至频次统计
    out_state = state;//debug用，将当前状态（state)输出
	end
	
	
	`FREQ_COUNT: begin
    //频次统计
	if(data_enable) begin   //仅当此位为高时进行数据输入&统计
		data[i] = data_in;
		i=i+1'b1;
		
			for(j=0;j<=max_symbol; j=j+1) begin
				if(data_in == symbol_list[j]) begin
                    //在表中寻得相同符号记录时，频次加1
					freq_list[j] = freq_list[j] + 1;
					flag_exist=1;   //此符号在表中已存在
				end	//End of if 
			end		//End of for loop
			
			//如果表中不存在此符号的记录
			if(!flag_exist) begin
				symbol_list[symbol_list_index] = data_in;

				freq_list[symbol_list_index] = 'b1;
				symbol_list_index = symbol_list_index + 1;
			end		
			
			flag_exist = 0; //重制标志位
			
		symbol_count = symbol_list_index;   //更新已有符号个数
		
		
		

	end
    else begin  //data_enable为低时，结束频次统计
        state = `SORT;  //进入排序阶段
        out_state = state;
        //debug用：
        $display("symbol_list_index:",symbol_list_index);
		for(i=0;i<symbol_count;i=i+1)begin
        $display("i=",i,"  symbol_list:",symbol_list[i],"  freq_list:",freq_list[i]); end
    end
	end
	
	
    `SORT :begin
    //对符号频次进行冒泡排序
    

    for(i=0;i<symbol_count;i=i+1)begin
        for(j=0;j<symbol_count-i-1;j=j+1)begin
            if(freq_list[j] < freq_list[j+1])begin
                temp1 = freq_list[j+1];
                temp2 = symbol_list[j+1];
                freq_list[j+1] = freq_list[j];
                symbol_list[j+1] = symbol_list[j];
                freq_list[j] = temp1;
                symbol_list[j] = temp2;
            end
        end
    end
    //debug用：
    for(i=0;i<symbol_count;i=i+1)
    $display("symbol:",symbol_list[i],"  freq:",freq_list[i]);

    //将排序后的符号、频次（权重）同步至哈夫曼节点数组中
    //注意i从1开始，哈夫曼节点数组的第0位闲置
    for(i=1;i<symbol_count+1;i=i+1)begin
        huffmantree_node_symbol[i] = symbol_list[i-1];
        huffmantree_node_weight[i] = freq_list[i-1];
    end
    //debug用：
    for(i=1;i<symbol_count+1;i=i+1)begin
    $display("i=",i,"  huff-symbol :",huffmantree_node_symbol[i],"   huff-weight:",huffmantree_node_weight[i]);end
    state = `BUILD_TREE;    //进入构建阶段
    out_state = state;
    huffmantree_node_weight[0] = 1023;  //
    end

	`BUILD_TREE: begin
    //构建哈夫曼树
    $display("when tree build starts,symbol_list_index=",symbol_list_index);
    //min1 = 10'd1024;
   // min2 = 10'd1024;
   min1=0;min2=0; //最小的两项（的数组下标）
    //找出最小项1
    for(i=1;i<=symbol_list_index;i=i+1)begin
        if(huffmantree_node_parent[i] == 'b0 && huffmantree_node_tag[i] != 1'b1)begin//父节点为0且tag为0
            //$display("parent!=0 && tag!=1",i);
            if(huffmantree_node_weight[i] <= huffmantree_node_weight[min1])begin
                min1 = i;
            end
        end
    end
   
    huffmantree_node_tag[min1] = 1'b1;  //标记tag，说明已被选取
    //找出最小项2
    for(i=1;i<=symbol_list_index;i=i+1)begin
        if(huffmantree_node_parent[i] == 'b0 && huffmantree_node_tag[i] != 1'b1)begin
            if(huffmantree_node_weight[i] <= huffmantree_node_weight[min2])begin
                min2 = i;
            end
        end
    end
     huffmantree_node_tag[min2] = 1'b1;

      $display("min1=",min1,"   min2=",min2);
    //$display("before +1,symbol_list_index=%d ",symbol_list_index);
    
     if(min1 != 0 && min2 != 0)begin    //成功获取到两项最小项后构建出新的哈夫曼节点进入数组
        symbol_list_index = symbol_list_index + 1'b1;//获得新下标
        //设置新节点权重
        huffmantree_node_weight[symbol_list_index] = huffmantree_node_weight[min1] + huffmantree_node_weight[min2];
         //设置新节点的左右孩子、父亲、tag
         huffmantree_node_lchild[symbol_list_index] = min1;
         huffmantree_node_rchild[symbol_list_index] = min2;
         huffmantree_node_parent[symbol_list_index] = 'b0;
         huffmantree_node_tag[symbol_list_index] = 1'b0;
        
        //最小项父节点为新节点
         huffmantree_node_parent[min1] = symbol_list_index;
         huffmantree_node_parent[min2] = symbol_list_index;
     end
     // $display("after +1,symbol_list_index=%d ",symbol_list_index);
    //组合新节点
    
	

   
	
   // if(min1 == 10'd1024 && min2 == 10'd1024)begin
    if(min1 == 0 && min2 == 0)begin //当树构建完成
       // debug用：
         for(i=0;i<=symbol_list_index;i=i+1)
         $display("i=",i,"  sym=",huffmantree_node_symbol[i],"  lchild:",
          huffmantree_node_lchild[i],"  rchild:",  huffmantree_node_rchild[i],
          "  weight:", huffmantree_node_weight[i]," parent:", huffmantree_node_parent[i]," tag:", huffmantree_node_tag[i]);
       //进入下一环节
       state = `GEN_CODE;
       out_state = state;
        i = 1;
        
    end
    end


	`GEN_CODE: begin
		//生成哈夫曼编码
            
           // $display("when gen code starts,i=" ,i);
            temp_parent = huffmantree_node_parent[i];   //获取当前哈夫曼节点的父亲（数组下标）
            temp_child = i;     //当前孩子
            while (temp_parent != 'b0) begin    //循环至父亲值为0（即循环至根节点）
                if(huffmantree_node_lchild[temp_parent] == temp_child)begin //如果当前孩子是父亲的左节点
                    //code_list[i-1] = code_list[i-1]>>1 | 'b0;
                    //code_list[i-1][2*bit_width+2 - code_length[i-1]] = 'b0;
                    code_list[i-1][code_length[i-1]] = 'b0;     //code += '0'；
                    code_length[i-1] = code_length[i-1] + 1;    //码长+1
                end else if(huffmantree_node_rchild[temp_parent] == temp_child)begin
                    //code_list[i-1] = code_list[i-1]>>1 | 'b1;
                    //code_list[i-1][2*bit_width+2 - code_length[i-1]] = 'b1;
                    code_list[i-1][code_length[i-1]] = 'b1;
                    code_length[i-1] = code_length[i-1] + 1;
                end
                temp_child = temp_parent;   
                temp_parent = huffmantree_node_parent[temp_parent];     //原来的父亲变成现在的孩子，再找到爷爷
            end
           $display("huffman code :%b", code_list[i-1]);

           i = i+1; //有请下一位（符号）

           if(i == symbol_count+1)begin //当所有符号的哈夫曼编码都已生成
                state = `SEND_CODE;out_state = state;
                i=0;
                data_out_state = 1;
           end
        
	end
	
	`SEND_CODE: begin
        //输出哈夫曼编码信息


        //debug
        if(i==0)begin
        for(i=0;i<symbol_count;i=i+1)begin
                 $display("i=%d",i," symbol:", symbol_list[i],"  length:%d",code_length[i],
                    "  code:%b",code_list[i]);
            end
        i=0;
        end

        
        if(i < symbol_count)begin
            data_out_symbol = symbol_list[i];
            data_out_length = code_length[i];
            data_out_code = code_list[i];
            // $display("symbol:", data_out_symbol,"  length:%d",data_out_length,
            // "  code:%b", data_out_code);
            i = i+1;
        end
        else begin
            data_out_state = 0;
            state = `IDLE;
        end

	
	end
	
    `IDLE:begin

    end
	
	
	endcase
end



endmodule
		

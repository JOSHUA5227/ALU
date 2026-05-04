module ALU(# parameter WIDTH = 8)(OPA,OPB,CIN,CLK,RST,CE,MODE,INP_VALID,CMD,RES,OFLOW,COUT,G,L,E,ERR);

input wire clk,rst;

input wire [WIDTH-1:0] OPA,OPB;

input wire CIN;
input wire CE;

input wire MODE;
input wire [3:0] CMD;

input wire [1:0] INP_VALID;

output reg [2*WIDTH -1:0]RES;
output reg OFLOW,COUT,G,L,E,ERR;

reg [1:0] count; // 3 bit counter
reg [4:0] current_operation; // for resetting counter


always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		RES <= 'b0;
		OFLOW <= 1'b0;
		COUT <= 1'b0;
		{G,L,E} <= 3'b0;
		ERR <= 1'b0;
	end
	else if(CE)
	begin
		case{MODE,CMD}
		5'b1_0000: 	// 0:ADD	
		5'b1_0001:	// 1:SUB	
		5'b1_0010:	// 2:ADD_CIN
		5'b1_0011:	// 3:SUB_CIN	
		5'b1_0100:	// 4:INC_A	
		5'b1_0101:	// 5:DEC_A	
		5'b1_0110:	// 6:INC_B	
		5'b1_0111:	// 7:DEC_B	
		5'b1_1000:	// 8:CMP	
		5'b1_1001:	// 9: OP 9	
		5'b1_1010:	// 10:OP 10	
		5'b1_1011:	// 11:OP 11	
		5'b1_1100:	// 12:OP 12	

		5'b0_0000: 	// 0:AND	
		5'b0_0001:	// 1:NAND	
		5'b0_0010:	// 2:OR
		5'b0_0011:	// 3:NOR	
		5'b0_0100:	// 4:XOR	
		5'b0_0101:	// 5:XNOR	
		5'b0_0110:	// 6:NOT_A
		5'b0_0111:	// 7:NOT_B	
		5'b0_1000:	// 8:SHR1_A	
		5'b0_1001:	// 9:SHL1_A	
		5'b0_1010:	// 10:SHR1_B	
		5'b0_1011:	// 11:SHL1_B	
		5'b0_1100:	// 12:ROL_A_B	
		5'b0_1101:	// 13:ROR_A_B	
	
		endcase		
	end
	else
	begin
		RES <= RES;
                OFLOW <= OFLOW;
                COUT <= COUT;
                {G,L,E} <= {G,L,E};
                ERR <= ERR;
	end
end

// storing previous operation
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		current_operation <= 5'b0;
	end
	else
		current_operation <= {CMD,MODE};
end


// counter logic
always@(posedge clk or posedge rst)
begin
	if(rst)
	begin
		count <=1'b0;
	end
	else if	(count_EN)
	begin
		else if(current_operation == {CMD,MODE})

		begin
			if(count >= 3)
				count <=1'b0;
			else
				count <= count + 1;
		end
		else
			count <= 1'b0;
	end
	else
			count <= 1'b0;
end
endmodule

`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/13 23:15:45
// Design Name: 
// Module Name: i2c_master
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_master(
	clk,
	rst_n,
	rw,
	start,
	stb,
	length,
	slave_address,
	reg_addr,
	datain,
	dataout,
	done,
	scl,
	sda
    );
input clk;
input rst_n;
input rw;
input start;
input stb;
input [4:0] length;
input [7:0] slave_address;
input [7:0] reg_addr;
input [7:0] datain;
output [7:0] dataout;
output done;
output scl;
inout sda;


parameter IDLE = 4'd0;
parameter START = 4'd1;
parameter ADDR = 4'd2;
parameter WAIT_ACK0 = 4'd3;
parameter SEND1 = 4'd4;
parameter WAIT_ACK1 = 4'd5;
parameter SEND2 = 4'd6;
parameter WAIT_ACK2 = 4'd7;
parameter START1 = 4'd8;
parameter ADDR1 = 4'd9;
parameter WAIT_ACK3 = 4'd10;
parameter RECEIVED = 4'd11;
parameter ACK = 4'd12;
parameter STOP = 4'd13;
//parameter IDLE = 4'd8;

parameter WR = 6'b000001;

parameter cnt_400k = 31;

reg [4:0] cnt;
wire cnt_done = (cnt == 5'd31)? 1'd1 : 1'd0;
wire cnt_ack = (cnt == 5'd14)? 1'd1 : 1'd0;
reg sda_oe;
reg sda_oe_tmp;
reg sda_o;
reg sda_o_tmp;
reg scl;
reg scl_tmp;
reg [7:0] dataout, dataout_reg; 
reg [4:0] cycle_cnt;
reg [4:0] cycle_cnt_tmp;
reg [3:0] cstate, nstate;
reg stp, stop_tmp;
reg [4:0] length_tmp;
reg [4:0] length_reg;
//assign length_tmp = length;
wire sda_reg;
assign sda_reg = sda;


//reg [4:0] length_reg;
reg [7:0] slave_address_reg;
reg [7:0] reg_addr_reg;
reg [7:0] datain_reg;

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		length_reg <= 5'd0;
	//end else if(stb)begin
	//end else if(cstate == 4'd1 && cnt_done && cycle_cnt == 5'd2)begin
	end else if(stb)begin
		length_reg <= length;
	end else if(cstate == ACK && cycle_cnt == 5'd1 && cnt_done)begin
		length_reg <= length_tmp;
	end else if(cstate ==4'd7 && cycle_cnt == 5'd1 && cnt_done)begin
		length_reg <= length_tmp;
	end else begin
		length_reg <= length_reg;
	end
	
end

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		slave_address_reg <= 8'd0;
		reg_addr_reg <= 8'd0;
		datain_reg <= 8'd0;
	end else if(stb)begin
		slave_address_reg <= slave_address;
		reg_addr_reg <= reg_addr;
		datain_reg <= datain;
	end else if(cstate ==4'd7 && cycle_cnt == 5'd1 && cnt_done)begin
		slave_address_reg <= slave_address;
		reg_addr_reg <= reg_addr;
		datain_reg <= datain;
	end
	
end
	

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		cnt <= 5'd0;
	end else if(stp)begin
		cnt <= 5'd0;
	end else if(start)begin
		cnt <= 5'd0;
	end else if(cnt_done)begin
		cnt <= 5'd0;
	end else begin
		cnt <= cnt + 5'd1;
	end 
end 
//fsm
always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		cstate <= IDLE;
	end else begin
		cstate <= nstate;
	end
end

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		cycle_cnt <= 5'd0;
	end else if(cnt_done)begin
		cycle_cnt <= cycle_cnt_tmp;

	end 
end 


always@(*)
begin
	case(cstate)
	
	IDLE://0
	begin
		cycle_cnt_tmp = cycle_cnt;
		scl_tmp = 1'd1;
		sda_o_tmp = 1'd1;
		sda_oe_tmp = 1'd1;

		if(start)begin
			nstate = START;
		end else begin
			nstate = IDLE;
		end 
	end
	START://1
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd1;
		if(cycle_cnt == 5'd3 && cnt_done)begin
			nstate = ADDR;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = START;
		end
		case(cycle_cnt)
			0:
			begin
				scl_tmp = 1'd1;
				sda_o_tmp = 1'd1;
			end
			1:
			begin
				scl_tmp = 1'd1;
				sda_o_tmp = 1'd0;
				stop_tmp = 1'd0;
			end
			2:
			begin
				scl_tmp = 1'd0;
				sda_o_tmp = 1'd0;
			end
			3:
			begin
				scl_tmp = 1'd0;
				sda_o_tmp = 1'd0;
			end
		endcase
	
	end
	ADDR://2
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd1;
		if(cycle_cnt == 5'd31 && cnt_done)begin
			nstate = WAIT_ACK0;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = ADDR;
		end
		case(cycle_cnt)
			0:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[7]; end
			1:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[7]; end
			2:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[7];end //sda_o_tmp = 1'd0;end
			3:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[7];end
			4:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[6];end
			5:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[6];end
			6:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[6];end
			7:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[6];end
			8:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[5];end
			9:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[5];end
			10:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[5];end
			11:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[5];end
			12:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[4];end
			13:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[4];end
			14:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[4];end
			15:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[4];end
			16:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[3];end
			17:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[3];end
			18:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[3];end
			19:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[3];end
			20:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[2];end
			21:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[2];end
			22:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[2];end
			23:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[2];end
			24:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[1];end
			25:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[1];end
			26:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[1];end
			27:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[1];end
			28:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[0];end
			29:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[0];end
			30:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[0];end
			31:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[0];end
			default:begin scl_tmp = 1'd1;sda_o_tmp = 1'd1; end
		endcase
			
	
	end
	WAIT_ACK0://3
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd0;
		if(cycle_cnt == 5'd4 && cnt_done)begin
			nstate = SEND1;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = WAIT_ACK0;
		end
		case(cycle_cnt)
			0:
			begin
				scl_tmp = 1'd0;
				//sda_o_tmp = 1'd1;
			end
			1:
			begin
				scl_tmp = 1'd1;
				//sda_o_tmp = 1'd0;
			end
			2:
			begin
				scl_tmp = 1'd1;
				//sda_o_tmp = 1'd0;
			end
			3:
			begin
				scl_tmp = 1'd0;
				//sda_o_tmp = 1'd1;
			end
		endcase
	
	end
	SEND1://4
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd1;
		if(cycle_cnt == 5'd31 && cnt_done)begin
			nstate = WAIT_ACK1;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = SEND1;
		end
		case(cycle_cnt)
			0:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[7]; end
			1:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[7]; end
			2:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[7];end
			3:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[7];end
			4:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[6];end
			5:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[6];end
			6:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[6];end
			7:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[6];end
			8:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[5];end
			9:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[5];end
			10:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[5];end
			11:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[5];end
			12:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[4];end
			13:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[4];end
			14:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[4];end
			15:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[4];end
			16:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[3];end
			17:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[3];end
			18:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[3];end
			19:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[3];end
			20:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[2];end
			21:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[2];end
			22:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[2];end
			23:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[2];end
			24:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[1];end
			25:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[1];end
			26:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[1];end
			27:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[1];end
			28:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[0];end
			29:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[0];end
			30:begin scl_tmp = 1'd1;sda_o_tmp = reg_addr_reg[0];end
			31:begin scl_tmp = 1'd0;sda_o_tmp = reg_addr_reg[0];end
			default:begin scl_tmp = 1'd1;sda_o_tmp = 1'd1; end
		endcase
			
	
	end
	WAIT_ACK1://5
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd0;
		//length_tmp = length_reg - 5'd1;
		if(cycle_cnt == 5'd4 && cnt_done && rw == 1'd0)begin
			nstate = SEND2;
			cycle_cnt_tmp = 5'd0;
		end else if(cycle_cnt == 5'd4 && cnt_done && rw == 1'd1)begin
			nstate = START1;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = WAIT_ACK1;
		end
		case(cycle_cnt)
			0:
			begin
				scl_tmp = 1'd0;
				//sda_o_tmp = 1'd1;
			end
			1:
			begin
				scl_tmp = 1'd1;
				//sda_o_tmp = 1'd0;
			end
			2:
			begin
				scl_tmp = 1'd1;
				//sda_o_tmp = 1'd0;
			end
			3:
			begin
				scl_tmp = 1'd0;
				sda_oe_tmp = 1'd0;
			end
			4:
			begin
				scl_tmp = 1'd0;
				sda_oe_tmp = 1'd0;
			end
		endcase
	
	end
	
	
	SEND2://6
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd1;
		length_tmp = length_reg - 5'd1;
		if(cycle_cnt == 5'd31 && cnt_done)begin
			nstate = WAIT_ACK2;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = SEND2;
		end
		case(cycle_cnt)
			0:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[7];end
			1:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[7]; end
			2:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[7];end
			3:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[7];end
			4:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[6];end
			5:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[6];end
			6:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[6];end
			7:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[6];end
			8:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[5];end
			9:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[5];end
			10:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[5];end
			11:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[5];end
			12:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[4];end
			13:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[4];end
			14:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[4];end
			15:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[4];end
			16:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[3];end
			17:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[3];end
			18:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[3];end
			19:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[3];end
			20:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[2];end
			21:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[2];end
			22:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[2];end
			23:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[2];end
			24:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[1];end
			25:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[1];end
			26:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[1];end
			27:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[1];end
			28:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[0];end
			29:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[0];end
			30:begin scl_tmp = 1'd1;sda_o_tmp = datain_reg[0];end
			31:begin scl_tmp = 1'd0;sda_o_tmp = datain_reg[0];end
			default:begin scl_tmp = 1'd1;sda_o_tmp = 1'd1; end
		endcase
			
	
	end
	WAIT_ACK2://7
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd0;
		if(cycle_cnt == 5'd3 && cnt_done && length_reg == 5'd0)begin
			nstate = STOP;
			cycle_cnt_tmp = 5'd0;
		end else if(cycle_cnt == 5'd4 && cnt_done && length_reg != 5'd0)begin
			nstate = SEND2;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = WAIT_ACK2;
		end
		case(cycle_cnt)
			0:
			begin
				scl_tmp = 1'd0;
				//sda_o_tmp = 1'd1;
			end
			1:
			begin
				scl_tmp = 1'd1;
				//sda_o_tmp = 1'd0;
			end
			2:
			begin
				scl_tmp = 1'd1;
				//sda_o_tmp = 1'd0;
			end
			3:
			begin
				scl_tmp = 1'd0;
				//sda_o_tmp = 1'd1;
			end
			4:
			begin
				scl_tmp = 1'd0;
				//sda_o_tmp = 1'd1;
			end
		endcase
	
	end
	START1://8
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd1;
		if(cycle_cnt == 5'd3 && cnt_done)begin
			nstate = ADDR1;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = START1;
		end
		case(cycle_cnt)
			0:
			begin
				scl_tmp = 1'd1;
				sda_o_tmp = 1'd1;
			end
			1:
			begin
				scl_tmp = 1'd1;
				sda_o_tmp = 1'd0;
				stop_tmp = 1'd0;
			end
			2:
			begin
				scl_tmp = 1'd0;
				sda_o_tmp = 1'd0;
			end
			3:
			begin
				scl_tmp = 1'd0;
				sda_o_tmp = 1'd0;
			end
		endcase
	
	end
	ADDR1://9
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd1;
		if(cycle_cnt == 5'd31 && cnt_done)begin
			nstate = WAIT_ACK3;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = ADDR1;
		end
		case(cycle_cnt)
			0:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[7]; end
			1:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[7]; end
			2:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[7];end //sda_o_tmp = 1'd0;end
			3:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[7];end
			4:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[6];end
			5:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[6];end
			6:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[6];end
			7:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[6];end
			8:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[5];end
			9:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[5];end
			10:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[5];end
			11:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[5];end
			12:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[4];end
			13:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[4];end
			14:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[4];end
			15:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[4];end
			16:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[3];end
			17:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[3];end
			18:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[3];end
			19:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[3];end
			20:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[2];end
			21:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[2];end
			22:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[2];end
			23:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[2];end
			24:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[1];end
			25:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[1];end
			26:begin scl_tmp = 1'd1;sda_o_tmp = slave_address_reg[1];end
			27:begin scl_tmp = 1'd0;sda_o_tmp = slave_address_reg[1];end
			28:begin scl_tmp = 1'd0;sda_o_tmp = rw;end
			29:begin scl_tmp = 1'd1;sda_o_tmp = rw;end
			30:begin scl_tmp = 1'd1;sda_o_tmp = rw;end
			31:begin scl_tmp = 1'd0;sda_o_tmp = rw;end
			default:begin scl_tmp = 1'd1;sda_o_tmp = 1'd1; end
		endcase
			
	
	end
	WAIT_ACK3://10
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd0;
		if(cycle_cnt == 5'd4 && cnt_done)begin
			nstate = RECEIVED;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = WAIT_ACK3;
		end
		case(cycle_cnt)
			0:
			begin
				scl_tmp = 1'd0;
				//sda_o_tmp = 1'd1;
			end
			1:
			begin
				scl_tmp = 1'd1;
				//sda_o_tmp = 1'd0;
			end
			2:
			begin
				scl_tmp = 1'd1;
				//sda_o_tmp = 1'd0;
			end
			3:
			begin
				scl_tmp = 1'd0;
				//sda_o_tmp = 1'd1;
			end
		endcase
	
	end
	RECEIVED://11
	begin
		sda_oe_tmp = 1'd0;
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		if(cycle_cnt == 5'd31 && cnt_done && length_reg == 5'd1)begin
			nstate = STOP;
			cycle_cnt_tmp = 5'd0;
		end else if(cycle_cnt == 5'd31 && cnt_done && length_reg != 5'd0)begin
			nstate = ACK;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = RECEIVED;
		end
		case(cycle_cnt)
			0:begin scl_tmp = 1'd0;dataout_reg[7] = sda_reg; end
			1:begin scl_tmp = 1'd1;dataout_reg[7] = sda_reg; end
			2:begin scl_tmp = 1'd1;end
			3:begin scl_tmp = 1'd0;end
			4:begin scl_tmp = 1'd0;dataout_reg[6] = sda_reg;end
			5:begin scl_tmp = 1'd1;dataout_reg[6] = sda_reg;end
			6:begin scl_tmp = 1'd1;end
			7:begin scl_tmp = 1'd0;end
			8:begin scl_tmp = 1'd0;dataout_reg[5] = sda_reg;end
			9:begin scl_tmp = 1'd1;dataout_reg[5] = sda_reg;end
			10:begin scl_tmp = 1'd1;end
			11:begin scl_tmp = 1'd0;end
			12:begin scl_tmp = 1'd0;dataout_reg[4] = sda_reg;end
			13:begin scl_tmp = 1'd1;dataout_reg[4] = sda_reg;end
			14:begin scl_tmp = 1'd1;end
			15:begin scl_tmp = 1'd0;end
			16:begin scl_tmp = 1'd0;dataout_reg[3] = sda_reg;end
			17:begin scl_tmp = 1'd1;dataout_reg[3] = sda_reg;end
			18:begin scl_tmp = 1'd1;end
			19:begin scl_tmp = 1'd0;end
			20:begin scl_tmp = 1'd0;dataout_reg[2] = sda_reg;end
			21:begin scl_tmp = 1'd1;dataout_reg[2] = sda_reg;end
			22:begin scl_tmp = 1'd1;end
			23:begin scl_tmp = 1'd0;end
			24:begin scl_tmp = 1'd0;dataout_reg[1] = sda_reg;end
			25:begin scl_tmp = 1'd1;dataout_reg[1] = sda_reg;end
			26:begin scl_tmp = 1'd1;end
			27:begin scl_tmp = 1'd0;end
			28:begin scl_tmp = 1'd0;dataout_reg[0] = sda_reg;end
			29:begin scl_tmp = 1'd1;dataout_reg[0] = sda_reg;end
			30:begin scl_tmp = 1'd1;end
			31:begin scl_tmp = 1'd0;end
			default:begin scl_tmp = 1'd1;end
		endcase
	
	
	end
	ACK://12
	begin
		cycle_cnt_tmp = cycle_cnt + 5'd1;
		sda_oe_tmp = 1'd1;
		length_tmp = length_reg - 5'd1;
		if(cycle_cnt == 5'd3 && cnt_done)begin
			nstate = RECEIVED;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = ACK;
		end
		case(cycle_cnt)
			0: begin scl_tmp = 1'd0; sda_o_tmp = 1'd0; end
			1: begin scl_tmp = 1'd1; sda_o_tmp = 1'd0; end
			2: begin scl_tmp = 1'd1; sda_o_tmp = 1'd0; end
			3: begin scl_tmp = 1'd0; sda_o_tmp = 1'd0; end
			default:begin scl_tmp = 1'd1; sda_o_tmp = 1'd1;end
		endcase
	
	end
	STOP://13
	begin
	cycle_cnt_tmp = cycle_cnt + 5'd1;
	sda_oe_tmp = 1'd1;
	if(cycle_cnt == 5'd3 && cnt_done)begin
			nstate = IDLE;
			cycle_cnt_tmp = 5'd0;
		end else begin
			nstate = STOP;
		end
		case(cycle_cnt)
			0:
			begin
				scl_tmp = 1'd0;
				sda_o_tmp = 1'd0;
			end
			1:
			begin
				scl_tmp = 1'd1;
				sda_o_tmp = 1'd0;
			end
			2:
			begin
				scl_tmp = 1'd1;
				sda_o_tmp = 1'd1;
				
			end
			3:
			begin
				scl_tmp = 1'd1;
				sda_o_tmp = 1'd1;
				//stop_tmp = 1'd1;
			end
			4:
			begin
				
				stop_tmp = 1'd1;
			end
		endcase
	
	end
	
	default:
	begin
		scl_tmp = 1'd1;
		sda_o_tmp = 1'd1;
		nstate = IDLE;
		sda_oe_tmp = 1'd1;
	end
	
	
	endcase
end

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		scl <= 1'd1;
		sda_o<= 1'd1;
		sda_oe <= 1'd1;
	end else begin
		scl <= scl_tmp;
		sda_o<=sda_o_tmp;
		sda_oe <= sda_oe_tmp;
	end 
end

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		stp <= 1'd0;
	end else begin
		stp <= stop_tmp;
	end 
end

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		stp <= 1'd0;
	end else begin
		stp <= stop_tmp;
	end 
end

always@(posedge clk or negedge rst_n)
begin
	if(~rst_n)begin
		dataout <= 8'd0;
	end else if(stp)begin
		dataout <= 8'd0;
	end else if((cstate == 4'd12 || cstate ==4'd13)&& cycle_cnt == 5'd2 && cnt_done)begin
		dataout <= dataout_reg;
	end else begin
		dataout <= dataout;
	end
end

wire data_val;
assign data_val = ((cstate == 4'd12 || cstate ==4'd13)&& cycle_cnt == 5'd3 && cnt_done);	


assign done = (cstate == WAIT_ACK2 && cycle_cnt == 5'd2 && cnt_done);

assign sda = (sda_oe)? sda_o : 1'bz;






	
endmodule

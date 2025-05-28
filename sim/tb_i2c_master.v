`timescale 1ns / 1ns

module tb_i2c_master;

    reg clk;
    reg rst_n;
    reg start;
    reg stb;
    reg rw;
    reg [4:0] length;
    reg [7:0] slave_address;
    reg [7:0] reg_addr;
    reg [7:0] datain;
    wire [7:0] dataout;
    wire done;
    wire scl;
    wire sda;
	pullup PUP(sda);
	//pullup PUP(scl);

    // Instantiate DUT
    i2c_master uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .stb(stb),
        .rw(rw),
        .length(length),
        .slave_address(slave_address),
        .reg_addr(reg_addr),
        .datain(datain),
        .dataout(dataout),
        .done(done),
        .scl(scl),
        .sda(sda)
    );

    // EEPROM Slave 模型（需你事先準備好，例如 M24LC04B）
    M24LC04B eeprom (
        .A0(1'b0),
        .A1(1'b0),
        .A2(1'b0),
        .WP(1'b0),
        .SDA(sda),
        .SCL(scl),
        .RESET(~rst_n)
    );

    // Clock
    always #10 clk = ~clk;

    // Test Procedure
    integer i;
    reg [7:0] buffer [0:7];
    reg [7:0] result;

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        stb = 0;
        rw = 0;
        slave_address = 8'hA0;
        reg_addr = 8'h10;
        length = 5;

        // 預設寫入資料
        buffer[0] = 8'h11;
        buffer[1] = 8'h22;
        buffer[2] = 8'h33;
        buffer[3] = 8'h44;
        buffer[4] = 8'h55;

        #100;
        rst_n = 1;
        #100;

        $display("==== Burst Write Start ====");
		
		@(posedge clk);
           start = 1;
        @(posedge clk);
           start = 0;

        for (i = 0; i < length; i = i + 1) begin
            datain = buffer[i];
            rw = 0;
            reg_addr = 8'h10 + i;
			//#10
            stb = 1;
            //start = 1;
            @(posedge clk);
            stb = 0;
           // start = 0;

            wait (done);
            @(posedge clk);
            wait (~done);
        end
#5000000
        $display("==== Burst Read Start ====");
		@(posedge clk);
           start = 1;
        @(posedge clk);
           start = 0;

        for (i = 0; i < length; i = i + 1) begin
            rw = 1;
            reg_addr = 8'h10 + i;
            stb = 1;
           // start = 1;
            @(posedge clk);
            stb = 0;
           // start = 0;

            wait (done);
            result = dataout;
            $display("Read reg 0x%02h = 0x%02h", reg_addr, result);
            @(posedge clk);
            wait (~done);
        end

        $display("==== Test Done ====");
        #100;
        $finish;
    end

endmodule

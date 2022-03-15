`timescale 1ns/1ps

module udp_tb ();
	localparam DUMP_PATH = "outp.txt";
	localparam CLK_PERIOD = 1;
	// clock
	logic clk;
	initial begin
		clk = '0;
		forever #(CLK_PERIOD*0.5) clk = ~clk;
	end

	logic [63:0] pkt_data [1023:0];
	logic [47:0] CFG_MAC = 48'hefbeadde0100;
	logic [31:0] CFG_IP = 32'h0101a8c0;
	logic [63:0] mac_rx_tdata;
	logic  [7:0] mac_rx_tkeep;
	logic        mac_rx_tvalid;
	logic        mac_rx_tuser;
	logic        mac_rx_tlast;
	logic [63:0] mac_tx_tdata =0;
	logic  [7:0] mac_tx_tkeep =0;
	logic        mac_tx_tvalid =0;
	logic        mac_tx_tlast =0;
	logic        mac_tx_tready =1;
	logic [63:0] udp_rx_tdata;
	logic  [7:0] udp_rx_tkeep;
	logic        udp_rx_tvalid;
	logic        udp_rx_tlast;
	logic        udp_rx_tready =1;
	logic [47:0] udp_rx_src_mac;
	logic [31:0] udp_rx_src_ip;
	logic [15:0] udp_rx_src_port;
	logic [15:0] udp_rx_dst_port;
	logic [63:0] udp_tx_tdata=0;
	logic  [7:0] udp_tx_tkeep=0;
	logic        udp_tx_tvalid=0;
	logic        udp_tx_tlast=0;
	logic        udp_tx_tready;
	logic [47:0] udp_tx_dst_mac =48'hefbeadde0100;
	logic [31:0] udp_tx_dst_ip=32'h0101a8c0;
	logic [15:0] udp_tx_dst_port= 16'h2e16;
	logic [15:0] udp_tx_src_port = 16'hd204;


	logic reset;
	initial begin
		reset <= '0;
		repeat(10)@(posedge clk);
		reset <= '1;
		repeat(10)@(posedge clk);
		reset <= '0;
	end



	udp_top inst_udp_top(
		.clk             (clk),
		.reset           (reset),


		.CFG_MAC         (CFG_MAC),
		.CFG_IP          (CFG_IP),


		.mac_rx_tdata    (mac_rx_tdata),
		.mac_rx_tkeep    (mac_rx_tkeep),
		.mac_rx_tvalid   (mac_rx_tvalid),
		.mac_rx_tuser    (mac_rx_tuser),
		.mac_rx_tlast    (mac_rx_tlast),


		.mac_tx_tdata    (mac_tx_tdata),
		.mac_tx_tkeep    (mac_tx_tkeep),
		.mac_tx_tvalid   (mac_tx_tvalid),
		.mac_tx_tlast    (mac_tx_tlast),
		.mac_tx_tready   (mac_tx_tready),


		.udp_rx_tdata    (udp_rx_tdata),
		.udp_rx_tkeep    (udp_rx_tkeep),
		.udp_rx_tvalid   (udp_rx_tvalid),
		.udp_rx_tlast    (udp_rx_tlast),
		.udp_rx_tready   (udp_rx_tready),

		.udp_rx_src_mac  (udp_rx_src_mac),
		.udp_rx_src_ip   (udp_rx_src_ip),
		.udp_rx_src_port (udp_rx_src_port),
		.udp_rx_dst_port (udp_rx_dst_port),


		.udp_tx_tdata    (udp_tx_tdata),
		.udp_tx_tkeep    (udp_tx_tkeep),
		.udp_tx_tvalid   (udp_tx_tvalid),
		.udp_tx_tlast    (udp_tx_tlast),
		.udp_tx_tready   (udp_tx_tready),
		.udp_tx_dst_mac  (udp_tx_dst_mac),

		.udp_tx_dst_ip   (udp_tx_dst_ip),
		.udp_tx_dst_port (udp_tx_dst_port),
		.udp_tx_src_port (udp_tx_src_port)
	);

	assign mac_rx_tdata = mac_tx_tdata;
	assign mac_rx_tkeep = mac_tx_tkeep;
	assign mac_rx_tvalid = mac_tx_tvalid;
	assign mac_rx_tlast = mac_tx_tlast;
	assign mac_rx_tuser = 1'b0;



	logic [7:0] data_pattern [7:0];
	logic[7:0] current_pattern =0;
	initial begin
		for (int j = 0; j < 1024; j++) begin
			for (int k = 0; k < 8; k++) begin
				data_pattern[k] = current_pattern;
				current_pattern = current_pattern +1;
			end
			pkt_data[j] = {data_pattern[7], data_pattern[6], data_pattern[5], data_pattern[4], 
								data_pattern[3], data_pattern[2], data_pattern[1], data_pattern[0]};
		end
	end

	task tx_pkt(input int pkt_len);
		automatic int beat_cntr =0;
		if (pkt_len>0) begin
			@(posedge clk);
			udp_tx_tdata <= pkt_data[beat_cntr];
			if (pkt_len <8) udp_tx_tkeep[7:0] <= (8'hff >> 8 - pkt_len);
			else udp_tx_tkeep <= 8'hff;
			udp_tx_tlast = (pkt_len <= 8) ? 1'b1 : 1'b0;
			udp_tx_tvalid <= 1;
			wait (udp_tx_tready);
			#(CLK_PERIOD);
			while ((beat_cntr+1)*8 < pkt_len) begin
				begin
					if (udp_tx_tready && udp_tx_tvalid) begin 
						beat_cntr = beat_cntr+1;
						udp_tx_tdata <= pkt_data[beat_cntr];
						if (pkt_len - beat_cntr*8 <8) udp_tx_tkeep[7:0] <= (8'hff >> 8 - (pkt_len - beat_cntr*8));
						else udp_tx_tkeep <= 8'hff;
						udp_tx_tlast <= ((pkt_len - beat_cntr*8) <= 8) ? 1'b1 : 1'b0;
					end
				end
				#CLK_PERIOD;
			end
			udp_tx_tvalid <= 0;


		end
	endtask  

	integer fdesc, i;
       
	initial begin
	  	forever begin
	      fdesc = $fopen(DUMP_PATH,"a");
	      while(!(mac_tx_tready && mac_tx_tvalid && mac_tx_tlast)) begin
	         @(posedge clk) begin
	              if (mac_tx_tready && mac_tx_tvalid) begin
	                  for (i = 0; i < 8; i=i+1) begin
	                      if (mac_tx_tkeep[i]) $fwrite(fdesc,"%h", mac_tx_tdata[i*8+:8]);
	                  end
	                  if (mac_tx_tready && mac_tx_tvalid && mac_tx_tlast) begin
	                      $fwrite(fdesc,"\n");
	                      $fclose(fdesc);
	                  end
	              end
	          end
	      end
	      wait(!(mac_tx_tready && mac_tx_tvalid && mac_tx_tlast));
	  end
	end


	int k;
	initial begin
		i = 0;
		reset <= 0;
		#10;
		reset <= 1;
		#10;
		reset <= 0;
		#100;

		repeat(20) begin
			k = k+1;
			tx_pkt(k);
			#100;
		end

		#1000;
		$finish;
	end



	reg [63:0] data_tmp;
	reg valid;
	reg [7:0] tkeep;
	reg tlast_tmp;


	always @(posedge clk) begin
		data_tmp <= udp_tx_tdata;
		valid <= udp_tx_tvalid && udp_tx_tready;
		tkeep <= udp_tx_tkeep;
		tlast_tmp <= udp_tx_tlast;
	end


endmodule
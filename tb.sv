/* Siddharth Dedhia (sdedhia)
   ECE 341, Fall 2013,
   Project 2 : NOC
   tb.sv
*/

module tb(
   output logic clk, rst_b,
   output pkt_t pkt_in[6],
   output logic pkt_in_avail[6],
   input cQ_full[6],
   input pkt_t pkt_out[6],
   input pkt_out_avail[6]);

tBench test(.*);
initial begin: I
        $monitor($time,
            "\npkt_out_node0: %h, pkt_out_avail = %b\n pkt_out_node1: %h, pkt_out_avail = %b\n pkt_out_node2: %h, pkt_out_avail = %b\
            \npkt_out_node3: %h, pkt_out_avail = %b\n pkt_out_node4: %h, pkt_out_avail = %b\n pkt_out_node5: %h, pkt_out_avail = %b\n", pkt_out[0], pkt_out_avail[0], pkt_out[1], pkt_out_avail[1], pkt_out[2],
               pkt_out_avail[2], pkt_out[3], pkt_out_avail[3], pkt_out[4], pkt_out_avail[4],
               pkt_out[5], pkt_out_avail[5]);
        clk = 0; rst_b = 0;
        rst_b <= #1 1;
        forever #5 clk = ~clk;
    end
endmodule: tb

program tBench
    (output logic pkt_in_avail[6],
     output pkt_t pkt_in[6],
     input logic clk);
   initial begin : J
   $display("sending a packet within a router...from n0->n2");
   @(posedge clk);
   pkt_in_avail[0] <= 1;
   pkt_in[0] <= 32'h02123456;
   @(posedge clk);
   pkt_in_avail[0] <= 0;
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   $display("sending a packet within routers..from n4->n0");
   pkt_in_avail[4] <= 1;
   pkt_in[4] <= 32'h00123456;
   @(posedge clk);
   pkt_in_avail[4] <= 0;
   @(posedge clk);
   $display("sending a packet at all ports at same time, but with different destinations");
   pkt_in[0] <= 32'h01000000;
   pkt_in[1] <= 32'h02111111;
   pkt_in[2] <= 32'h03222222;
   pkt_in[3] <= 32'h04333333;
   pkt_in[4] <= 32'h05444444;
   pkt_in[5] <= 32'h00555555;
   pkt_in_avail[0] <= 1;
   pkt_in_avail[1] <= 1;
   pkt_in_avail[2] <= 1;
   pkt_in_avail[3] <= 1;
   pkt_in_avail[4] <= 1;
   pkt_in_avail[5] <= 1;
   @(posedge clk);
   pkt_in_avail[0] <= 0;
   pkt_in_avail[1] <= 0;
   pkt_in_avail[2] <= 0;
   pkt_in_avail[3] <= 0;
   pkt_in_avail[4] <= 0;
   pkt_in_avail[5] <= 0;
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   $display("Testing all packets with the same destination...");
   pkt_in_avail[0] <= 1;
   pkt_in_avail[1] <= 1;
   pkt_in_avail[2] <= 1;
   pkt_in_avail[3] <= 1;
   pkt_in_avail[4] <= 1;
   pkt_in_avail[5] <= 1;
   pkt_in[0] <= 32'h04000000;
   pkt_in[1] <= 32'h04000001;
   pkt_in[2] <= 32'h04000002;
   pkt_in[3] <= 32'h04000003;
   pkt_in[4] <= 32'h04000004;
   pkt_in[5] <= 32'h04000005;
   @(posedge clk);
   pkt_in_avail[0] <= 0;
   pkt_in_avail[1] <= 0;
   pkt_in_avail[2] <= 0;
   pkt_in_avail[3] <= 0;
   pkt_in_avail[4] <= 0;
   pkt_in_avail[5] <= 0;
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   @(posedge clk);
   #2 $finish;

end
endprogram: tBench
module tb(
   output logic clk, rst_b,
   output pkt_t pkt_in[6],
   output logic pkt_in_avail[6],
   input cQ_full[6],
   input pkt_t pkt_out[6],
   input pkt_out_avail[6]);

endmodule

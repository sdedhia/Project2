/*
  ECE 341, Fall 2013,
  Siddharth Dedhia
  sdedhia
  Prelab 2 - Testbench as per handout spec for prelab
*/


`default_nettype none

typedef struct packed {
  bit [3:0] sourceID;
  bit [3:0] destID;
  bit [23:0] data;
} pkt_t;


module top;
    pkt_t data_for_fifo, data_for_router_to_node_to_tb;
    pkt_t data_fifo_router, data_from_router_to_node_to_tb;
    logic rst_b, clk, pkt_avail_for_fifo, data_taken_from_router, wr_data_to_router, pkt_avail_for_node_from_router;
    logic data_empty, data_available_tb_node_router, fifo_full, data_avail_node_tb;

    prelab_dut dut(.*);
    tbench tb(.*);

    initial begin: I
        $monitor($time,
            " Data receieved by router is valid = %d,\
              Data receieved by router: %d,\n\
                     Data receieved by TB is valid: %d,\
                            Data received by TB from Router through node = %d,\
              \n\ ", data_fifo_router, data_available_tb_node_router,data_avail_node_tb,data_from_router_to_node_to_tb);
        clk = 0; rst_b = 0;
        rst_b <= #1 1;
        forever #5 clk = ~clk;
    end
endmodule: top


module tbench ( output pkt_t data_for_fifo, data_for_router_to_node_to_tb,
                output logic data_taken_from_router, wr_data_to_router, pkt_avail_for_fifo,
                pkt_avail_for_node_from_router,
                input logic clk, data_available_tb_node_router, data_avail_node_tb );


    initial begin: J
        $display("Testing FIFO, and also the node -> router handshake...");
          @(posedge clk);
           data_for_fifo <= 32'd45;
           pkt_avail_for_fifo <= 1;
           @(posedge clk);
            data_for_fifo <= 32'd32;
          @(posedge clk);
            data_for_fifo <= 32'd11;
            @(posedge clk);
            data_for_fifo <= 32'd65;
            @(posedge clk);
            //This should replace 45 since it wouldve been read out by now
            data_for_fifo <= 32'd22;
            @(posedge clk);
            //This should be ignored since FIFO is full
            data_for_fifo <= 32'd200;
            @(posedge clk);
            pkt_avail_for_fifo <= 0;
            wait_for_data(1);
            @(posedge clk);
            wait_for_data(1);
            @(posedge clk);
            wait_for_data(1);
            @(posedge clk);
            wait_for_data(1);
            @(posedge clk);
            wait_for_data(1);
            @(posedge clk);
            $display("Adding data to router's output buffer, and checking whether it travels\
                      Router -> Node -> TB...");
            wr_data_to_router <= 1;
            pkt_avail_for_node_from_router <= 1;
            data_for_router_to_node_to_tb <= 32'd256;
            @(posedge clk);
             wait_for_data(0);
            @(posedge clk);
            #2 $finish;
        end

 task wait_for_data;
  input logic tb_or_router;

  begin: K
  if (tb_or_router) begin
    while (~data_available_tb_node_router) begin
    @(posedge clk);
   end
    data_taken_from_router <= 1;
    $display("Data receieved from node!");
    @(posedge clk);
        data_taken_from_router <= 0;
  end
  else begin
    while(~data_avail_node_tb) begin
      @(posedge clk);
    end
    $display("Data receieved from router!");
   end
 end

 endtask

endmodule: tbench






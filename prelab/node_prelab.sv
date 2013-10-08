/*
 ECE 341, Spring 2013,
 Siddharth Dedhia
 sdedhia
 Prelab 2 - Node and Router IO buffer as per handout spec for prelab
 */

/* top module for prelab */

module prelab_dut(
  input logic clk, rst_b, pkt_avail_for_fifo, data_taken_from_router, wr_data_to_router, pkt_avail_for_node_from_router,
  input pkt_t data_for_fifo, data_for_router_to_node_to_tb,
  output logic data_empty, data_available_tb_node_router, fifo_full, data_avail_node_tb,
  output pkt_t data_fifo_router, data_from_router_to_node_to_tb);

logic put_inbound, free_inbound, put_outbound, free_outbound;
logic[7:0] payload_outbound, payload_inbound;
     /* node */
  node node_ut (.clk(clk), .rst_b(rst_b), .pkt_in(data_for_fifo), .pkt_in_avail(pkt_avail_for_fifo),
        .cQ_full(fifo_full), .pkt_out(data_from_router_to_node_to_tb), .pkt_out_avail(data_avail_node_tb),
        .free_outbound(free_outbound), .put_outbound(put_outbound),
        .payload_outbound(payload_outbound), .free_inbound(free_inbound),
        .put_inbound(put_inbound), .payload_inbound(payload_inbound));
    /* input buffer of router */
  node_to_router node_to_router_ut (.clk(clk) ,.rst_b(rst_b), .put_inbound(put_outbound),
      .clear_data_available(data_taken_from_router),
      .free_inbound(free_outbound), .data_available(data_available_tb_node_router),
      .data_from_node(data_fifo_router),
      .payload_inbound(payload_outbound));

    /* output buffer of router */
  router_to_node router_to_node_ut (.clk(clk), .rst_b(rst_b), .wr_data(wr_data_to_router),
                                    .free_outbound(free_inbound),
                                    .clr_empty(pkt_avail_for_node_from_router),
                                    .put_outbound(put_inbound), .data_empty(data_empty),
                                    .data_wires(data_for_router_to_node_to_tb),
                                    .payload_outbound(payload_inbound));

  endmodule

/* FSM-D of router to receive data from node */

module node_to_router
  (input logic clk , rst_b, put_inbound, clear_data_available,
   output logic free_inbound, data_available,
   output pkt_t data_from_node,
   input logic[7:0] payload_inbound );

 enum logic [1:0] {wait_state = 2'd0 , data_load = 2'd1, take_data = 2'd2} cs, ns;

 logic set_data_available, tick_up, wr_and_shift;
 logic [1:0] count;
 /* update the output data shift register */
  always_ff@(posedge clk or negedge rst_b) begin
    if (~rst_b)
      data_from_node <= 0;
    else begin
      if (wr_and_shift) begin
        data_from_node <= (data_from_node << 8);
        data_from_node[7:0] <= payload_inbound;
      end
    end
  end

 /* update the data available flop  */
   always_ff@(posedge clk or negedge rst_b) begin
    if (~rst_b)
      data_available <= 0;
    else begin
      if (clear_data_available)
        data_available <= 0;
      else if (set_data_available)
        data_available <= 1;
    end
  end

 /* update the fsm */

 always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      cs <= wait_state;
   else
      cs <= ns;
  end
 /* update the counter */

   always_ff @(posedge clk or negedge rst_b) begin
    if (~rst_b)
      count <= 0;
    else begin
      if (tick_up)
        count <= count + 1;
      else
        count <= 0;
    end
  end

 /* update handshake signal, synchronously */
  always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      free_inbound <= 1;
    else begin
      case (ns)
        wait_state: free_inbound <= 1;
        data_load: free_inbound <= 0;
        take_data: free_inbound <= 0;
        default: begin
          $display("invalid state from node to router fsm at handshake signal update1");
          free_inbound <= 0;
        end
      endcase
    end
  end

 /* drive the outputs*/
  always_comb begin
   tick_up = 0;
   ns = wait_state;
   set_data_available = 0;
   wr_and_shift = 0;
   case (cs)
    wait_state: begin
      if (put_inbound) begin
        ns = data_load;
        wr_and_shift = 1;
        tick_up = 1;
      end
    end
    data_load: begin
      if (count == 3) begin
        wr_and_shift = 1;
        set_data_available = 1;
        ns = take_data;
      end
      else begin
        tick_up = 1;
        wr_and_shift = 1;
        ns = data_load;
      end
    end
    take_data: begin
      if (data_available == 0) //router fsm will clear the data available when it takes the data
        ns = wait_state;
      else
        ns = take_data;
    end
    default : $display("incorrect state in the node router fsm, driving the outputs, current state is %d and ns is %d", cs, ns);
   endcase
 end

 endmodule

 /* FSM-D of router to send data to node */

module router_to_node
  (input clk, rst_b, wr_data, free_outbound, clr_empty,
   output logic put_outbound, data_empty,
   input pkt_t data_wires,
   output logic [7:0] payload_outbound);

  enum logic { wait_state = 1'b0 , send_data = 1'b1} cs, ns;
  logic [3:0][7:0] data_to_node;
  logic wr_empty, tick_up;
  logic [1:0] select;

  /* update data register */

  always_ff@(posedge clk or negedge rst_b) begin
     if(~rst_b) begin
       data_to_node <= 0;
     end
     else begin
      if (wr_data)begin
        data_to_node <= data_wires;
      end
     end
  end


 /* update empty signaling register */

  always_ff@(posedge clk or negedge rst_b) begin
     if(~rst_b) begin
      data_empty <= 1;
     end
     else begin
      if (wr_empty)
        data_empty <= 1;
      else if (clr_empty)
        data_empty <= 0;
     end
  end

  /* update handshaking signal, SYNCHRONOUSLY */

    always_ff@(posedge clk or negedge rst_b) begin
     if(~rst_b) begin
       put_outbound <= 0;
     end
     else begin
      if (ns == send_data)
        put_outbound <= 1;
      else
        put_outbound <= 0;
     end
  end

  /* update count register */
     always_ff@(posedge clk or negedge rst_b) begin
     if(~rst_b) begin
       select <= 0;
     end
     else begin
      if (tick_up)
        select <= select + 1;
      else
        select <= 0;
     end
  end

  /* update fsm */

  always_ff@(posedge clk or negedge rst_b) begin
     if(~rst_b)
       cs <= wait_state;
     else
      cs <= ns;
  end
  /* update outputs */
always_comb begin
   wr_empty = 0;
   tick_up = 0;
   ns = wait_state;
   case(cs)
    wait_state: begin
         if (free_outbound && ~data_empty)
          ns = send_data;
    end
    send_data: begin
      if (select == 2'd3) begin
        tick_up = 0;
        wr_empty = 1;
      end
      else begin
        tick_up = 1;
        ns = send_data;
      end
    end
    endcase
  end

  always_comb begin
   payload_outbound = data_to_node[select];
 end


endmodule: router_to_node

/* Top node module */

module node(clk, rst_b, pkt_in, pkt_in_avail, cQ_full, pkt_out, pkt_out_avail,
            free_outbound, put_outbound, payload_outbound,
            free_inbound, put_inbound, payload_inbound);

  parameter NODEID = 0;
  input clk, rst_b;

  // Interface to TestBench
  input pkt_t pkt_in;
  input pkt_in_avail;
  output cQ_full;
  output pkt_t pkt_out;
  output logic pkt_out_avail;

  // Endpoint -> Router transaction
  input free_outbound; // Router -> Endpoint
  output put_outbound; // Endpoint -> Router
  output [7:0] payload_outbound;

  // Router -> Endpoint transaction
  output free_inbound; // Endpoint -> Router
  input put_inbound; // Router -> Endpoint
  input [7:0] payload_inbound;





handshake_router_node r_n_tb(.put_inbound(put_inbound), .rst_b(rst_b), .clk(clk),
                             .pl_inbound(payload_inbound), .free_inbound(free_inbound),
                             .pkt_out_avail(pkt_out_avail), .data_wr(pkt_out));


fifo_node_router f_n_r(.clk(clk), .rst_b(rst_b), .pkt_in_avail(pkt_in_avail),
                        .free_outbound(free_outbound), .cQ_full(cQ_full),
                        .put_outbound(put_outbound), .pkt_in(pkt_in), .payload_out(payload_outbound));


endmodule: node

/* FSM-D of node for receiving data from TB, storing in FIFO and sending to router */

module fifo_node_router
  (input logic clk, rst_b, pkt_in_avail, free_outbound,
   output logic cQ_full, put_outbound,
   input pkt_t pkt_in,
   output logic [7:0] payload_out);

  logic fifo_empty, read, tick_up, data_wr;
  logic [31:0] buffer_wires;
  logic [3:0][7:0] buffer;
  logic [1:0] select;

  fifo fifo_node(.clk(clk), .rst_b(rst_b), .data_in(pkt_in),
                 .we(pkt_in_avail), .re(read), .full(cQ_full),
                 .empty(fifo_empty), .data_out(buffer_wires));

  enum logic {wait_state = 1'b0, take_it = 1'b1} cs, ns;

  /* output register update */

  always_ff @(posedge clk or negedge rst_b) begin
    if (~rst_b)
      buffer <= 0;
    else begin
      if (data_wr)
       buffer <= buffer_wires;
    end
  end

  /* update counter (select in this case) */

  always_ff @(posedge clk or negedge rst_b) begin
    if (~rst_b)
      select <= 0;
    else begin
      if (tick_up)
       select <= select + 1;
     else
      select <= 0;
    end
  end

  /* update fsm*/
  always_ff @(posedge clk or negedge rst_b) begin
    if (~rst_b)
       cs <= wait_state;
    else
       cs <= ns;
   end

  /* update the handshake signal, SYNCHRONOUSLY */

  always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      put_outbound <= 0;
    else begin
      if (ns == take_it)
        put_outbound <= 1;
      else
        put_outbound <= 0;
    end
  end

  /* update outputs */

  always_comb begin
    data_wr = 0;
    read = 0;
    tick_up = 0;
    ns = wait_state;
    case (cs)
      wait_state: begin
            if (fifo_empty || ~free_outbound) begin end //do nothing
            else begin
              read = 1;
              data_wr = 1;
              ns = take_it;
            end
          end
      take_it: begin
           if (select != 3)begin
             tick_up = 1;
             ns = take_it;
             end
           else
           /* since select gets updated synchronouly even though tick up
              is not asserted here, the value of 3 on it will be valid atleast
              until the clock hits after this update here on the outputs.
            */
            ns = wait_state;
        end
       endcase
     end

  assign payload_out = buffer[3-select];

endmodule: fifo_node_router

/* FSM-D of node for receiving data from router */


module handshake_router_node
  ( input logic put_inbound, rst_b, clk,
    input logic[7:0] pl_inbound,
    output logic free_inbound, pkt_out_avail,
    output pkt_t data_wr);


  enum logic {wait_for_data = 1'b0, data_here = 1'b1} cs, ns;

  logic wr_and_shift, tick_up;
  logic [2:0] count;

  /* input register update */
  always_ff@(posedge clk or negedge rst_b) begin
    if (~rst_b)
      data_wr <= 0;
    else begin
      if (wr_and_shift) begin
        data_wr <= data_wr >> 8;
        data_wr[31:24] <= pl_inbound;
      end
    end
  end

  /* fsm update */

  always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      cs <= wait_for_data;
   else
      cs <= ns;
  end

  /* update the handshake signal, SYNCHRONOUSLY */

  always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      free_inbound <= 0;
    else begin
      if (ns == wait_for_data)
        free_inbound <= 1;
      else
        free_inbound <= 0;
    end
  end

  /* update the counter */

  always_ff @(posedge clk or negedge rst_b) begin
    if (~rst_b)
      count <= 0;
    else begin
      if (tick_up)
        count <= count + 1;
      else
        count <= 0;
    end
  end

  /* drive the outputs */

  always_comb begin
    wr_and_shift = 0;
    tick_up = 0;
    ns = wait_for_data;
    pkt_out_avail = 0;
    case (cs)
      wait_for_data: begin
         if (put_inbound) begin
            tick_up = 1;
            wr_and_shift = 1;
            ns = data_here;
          end
        end
      data_here : begin
        if (count == 4) begin
          ns = wait_for_data;
          tick_up = 0;
          pkt_out_avail = 1;
        end
        else begin
          ns = data_here;
          tick_up = 1;
          wr_and_shift = 1;
        end
      end
    endcase
  end


endmodule: handshake_router_node


/*  Create a fifo (First In First Out) with depth 4 using the given interface and constraints.
 *  -The fifo is initally empty.
 *  -Reads are combinational
 *  -Writes are processed on the clock edge.
 *  -If the "we" happens to be asserted while the fifo is full, do NOT update the fifo.
 *  -Similarly, if the "re" is asserted while the fifo is empty, do NOT update the fifo.
 */

module fifo(clk, rst_b, data_in, we, re, full, empty, data_out);
  parameter WIDTH = 32;
  input clk, rst_b;
  input [WIDTH-1:0] data_in;
  input we; //write enable
  input re; //read enable
  output full;
  output empty;
  output [WIDTH-1:0] data_out ;

  /* creating a packed array of 4 registers (as per the
     depth spec) */
  logic [3:0][WIDTH-1:0] fifomemory;

  /* registers to count the number of elements in the
     FIFO, and keep track of the first and last element
     for read and write */
  logic [2:0] count;
  logic [1:0] first;
  logic [1:0] last;


  always_ff @(posedge clk or negedge rst_b) begin
   // $display ("q0 = %d , q1 = %d , q2 = %d , q3 = %d",fifomemory[0], fifomemory[1], fifomemory[2], fifomemory[3]);
    if (~rst_b) begin
      fifomemory[3:0] <= 0;
      count <= 0;
      first <= 0;
      last <= 0;
    end
    else
      case ({re,we})
        2'b00: //no read, no write
              count <= count;
        2'b01: begin //just a write
                if (~full) begin
                  count <= count + 1;
                  fifomemory[last] <= data_in;
                  last <= last + 1;
                end
               end
        2'b10: begin //just a read
                if (~empty) begin
                  count <= count - 1;
                  first <= first + 1;
                end
              end
        2'b11: begin  /* both read and write ; must take care of case
                      / when its empty, since read should be ignored */
                  if (empty) begin
                  count <= count + 1;
                  last <= last + 1;
                  /* first not updated */
                end
                else begin
                  count <= count;
                  last <= last + 1;
                  first <= first + 1;
                  fifomemory[last] <= data_in;
                  end
                end
              endcase
  end
//$display ("q0 = %d , q1 = %d , q2 = %d , q3 = %d",fifomemory[0], fifomemory[1], fifomemory[2], fifomemory[3] );
   assign data_out = fifomemory[first];
   assign empty = (count == 0) ? 1 : 0;
   assign full = (count == 4) ? 1 : 0;


endmodule: fifo

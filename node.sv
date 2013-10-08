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
        data_wr <= data_wr << 8;
        data_wr[7:0] <= pl_inbound;
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

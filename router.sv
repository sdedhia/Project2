/*
 * A router transfers packets between nodes and other routers.
 */
module router(clk, rst_b,
              free_outbound, put_outbound, payload_outbound,
              free_inbound, put_inbound, payload_inbound);
  parameter ROUTERID = 0; // To differentiate between routers
  input  clk, rst_b;

  // self -> destination (sending a payload)
  input [3:0] free_outbound;
  output [3:0] put_outbound;
  output [3:0][7:0] payload_outbound;

  // source -> self (receiving a payload)
  output [3:0] free_inbound;
  input [3:0] put_inbound;
  input [3:0][7:0] payload_inbound;


enum logic [1:0] {wait_state = 2'd0, send_one = 2'd1, send_two = 2'd2, send_three = 2'd3} cs, ns;
typedef enum logic [1:0] {from_p0 = 2'd0, from_p1 = 2'd1, from_p2 = 2'd2, from_p3 = 2'd3} select;

/* control signals */

/* A brief explanation on the control signals:
   clear data available signals to the input buffer fsm that the data that was sent to the port from the node has
   been transferred to the appropriate destination, while wr_data writes the said data to the correct destination
   output buffer. select out selects data from which port gets written to the concerning output buffer
   for eg. select_out.port2 = from_p0 means that data from port 0 was sent to port 2's output buffer.
   you need to assert the correct wr_data and clear_data_available at the same time as setting the
   select_out variable.
 */

struct packed
{
  bit port0;
  bit port1;
  bit port2;
  bit port3;
} clear_data_available;

struct packed
{
  bit port0;
  bit port1;
  bit port2;
  bit port3;
} wr_data;

struct packed
{
  select port0;
  select port1;
  select port2;
  select port3;
} select_out;

/* status signals */

/* A brief explanation:
   data_empty signals that the respective output buffer is empty and can transfer data to the node. Data
   available signals that data from the node is available on the input buffer of the appropriate port
 */

logic [2:0] data_empty, data_available;

/* priority maintaining variables */

logic [1:0] rr_priority;
logic update_priority;

/* 32 bit wires from mux to each output buffer */
pkt_t [3:0] data_to_node;
/* 32 bit wires from input buffer of each port to muxes */
pkt_t[3:0] data_to_port;



/* connecting the input port buffers of the router to the respective node to router handshake FSM-D's */

node_to_router p0 (.clk(clk) , .rst_b(rst_b), .put_inbound(put_inbound[0]), .clear_data_available(clear_data_available.port0),
   .free_inbound(free_inbound[0]), .data_available(data_available[0]), .data_from_node(data_to_port[0]), .payload_inbound(payload_inbound[0]));
node_to_router p1 (.clk(clk) , .rst_b(rst_b), .put_inbound(put_inbound[1]), .clear_data_available(clear_data_available.port1),
   .free_inbound(free_inbound[1]), .data_available(data_available[1]), .data_from_node(data_to_port[1]), .payload_inbound(payload_inbound[1]));
node_to_router p2 (.clk(clk) , .rst_b(rst_b), .put_inbound(put_inbound[2]), .clear_data_available(clear_data_available.port2),
   .free_inbound(free_inbound[2]), .data_available(data_available[2]), .data_from_node(data_to_port[2]), .payload_inbound(payload_inbound[2]));
node_to_router p3 (.clk(clk) , .rst_b(rst_b), .put_inbound(put_inbound[3]), .clear_data_available(clear_data_available.port3),
   .free_inbound(free_inbound[3]), .data_available(data_available[3]), .data_from_node(data_to_port[3]), .payload_inbound(payload_inbound[3]));

/* connecting the buses to the output buffers and the respective FSM-Ds to send data to node */

mux4to1 port0_out (.select(select_out.port0), .data_in(data_to_port), .data_out(data_to_node[0]));
mux4to1 port1_out (.select(select_out.port1), .data_in(data_to_port), .data_out(data_to_node[1]));
mux4to1 port2_out (.select(select_out.port2), .data_in(data_to_port), .data_out(data_to_node[2]));
mux4to1 port3_out (.select(select_out.port3), .data_in(data_to_port), .data_out(data_to_node[3]));

router_to_node p0_out (.clk(clk), .rst_b(rst_b), .wr_data(wr_data[0]), .free_outbound(free_outbound[0]), .clr_empty(wr_data[0]),
   .put_outbound(put_outbound[0]), .data_empty(data_empty[0]), .data_wires(data_to_node[0]), .payload_outbound(payload_outbound[0]));
router_to_node p1_out (.clk(clk), .rst_b(rst_b), .wr_data(wr_data[1]), .free_outbound(free_outbound[1]), .clr_empty(wr_data[1]),
   .put_outbound(put_outbound[1]), .data_empty(data_empty[1]), .data_wires(data_to_node[1]), .payload_outbound(payload_outbound[1]));
router_to_node p2_out (.clk(clk), .rst_b(rst_b), .wr_data(wr_data[2]), .free_outbound(free_outbound[2]), .clr_empty(wr_data[2]),
   .put_outbound(put_outbound[2]), .data_empty(data_empty[2]), .data_wires(data_to_node[2]), .payload_outbound(payload_outbound[2]));
router_to_node p3_out (.clk(clk), .rst_b(rst_b), .wr_data(wr_data[3]), .free_outbound(free_outbound[3]), .clr_empty(wr_data[3]),
   .put_outbound(put_outbound[3]), .data_empty(data_empty[3]), .data_wires(data_to_node[3]), .payload_outbound(payload_outbound[3]));

/* update the fsm state */

 always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      cs <= wait_state;
   else
      cs <= ns;
  end

/* update the output buffer control signals

assign {clear_data_available[3], clear_data_available[2], clear_data_available[1], clear_data_available[0]} = data_write;
assign {wr_data[3], wr_data[2], wr_data[1], wr_data[0]} = data_write;
*/


/* update the priority counter */

 always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      rr_priority <= 0;
   else begin
    if (update_priority)
      rr_priority <= rr_priority + 1;
   end
 end


assign


module mux4to1
  (input logic[1:0] select,
   input [3:0] pkt_t data_in,
   output pkt_t data_out);

assign data_out = data_in[select];

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
        data_from_node <= (data_from_node >> 8);
        data_from_node[31:24] <= payload_inbound;
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
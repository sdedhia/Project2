`default_nettype none
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

/* need a wire for this since its driven by the multiple queues at the output buffer at each port
   define below. However the queues when required assert the particular clear_data_available port
   to 0 and the rest to z. */

enum logic {wait_state = 1'd0, rr = 1'd1} cs, ns;
typedef enum logic[1:0]{port0 = 2'd0, port1 = 2'd1, port2 = 2'd2, port3 = 2'd3} p_number;
logic [1:0] p;
logic [3:0][1:0]port_number;

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
  bit port3;
  bit port2;
  bit port1;
  bit port0;
} clear_data_available;

struct packed
{
  bit port3;
  bit port2;
  bit port1;
  bit port0;
} wr_data;

struct packed
{
  logic[1:0] port3;
  logic[1:0] port2;
  logic[1:0] port1;
  logic[1:0] port0;
} select_out;

/* status signals */

/* A brief explanation:
   data_empty signals that the respective output buffer is empty and can transfer data to the node, if needed.
   Data_available signal's that data from the node is available on the input buffer of the appropriate port to
   be transferred to the destination
 */

struct packed
{
  bit port3;
  bit port2;
  bit port1;
  bit port0;
} data_empty;

struct packed
{
  bit port3;
  bit port2;
  bit port1;
  bit port0;
} data_available;

struct packed
{
  bit port3;
  bit port2;
  bit port1;
  bit port0;
} added_to_queue_register;

struct packed
{
  bit port3;
  bit port2;
  bit port1;
  bit port0;
} add_to_queue;

struct packed
{
  bit port3;
  bit port2;
  bit port1;
  bit port0;
} rem_add;

logic[3:0][3:0] destination;

assign destination[0] = data_to_port[0].destID;
assign destination[1] = data_to_port[1].destID;
assign destination[2] = data_to_port[2].destID;
assign destination[3] = data_to_port[3].destID;

/* priority maintaining variables */

logic [1:0] rr_priority, counter, rr_counter;
logic update_priority, count_up, rr_up;
logic none_available, single_available, multiple_available;
logic[2:0] num_available;
/* 32 bit wires from mux to each output buffer */
pkt_t [3:0] data_to_node;
/* 32 bit wires from input buffer of each port to muxes */
pkt_t [3:0] data_to_port;
logic [3:0] clear_data_available_p0, clear_data_available_p1, clear_data_available_p2, clear_data_available_p3;
/* How many ports have data available that have not been added to queues already*/

assign num_available = ((~added_to_queue_register[3]) & data_available.port3)+((~added_to_queue_register[2]) & data_available.port2)+
                          ((~added_to_queue_register[1]) & data_available.port1)+((~added_to_queue_register[0]) & data_available.port0);
assign none_available = (num_available == 0);
assign single_available = (num_available == 1);
assign multiple_available = (~single_available && ~none_available);

/* assign the 4bit signal to the wires that go into the respective queues. The queues drive the non asserted bits with a z */
assign clear_data_available = clear_data_available_p0 | clear_data_available_p1 | clear_data_available_p2 | clear_data_available_p3;

/* connecting the input port buffers of the router to the respective node to router handshake FSM-D's */

node_to_router p0 (.clk(clk) , .rst_b(rst_b), .put_inbound(put_inbound[0]), .clear_data_available(clear_data_available.port0),
   .free_inbound(free_inbound[0]), .data_available(data_available.port0), .data_from_node(data_to_port[0]), .payload_inbound(payload_inbound[0]));
node_to_router p1 (.clk(clk) , .rst_b(rst_b), .put_inbound(put_inbound[1]), .clear_data_available(clear_data_available.port1),
   .free_inbound(free_inbound[1]), .data_available(data_available.port1), .data_from_node(data_to_port[1]), .payload_inbound(payload_inbound[1]));
node_to_router p2 (.clk(clk) , .rst_b(rst_b), .put_inbound(put_inbound[2]), .clear_data_available(clear_data_available.port2),
   .free_inbound(free_inbound[2]), .data_available(data_available.port2), .data_from_node(data_to_port[2]), .payload_inbound(payload_inbound[2]));
node_to_router p3 (.clk(clk) , .rst_b(rst_b), .put_inbound(put_inbound[3]), .clear_data_available(clear_data_available.port3),
   .free_inbound(free_inbound[3]), .data_available(data_available.port3), .data_from_node(data_to_port[3]), .payload_inbound(payload_inbound[3]));

/* connecting the buses to the output buffers and the respective FSM-Ds to send data to node */
queue port0_output(.clk(clk), .rst_b(rst_b), .add_to_queue(add_to_queue.port0), .data_empty(data_empty.port0),
                    .port_num(port_number[0]), .wr_data(wr_data.port0), .select(select_out.port0),
                    .clear_data_available(clear_data_available_p0));
queue port1_output(.clk(clk), .rst_b(rst_b), .add_to_queue(add_to_queue.port1), .data_empty(data_empty.port1),
                    .port_num(port_number[1]), .wr_data(wr_data.port1), .select(select_out.port1),
                    .clear_data_available(clear_data_available_p1));
queue port2_output(.clk(clk), .rst_b(rst_b), .add_to_queue(add_to_queue.port2), .data_empty(data_empty.port2),
                   .port_num(port_number[2]), .wr_data(wr_data.port2), .select(select_out.port2),
                   .clear_data_available(clear_data_available_p2));
queue port3_output(.clk(clk), .rst_b(rst_b), .add_to_queue(add_to_queue.port3), .data_empty(data_empty.port3),
                    .port_num(port_number[3]), .wr_data(wr_data.port3), .select(select_out.port3),
                    .clear_data_available(clear_data_available_p3));

mux4to1 port0_out (.select(select_out.port0), .data_in(data_to_port), .data_out(data_to_node[0]));
mux4to1 port1_out (.select(select_out.port1), .data_in(data_to_port), .data_out(data_to_node[1]));
mux4to1 port2_out (.select(select_out.port2), .data_in(data_to_port), .data_out(data_to_node[2]));
mux4to1 port3_out (.select(select_out.port3), .data_in(data_to_port), .data_out(data_to_node[3]));

router_to_node p0_out (.clk(clk), .rst_b(rst_b), .wr_data(wr_data.port0), .free_outbound(free_outbound[0]), .clr_empty(wr_data.port0),
   .put_outbound(put_outbound[0]), .data_empty(data_empty.port0), .data_wires(data_to_node[0]), .payload_outbound(payload_outbound[0]));
router_to_node p1_out (.clk(clk), .rst_b(rst_b), .wr_data(wr_data.port1), .free_outbound(free_outbound[1]), .clr_empty(wr_data.port1),
   .put_outbound(put_outbound[1]), .data_empty(data_empty.port1), .data_wires(data_to_node[1]), .payload_outbound(payload_outbound[1]));
router_to_node p2_out (.clk(clk), .rst_b(rst_b), .wr_data(wr_data.port2), .free_outbound(free_outbound[2]), .clr_empty(wr_data.port2),
   .put_outbound(put_outbound[2]), .data_empty(data_empty.port2), .data_wires(data_to_node[2]), .payload_outbound(payload_outbound[2]));
router_to_node p3_out (.clk(clk), .rst_b(rst_b), .wr_data(wr_data.port3), .free_outbound(free_outbound[3]), .clr_empty(wr_data.port3),
   .put_outbound(put_outbound[3]), .data_empty(data_empty.port3), .data_wires(data_to_node[3]), .payload_outbound(payload_outbound[3]));


/* update the added to queue register */
 always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)begin
      added_to_queue_register <= 0;
   end
   else begin
    added_to_queue_register <= ((rem_add | added_to_queue_register) & ~clear_data_available);
  end
end

/* update the fsm state */

 always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      cs <= wait_state;
   else
      cs <= ns;
  end


/* update the priority counter */

 always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      rr_priority <= 0;
   else begin
    if (update_priority)
      rr_priority <= rr_priority + 1;
   end
 end

/* update the rr counter */

 always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      rr_counter <= 0;
   else begin
    if (update_priority)
      rr_counter <= rr_priority + 1;
    else if (rr_up)
      rr_counter <= rr_counter + 1;
   end
 end

 /* update the counter */
always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      counter <= 0;
   else begin
    if (count_up)
      counter <= counter + 1;
    else
      counter <= 0;
   end
 end

/* update the outputs */

always_comb begin
  add_to_queue = 0;
  port_number = 0;
  ns = wait_state;
  p = 0;
  update_priority = 0;
  rr_up = 0;
  count_up = 0;
  rem_add = 0;
case (cs)
  wait_state: begin
    if (single_available) begin
     ns = wait_state;
     if ((data_available.port0 && ~added_to_queue_register[0]) || (data_available.port1 && ~added_to_queue_register[1])
         || (data_available.port2 && ~added_to_queue_register[2]) || (data_available.port3 && ~added_to_queue_register[3])) begin
        case (data_available & ~added_to_queue_register)
          4'b0001: p = 0;
          4'b0010: p = 1;
          4'b0100: p = 2;
          4'b1000: p = 3;
          default: begin
          //    $display("shouldnt happen: %b, added_to_queue_register %b, num_available %d",data_available , added_to_queue_register, num_available);
              p = 0;
             end
        endcase
      //$display("hurrah , data_available = %b, destination[0] = %b, destination[1] = %b\
       // destination[2] = %d,destination[3] = %d," , data_available, destination[0], destination[1], destination[2], destination[3]);
        if ( ROUTERID == 0) begin
          if (destination[p] >= 3) begin
          add_to_queue.port1 = 1;
          rem_add = rem_add | (1 << p);
          port_number[1] = p;
          end
          else begin
            if (destination[p] == 0) begin
              add_to_queue.port0 = 1;
              port_number[0] = p;
              rem_add = rem_add | (1 << p);
            end
            else begin
              add_to_queue[destination[p]+1] = 1;
              port_number[destination[p]+1] = p;
              rem_add = rem_add | (1 << p);
            end
          end
        end
        else begin
          if (destination[p] < 3) begin
           add_to_queue.port3 = 1;
           port_number[3] = p;
           rem_add = rem_add | (1 << p);
           end
          else begin
              add_to_queue[destination[p]-3] = 1;
              port_number[destination[p]-3] = p;
              rem_add = rem_add | (1 << p);
           end
        end
      end
    end
    else if (multiple_available) begin
      update_priority = 1;
      ns = rr;
      count_up = 1;
      if (data_available[rr_priority] && ~added_to_queue_register[rr_priority]) begin
         if ( ROUTERID == 0) begin
          if (destination[rr_priority] >= 3) begin
          add_to_queue.port1 = 1;
          port_number[1] = rr_priority;
          rem_add = rem_add | 1 << rr_priority;
          end
          else begin
            if (destination[rr_priority] == 0) begin
              add_to_queue.port0 = 1;
              port_number[0] = rr_priority;
              rem_add = rem_add | (1 << rr_priority);
            end
            else begin
              add_to_queue[destination[rr_priority]+1] = 1;
              port_number[destination[rr_priority]+1] = rr_priority;
              rem_add = rem_add | (1 << rr_priority);
            end
          end
        end
        else begin
      //    if (destination[rr_priority] > 5 ) begin
        //    $display("fudgeeeeeeee");
          //  end
          if (destination[rr_priority] < 3) begin
           add_to_queue.port3 = 1;
           port_number[3] = rr_priority;
           rem_add = rem_add | (1 << rr_priority);
           end
          else begin
              add_to_queue[destination[rr_priority]-3] = 1;
              port_number[destination[rr_priority]-3] = rr_priority;
              rem_add = rem_add | (1 << rr_priority);
           end
        end
      end
    end
  end
  rr: begin
           if (counter == 3) begin
            rr_up = 0;
            ns = wait_state;
            end
           if (counter != 3) begin
             rr_up = 1;
             count_up = 1;
             ns = rr;
            end
            if (data_available[rr_counter] && ~added_to_queue_register[rr_counter]) begin
               if ( ROUTERID == 0) begin
                if (destination[rr_counter] >= 3) begin
                 add_to_queue.port1 = 1;
                 port_number[1] = rr_counter;
                 rem_add = rem_add | (1 << rr_counter);
                end
                else begin
                  if (destination[rr_counter] == 0) begin
                    add_to_queue.port0 = 1;
                    port_number[0] = rr_counter;
                    rem_add = rem_add | (1 << rr_counter);
                  end
                  else begin
                    add_to_queue[destination[rr_counter]+1] = 1;
                    port_number[destination[rr_counter]+1] = rr_counter;
                    rem_add = rem_add | (1 << rr_counter);
                  end
                end
              end
              else begin
              //  if (destination[rr_counter] > 5 ) begin
            //$display("fudgeeeeeeee, destination[rr_priority] = %d and rr_priority = %d",destination[rr_counter], rr_counter);
            //end
                if (destination[rr_counter] < 3) begin
                 add_to_queue.port3 = 1;
                 port_number[3] = rr_counter;
                 rem_add = rem_add | (1 << rr_counter);
                 end
                else begin
                    add_to_queue[destination[rr_counter]-3] = 1;
                    port_number[destination[rr_counter]-3] = rr_counter;
                    rem_add = rem_add | (1 << rr_counter);
                 end
              end
            end
          end
  endcase

end
endmodule


module mux4to1
  (input logic[1:0] select,
   input pkt_t[3:0] data_in,
   output pkt_t data_out);

assign data_out = data_in[select];

endmodule

module queue
  (input logic clk, rst_b, add_to_queue, data_empty,
   input logic [1:0] port_num,
   output logic wr_data,
   output logic [1:0] select,
   output logic [3:0] clear_data_available);

  logic [3:0][1:0] queuememory;

  /* registers to count the number of elements in the
     queue, and keep track of the first and last element
     for dequeue and enqueue */
  logic [3:0] count;
  logic [1:0] first, last, queue_out;
  logic increment_counter, decrement_counter, enable_counter, wr_queue, increment_last, increment_first, queue_empty;

enum logic {empty = 1'd0, dequeue = 1'd1} cs, ns;

// clear data available must clear added_to_queue flag in master fsm

  always_ff @(posedge clk or negedge rst_b) begin
   //$display ("q0 = %d , q1 = %d , q2 = %d , q3 = %d",queuememory[0], queuememory[1], queuememory[2], queuememory[3]);
    if (~rst_b) begin
      cs <= empty;
    end
    else
      cs <= ns;
  end

/* write it to queue */

always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
      queuememory[3:0] <= 0;
   else begin
    if (wr_queue)
      queuememory[last] <= port_num;
    end
  end


/* counter update */
  always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
     count <= 0;
   else begin
    if (enable_counter) begin
      if (increment_counter) begin
        count <= count + 1;
        end
      else if (decrement_counter)
        count <= count - 1;
    end
   end
  end

  /* update last pointer */

  always_ff @(posedge clk or negedge rst_b) begin
   if (~rst_b)
     first <= 0;
   else begin
    if (increment_first)
      first <= first + 1;
    end
  end

  /* update first pointer */

  always_ff @(posedge clk or negedge rst_b) begin
    if (~rst_b)
     last <= 0;
    else begin
     if (increment_last)
       last <= last + 1;
    end
  end

  always_comb begin
    increment_first = 0;
    increment_last = 0;
    enable_counter = 0;
    increment_counter = 0;
    decrement_counter = 0;
    clear_data_available = 4'b0000;
    select = 0;
    wr_data = 0;
    wr_queue = 0;
    ns = empty;
    case (cs)
      empty: begin
        if (add_to_queue) begin
          //$display("data_empty : %d must be one, otherwise error", data_empty);
          ns = dequeue;
          clear_data_available[port_num] = 1;
          wr_data = 1;
          select = port_num;
        end
      end
      dequeue: begin
      case ({queue_empty, add_to_queue, data_empty})
        3'b000: //queue not empty, noone wants to add to queue, data is not empty
               ns = dequeue;
        3'b001: begin
                //queue not empty, noone wants to add to queue, data is empty
               ns = dequeue;
               clear_data_available[queue_out] = 1;
               wr_data = 1;
               select = queue_out;
               enable_counter = 1;
               decrement_counter = 1;
               increment_first = 1;
              end
        3'b010: begin
        //queue not empty, someone wants to add to queue, data is not empty
               ns = dequeue;
               enable_counter = 1;
               increment_counter = 1;
               increment_last = 1;
               wr_queue = 1;
              end
        3'b011: begin         //queue not empty, someone wants to add to queue, data is empty
               ns = dequeue;
               clear_data_available[queue_out] = 1;
               wr_data = 1;
               select = queue_out;
               //dont increment or decrement counter since data coming and data going out
               increment_first = 1;
               increment_last = 1;
               wr_queue = 1;
               end
        3'b100: begin
                  //queue empty, noone to add to queue, data is not empty
               ns = dequeue;
          //     $display("assert first %d == last %d", first, last);
             end
        3'b101: begin
                  //queue empty, noone wants to add to queue, data is empty
                ns = dequeue;
              end
        3'b110: begin
                  //queue empty, someone wants to add to queue, data is not empty
                  ns = dequeue;
                  enable_counter = 1;
                  increment_counter = 1;
                  increment_last = 1;
                  //increment_first = 1;
                  wr_queue = 1;
                end
        3'b111: begin
                  //queue empty, someone wants to add to queue, data empty
                  ns = dequeue;
                  clear_data_available[port_num] = 1;
                  wr_data = 1;
                  select = port_num;
                end
      endcase
      end
    endcase
  end


   assign queue_out = queuememory[first];
   assign queue_empty = (count == 0) ? 1 : 0;

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
    default : ns = wait_state;
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
   payload_outbound = data_to_node[3-select];
 end


endmodule: router_to_node
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
  logic [1:0] first, last;
  logic increment_counter, decrement_counter, enable_counter, wr_queue, increment_last, increment_first;

enum logic {empty = 1'd0, dequeue = 1'd1} cs, ns;

// clear data available must clear added_to_queue flag in master fsm

  always_ff @(posedge clk or negedge rst_b) begin
   // $display ("q0 = %d , q1 = %d , q2 = %d , q3 = %d",queuememory[0], queuememory[1], queuememory[2], queuememory[3]);
    if (~rst_b) begin
      increment_counter <= 0;
      decrement_counter <= 0;
      enable_counter <= 0;
      clear_data_available <= 0;
      select <= 0;
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
      if (increment_counter)
        count <= count + 1;
        $display("count should not be 4 here : %d \
          and we increased it, if its 4 this is not possible!", count)
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
       last = last + 1;
    end
  end

  always_comb begin
    increment_first = 0;
    increment_last = 0;
    enable_counter = 0;
    increment_counter = 0;
    decrement_counter = 0;
    clear_data_available = 0;
    cleared_from_queue = 0;
    select = 0;
    wr_data = 0;
    wr_queue = 0;
    ns = empty;
    case (cs)
      empty: begin
        if (addtoqueue) begin
          $display("data_empty : %d must be zero, otherwise error", data_empty);
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
               $display("assert first %d == last %d", first, last);
             end
        3'b101: begin
                  //queue empty, noone wants to add to queue, data is empty
                ns = empty;
              end
        3'b110: begin
                  //queue empty, someone wants to add to queue, data is not empty
                  ns = dequeue;
                  enable_counter = 1;
                  increment_counter = 1;
                  increment_last = 1;
                  wr_queue = 1;
                end
        3'b111: begin
                  //queue empty, someone wants to add to queue, data empty
                  ns = empty;
                  clear_data_available[port_num] = 1;
                  wr_data = 1;
                  select = port_num;
                end
      endcase
      end
    endcase
  end

$display ("q0 = %d , q1 = %d , q2 = %d , q3 = %d",queuememory[0], queuememory[1], queuememory[2], queuememory[3] );


   assign queue_out = queuememory[first];
   assign queue_empty = (count == 0) ? 1 : 0;

endmodule
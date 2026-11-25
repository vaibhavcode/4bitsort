`timescale 1ns / 1ps

module insertion_sort_desc (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [15:0] din,
    output reg  [15:0] dout,
    output reg  [3:0]  cycles,
    output reg         done
);
    localparam IDLE = 2'd0, RUN = 2'd1, FIN = 2'd2;

    reg [1:0]  state;
    reg [2:0]  i, j;
    reg [15:0] arr;

    wire [1:0] jm1   = j[1:0] - 2'd1;
    wire [3:0] left  = arr[4*jm1    +: 4];
    wire [3:0] right = arr[4*j[1:0] +: 4];

    always @(posedge clk) begin
        if (rst) begin
            state  <= IDLE;
            done   <= 1'b0;
            cycles <= 4'd0;
            dout   <= 16'd0;
            i      <= 3'd1;
            j      <= 3'd1;
            arr    <= 16'd0;
        end else begin
            case (state)
                IDLE: if (start) begin
                    arr    <= din;
                    i      <= 3'd1;
                    j      <= 3'd1;
                    cycles <= 4'd0;
                    done   <= 1'b0;
                    state  <= RUN;
                end

                RUN: begin
                    if (j == 3'd0) begin
                        if (i == 3'd3) state <= FIN;
                        else begin i <= i + 3'd1; j <= i + 3'd1; end
                    end else begin
                        cycles <= cycles + 4'd1;
                        if (left < right) begin
                            arr[4*jm1    +: 4] <= right;
                            arr[4*j[1:0] +: 4] <= left;
                            j <= j - 3'd1;
                        end else begin
                            if (i == 3'd3) state <= FIN;
                            else begin i <= i + 3'd1; j <= i + 3'd1; end
                        end
                    end
                end

                FIN: begin
                    dout  <= arr;
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule

module oddeven_sort_desc (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [15:0] din,
    output reg  [15:0] dout,
    output reg  [3:0]  cycles,
    output reg         done
);
    localparam IDLE = 2'd0, RUN = 2'd1, FIN = 2'd2;

    reg [1:0] state;
    reg       phase;
    reg [3:0] a0, a1, a2, a3;

    wire is_sorted = (a0 >= a1) && (a1 >= a2) && (a2 >= a3);

    always @(posedge clk) begin
        if (rst) begin
            state  <= IDLE;
            done   <= 1'b0;
            cycles <= 4'd0;
            dout   <= 16'd0;
            phase  <= 1'b0;
            {a3, a2, a1, a0} <= 16'd0;
        end else begin
            case (state)
                IDLE: if (start) begin
                    {a3, a2, a1, a0} <= din;
                    phase  <= 1'b0;
                    cycles <= 4'd0;
                    done   <= 1'b0;
                    state  <= RUN;
                end

                RUN: begin
                    if (is_sorted) state <= FIN;
                    else begin
                        cycles <= cycles + 4'd1;
                        phase  <= ~phase;
                        if (!phase) begin
                            if (a0 < a1) begin a0 <= a1; a1 <= a0; end
                            if (a2 < a3) begin a2 <= a3; a3 <= a2; end
                        end else begin
                            if (a1 < a2) begin a1 <= a2; a2 <= a1; end
                        end
                    end
                end

                FIN: begin
                    dout  <= {a3, a2, a1, a0};
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule

module debounce #(parameter N = 20) (
    input  wire clk,
    input  wire in,
    output reg  out
);
    reg s0 = 1'b0, s1 = 1'b0;
    reg [N-1:0] cnt = {N{1'b0}};
    initial out = 1'b0;

    always @(posedge clk) begin
        s0 <= in;
        s1 <= s0;
        if (s1 == out) cnt <= {N{1'b0}};
        else begin
            cnt <= cnt + 1'b1;
            if (&cnt) out <= s1;
        end
    end
endmodule

module sevenseg_mux #(
    parameter AN_ACTIVE_LOW  = 1,
    parameter SEG_ACTIVE_LOW = 1
) (
    input  wire        clk,
    input  wire [4:0]  d0, d1, d2, d3,
    output wire [3:0]  an,
    output wire [7:0]  seg
);
    reg [16:0] cnt = 17'd0;
    always @(posedge clk) cnt <= cnt + 1'b1;
    wire [1:0] sel = cnt[16:15];

    reg [4:0] cur;
    reg [3:0] an_h;
    always @* begin
        case (sel)
            2'd0: begin cur = d0; an_h = 4'b0001; end
            2'd1: begin cur = d1; an_h = 4'b0010; end
            2'd2: begin cur = d2; an_h = 4'b0100; end
            default: begin cur = d3; an_h = 4'b1000; end
        endcase
    end

    reg [6:0] s;
    always @* begin
        if (cur[4]) s = 7'b0000000;
        else case (cur[3:0])
            4'h0: s = 7'b0111111;
            4'h1: s = 7'b0000110;
            4'h2: s = 7'b1011011;
            4'h3: s = 7'b1001111;
            4'h4: s = 7'b1100110;
            4'h5: s = 7'b1101101;
            4'h6: s = 7'b1111101;
            4'h7: s = 7'b0000111;
            4'h8: s = 7'b1111111;
            4'h9: s = 7'b1101111;
            4'hA: s = 7'b1110111;
            4'hB: s = 7'b1111100;
            4'hC: s = 7'b0111001;
            4'hD: s = 7'b1011110;
            4'hE: s = 7'b1111001;
            default: s = 7'b1110001;
        endcase
    end

    assign an  = AN_ACTIVE_LOW  ? ~an_h      : an_h;
    assign seg = SEG_ACTIVE_LOW ? ~{1'b0, s} : {1'b0, s};
endmodule

module boolean_top #(
    parameter DEBOUNCE_BITS  = 20,
    parameter AN_ACTIVE_LOW  = 1,
    parameter SEG_ACTIVE_LOW = 1
) (
    input  wire        clk_100mhz,
    input  wire [15:0] sw,
    input  wire [3:0]  btn,
    output wire [15:0] led,
    output wire [3:0]  D0_AN,
    output wire [7:0]  D0_SEG,
    output wire [3:0]  D1_AN,
    output wire [7:0]  D1_SEG
);
    wire [3:0] b;
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : DB
            debounce #(.N(DEBOUNCE_BITS)) u (.clk(clk_100mhz), .in(btn[g]), .out(b[g]));
        end
    endgenerate

    reg [3:0] b_d = 4'd0;
    always @(posedge clk_100mhz) b_d <= b;
    wire [3:0] pulse = b & ~b_d;

    wire rst     = b[3];
    wire start_p = pulse[0];
    wire next_p  = pulse[1];
    wire alg_p   = pulse[2];

    wire [15:0] ins_out, oe_out;
    wire [3:0]  ins_cyc, oe_cyc;
    wire        ins_done, oe_done;

    insertion_sort_desc u_ins (
        .clk(clk_100mhz), .rst(rst), .start(start_p), .din(sw),
        .dout(ins_out), .cycles(ins_cyc), .done(ins_done));

    oddeven_sort_desc u_oe (
        .clk(clk_100mhz), .rst(rst), .start(start_p), .din(sw),
        .dout(oe_out), .cycles(oe_cyc), .done(oe_done));

    reg [1:0] rank    = 2'd0;
    reg       alg_sel = 1'b0;
    always @(posedge clk_100mhz) begin
        if (rst) begin
            rank    <= 2'd0;
            alg_sel <= 1'b0;
        end else begin
            if (start_p)     rank <= 2'd0;
            else if (next_p) rank <= rank + 2'd1;
            if (alg_p)       alg_sel <= ~alg_sel;
        end
    end

    wire [15:0] shown = alg_sel ? oe_out : ins_out;
    wire [3:0]  value = shown[4*rank +: 4];

    wire [4:0] BLANK = 5'b10000;

    wire [3:0] ins_t = (ins_cyc >= 4'd10) ? 4'd1 : 4'd0;
    wire [3:0] ins_u = (ins_cyc >= 4'd10) ? ins_cyc - 4'd10 : ins_cyc;
    wire [3:0] oe_t  = (oe_cyc  >= 4'd10) ? 4'd1 : 4'd0;
    wire [3:0] oe_u  = (oe_cyc  >= 4'd10) ? oe_cyc - 4'd10 : oe_cyc;

    sevenseg_mux #(.AN_ACTIVE_LOW(AN_ACTIVE_LOW), .SEG_ACTIVE_LOW(SEG_ACTIVE_LOW)) u_d0 (
        .clk(clk_100mhz),
        .d3({1'b0, 3'd0, alg_sel} + 5'd1),
        .d2({3'd0, rank} + 5'd1),
        .d1(BLANK),
        .d0({1'b0, value}),
        .an(D0_AN), .seg(D0_SEG));

    sevenseg_mux #(.AN_ACTIVE_LOW(AN_ACTIVE_LOW), .SEG_ACTIVE_LOW(SEG_ACTIVE_LOW)) u_d1 (
        .clk(clk_100mhz),
        .d3({1'b0, ins_t}),
        .d2({1'b0, ins_u}),
        .d1({1'b0, oe_t}),
        .d0({1'b0, oe_u}),
        .an(D1_AN), .seg(D1_SEG));

    assign led[0]     = ins_done;
    assign led[1]     = oe_done;
    assign led[2]     = ins_done & oe_done & (ins_out == oe_out);
    assign led[3]     = alg_sel;
    assign led[5:4]   = rank;
    assign led[11:6]  = 6'd0;
    assign led[15:12] = value;
endmodule

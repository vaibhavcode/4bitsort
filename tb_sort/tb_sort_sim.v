`timescale 1ns / 1ps
//==============================================================================
// FILE 1 : tb_sort_sim.v   -- VIVADO SIMULATION ONLY (NOT for the board)
//
// Behavioral model of the project:
//   4 x 4-bit numbers (sw[15:0] = {D,C,B,A}) sorted DESCENDING by
//     (1) Insertion sort
//     (2) Odd-even transposition sort
//   and the number of compare/swap cycles each one takes.
//
// Cycle definitions (same as the board design in boolean_sort.v):
//   Insertion : 1 cycle per compare (compare + conditional swap)
//   Odd-even  : 1 cycle per phase (all pairs of that phase compared in parallel)
//
// HOW TO RUN:
//   Add as a *Simulation Source* -> set as simulation top (tb_sort_sim)
//   -> Run Simulation -> Run Behavioral Simulation. Read the Tcl Console.
//   Then Run All (or: run -all).
//==============================================================================
module tb_sort_sim;

    reg  [15:0] sw;                 // input, {D,C,B,A}
    reg  [3:0]  ia [0:3];           // insertion-sort working array
    reg  [3:0]  oa [0:3];           // odd-even working array
    reg  [3:0]  t;

    integer ins_cycles, oe_cycles;
    integer errors, tests;
    integer min_i, max_i, min_o, max_o;
    integer sum_i, sum_o;
    integer n, k, c_in, c_out, r;

    // waveform-friendly copies (add these to the wave window)
    reg [15:0] sorted_ins;          // {rank4,rank3,rank2,rank1}, rank1 = largest
    reg [15:0] sorted_oe;
    reg [7:0]  cyc_ins, cyc_oe;

    //--------------------------------------------------------------------------
    // Algorithm 1: insertion sort (descending)
    //--------------------------------------------------------------------------
    task insertion_sort;
        integer ii, jj;
        reg stop;
        begin
            ins_cycles = 0;
            for (ii = 1; ii < 4; ii = ii + 1) begin
                jj   = ii;
                stop = 1'b0;
                while (jj > 0 && !stop) begin
                    ins_cycles = ins_cycles + 1;          // one compare cycle
                    if (ia[jj-1] < ia[jj]) begin          // out of order -> swap
                        t        = ia[jj-1];
                        ia[jj-1] = ia[jj];
                        ia[jj]   = t;
                        jj       = jj - 1;
                    end else
                        stop = 1'b1;
                end
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Algorithm 2: odd-even transposition sort (descending)
    //   even phase: pairs (0,1),(2,3)   odd phase: pair (1,2)
    //--------------------------------------------------------------------------
    task oddeven_sort;
        reg ph;
        begin
            oe_cycles = 0;
            ph = 1'b0;
            while (!(oa[0] >= oa[1] && oa[1] >= oa[2] && oa[2] >= oa[3])) begin
                oe_cycles = oe_cycles + 1;                // one phase = one cycle
                if (!ph) begin
                    if (oa[0] < oa[1]) begin t = oa[0]; oa[0] = oa[1]; oa[1] = t; end
                    if (oa[2] < oa[3]) begin t = oa[2]; oa[2] = oa[3]; oa[3] = t; end
                end else begin
                    if (oa[1] < oa[2]) begin t = oa[1]; oa[1] = oa[2]; oa[2] = t; end
                end
                ph = ~ph;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Run one input vector, check results, optionally print
    //--------------------------------------------------------------------------
    task run_case;
        input [15:0] vec;
        input        verbose;
        begin
            sw = vec;
            ia[0] = vec[3:0];  ia[1] = vec[7:4];  ia[2] = vec[11:8];  ia[3] = vec[15:12];
            oa[0] = vec[3:0];  oa[1] = vec[7:4];  oa[2] = vec[11:8];  oa[3] = vec[15:12];

            insertion_sort;
            oddeven_sort;

            sorted_ins = {ia[3], ia[2], ia[1], ia[0]};
            sorted_oe  = {oa[3], oa[2], oa[1], oa[0]};
            cyc_ins    = ins_cycles;
            cyc_oe     = oe_cycles;

            tests = tests + 1;

            // check 1: descending order
            if (!(ia[0] >= ia[1] && ia[1] >= ia[2] && ia[2] >= ia[3])) begin
                errors = errors + 1;
                $display("ERROR: insertion not descending, in=%h out=%h", vec, sorted_ins);
            end
            // check 2: both algorithms agree
            if (sorted_ins !== sorted_oe) begin
                errors = errors + 1;
                $display("ERROR: mismatch, in=%h ins=%h oe=%h", vec, sorted_ins, sorted_oe);
            end
            // check 3: output is a permutation of the input
            for (k = 0; k < 16; k = k + 1) begin
                c_in  = (vec[3:0]   == k) + (vec[7:4]   == k) + (vec[11:8]  == k) + (vec[15:12] == k);
                c_out = (ia[0] == k) + (ia[1] == k) + (ia[2] == k) + (ia[3] == k);
                if (c_in != c_out) begin
                    errors = errors + 1;
                    $display("ERROR: not a permutation, in=%h out=%h", vec, sorted_ins);
                end
            end

            // statistics
            if (ins_cycles < min_i) min_i = ins_cycles;
            if (ins_cycles > max_i) max_i = ins_cycles;
            if (oe_cycles  < min_o) min_o = oe_cycles;
            if (oe_cycles  > max_o) max_o = oe_cycles;
            sum_i = sum_i + ins_cycles;
            sum_o = sum_o + oe_cycles;

            if (verbose) begin
                $display("--------------------------------------------------");
                $display("INPUT  A=%0d B=%0d C=%0d D=%0d", vec[3:0], vec[7:4], vec[11:8], vec[15:12]);
                // "one at a time" like the board display
                for (r = 0; r < 4; r = r + 1)
                    $display("  rank %0d : %0d   (insertion)  %0d (odd-even)",
                             r + 1, ia[r], oa[r]);
                $display("  CYCLES  insertion = %0d   odd-even = %0d", ins_cycles, oe_cycles);
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Stimulus
    //--------------------------------------------------------------------------
    initial begin
        errors = 0; tests = 0;
        min_i = 1000; max_i = 0; min_o = 1000; max_o = 0;
        sum_i = 0;    sum_o = 0;
        sw = 16'h0000;
        #10;

        $display("==================== DIRECTED TESTS ====================");
        // {D,C,B,A}
        run_case(16'h4321, 1);  #10;   // A=1 B=2 C=3 D=4  (ascending = worst case)
        run_case(16'h1234, 1);  #10;   // A=4 B=3 C=2 D=1  (already sorted = best case)
        run_case(16'h7777, 1);  #10;   // all equal
        run_case(16'h9C3F, 1);  #10;   // mixed
        run_case(16'hA5A5, 1);  #10;   // duplicates
        run_case(16'h0000, 1);  #10;
        run_case(16'hFFFF, 1);  #10;
        run_case(16'h2B91, 1);  #10;

        $display("================ EXHAUSTIVE (65536 inputs) =============");
        for (n = 0; n < 65536; n = n + 1)
            run_case(n[15:0], 0);

        $display("tests  = %0d", tests);
        $display("errors = %0d", errors);
        $display("Insertion : min=%0d max=%0d avg=%0d.%02d cycles", min_i, max_i,
                 sum_i / tests, ((sum_i * 100) / tests) % 100);
        $display("Odd-even  : min=%0d max=%0d avg=%0d.%02d cycles", min_o, max_o,
                 sum_o / tests, ((sum_o * 100) / tests) % 100);
        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL");
        $finish;
    end

endmodule

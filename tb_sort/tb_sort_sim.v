`timescale 1ns / 1ps

module tb_sort_sim;

    reg  [15:0] sw;
    reg  [3:0]  ia [0:3];
    reg  [3:0]  oa [0:3];
    reg  [3:0]  t;

    integer ins_cycles, oe_cycles;
    integer errors, tests;
    integer min_i, max_i, min_o, max_o;
    integer sum_i, sum_o;
    integer n, k, c_in, c_out;

    reg [15:0] sorted_ins;
    reg [15:0] sorted_oe;
    reg [7:0]  cyc_ins, cyc_oe;

    task insertion_sort;
        integer ii, jj;
        reg stop;
        begin
            ins_cycles = 0;
            for (ii = 1; ii < 4; ii = ii + 1) begin
                jj   = ii;
                stop = 1'b0;
                while (jj > 0 && !stop) begin
                    ins_cycles = ins_cycles + 1;
                    if (ia[jj-1] < ia[jj]) begin
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

    task oddeven_sort;
        reg ph;
        begin
            oe_cycles = 0;
            ph = 1'b0;
            while (!(oa[0] >= oa[1] && oa[1] >= oa[2] && oa[2] >= oa[3])) begin
                oe_cycles = oe_cycles + 1;
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

            if (!(ia[0] >= ia[1] && ia[1] >= ia[2] && ia[2] >= ia[3])) begin
                errors = errors + 1;
                $display("ERROR not sorted: in=%h out=%h", vec, sorted_ins);
            end

            if (sorted_ins !== sorted_oe) begin
                errors = errors + 1;
                $display("ERROR mismatch: in=%h ins=%h oe=%h", vec, sorted_ins, sorted_oe);
            end

            for (k = 0; k < 16; k = k + 1) begin
                c_in  = (vec[3:0]   == k) + (vec[7:4]   == k) + (vec[11:8]  == k) + (vec[15:12] == k);
                c_out = (ia[0] == k) + (ia[1] == k) + (ia[2] == k) + (ia[3] == k);
                if (c_in != c_out) begin
                    errors = errors + 1;
                    $display("ERROR bad permutation: in=%h out=%h", vec, sorted_ins);
                end
            end

            if (ins_cycles < min_i) min_i = ins_cycles;
            if (ins_cycles > max_i) max_i = ins_cycles;
            if (oe_cycles  < min_o) min_o = oe_cycles;
            if (oe_cycles  > max_o) max_o = oe_cycles;
            sum_i = sum_i + ins_cycles;
            sum_o = sum_o + oe_cycles;

            if (verbose)
                $display("in=%h sorted=%h cycles: ins=%0d oe=%0d",
                         vec, sorted_ins, ins_cycles, oe_cycles);
        end
    endtask

    initial begin
        errors = 0; tests = 0;
        min_i = 1000; max_i = 0; min_o = 1000; max_o = 0;
        sum_i = 0;    sum_o = 0;
        sw = 16'h0000;
        #10;

        run_case(16'h4321, 1);  #10;
        run_case(16'h1234, 1);  #10;
        run_case(16'h7777, 1);  #10;
        run_case(16'h9C3F, 1);  #10;
        run_case(16'hA5A5, 1);  #10;
        run_case(16'h0000, 1);  #10;
        run_case(16'hFFFF, 1);  #10;
        run_case(16'h2B91, 1);  #10;

        for (n = 0; n < 65536; n = n + 1)
            run_case(n[15:0], 0);

        $display("tests=%0d errors=%0d", tests, errors);
        $display("insertion: min=%0d max=%0d avg=%0d.%02d", min_i, max_i,
                 sum_i / tests, ((sum_i * 100) / tests) % 100);
        $display("odd-even:  min=%0d max=%0d avg=%0d.%02d", min_o, max_o,
                 sum_o / tests, ((sum_o * 100) / tests) % 100);
        if (errors == 0) $display("PASS");
        else             $display("FAIL");
        $finish;
    end

endmodule

module qpsk_differential_encoder (
    input  wire                         clk                        ,
    input  wire                         rst_n                      ,
    input  wire        [   1:0]         data_in                    ,
    input  wire                         data_valid                 ,
    output reg                          i_out                      ,
    output reg                          q_out                      ,
    output reg                          out_valid                   
);

reg                                     i_prev                     ;
reg                                     q_prev                     ;
reg last_data_valid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            i_out <= 1'b0;
            q_out <= 1'b0;
            i_prev <= 1'b0;
            q_prev <= 1'b0;
            out_valid <= 1'b0;
            last_data_valid <= 1'b0;
        end else begin
            last_data_valid <= data_valid;
            if (data_valid) begin
                i_out <= i_prev ^ data_in[0];
                q_out <= q_prev ^ data_in[1];

                i_prev <= i_prev ^ data_in[0];
                q_prev <= q_prev ^ data_in[1];

                out_valid <= 1'b1;
            end else if (last_data_valid && !data_valid) begin
                out_valid <= 1'b1;
                i_out <= i_prev ^ 1'b0;
                q_out <= q_prev ^ 1'b0;

                i_prev <= i_prev ^ 1'b0;
                q_prev <= q_prev ^ 1'b0;
            end else begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule
module qpsk_differential_decoder (
    input wire clk,
    input wire rst_n,
    input wire i_in,
    input wire q_in,
    input wire data_valid,
    output reg [1:0] data_out,
    output reg out_valid
);

    reg i_prev;
    reg q_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 2'b00;
            i_prev <= 1'b0;      
            q_prev <= 1'b0;      
            out_valid <= 1'b0;
        end else begin
            if (data_valid) begin
     
                data_out[0] <= i_in ^ i_prev;
                data_out[1] <= q_in ^ q_prev;

                i_prev <= i_in;
                q_prev <= q_in;
                
                out_valid <= 1'b1;
            end else begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule
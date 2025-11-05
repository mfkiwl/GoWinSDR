module demod_433 (
    input                               sys_clk                    ,
    input                               rst_n                      ,

    input              [  11:0]         adc_data_i1                ,
    input              [  11:0]         adc_data_q1                ,
    input                               adc_data_valid             ,

    output             [  11:0]         demod_data                 ,
    output                              demod_data_valid            
    );

reg                    [  12:0]         magnitude                  ;

wire                   [  11:0]         i_abs = adc_data_i1[11] ? -adc_data_i1 : adc_data_i1;
wire                   [  11:0]         q_abs = adc_data_q1[11] ? -adc_data_q1 : adc_data_q1;

always @(posedge sys_clk) begin
    magnitude <= i_abs + q_abs;
end

endmodule
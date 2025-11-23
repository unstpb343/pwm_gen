module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output[15:0] count_val,
    input[15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input[7:0] prescale
);

reg [7:0] prescale_cnt;
reg [15:0] period_cnt;
reg [7:0] int_prescale;
reg[15:0] int_period;
reg int_upnotdown;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
    period_cnt <= 0;
    prescale_cnt <= 0;
    
    int_prescale <= 0;
    int_period <= 0;
    int_upnotdown <= 0;
    end
    
    else if(count_reset) begin
    period_cnt <= 0;
    prescale_cnt <=0;
    
    int_prescale <= prescale;
    int_period <= period;
    int_upnotdown <= upnotdown;
    end
    
    else if(en) begin
        if(prescale_cnt>=int_prescale) begin
            prescale_cnt <= 0;
            
            if(int_upnotdown) begin
                if(period_cnt >= int_period) begin
                    period_cnt <= 0;
                    
                    int_period <= period;
                    int_prescale <= prescale;
                    int_upnotdown <= upnotdown;
                end
                else begin
                period_cnt <= period_cnt + 1;
                end
            end        
            else begin 
                if(period_cnt == 0) begin
                    period_cnt <= period;
                    
                    int_period <= period;
                    int_prescale <= prescale;
                    int_upnotdown <= upnotdown;
                end
                else begin
                period_cnt <= period_cnt - 1;
                end
             end
        end        
        else begin
        prescale_cnt <= prescale_cnt +1;
        end
     end
    else begin 
    int_period <= period;
    int_prescale <= prescale;
    int_upnotdown <= upnotdown;
    end
end

assign count_val = period_cnt;

endmodule

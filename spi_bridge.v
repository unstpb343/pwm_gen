module spi_bridge (
    input clk, rst_n, sclk, cs_n, mosi,
    output miso, byte_sync,
    output [7:0] data_in, // Acum va fi legat la buffer
    input [7:0] data_out
);

    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;
    
    // 1. ADĂUGĂM UN BUFFER PENTRU RECEPȚIE
    reg [7:0] buffer; 

    always @(posedge sclk or posedge cs_n or negedge rst_n) begin
        if(!rst_n) begin 
            shift_reg <= 0;
            bit_cnt   <= 0;
            buffer <= 0; 
        end
        else if(cs_n) begin
            bit_cnt   <= 0;
            shift_reg <= data_out; 
        end
        else begin
            shift_reg <= {shift_reg[6:0], mosi};
            bit_cnt   <= bit_cnt + 1;
            
            
            if (bit_cnt == 3'd7) begin
                
                buffer <= {shift_reg[6:0], mosi};
            end
        end
    end 

    assign miso = shift_reg[7];
    
    assign data_in = buffer; 
    
    assign byte_sync = (bit_cnt == 3'd7);

endmodule

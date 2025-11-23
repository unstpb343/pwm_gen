module regs (
    // peripheral clock signals
    input clk,
    input rst_n,
    // decoder facing signals
    input read,
    input write,
    input[5:0] addr,
    output reg[7:0] data_read,
    input[7:0] data_write,
    // counter programming signals
    input[15:0] counter_val,
    output[15:0] period,
    output en,
    output count_reset,
    output upnotdown,
    output[7:0] prescale,
    // PWM signal programming values
    output pwm_en,
    output[7:0] functions,
    output[15:0] compare1,
    output[15:0] compare2
);

// --- 1. Declararea Registrelor Interne (Logica de Stocare) ---
// Registre pe 16 biți
reg[15:0] period_r, compare1_r, compare2_r;
// Registre pe 8 biți (sau mai mici, extinse la 8 pentru a fi byte-addressable)
reg en_r, count_reset_r, upnotdown_r, pwm_en_r;
reg[7:0] prescale_r, functions_r;
// Contor intern pentru auto-clear COUNTER_RESET
reg[2:0] reset_clear_cnt;
// --- 2. Conectarea Ieșirilor la Registrele Interne ---
assign period = period_r;
assign compare1 = compare1_r;
assign compare2 = compare2_r;
assign prescale = prescale_r;
assign functions = functions_r;

assign en = en_r;
assign upnotdown = upnotdown_r;
assign pwm_en = pwm_en_r;
assign count_reset = count_reset_r; // Ieșirea activă

// --- 3. Logica de Scrierea (Sincronă) ---
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Reset Sincron (asigură o stare inițială cunoscută)
        period_r      <= 16'h0000;
        compare1_r    <= 16'h0000;
        compare2_r    <= 16'h0000;
        prescale_r    <= 8'h00;
        functions_r   <= 8'h00;
        en_r          <= 1'b0;
        upnotdown_r   <= 1'b0;
        pwm_en_r      <= 1'b0;
        count_reset_r <= 1'b0;
        reset_clear_cnt <= 3'b000;
    end else begin
        // --- Auto-Clear pentru COUNTER_RESET (0x07) ---
        if (count_reset_r) begin
            // CONTORIZEAZA 2 CICLURI DE CEAS DUPA CE E SCRIS
          if (reset_clear_cnt == 3'd3) begin
                count_reset_r <= 1'b0;
                reset_clear_cnt <= 3'b000;
            end else begin
                reset_clear_cnt <= reset_clear_cnt + 3'd1;
            end
        end

        // --- Logica de Scrierea (Write) ---
        if (write) begin
            case (addr)
                // PERIOD [15:0] (0x00 LSB, 0x01 MSB)
                6'h00: period_r[7:0] <= data_write;   // LSB
                6'h01: period_r[15:8] <= data_write;  // MSB

                // COUNTER_EN [0] (0x02)
                6'h02: en_r <= data_write[0];

                // COMPARE1 [15:0] (0x03 LSB, 0x04 MSB)
                6'h03: compare1_r[7:0] <= data_write;  // LSB
                6'h04: compare1_r[15:8] <= data_write; // MSB

                // COMPARE2 [15:0] (0x05 LSB, 0x06 MSB)
                6'h05: compare2_r[7:0] <= data_write;  // LSB
                6'h06: compare2_r[15:8] <= data_write; // MSB

                // COUNTER_RESET [0] (0x07) - Write-Only, auto-clear
                6'h07: begin
                    count_reset_r <= 1'b1; // Setare reset activ
                    reset_clear_cnt <= 3'b000; // Resetarea contorului de auto-clear
                end

                // PRESCALE [7:0] (0x0A)
                6'h0A: prescale_r <= data_write;

                // UPNOTDOWN [0] (0x0B)
                6'h0B: upnotdown_r <= data_write[0];

                // PWM_EN [0] (0x0C)
                6'h0C: pwm_en_r <= data_write[0];

                // FUNCTIONS [1:0] (0x0D)
                6'h0D: functions_r <= data_write;

                default: begin
                    // Adrese nevalide/nefolosite sunt ignorate la scriere
                end
            endcase
        end // end if (write)
    end
end

// --- 4. Logica de Citire (Combinatorie) ---
// data_read este logica combinatorie care multiplexează valoarea din registrul intern
// sau valoarea contorului curent (COUNTER_VAL) la ieșire.
always @(*) begin
    if (read) begin
        case (addr)
            // PERIOD [15:0] (0x00 LSB, 0x01 MSB)
            6'h00: data_read = period_r[7:0];
            6'h01: data_read = period_r[15:8];

            // COUNTER_EN [0] (0x02)
            6'h02: data_read = {7'h00, en_r};

            // COMPARE1 [15:0] (0x03 LSB, 0x04 MSB)
            6'h03: data_read = compare1_r[7:0];
            6'h04: data_read = compare1_r[15:8];

            // COMPARE2 [15:0] (0x05 LSB, 0x06 MSB)
            6'h05: data_read = compare2_r[7:0];
            6'h06: data_read = compare2_r[15:8];

            // COUNTER_RESET [0] (0x07) - Returnează 0 la citire, fiind WO
            6'h07: data_read = 8'h00;

            // COUNTER_VAL [15:0] (0x08 LSB, 0x09 MSB) - Citire directă din contor
            6'h08: data_read = counter_val[7:0];
            6'h09: data_read = counter_val[15:8];

            // PRESCALE [7:0] (0x0A)
            6'h0A: data_read = prescale_r;

            // UPNOTDOWN [0] (0x0B)
            6'h0B: data_read = {7'h00, upnotdown_r};

            // PWM_EN [0] (0x0C)
            6'h0C: data_read = {7'h00, pwm_en_r};

            // FUNCTIONS [1:0] (0x0D)
            6'h0D: data_read = {6'h00, functions_r[1:0]};

            default: data_read = 8'h00; // Returnează 0 pentru adrese nevalide/nefolosite
        endcase
    end else begin
        data_read = 8'hzz; // Ieșire de înaltă impedanță când nu se citește (opțional)
    end
end

endmodule

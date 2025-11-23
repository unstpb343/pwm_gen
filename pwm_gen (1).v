module pwm_gen (
    // peripheral clock signals
    input        clk,
    input        rst_n,

    // PWM signal register configuration
    input        pwm_en,       // activează / dezactiveaza generarea PWM
    input [15:0] period,       // perioada counter-ului (nu o folosim direct aici)
    input [7:0]  functions,    // funcțiile PWM: mod alinare / nealiniere
    input [15:0] compare1,     // primul prag de comparare
    input [15:0] compare2,     // al doilea prag (doar în unaligned)
    input [15:0] count_val,    // valoarea curenta a counterului

    // top facing signals
    output reg   pwm_out       // semnalul PWM final
);

    // Extragem semnificatia bitilor din FUNCTIONS
    wire aligned    = (functions[1] == 1'b0);   // 0 = aligned, 1 = unaligned
    wire left_align = (functions[0] == 1'b0);   // doar în mod aliniat

    // Detectam inceputul unei noi perioade (overflow)
    // Counterul revine la 0 -> incepe o perioada noua de PWM
    wire overflow = (count_val == 16'd0);

    // Procesarea PWM la fiecare clock
    always @(posedge clk or negedge rst_n) begin
        
        // Reset asincron pe nivel jos
        if (!rst_n) begin
            pwm_out <= 1'b0;   // iesirea este resetata complet

        // PWM dezactivat -> mentinem starea actuală
        end else if (!pwm_en) begin
            pwm_out <= pwm_out;

        // PWM activ -> generam semnalul
        end else begin

            // ===============================
            //    MOD ALINIAT (FUNCTIONS[1]=0)
            // ===============================
            if (aligned) begin

                // 1) La overflow -> setam valoarea de start
                if (overflow) begin
                    if (left_align)
                        pwm_out <= 1'b1;   // left aligned -> începe cu 1
                    else
                        pwm_out <= 1'b0;   // right aligned -> începe cu 0
                end

                // 2) La compare1 -> toggling (1->0 sau 0->1)
                else if (count_val == compare1) begin
                    pwm_out <= ~pwm_out;
                end

                // 3) In rest -> mentinem starea
                else begin
                    pwm_out <= pwm_out;
                end


            // ===============================
            //    MOD NEALINIAT (FUNCTIONS[1]=1)
            // ===============================
            end else begin

                // 1) La overflow -> inceputul perioadei -> pwm_out = 0
                if (overflow) begin
                    pwm_out <= 1'b0;
                end

                // 2) La compare1 -> pornim semnalul -> 1
                else if (count_val == compare1) begin
                    pwm_out <= 1'b1;
                end

                // 3) La compare2 - oprim semnalul -> 0
                else if (count_val == compare2) begin
                    pwm_out <= 1'b0;
                end

                // 4) In rest -> mentinem starea
                else begin
                    pwm_out <= pwm_out;
                end
            end
        end
    end

endmodule

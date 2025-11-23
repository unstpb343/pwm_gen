`timescale 1ns / 1ns

module regs_tb;

    // --- Semnale de Testbench (TB) ---
    reg clk;
    reg rst_n;

    // Semnale de la Decodor
    reg read;
    reg write;
    reg[5:0] addr;
    wire[7:0] data_read;
    reg[7:0] data_write;

    // Semnale de la Contor
    reg[15:0] counter_val_w; // Valoare simulată a contorului

    // Ieșirile Modulului (Verificate)
    wire[15:0] period;
    wire en;
    wire count_reset;
    wire upnotdown;
    wire[7:0] prescale;
    wire pwm_en;
    wire[7:0] functions;
    wire[15:0] compare1;
    wire[15:0] compare2;

    // --- Instanțierea Modulului de Testat (DUT) ---
    regs DUT (
        .clk(clk),
        .rst_n(rst_n),
        .read(read),
        .write(write),
        .addr(addr),
        .data_read(data_read),
        .data_write(data_write),
        .counter_val(counter_val_w),
        .period(period),
        .en(en),
        .count_reset(count_reset),
        .upnotdown(upnotdown),
        .prescale(prescale),
        .pwm_en(pwm_en),
        .functions(functions),
        .compare1(compare1),
        .compare2(compare2)
    );

    // --- Generarea Ceasului (50% Duty Cycle) ---
    parameter CLK_PERIOD = 10; // 10ns = 100MHz
    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2) clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    // --- Secvența de Test (Main Body) ---
    initial begin
        // Setare inițială
        read = 1'b0;
        write = 1'b0;
        addr = 6'h00;
        data_write = 8'h00;
        counter_val_w = 16'hFFFF; // Valoare inițială a contorului

        // 1. Reset Asincron
        $display("--- 1. RESET ASINCRON ---");
        rst_n = 1'b0;
        # (CLK_PERIOD * 3);
        rst_n = 1'b1;
        # (CLK_PERIOD);
        $display("Reset completat. Toate registrele ar trebui sa fie 0x0000 / 0.");

        // 2. Scrierea in PERIOD (0x00 LSB, 0x01 MSB)
        $display("--- 2. SCRIERE PERIOD (0xABBA) ---");
        // Scrierea LSB (0xBA) la adresa 0x00
        write = 1'b1;
        addr = 6'h00;
        data_write = 8'hBA;
        # (CLK_PERIOD);
        // Scrierea MSB (0xAB) la adresa 0x01
        addr = 6'h01;
        data_write = 8'hAB;
        # (CLK_PERIOD);
        write = 1'b0;

        // 3. Citirea PERIOD
        $display("--- 3. CITIRE PERIOD (Ar trebui sa fie 0xABBA) ---");
        read = 1'b1;
        // Citire LSB (0xBA) de la adresa 0x00
        addr = 6'h00;
        # (CLK_PERIOD/2);
        $display("Adresa 0x00 (LSB): Asteptat 0xBA, Citit %h", data_read);
        // Citire MSB (0xAB) de la adresa 0x01
        addr = 6'h01;
        # (CLK_PERIOD);
        $display("Adresa 0x01 (MSB): Asteptat 0xAB, Citit %h", data_read);
        read = 1'b0;
        # (CLK_PERIOD);

        // 4. Scrierea si Citirea Registrelor de Control (8 biti)
        $display("--- 4. SCRIERE/CITIRE CONTROL (PRESCALE 0x0A, FUNCTIONS 0x0D) ---");
        // Scrierea PRESCALE 0x42
        write = 1'b1;
        addr = 6'h0A;
        data_write = 8'h42;
        # (CLK_PERIOD);
        write = 1'b0;
        // Citirea PRESCALE
        read = 1'b1;
        addr = 6'h0A;
        # (CLK_PERIOD/2);
        $display("Adresa 0x0A (PRESCALE): Asteptat 0x42, Citit %h", data_read);
        read = 1'b0;

        // 5. Verificarea COUNTER_VAL (0x08 LSB, 0x09 MSB)
        $display("--- 5. CITIRE COUNTER_VAL (Simulat 0x1234) ---");
        counter_val_w = 16'h1234;
        read = 1'b1;
        // Citire LSB (0x34)
        addr = 6'h08;
        # (CLK_PERIOD/2);
        $display("Adresa 0x08 (CV LSB): Asteptat 0x34, Citit %h", data_read);
        // Citire MSB (0x12)
        addr = 6'h09;
        # (CLK_PERIOD);
        $display("Adresa 0x09 (CV MSB): Asteptat 0x12, Citit %h", data_read);
        read = 1'b0;

       // 6. Testarea COUNTER_RESET (0x07) si Auto-Clear (2 cicluri)
// Resetul trebuie sa fie HIGH in Ciclul 1 si Ciclul 2, si LOW in Ciclul 3 (T4).
$display("--- 6. COUNTER_RESET (Auto-Clear) ---");

// 1. Activare reset (Scriere 0x07)
write = 1'b1;
addr = 6'h07;
data_write = 8'hFF;

// Așteptăm frontul pozitiv unde se face scrierea (Ciclul 0 -> 1)
// write va fi dezactivat imediat dupa acest front, pentru a permite auto-clear-ul
# (CLK_PERIOD); 
write = 1'b0; 

// Acum citim starea count_reset pe fronturile urmatoare:

// T1/Ciclul 1: count_reset este HIGH (reset_clear_cnt -> 1)
@(posedge clk) $display("T1: count_reset este %b (Asteptat 1)", count_reset); 

// T2/Ciclul 2: count_reset este HIGH (reset_clear_cnt -> 2)
@(posedge clk) $display("T2: count_reset este %b (Asteptat 1)", count_reset); 

// T3/Ciclul 3: count_reset este HIGH (reset_clear_cnt -> 3. Logic: count_reset_r se schimba la 0 pe acest front)
@(posedge clk) $display("T3: count_reset este %b (Asteptat 1)", count_reset); 

// T4/Ciclul 4: count_reset este LOW (Logica din T3 este vizibila aici)
@(posedge clk) $display("T4: count_reset este %b (Asteptat 0)", count_reset); 

// Adaugam o verificare rapida
@(posedge clk);
if (count_reset == 1'b0) begin
    $display("SUCCESS: COUNTER_RESET s-a golit corect dupa 2 cicluri!");
end else begin
    $display("FAILURE: COUNTER_RESET NU s-a golit la timpul T4.");
end
        
        // Final
        $display("--- Simularea s-a terminat ---");
        $stop;
    end
endmodule

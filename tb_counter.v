`timescale 1ns / 1ps

module tb_counter;

    // 1. Definim semnalele de test (registre pentru intrări, fire pentru ieșiri)
    reg clk;
    reg rst_n;
    reg en;
    reg count_reset;
    reg upnotdown;
    reg [15:0] period;
    reg [7:0] prescale;
    
    wire [15:0] count_val; // Aici vedem ieșirea

    // 2. Instanțiem modulul tău (Device Under Test - DUT)
    counter dut (
        .clk(clk),
        .rst_n(rst_n),
        .count_val(count_val), // Legăm ieșirea la firul nostru
        .period(period),
        .en(en),
        .count_reset(count_reset),
        .upnotdown(upnotdown),
        .prescale(prescale)
    );

    // 3. Generăm ceasul (pulsează la fiecare 5ns -> perioadă 10ns = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. Scenariul de test (Povestea)
    initial begin
        // A. Inițializare (Totul e oprit)
        rst_n = 0;       // Ținem resetul apăsat
        en = 0;
        count_reset = 0;
        upnotdown = 1;   // Numărăm în sus
        period = 10;     // Numărăm până la 10
        prescale = 2;    // Prescaler mic (viteză mare)
        
        #20;             // Așteptăm 20ns
        rst_n = 1;       // Eliberăm resetul (pornire cip)
        #10;
        
        // B. Pornim motorul
        $display("Start numarare...");
        en = 1;          // Start!
        
        // Lăsăm să meargă câteva cicluri (aprox 2 ture complete)
        #500; 
        
        // C. Testăm Shadow Register (Schimbăm perioada în timp ce merge)
        $display("Schimbam perioada la 5 in timpul functionarii...");
        period = 5;      
        // Observă pe grafic: counterul ar trebui să termine tura veche (până la 10)
        // și abia apoi să numere doar până la 5.
        
        #300;
        
        // D. Testăm Direcția (Down)
        $display("Schimbam directia in JOS...");
        upnotdown = 0;
        
        #300;
        
        // E. Testăm Count Reset
        $display("Test Soft Reset...");
        count_reset = 1;
        #20;
        count_reset = 0;
        
        #100;
        $finish; // Oprim simularea
    end

endmodule

`timescale 1ns / 1ps

module tb_spi_bridge;

    // 1. SEMNALE
    reg clk;            // Ceas sistem (100 MHz)
    reg rst_n;
    
    // Semnale SPI (Simulăm Masterul)
    reg sclk;
    reg cs_n;
    reg mosi;
    wire miso;
    
    // Semnale Interne
    wire byte_sync;
    wire [7:0] data_in;  // Ce a primit bridge-ul de la Master
    reg  [7:0] data_out; // Ce vrea bridge-ul să trimită la Master

    // Variabile ajutătoare pentru verificare
    reg [7:0] master_rx_data; // Aici stocăm ce citim de pe MISO

    // 2. INSTANȚIERE (DUT - Device Under Test)
    spi_bridge dut (
        .clk(clk),
        .rst_n(rst_n),
        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),
        .byte_sync(byte_sync),
        .data_in(data_in),
        .data_out(data_out)
    );

    // 3. GENERARE CEAS SISTEM
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz (nu e folosit critic, dar e bine să fie)
    end

    // 4. TASK: Simulare Tranzacție SPI (Trimite un octet și primește unul)
    // Această "funcție" face munca grea de a da din pini de 8 ori
    task spi_transaction;
        input [7:0] data_to_send; // Ce trimite Masterul (MOSI)
        integer i;
    begin
        // A. Start Tranzacție
        cs_n = 0; // Activăm Slave-ul
        master_rx_data = 0;
        
        // B. Bucla de 8 biți
        for (i = 7; i >= 0; i = i - 1) begin
            // 1. Masterul pune bitul pe MOSI (MSB first)
            mosi = data_to_send[i];
            
            // Așteptăm un pic (setup time)
            #50; 
            
            // 2. Rising Edge SCLK (Slave-ul citește MOSI, shiftează MISO)
            sclk = 1;
            
            // 3. Citim ce ne dă Slave-ul pe MISO
            // (Construim octetul primit bit cu bit)
            master_rx_data[i] = miso;
            
            #50;
            
            // 4. Falling Edge SCLK
            sclk = 0;
        end
        
        // C. Stop Tranzacție
        #20;
        cs_n = 1; // Dezactivăm Slave-ul
        #20;
    end
    endtask

    // 5. SCENARIUL DE TEST
    initial begin
        // A. Inițializare
        rst_n = 0;
        sclk = 0;
        cs_n = 1; // Inactiv
        mosi = 0;
        data_out = 8'h00;
        
        // B. Reset Pulse
        #20;
        rst_n = 1;
        #20;

        // --- TEST 1: Master trimite 0xA5 (10100101) ---
        // Bridge-ul trimite înapoi 0xFF (setat mai jos)
        $display("TEST 1: Master sends 0xA5, Slave sends 0xFF");
        
        // 1. Încărcăm datele pe care Slave-ul trebuie să le trimită
        // Acest lucru se întâmplă cât timp CS_N este 1 (înainte de tranzacție)
        data_out = 8'hFF; 
        #10;
        
        // 2. Apelăm tranzacția SPI
        spi_transaction(8'hA5);
        
        // 3. Verificăm
        if (data_in == 8'hA5) $display("  -> SUCCESS: Bridge received 0xA5 correctly.");
        else                  $display("  -> ERROR: Bridge received %h instead of A5.", data_in);

        
        // --- TEST 2: Master trimite 0x3C (00111100) ---
        // Bridge-ul trimite înapoi ce a primit tura trecută (0xA5)
        // (Pentru că data_in este conectat la data_out în multe aplicații, 
        //  dar aici setăm manual data_out pentru test)
        
        $display("TEST 2: Master sends 0x3C, Slave sends 0x55");
        
        // Setăm ce vrea Slave-ul să trimită
        data_out = 8'h55; 
        #10;
        
        spi_transaction(8'h3C);
        
        // Verificăm ce a primit bridge-ul
        if (data_in == 8'h3C) $display("  -> SUCCESS: Bridge received 0x3C correctly.");
        else                  $display("  -> ERROR: Bridge received %h instead of 3C.", data_in);
        
        // Verificăm ce a primit Masterul (MISO)
        if (master_rx_data == 8'h55) $display("  -> SUCCESS: Master received 0x55 correctly from MISO.");
        else                         $display("  -> ERROR: Master received %h instead of 55.", master_rx_data);

        // Verificăm Byte Sync
        // Ar trebui să vedem un puls pe grafic la finalul tranzacției.
        
        #100;
        $finish;
    end

endmodule

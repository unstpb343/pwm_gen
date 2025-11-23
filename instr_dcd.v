// Descriere: Decodor de Instructiuni (instr_dcd.v)
// Ac?ioneaz? ca o Ma?in? de St?ri Finite (FSM) care traduce fluxul de octe?i de la SPI Bridge
// în semnale de control (read/write/addr) pentru Registre (regs.v).

module instr_dcd (
    // Clock ?i Reset
    input clk,
    input rst_n,
    // Interfa?? de la spi_bridge.v
    input byte_sync,      // Activ pe un ciclu cand un byte a fost receptionat
    input[7:0] data_in,   // Byte-ul primit de la SPI Master
    output reg[7:0] data_out, // Byte-ul de trimis catre SPI Master (MISO)
    // Interfa?? c?tre regs.v
    input[7:0] data_read,  // Byte-ul citit din registre
    output reg read,       
    output reg write,      
    output reg[5:0] addr,  
    output reg[7:0] data_write // Date de scris in registre
);

// --- Declararea St?rilor FSM ---
parameter STATE_SETUP = 1'b0; // A?teapt? octetul de instruc?iune (Byte 1)
parameter STATE_DATA  = 1'b1; // A?teapt?/Trimite octetul de date (Byte 2)

// Registre FSM ?i Starea Urm?toare
reg state_r; 
wire state_next; 

// Registre pentru a stoca instructiunea decodata din octetul de SETUP (STOCARE)
reg read_op_r, write_op_r;    // Bit 7: 0=Read, 1=Write
reg high_low_bit_r;         // Bit 6: 0=LSB, 1=MSB
reg[5:0] addr_temp_r;       // Bits 5:0: Adresa de baza

// --- 1. Logica Secven?ial? FSM (Tranzi?ia St?rilor ?i Staging) ---
// Logica de tranzi?ie FSM
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Resetarea registrelor de instructiuni stocate
        read_op_r      <= 1'b0;
        write_op_r     <= 1'b0;
        high_low_bit_r <= 1'b0;
        addr_temp_r    <= 6'h00; 
        state_r        <= STATE_SETUP;
    end else begin
        // Logica de Staging: Stocheaza instructiunea pe frontul din starea SETUP
        if (state_r == STATE_SETUP && byte_sync) begin
            write_op_r     <= data_in[7];
            read_op_r      <= ~data_in[7];
            high_low_bit_r <= data_in[6];
            addr_temp_r    <= data_in[5:0];
        end
        
        // Actualizarea St?rii FSM
        state_r <= state_next;
    end
end

// Logica Combinatorie FSM (Calculul St?rii Urm?toare)
assign state_next = (byte_sync) ? ~state_r : state_r;


// --- 2. Logica de Ac?iune (Secven?ial? ?i Control) ---
// Toate ie?irile de control ?i date sunt REG ?i sunt actualizate la byte_sync.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        // Resetare Semnale de Iesire
        read         <= 1'b0;
        write        <= 1'b0;
        addr         <= 6'h00;
        data_write   <= 8'h00;
        data_out     <= 8'h00;
    end else if (byte_sync) begin 
        // Logica de reset ?i activare la primirea unui byte
        read  <= 1'b0;
        write <= 1'b0;

        if (state_r == STATE_DATA) begin 
            // Ac?ion?m DOAR în starea DATA (Executarea Tranzac?iei)
            
            // 1. Calcularea Adresei Finale (Adresa de baza + Bitul H/L)
            addr <= addr_temp_r + high_low_bit_r; 

            if (write_op_r) begin
                // SCRIE
                write      <= 1'b1; 
                data_write <= data_in; // Captur?m byte-ul de date
                data_out   <= 8'h00; 
            end else if (read_op_r) begin
                // CITE?TE
                read       <= 1'b1; 
                data_out   <= data_read; // Trimitm datele din registrul citit
                data_write <= 8'h00; 
            end
        end else begin // STATE_SETUP
            // Reset?m ie?irile în starea SETUP (adres? invalid?, date nefolosite)
            addr       <= 6'h00; 
            data_write <= 8'h00; 
            data_out   <= 8'h00; 
        end
    end else begin
        // Când byte_sync e LOW, asigur?m c? semnalele de control r?mân inactive
        read  <= 1'b0;
        write <= 1'b0;
    end
end

endmodule

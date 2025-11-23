# Generator Semnal PWM – Documentație și Cod Complet

Acest fișier conține atât documentația pe module, cât și codul Verilog aferent perifericului PWM:
- `spi_bridge`
- `instr_dcd`
- `regs`
- `counter`
- `pwm_gen`
- `top`

Structura responsabilităților în echipă:
- **Stan Alexandru Ștefan** – Documentație, `pwm_gen`
- **Corodeanu Călin Andrei** – `counter`, `spi_bridge`
- **Șipanu Eduard** – `regs`, `instr_dcd`


---

## 1. Modulul `spi_bridge`

### Descriere

`spi_bridge` implementează logica de recepție și transmisie pentru protocolul SPI în modul slave, cu setările:
- CPOL = 0
- CPHA = 0
- MSB-first

Datele sunt:
- **citite** de pe linia `MOSI` pe frontul crescător al lui `sclk`,
- **emise** pe `MISO` pe frontul descrescător.

La fiecare 8 biți recepționați, se generează un octet valid (`rx_data`, `rx_valid`), transmis mai departe către modulul `instr_dcd`. Pentru transmisie, primește un octet (`tx_data`) și îl deplasează bit cu bit pe `MISO` când `tx_valid` este activ.

Semnalul `cs_n` (chip select, activ pe 0) delimitează tranzacțiile: la trecerea în 1, intern se resetează contorul de biți.

---

## 2. Modulul `instr_dcd`

### Descriere

`instr_dcd` (instruction decoder) primește octeții din `spi_bridge` și îi traduce în operații asupra blocului de registre (`regs`).

Protocolul este pe doi octeți:
- **Byte 1 (setup)**:
  - bit 7: R/W (1 = write, 0 = read)
  - bit 6: High/Low (1 = [15:8], 0 = [7:0])
  - bit 5:0: adresa registrului
- **Byte 2 (data)**:
  - la write: valoarea ce se scrie
  - la read: octet dummy de la master, iar perifericul trimite înapoi `reg_rdata`

Modulul este un FSM cu două stări: `IDLE` (așteaptă setup) și `DATA` (așteaptă byte-ul de date).

---

## 3. Modulul `regs`

### Descriere

`regs` reprezintă blocul de registre configurabile ale perifericului.  
Acesta este accesat pe 8 biți (octeți), dar internele pot avea 16 biți. Accesul HIGH/LOW este controlat de `reg_high`.

Registrele implementate (conform temei):
- `PERIOD` – 0x00, 16 biți
- `COUNTER_EN` – 0x02, 1 bit
- `COMPARE1` – 0x03, 16 biți
- `COMPARE2` – 0x05, 16 biți
- `COUNTER_RESET` – 0x07, 1 bit, write-only (se auto-cleară)
- `COUNTER_VAL` – 0x08, 16 biți, read-only
- `PRESCALE` – 0x0A, 8 biți
- `UPNOTDOWN` – 0x0B, 1 bit
- `PWM_EN` – 0x0C, 1 bit
- `FUNCTIONS` – 0x0D, [1:0], restul biților ignorați

---

## 4. Modulul `counter`

### Descriere

`counter` generează baza de timp, folosind:
- `period` – limita superioară
- `prescale` – cât de des se incrementează/decrementează counterul
- `upnotdown` – direcția de numărare
- `counter_en` / `counter_reset` – control de start/stop/reset

Valoarea curentă `count_val` este folosită de `pwm_gen` pentru comparații.
---

## 5. Modulul `pwm_gen`

### Descriere

`pwm_gen` generează semnalul `pwm_out` în funcție de:
- `count_val`
- `compare1`, `compare2`
- `functions`
- `pwm_en`

Moduri:
- **FUNCTIONS = 0x00** – aliniat stânga: semnalul începe cu 1 și devine 0 la `compare1`.
- **FUNCTIONS = 0x01** – aliniat dreapta: semnalul începe cu 0 și devine 1 la `compare1`.
- **FUNCTIONS = 0x02/0x03** – nealiniat: semnalul este 1 între `compare1` și `compare2`, 0 în rest.

---

## 6. Modulul `top`

### Descriere

`top` leagă toate modulele într-un singur periferic:
- primește semnalele SPI (`sclk`, `cs_n`, `mosi`, `miso`)
- primește clock-ul și reset-ul de sistem
- expune semnalul final `pwm_out`

---
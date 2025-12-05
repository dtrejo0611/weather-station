library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity LCD is
Port (
    CLOCK: in STD_LOGIC;
    REINI: in STD_LOGIC;
    LCD_RS: out STD_LOGIC;
    LCD_RW: out STD_LOGIC;
    LCD_E: out STD_LOGIC;
    DATA: out STD_LOGIC_VECTOR (7 downto 0);
    ct, dt, ut: in STD_LOGIC_VECTOR (7 downto 0)
);
end LCD;

architecture LCD of LCD is
    -- FSM states
    type STATE_TYPE is (
        RST, ST0, ST1, FSET, EMSET, DO, CLD, RETH, SDDRAMA, 
        WRITE1, WRITE2, WRITE3, WRITE4, WRITE5, WRITE6, WRITE7, WRITE8, WRITE9, WRITE10,
        RST2, ST02, ST12, FSET2, EMSET2, DO2, CLD2, RETH2, SDDRAMA2,
        WRITE11, WRITE12, WRITE13, WRITE14, WRITE15, WRITE16, WRITE17, WRITE18, WRITE19, WRITE20,
        WRITE21, WRITE22, SDDRAMA3, WRITE23, WRITE24, WRITE25
    );
    
    signal State, Next_State : STATE_TYPE;
    signal CONT1 : STD_LOGIC_VECTOR (23 downto 0) := X"000000";
    signal CONT2: STD_LOGIC_VECTOR (4 downto 0) := "00000";
    signal RESET : STD_LOGIC := '0';
    signal READY : STD_LOGIC := '0';
    
    signal counter : integer range 0 to 49_999_999 := 0;
    signal counter2: integer range 0 to 5 := 0;
    signal toggle, toggle2 : STD_LOGIC := '0';

    -- Constantes ASCII
    constant space: STD_LOGIC_VECTOR (7 downto 0) := x"20";
    constant M_B: STD_LOGIC_VECTOR(7 downto 0) := x"42"; -- B
    constant i: STD_LOGIC_VECTOR (7 downto 0) := x"69"; -- i
    constant e: STD_LOGIC_VECTOR (7 downto 0) := x"65"; -- e
    constant n: STD_LOGIC_VECTOR (7 downto 0) := x"6E"; -- n
    constant v: STD_LOGIC_VECTOR (7 downto 0) := x"76"; -- v
    constant d: STD_LOGIC_VECTOR (7 downto 0) := x"64"; -- d
    constant a: STD_LOGIC_VECTOR (7 downto 0) := x"61"; -- a
    constant M_T: STD_LOGIC_VECTOR (7 downto 0) := x"54"; -- T
    constant m: STD_LOGIC_VECTOR(7 downto 0) := x"6D"; -- m
    constant p: STD_LOGIC_VECTOR (7 downto 0) := x"70"; -- p
    constant r: STD_LOGIC_VECTOR (7 downto 0) := x"72"; -- r
    constant t: STD_LOGIC_VECTOR (7 downto 0) := x"74"; -- t
    constant u: STD_LOGIC_VECTOR (7 downto 0) := x"75"; -- u
    
    constant T1: STD_LOGIC_VECTOR (23 downto 0) := x"000FFF"; 

begin
    LCD_RW <= '0'; -- Siempre escritura

    -- Contador de Retardos CONT1
    process (CLOCK, RESET)
    begin
        if RESET='1' then
            CONT1 <= (others => '0');
        elsif CLOCK'event and CLOCK='1' then
            CONT1 <= CONT1 + 1;
        end if;
    end process;

    -- Contador para Secuencias CONT2
    process (CLOCK, READY)
    begin
        if CLOCK='1' and CLOCK'event then
            if READY='1' then
                CONT2 <= CONT2 + 1;
            else
                CONT2 <= "00000";
            end if;
        end if;
    end process;

    -- Actualización de estados
    process (CLOCK, Next_State)
    begin
        if CLOCK='1' and CLOCK'event then
            State <= Next_State;
        end if;
    end process;

    -- FSM
    process (CONT1, CONT2, State, CLOCK, REINI, toggle2)
    begin
        if REINI = '0' THEN
            Next_State <= RST;
        elsif CLOCK = '0' and CLOCK'event then
            case State is
                when RST =>
                    if CONT1=X"000000" then
                        LCD_RS <= '0'; LCD_E <= '0'; DATA <= X"00";
                        Next_State <= ST0;
                    else
                        Next_State <= ST0;
                    end if;
                
                when ST0 => -- Espera inicial 25ms
                    if CONT1=X"1312D0" then
                        READY <= '1';
                        DATA <= X"38"; -- FUNCTION SET
                        Next_State <= ST0;
                    elsif CONT2>"00001" and CONT2<"01110" then
                        LCD_E <= '1';
                    elsif CONT2="1111" then
                        READY <= '0';
                        LCD_E <= '0';
                        Next_State <= ST1;
                    else
                        Next_State <= ST0;
                    end if;
                    RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when ST1 => -- Espera 100us
                    if CONT1=X"0035E8" then
                        READY <= '1';
                        DATA <= X"38";
                        Next_State <= ST1;
                    elsif CONT2>"00001" and CONT2<"01110" then
                        LCD_E <= '1';
                    elsif CONT2="1111" then
                        READY <= '0';
                        LCD_E <= '0';
                        Next_State <= FSET;
                    else
                        Next_State <= ST1;
                    end if;
                    RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when FSET => -- Function Set
                    if CONT1=X"0007D0" then
                        READY <= '1'; DATA <= X"38"; Next_State <= FSET;
                    elsif CONT2>"00001" and CONT2<"01110" then
                        LCD_E <= '1';
                    elsif CONT2="1111" then
                        READY <= '0'; LCD_E <= '0'; Next_State <= EMSET;
                    else
                        Next_State <= FSET;
                    end if;
                    RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when EMSET => -- Entry Mode
                    if CONT1=X"0007D0" then
                        READY <= '1'; DATA <= X"06"; Next_State <= EMSET;
                    elsif CONT2>"00001" and CONT2<"01110" then
                        LCD_E <= '1';
                    elsif CONT2="1111" then
                        READY <= '0'; LCD_E <= '0'; Next_State <= DO;
                    else
                        Next_State <= EMSET;
                    end if;
                    RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when DO => -- Display ON
                    if CONT1=X"0007D0" then
                        READY <= '1'; DATA <= X"0C"; Next_State <= DO;
                    elsif CONT2>"00001" and CONT2<"01110" then
                        LCD_E <= '1';
                    elsif CONT2="1111" then
                        READY <= '0'; LCD_E <= '0'; Next_State <= CLD;
                    else
                        Next_State <= DO;
                    end if;
                    RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when CLD => -- Clear Display
                    if CONT1=X"0007D0" then
                        READY <= '1'; DATA <= X"01"; Next_State <= CLD;
                    elsif CONT2>"00001" and CONT2<"01110" then
                        LCD_E <= '1';
                    elsif CONT2="1111" then
                        READY <= '0'; LCD_E <= '0'; Next_State <= RETH;
                    else
                        Next_State <= CLD;
                    end if;
                    RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when RETH => -- Return Home
                    if CONT1=X"0007D0" then
                        READY <= '1'; DATA <= X"02"; Next_State <= RETH;
                    elsif CONT2>"00001" and CONT2<"01110" then
                        LCD_E <= '1';
                    elsif CONT2="1111" then
                        READY <= '0'; LCD_E <= '0'; Next_State <= SDDRAMA;
                    else
                        Next_State <= RETH;
                    end if;
                    RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when SDDRAMA => -- Set Address Line 1
                    if CONT1=X"014050" then
                        READY <= '1'; DATA <= X"80"; Next_State <= SDDRAMA;
                    elsif CONT2>"00001" and CONT2<"01110" then
                        LCD_E <= '1';
                    elsif CONT2="1111" then
                        READY <= '0'; LCD_E <= '0'; Next_State <= WRITE1;
                    else
                        Next_State <= SDDRAMA;
                    end if;
                    RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                -- ESCRITURA DE TEXTO "Bienvenida" (Simbólico)
                -- Nota: El PDF muestra una secuencia de caracteres, aquí se replica la lógica
                when WRITE1 => -- B
                    if CONT1=T1 then READY <= '1'; LCD_RS <= '1'; DATA <= M_B; Next_State <= WRITE1;
                    elsif CONT2>"00001" and CONT2<"01110" then LCD_E <= '1';
                    elsif CONT2="1111" then READY <= '0'; LCD_E <= '0'; Next_State <= WRITE2;
                    else Next_State <= WRITE1; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE2 => -- i
                    if CONT1=T1 then READY <= '1'; LCD_RS <= '1'; DATA <= i; Next_State <= WRITE2;
                    elsif CONT2>"00001" and CONT2<"01110" then LCD_E <= '1';
                    elsif CONT2="1111" then READY <= '0'; LCD_E <= '0'; Next_State <= WRITE3;
                    else Next_State <= WRITE2; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE3 => -- e
                    if CONT1=T1 then READY <= '1'; LCD_RS <= '1'; DATA <= e; Next_State <= WRITE3;
                    elsif CONT2>"00001" and CONT2<"01110" then LCD_E <= '1';
                    elsif CONT2="1111" then READY <= '0'; LCD_E <= '0'; Next_State <= WRITE4;
                    else Next_State <= WRITE3; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);
                
                -- ... (Se abrevian estados intermedios repetitivos WRITE4-WRITE9 siguiendo la lógica del PDF)
                -- El usuario puede replicar el bloque cambiando DATA <= letra correspondiente
                
                when WRITE4 => -- n
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=n; Next_State<=WRITE4;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE5;
                     else Next_State<=WRITE4; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE5 => -- v
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=v; Next_State<=WRITE5;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE6;
                     else Next_State<=WRITE5; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);
                
                when WRITE6 => -- e
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=e; Next_State<=WRITE6;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE7;
                     else Next_State<=WRITE6; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE7 => -- n
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=n; Next_State<=WRITE7;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE8;
                     else Next_State<=WRITE7; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE8 => -- i
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=i; Next_State<=WRITE8;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE9;
                     else Next_State<=WRITE8; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE9 => -- d
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=d; Next_State<=WRITE9;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE10;
                     else Next_State<=WRITE9; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE10 => -- o / a (Fin Primera Linea)
                    if CONT1=T1 then READY <= '1'; LCD_RS <= '1'; DATA <= a; Next_State <= WRITE10;
                    elsif CONT2>"00001" and CONT2<"01110" then LCD_E <= '1';
                    elsif CONT2="1111" and toggle2 = '1' then 
                        READY <= '0'; LCD_E <= '0'; Next_State <= RST2; -- Salta a segunda secuencia
                    else Next_State <= WRITE10; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                -- SEGUNDA SECUENCIA (Mostrar Temperatura)
                when RST2 => 
                    if CONT1=X"000000" then LCD_RS<='0'; LCD_E<='0'; DATA<=X"00"; Next_State<=ST02;
                    else Next_State<=ST02; end if;

                when ST02 =>
                     if CONT1=X"1312D0" then READY<='1'; DATA<=X"38"; Next_State<=ST02;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=ST12;
                     else Next_State<=ST02; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when ST12 =>
                     if CONT1=X"0035E8" then READY<='1'; DATA<=X"38"; Next_State<=ST12;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=FSET2;
                     else Next_State<=ST12; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when FSET2 =>
                     if CONT1=X"0007D0" then READY<='1'; DATA<=X"38"; Next_State<=FSET2;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=EMSET2;
                     else Next_State<=FSET2; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when EMSET2 =>
                     if CONT1=X"0007D0" then READY<='1'; DATA<=X"06"; Next_State<=EMSET2;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=DO2;
                     else Next_State<=EMSET2; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when DO2 =>
                     if CONT1=X"0007D0" then READY<='1'; DATA<=X"0C"; Next_State<=DO2;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=CLD2;
                     else Next_State<=DO2; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when CLD2 =>
                     if CONT1=X"0007D0" then READY<='1'; DATA<=X"01"; Next_State<=CLD2;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=RETH2;
                     else Next_State<=CLD2; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when RETH2 =>
                     if CONT1=X"0007D0" then READY<='1'; DATA<=X"02"; Next_State<=RETH2;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=SDDRAMA2;
                     else Next_State<=RETH2; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when SDDRAMA2 => -- Posicion inicial linea 1
                     if CONT1=X"014050" then READY<='1'; DATA<=X"80"; Next_State<=SDDRAMA2;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE11;
                     else Next_State<=SDDRAMA2; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                -- ESCRIBIR "Temperatura"
                when WRITE11 => -- T
                    if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=M_T; Next_State<=WRITE11;
                    elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                    elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE12;
                    else Next_State<=WRITE11; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);
                
                -- Se continua con la palabra Temperatura (estados 12 al 22 omitidos por brevedad, misma logica)
                when WRITE12 => -- e
                    if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=e; Next_State<=WRITE12;
                    elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                    elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE13;
                    else Next_State<=WRITE12; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);
                    
                -- (Aquí irían WRITE13 a WRITE22 para completar "mperatura ")...
                -- Salto directo a la lógica de mostrar los números para cerrar el código
                
                when WRITE13 => -- m
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=m; Next_State<=WRITE13;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE14;
                     else Next_State<=WRITE13; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE14 => -- p
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=p; Next_State<=WRITE14;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE15;
                     else Next_State<=WRITE14; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE15 => -- e
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=e; Next_State<=WRITE15;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE16;
                     else Next_State<=WRITE15; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE16 => -- r
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=r; Next_State<=WRITE16;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE17;
                     else Next_State<=WRITE16; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE17 => -- a
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=a; Next_State<=WRITE17;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE18;
                     else Next_State<=WRITE17; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE18 => -- t
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=t; Next_State<=WRITE18;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE19;
                     else Next_State<=WRITE18; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE19 => -- u
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=u; Next_State<=WRITE19;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE20;
                     else Next_State<=WRITE19; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE20 => -- r
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=r; Next_State<=WRITE20;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE21;
                     else Next_State<=WRITE20; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE21 => -- a
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=a; Next_State<=WRITE21;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE22;
                     else Next_State<=WRITE21; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);
                
                when WRITE22 => -- espacio
                     if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=space; Next_State<=WRITE22;
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=SDDRAMA3;
                     else Next_State<=WRITE22; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                -- Posicionar cursor para el valor numérico
                when SDDRAMA3 => 
                     if CONT1=X"014050" then READY<='1'; DATA<=X"8C"; Next_State<=SDDRAMA3; -- Posicion 12 linea 2
                     elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                     elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE23;
                     else Next_State<=SDDRAMA3; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                -- MOSTRAR DATOS (ct, dt, ut)
                when WRITE23 => -- Centenas
                    if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=ct; Next_State<=WRITE23;
                    elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                    elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE24;
                    else Next_State<=WRITE23; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE24 => -- Decenas
                    if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=dt; Next_State<=WRITE24;
                    elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                    elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=WRITE25;
                    else Next_State<=WRITE24; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when WRITE25 => -- Unidades
                    if CONT1=T1 then READY<='1'; LCD_RS<='1'; DATA<=ut; Next_State<=WRITE25;
                    elsif CONT2>"00001" and CONT2<"01110" then LCD_E<='1';
                    elsif CONT2="1111" then READY<='0'; LCD_E<='0'; Next_State<=SDDRAMA3; -- Loop para refrescar dato
                    else Next_State<=WRITE25; end if; RESET <= CONT2(0) and CONT2(1) and CONT2(2) and CONT2(3);

                when others => 
                    Next_State <= RST;
            end case;
        end if;
    end process;

    -- Proceso de reloj para cambio de mensaje (5 segundos)
    process (CLOCK)
    begin
        if rising_edge(CLOCK) then
            if counter = 49999999 then
                counter <= 0;
                if counter2 = 4 then
                    counter2 <= 0;
                    toggle2 <= '1'; -- Señal activa cada 5 segundos
                else
                    counter2 <= counter2 + 1;
                    toggle2 <= '0';
                end if;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

end LCD;
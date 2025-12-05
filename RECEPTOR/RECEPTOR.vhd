library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity RECEPTOR is
port(
    azul, rojo: out std_logic;
    reset: in std_logic;
    CLK: in STD_LOGIC; -- Reloj principal
    LEDS: out STD_LOGIC_VECTOR (7 downto 0);
    LCD_RS: out STD_LOGIC; -- del LCD (JC4)
    LCD_RW: out STD_LOGIC; -- read/write del LCD (JC5)
    LCD_E: out STD_LOGIC;  -- enable del LCD (JC6)
    DATA: out STD_LOGIC_VECTOR (7 downto 0); -- bus de datos de la LCD
    RX: in STD_LOGIC -- Entrada de datos del receptor
);
end RECEPTOR;

architecture Behavioral of RECEPTOR is
    -- Señales internas
    signal tx_in_s, rx_in_s: STD_LOGIC; 
    signal tx_fin_s, tx: STD_LOGIC; 
    signal asigna_led: std_logic_vector (7 downto 0);
    signal datain_s, dout_s: STD_LOGIC_VECTOR (7 downto 0);
    signal ct, dt, ut: std_logic_vector(7 downto 0);
    
    type Sreg0_type is (RECIBE, MUESTRA);
    signal Sreg0, NextState_Sreg0: Sreg0_type;

    component RS232 is
    generic(
        FPGA_CLK: integer := 50000000;
        BAUD_RS232: integer := 9600
    );
    port(
        CLK: in std_logic;
        RX: in std_logic;
        TX_INI: in std_logic;
        DATAIN: in std_logic_vector(7 downto 0);
        TX_FIN: out std_logic;
        TX: out std_logic;
        RX_IN: out std_logic;
        DOUT: out std_logic_vector(7 downto 0)
    );
    end component RS232;

begin
    u1: RS232 generic map(
        FPGA_CLK => 50_000_000,
        BAUD_RS232 => 9600
    )
    port map(
        CLK => CLK,
        RX => RX,
        TX_INI => tx_in_s,
        TX_FIN => tx_fin_s,
        TX => TX, -- No se utiliza transmisión
        RX_IN => rx_in_s,
        DATAIN => datain_s,
        DOUT => dout_s
    );

    u2: entity work.convtemp port map(
        TEMP => asigna_led,
        ct => ct,
        dt => dt,
        ut => ut
    );

    u3: entity work.LCD port map(
        CLOCK => CLK,
        REINI => reset,
        LCD_RS => LCD_RS,
        LCD_RW => LCD_RW,
        LCD_E => LCD_E,
        DATA => DATA,
        ct => ct,
        dt => dt,
        ut => ut
    );

    -- Lógica de Estado Siguiente
    Sreg0_NextState: process (Sreg0, RX_IN_S, dout_s)
    begin
        NextState_Sreg0 <= Sreg0;
        case Sreg0 is
            when RECIBE =>
                if RX_IN_S = '1' then
                    NextState_Sreg0 <= MUESTRA;
                elsif RX_IN_S = '0' then
                    NextState_Sreg0 <= RECIBE;
                end if;
            when MUESTRA =>
                asigna_led <= DOUT_S;
                NextState_Sreg0 <= RECIBE;
            when others =>
                null;
        end case;
    end process;

    -- Lógica de Estado Actual
    Sreg0_CurrentState: process (clk)
    begin
        if rising_edge(clk) then
            Sreg0 <= NextState_Sreg0;
        end if;
    end process;

    -- Control de LEDs
    process (asigna_led)
    begin
        if asigna_led < "01100100" then
            azul <= '1';
            rojo <= '0';
        else
            azul <= '0';
            rojo <= '1';
        end if;
    end process;
    
    LEDS <= asigna_led; -- Asignación faltante inferida para visualización en LEDs

end Behavioral;
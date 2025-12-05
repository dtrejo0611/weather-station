library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity EMISOR IS
port(
    azul, rojo: out std_logic;
    RESET: in std_logic;
    CLK: in STD_LOGIC;
    DIP_SWITCH: in STD_LOGIC_VECTOR (7 downto 0);
    reloj_adc: out std_logic;
    LCD_RS: out STD_LOGIC; -- del LCD (JC4)
    LCD_RW: out STD_LOGIC; -- read/write del LCD (JC5)
    LCD_E: out STD_LOGIC;  -- enable del LCD (JC6)
    DATA: out STD_LOGIC_VECTOR (7 downto 0); -- bus de datos de la LCD
    TX: out STD_LOGIC 
);
end EMISOR;

architecture Behavioral of EMISOR is
    signal ct, dt, ut: std_logic_vector(7 downto 0);
    signal tx_in_s, rx_in_s: std_logic;
    signal tx_fin_s, rx: std_logic;
    signal datain_s, dout_s: std_logic_vector (7 downto 0);
    
    constant COUNTER_MAX : integer := 24_999_999;
    
    type STATE_type is (ASIGNA, ENVIA);
    signal STATE, NextState_STATE: STATE_type;
    
    signal counter : integer range 0 to COUNTER_MAX := 0;
    signal toggle : STD_LOGIC := '0';

    -- Declaración de componentes
    component RS232 is
    generic(
        FPGA_CLK : integer := 50000000;
        BAUD_RS232 : integer := 9600
    );
    port(
        CLK : in std_logic;
        RX : in std_logic;
        TX_INI : in std_logic;
        DATAIN : in std_logic_vector(7 downto 0);
        TX_FIN : out std_logic;
        TX : out std_logic;
        RX_IN : out std_logic;
        DOUT : out std_logic_vector(7 downto 0)
    );
    end component RS232;

begin
    -- COMPONENTE PARA LA COMUNICACIÓN RS232
    u1: rs232 generic map(
        FPGA_CLK => 50_000_000,
        BAUD_RS232 => 9600
    )
    port map(
        CLK => CLK,
        RX => rx, -- rx interno no conectado a puerto físico en emisor según diagrama
        TX_INI => tx_in_s,
        TX_FIN => tx_fin_s,
        TX => TX,
        RX_IN => rx_in_s,
        DATAIN => datain_s,
        DOUT => dout_s
    );

    -- Máquina de estados principal
    STATE_NextState: process (STATE, TX_FIN_s, DIP_SWITCH)
    begin
        NextState_STATE <= STATE; 
        case STATE is
            when ASIGNA =>
                DATAIN_S <= DIP_SWITCH;
                NextState_STATE <= ENVIA;
            when ENVIA =>
                if TX_FIN_s = '0' then
                    NextState_STATE <= ENVIA;
                    TX_IN_s <= '1';
                elsif TX_FIN_s = '1' then
                    NextState_STATE <= ASIGNA;
                    TX_IN_s <= '0';
                end if;
            when others =>
                null;
        end case;
    end process;

    u2: entity work.convtemp port map(
        TEMP => DIP_SWITCH,
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

    -- Lógica secuencial de estado
    STATE_CurrentState: process (clk)
    begin
        if rising_edge(clk) then
            STATE <= NextState_STATE;
        end if;
    end process;

    -- Generador de reloj para ADC (toggle)
    adc: process (clk)
    begin
        if rising_edge(clk) then
            if counter = COUNTER_MAX then
                counter <= 0;
                -- Toggle logic
                if toggle = '0' then 
                    toggle <= '1'; 
                else 
                    toggle <= '0'; 
                end if;
            else
                counter <= counter + 1;
            end if;
            
            -- Lógica alternativa del PDF para toggle
            if counter < COUNTER_MAX / 2 then
                toggle <= '0';
            else
                toggle <= '1';
            end if;
        end if;
    end process;

    -- Control de LEDs
    process (DIP_SWITCH)
    begin
        if DIP_SWITCH < "01100100" then -- Comparación con 100 decimal (aprox)
            azul <= '1';
            rojo <= '0';
        else
            azul <= '0';
            rojo <= '1';
        end if;
    end process;

    reloj_adc <= toggle;

end Behavioral;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity EMISOR is
    Port ( clk : in STD_LOGIC;            -- Reloj del sistema
           reset : in STD_LOGIC;          -- Señal de reset
           tx_data : in STD_LOGIC_VECTOR(7 downto 0); -- Datos a transmitir
           start_tx : in STD_LOGIC;       -- Señal para iniciar la transmisión
           tx : out STD_LOGIC);            -- Pin de transmisión (TX)
end EMISOR;

architecture Behavioral of EMISOR is
	 signal baud_div : integer := 0;
    signal baud_rate_counter : integer := 0;
    signal tx_reg : STD_LOGIC_VECTOR(9 downto 0); -- 1 bit start + 8 bits de datos + 1 bit de parada
    signal tx_busy : STD_LOGIC := '0';
    constant baud_rate : integer := 9600;
    constant clock_freq : integer := 50000000; -- Asumimos un reloj de 50 MHz

begin

    -- Generador de la tasa de baudios (divisor de frecuencia)
    process(clk, reset)
    begin
        if reset = '0' then
            baud_rate_counter <= 0;
        elsif rising_edge(clk) then
            if baud_rate_counter = (clock_freq / baud_rate) - 1 then
                baud_rate_counter <= 0;
            else
                baud_rate_counter <= baud_rate_counter + 1;
            end if;
        end if;
    end process;

    -- Transmisor UART
    process(clk, reset)
    begin
        if reset = '0' then
            tx_busy <= '0';
            tx_reg <= (others => '1'); -- Línea en estado '1' (idle)
            tx <= '1'; -- Estado idle (sin transmisión)
        elsif rising_edge(clk) then
            if baud_rate_counter = 0 then
                if start_tx = '0' and tx_busy = '0' then
                    -- Iniciar transmisión de datos
                    tx_reg <= '0' & tx_data & '1'; -- Start bit + datos + stop bit
                    tx_busy <= '1';
                elsif tx_busy = '1' then
                    -- Enviar un bit de tx_reg
                    tx <= tx_reg(0); -- Enviar el bit menos significativo
                    tx_reg <= tx_reg(9 downto 1) & '1'; -- Shift de bits
                    if tx_reg(8 downto 0) = "111111111" then
                        -- Transmisión completa
                        tx_busy <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;

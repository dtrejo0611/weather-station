library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RS232 is
    generic (
        FPGA_CLK : INTEGER := 50000000; -- Frecuencia del FPGA
        BAUD_RS232 : INTEGER := 9600    -- Baudios
    );
    port (
        CLK : in std_logic;
        RX : in std_logic;
        TX_INI : in std_logic;
        TX_FIN : out std_logic;
        TX : out std_logic;
        RX_IN : out std_logic;
        DATAIN : in std_logic_vector(7 downto 0);
        DOUT : out std_logic_vector(7 downto 0)
    );
end RS232;

architecture Behavioral of RS232 is
    CONSTANT FPGA_CLK2 : INTEGER := FPGA_CLK;
    CONSTANT BAUD_RS2322 : INTEGER := BAUD_RS232;
    CONSTANT BAUD_FPGA2 : INTEGER := FPGA_CLK2/BAUD_RS2322;
    CONSTANT CLKBAUD2 : INTEGER := BAUD_FPGA2/2;

    signal flanco_bajada : std_logic := '0';
    signal clk_ini : std_logic := '0';
    signal clk_tx_ini : std_logic := '0';
    signal clk_flanco : std_logic := '0';
    signal clk_tx_flanco : std_logic := '0';
    
    signal rx_vector : std_logic_vector(4 downto 0);
    signal rx_vector2 : std_logic_vector(4 downto 0);
    
    signal tx_data : std_logic_vector(7 downto 0);
    signal tx_data2 : std_logic_vector(7 downto 0);
    
    signal dout_paralelo : std_logic_vector(9 downto 0);
    
    signal clk_baud : natural range 0 to CLKBAUD2 := 0;
    signal clk_tx_baud : natural range 0 to BAUD_FPGA2 := 0;
    
    signal paralelo_paso : natural range 0 to 6 := 0;
    signal tx_maquina : natural range 0 to 6 := 0;
    signal n : natural range 0 to 10 := 0;
    signal tx_n : natural range 0 to 10 := 0;

begin
    -- Registro de corrimiento que muestrea RX en busca de condicion de INICIO
    rx_vector <= rx_vector2(3 downto 0) & RX;
    
    process (CLK)
    begin
        if rising_edge(CLK) then
            rx_vector2 <= rx_vector;
        end if;
    end process;

    -- Genera un flanco de bajada siempre que la condicion "1100" sea cierta
    flanco_bajada <= '1' when rx_vector(4 downto 1) = "1100" else '0';

    -- Maquina de estados que controla la recepcion de 1 byte
    RECEPCION: process (CLK)
    begin
        if rising_edge(CLK) then
            if paralelo_paso = 0 then
                n <= 0;
                if flanco_bajada = '1' then
                    paralelo_paso <= 1;
                else
                    paralelo_paso <= 0;
                end if;
                RX_IN <= '0';
            elsif paralelo_paso = 1 then
                clk_ini <= '1';
                paralelo_paso <= 2;
            elsif paralelo_paso = 2 then
                if clk_flanco = '1' then
                    paralelo_paso <= 5;
                else
                    paralelo_paso <= 2;
                end if;
            elsif paralelo_paso = 3 then
                if clk_flanco = '1' then
                    paralelo_paso <= 4;
                else 
                    if n < 10 then
                        paralelo_paso <= 3;
                    else
                        n <= 10;
                        paralelo_paso <= 6;
                    end if;
                end if;
            elsif paralelo_paso = 4 then
                if clk_flanco = '1' then
                    paralelo_paso <= 5;
                else
                    paralelo_paso <= 4;
                end if;
            elsif paralelo_paso = 5 then
                 n <= n + 1;
                 dout_paralelo(n) <= RX;
                 paralelo_paso <= 3;
            else
                 DOUT <= dout_paralelo(8 downto 1);
                 clk_ini <= '0';
                 n <= 0;
                 paralelo_paso <= 0;
                 RX_IN <= '1';
            end if;
        end if;
    end process;

    -- Reloj con frecuencia de BAUDIOS/2 para entrada
    process (CLK)
    begin
        if rising_edge(CLK) then
            if clk_ini = '1' then
                if clk_baud < (CLKBAUD2-1) then
                    clk_baud <= clk_baud + 1;
                    clk_flanco <= '0';
                else
                    clk_baud <= 0;
                    clk_flanco <= '1';
                end if;
            else
                clk_flanco <= '0';
                clk_baud <= 0;
            end if;
        end if;
    end process;

    -- Maquina de estados que controla transmisión de 1 BYTE
    TRANSMICION: process (CLK)
    begin
        if rising_edge(CLK) then
            if tx_maquina = 0 then
                TX <= '1';
                clk_tx_ini <= '0';
                tx_n <= 0;
                TX_FIN <= '0';
                if TX_INI = '1' then
                    tx_maquina <= 1;
                    tx_data <= DATAIN;
                else
                    tx_maquina <= 0;
                    tx_data <= "00000000";
                end if;
            elsif tx_maquina = 1 then
                TX <= '0';
                clk_tx_ini <= '1';
                tx_maquina <= 2;
            elsif tx_maquina = 2 then
                if clk_tx_flanco = '1' then
                    tx_maquina <= 3;
                    TX <= tx_data(0);
                else
                    tx_maquina <= 2;
                end if;
            elsif tx_maquina = 3 then
                if tx_n < 9 then
                    tx_n <= tx_n + 1;
                    tx_data2 <= '1' & tx_data(7 downto 1);
                    tx_maquina <= 4;
                else
                    tx_maquina <= 5;
                end if;
            elsif tx_maquina = 4 then
                tx_data <= tx_data2;
                tx_maquina <= 2;
            else
                if TX_INI = '1' then
                    TX_FIN <= '1';
                    tx_maquina <= 5;
                else
                    TX_FIN <= '0';
                    tx_maquina <= 0;
                end if;
            end if;
        end if;
    end process;

    -- RELOJ DE BAUDIOS PARA TRANSMISION
    process (CLK)
    begin
        if rising_edge(CLK) then
            if clk_tx_ini = '1' then
                if clk_tx_baud < (BAUD_FPGA2-1) then
                    clk_tx_baud <= clk_tx_baud + 1;
                    clk_tx_flanco <= '0';
                else
                    clk_tx_baud <= 0;
                    clk_tx_flanco <= '1';
                end if;
            else
                clk_tx_flanco <= '0';
                clk_tx_baud <= 0;
            end if;
        end if;
    end process;

end Behavioral;
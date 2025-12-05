library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity convtemp is
port(
    TEMP: in std_logic_vector(7 downto 0) := (others => '0');
    ct, dt, ut: out std_logic_vector(7 downto 0)
);
end convtemp;

architecture behavioral of convtemp is
    signal decimal : integer := 0;
    signal centenas, decenas, unidades : integer := 0;
begin
    -- Proceso para calcular los dígitos
    process (TEMP)
    begin
        -- Convertir TEMP a un valor decimal (temperatura en °C)
        decimal <= to_integer(unsigned(TEMP)) / 2; -- Ajuste según LM35 y ADC
        
        -- Calcular centenas, decenas y unidades
        centenas <= decimal / 100;
        decenas <= (decimal mod 100) / 10;
        unidades <= decimal mod 10;
        
        -- Convertir a ASCII (+48 decimal es el offset ASCII para números)
        ct <= std_logic_vector(to_unsigned(centenas + 48, 8));
        dt <= std_logic_vector(to_unsigned(decenas + 48, 8));
        ut <= std_logic_vector(to_unsigned(unidades + 48, 8));
    end process;
end behavioral;
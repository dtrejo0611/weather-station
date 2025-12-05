------------------------------------------------------------------------------------------
-- Ejemplo de uso del módulo bluetooth HC06 como receptor
-- Conectado a la tarjeta Nexys2, usando protocolo RS-232 y
-- una aplicación de celular comercial que envía código ASCII.
------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

----------------------------------------------------------
entity RECEPTOR is
    port(
        clk    : in std_logic;                -- 50 MHz
        reset  : in std_logic;                -- Reset
        rx     : in std_logic;                -- Entrada de datos del módulo Bluetooth (a DO)
        leds   : out std_logic_vector(7 downto 0)  -- Salida a LEDs
    );
end RECEPTOR;

----------------------------------------------------------
architecture rx of RECEPTOR is
    -- FSM states
    type state_type is (EDO_1, EDO_2);
    signal presentstate : state_type := EDO_1;  -- Estado presente
    signal nextstate    : state_type;           -- Estado futuro

    -- Señales
    signal control : std_logic := '0';          -- Indica cuando ocurre el bit de start
    signal done    : std_logic := '0';          -- Indica cuando termina la recepción de datos
    signal tmp     : std_logic_vector(8 downto 0) := "000000000"; -- Registro de datos

    -- Contadores para los retardos
    -- signal i : std_logic_vector(3 downto 0) := "0000"; -- Contador de los bits recibidos
    signal c      : std_logic_vector(9 downto 0) := "1111111111";  -- Contador de retardos (868)
    signal delay  : std_logic := '0';          -- Reloj de C2
    signal c2     : std_logic_vector(1 downto 0) := "11";           -- Contador de muestreo
    signal capture: std_logic := '0';          -- Reloj de captura

begin
    ----------------------------- Proceso de retardo
    -- Proceso de retardo al triple de la frecuencia
    process(clk)
    begin
        if clk'event and clk = '1' then
            if c < "1101100100" then
                c <= c + '1';  -- 868
            else
                c <= (others => '0');
            end if;
            delay <= not delay;
        end if;
    end process;

    ----------------------------- Proceso para el contador C2
    -- Proceso para el contador C2 para la captura
    process(delay)
    begin
        if delay'event and delay = '1' then
            if c2 > "01" then
                c2 <= "00";  -- Control de muestreo
            else
                c2 <= c2 + '1';
            end if;
        end if;
    end process;

    ----------------------------- Proceso para captura
    -- Proceso para capturar en el bit de en medio (capture)
    process(c2)
    begin
        if c2 = "01" then
            capture <= '1';  -- Activar captura
        else
            capture <= '0';  -- Desactivar captura
        end if;
    end process;

    ----------------------------- FSM para controlar la recepción
    -- FSM
    process(reset, capture)
    begin
        if capture'event and capture = '1' then
            if reset = '0' then
                presentstate <= EDO_1;  -- Reset al estado inicial
            else
                presentstate <= nextstate;
            end if;
        end if;
    end process;

    ----------------------------- Transición de estados de la FSM
    process(presentstate, rx, done)
    begin
        case presentstate is
            when EDO_1 =>
                if rx = '1' and done = '0' then
                    control <= '0';  -- Esperando inicio de la transmisión
                    nextstate <= EDO_1;
                elsif rx = '0' and done = '0' then
                    control <= '1';  -- Se ha recibido un bit de inicio
                    nextstate <= EDO_2;
                else
                    control <= '0';
                    nextstate <= EDO_1;
                end if;

            when EDO_2 =>
                if done = '0' then
                    control <= '1';  -- Continuar recibiendo datos
                    nextstate <= EDO_2;
                else
                    control <= '0';  -- Fin de la recepción
                    nextstate <= EDO_1;
                end if;

            when others =>
                nextstate <= EDO_1;
        end case;
    end process;

    ----------------------------- Proceso de recepción de datos
    -- Proceso de recepción de datos
    process(capture)
    begin
        if capture'event and capture = '1' then
            if control = '1' and done = '0' then
                tmp <= rx & tmp(8 downto 1);  -- Captura rx
            end if;
        end if;
    end process;

    ----------------------------- Proceso que cuenta los bits recibidos
    -- Proceso que cuenta los bits que llegan (9 bits)
    process(capture, control, reset)
    variable i : std_logic_vector(3 downto 0) := "0000";  -- Contador de los bits recibidos
    begin
        if reset = '0' then
            leds <= x"00";  -- Apagar LEDs en caso de reset
        elsif capture'event and capture = '1' then
            if control = '1' then
                if (i >= "1001") then
                    i := x"0";  -- Resetear contador de bits
                    done <= '1';  -- Señal de fin de recepción
                    leds <= tmp(8 downto 1);  -- Mostrar datos en LEDs
                else
                    i := i + '1';  -- Incrementar contador de bits
                    done <= '0';
                end if;
            else
                done <= '0';
            end if;
        end if;
    end process;

end rx; -- Fin de la arquitectura

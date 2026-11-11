library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rsa_fsm is
    generic (
        H : positive := 256
    );
    port (
        clk          : in  std_logic;
        reset_n      : in  std_logic;

        msgin_valid  : in  std_logic;
        msgin_ready  : out std_logic;
        msgin_last   : in  std_logic;

        msgout_valid : out std_logic;
        msgout_ready : in  std_logic;
        msgout_last  : out std_logic;

        e_bit        : in  std_logic;
        e_rest_zero  : in  std_logic;
        mul_done     : in  std_logic;
        sq_done      : in  std_logic;

        load_en      : out std_logic;
        mul_start    : out std_logic;
        sq_start     : out std_logic;
        update_c     : out std_logic;
        update_p     : out std_logic;
        shift_e      : out std_logic
    );
end rsa_fsm;

architecture Behavioral of rsa_fsm is

    type state_type is (IDLE, START, WAIT_DONE, SHIFT, OUT_ST);
    signal state, next_state : state_type := IDLE;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                state <= IDLE;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    process(state, reset_n, msgin_valid, msgout_ready,
            e_bit, e_rest_zero, mul_done, sq_done)
    begin
        next_state   <= state;

        msgin_ready  <= '0';
        msgout_valid <= '0';
        msgout_last  <= '0';

        load_en      <= '0';
        mul_start    <= '0';
        sq_start     <= '0';
        update_c     <= '0';
        update_p     <= '0';
        shift_e      <= '0';

        if reset_n = '0' then
            next_state <= IDLE;
        else
            case state is

                when IDLE =>
                    msgin_ready <= '1';
                    if msgin_valid = '1' then
                        load_en    <= '1';
                        next_state <= START;
                    end if;

                when START =>
                    if e_bit = '1' then
                        mul_start <= '1';
                    end if;
                    sq_start   <= '1';
                    next_state <= WAIT_DONE;

                when WAIT_DONE =>
                    if (mul_done = '1' or e_bit = '0') and sq_done = '1' then
                        next_state <= SHIFT;
                    end if;

                when SHIFT =>
                    update_c <= e_bit;
                    update_p <= '1';
                    shift_e  <= '1';
                    if e_rest_zero = '1' then
                        next_state <= OUT_ST;
                    else
                        next_state <= START;
                    end if;

                when OUT_ST =>
                    msgout_valid <= '1';
                    msgout_last  <= '1';
                    if msgout_ready = '1' then
                        next_state <= IDLE;
                    end if;

            end case;
        end if;
    end process;

end Behavioral;
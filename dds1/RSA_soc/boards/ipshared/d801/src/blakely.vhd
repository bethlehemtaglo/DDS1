library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blakely is
    generic (BLOCK_SIZE : integer := 256);
    Port (
        clk     : in  STD_LOGIC;
        reset_n : in  STD_LOGIC;
        n       : in  STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);
        b       : in  STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);
        a       : in  STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);
        R       : out STD_LOGIC_VECTOR(BLOCK_SIZE-1 downto 0);
        done    : out STD_LOGIC
    );
end blakely;

architecture Behavioral of blakely is

    constant W : integer := BLOCK_SIZE + 3;

    type state_type is (INIT, STG_A, STG_B, STG_C, FINISH);
    signal state : state_type := INIT;

    signal a_shift : std_logic_vector(BLOCK_SIZE-1 downto 0) := (others => '0');
    signal i_cnt   : integer range 0 to BLOCK_SIZE-1 := 0;
    signal done_r  : std_logic := '0';

    signal s_reg  : unsigned(W-1 downto 0) := (others => '0');
    signal s1_reg : unsigned(W-1 downto 0) := (others => '1');
    signal t1_reg : unsigned(W-1 downto 0) := (others => '0');
    signal d_reg  : unsigned(W-1 downto 0) := (others => '0');
    signal bn_reg : unsigned(W-1 downto 0) := (others => '0');

    signal n_ext, b_ext : unsigned(W-1 downto 0);
    signal r_eff, r_dbl : unsigned(W-1 downto 0);
    signal ax, a_sub    : unsigned(W-1 downto 0);

begin

    n_ext <= resize(unsigned(n), W);
    b_ext <= resize(unsigned(b), W);

    r_eff <= s_reg when s1_reg(W-1) = '1' else s1_reg;
    r_dbl <= r_eff(W-2 downto 0) & '0';

    ax    <= b_ext when state = INIT else r_dbl;
    a_sub <= ax - n_ext;

    R    <= std_logic_vector(r_eff(BLOCK_SIZE-1 downto 0));
    done <= done_r;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                state   <= INIT;
                i_cnt   <= 0;
                a_shift <= a;
                s_reg   <= (others => '0');
                s1_reg  <= (others => '1');
                done_r  <= '0';
            else
                case state is

                    when INIT =>
                        bn_reg <= a_sub;
                        state  <= STG_A;

                    when STG_A =>
                        t1_reg <= a_sub;
                        state  <= STG_B;

                    when STG_B =>
                        if t1_reg(W-1) = '1' then
                            d_reg <= r_dbl;
                        else
                            d_reg <= t1_reg;
                        end if;
                        state <= STG_C;

                    when STG_C =>
                        if a_shift(BLOCK_SIZE-1) = '1' then
                            s_reg  <= d_reg + b_ext;
                            s1_reg <= d_reg + bn_reg;
                        else
                            s_reg  <= d_reg;
                            s1_reg <= (others => '1');
                        end if;
                        a_shift <= a_shift(BLOCK_SIZE-2 downto 0) & '0';
                        if i_cnt = BLOCK_SIZE-1 then
                            state <= FINISH;
                        else
                            i_cnt <= i_cnt + 1;
                            state <= STG_A;
                        end if;

                    when FINISH =>
                        done_r <= '1';

                end case;
            end if;
        end if;
    end process;

end Behavioral;
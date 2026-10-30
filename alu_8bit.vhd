library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity alu_8bit is
    Port ( A      : in  STD_LOGIC_VECTOR (7 downto 0);
           B      : in  STD_LOGIC_VECTOR (7 downto 0);
           OP     : in  STD_LOGIC_VECTOR (1 downto 0);  -- 00=ADD, 01=SUB, 10=AND, 11=OR
           RESULT : out STD_LOGIC_VECTOR (7 downto 0);
           COUT   : out STD_LOGIC;                      -- carry out (SUB: 1 = no borrow)
           ZERO   : out STD_LOGIC);                     -- 1 when RESULT = 0
end alu_8bit;

architecture Structural of alu_8bit is

    component adder_8bit
        Port ( A    : in  STD_LOGIC_VECTOR (7 downto 0);
               B    : in  STD_LOGIC_VECTOR (7 downto 0);
               CIN  : in  STD_LOGIC;
               SUM  : out STD_LOGIC_VECTOR (7 downto 0);
               COUT : out STD_LOGIC);
    end component;

    component xor_gate
        Port ( A : in  STD_LOGIC;
               B : in  STD_LOGIC;
               Y : out STD_LOGIC);
    end component;

    component and_gate
        Port ( A : in  STD_LOGIC;
               B : in  STD_LOGIC;
               Y : out STD_LOGIC);
    end component;

    component or_gate
        Port ( A : in  STD_LOGIC;
               B : in  STD_LOGIC;
               Y : out STD_LOGIC);
    end component;

    component mux4
        Port ( D0  : in  STD_LOGIC;
               D1  : in  STD_LOGIC;
               D2  : in  STD_LOGIC;
               D3  : in  STD_LOGIC;
               SEL : in  STD_LOGIC_VECTOR (1 downto 0);
               Y   : out STD_LOGIC);
    end component;

    signal sub_sel  : STD_LOGIC;                        -- '1' only for SUB
    signal b_xor    : STD_LOGIC_VECTOR (7 downto 0);    -- B, inverted when subtracting
    signal sum_res  : STD_LOGIC_VECTOR (7 downto 0);    -- adder output (ADD and SUB)
    signal and_res  : STD_LOGIC_VECTOR (7 downto 0);
    signal or_res   : STD_LOGIC_VECTOR (7 downto 0);
    signal res_int  : STD_LOGIC_VECTOR (7 downto 0);    -- selected result
    signal cout_add : STD_LOGIC;

begin

    -- SUB (OP = "01"): A - B = A + (NOT B) + 1
    sub_sel <= (not OP(1)) and OP(0);

    -- Adder / subtractor: XOR each B bit with sub_sel, carry-in = sub_sel
    ADDER: adder_8bit port map ( A => A, B => b_xor, CIN => sub_sel,
                                 SUM => sum_res, COUT => cout_add );

    -- One slice per bit: XOR (for SUB), AND, OR and a 4-to-1 multiplexer
    GEN_BIT: for i in 0 to 7 generate
        XG: xor_gate port map ( A => B(i), B => sub_sel, Y => b_xor(i) );
        AG: and_gate port map ( A => A(i), B => B(i),    Y => and_res(i) );
        OG: or_gate  port map ( A => A(i), B => B(i),    Y => or_res(i) );
        MX: mux4     port map ( D0 => sum_res(i),   -- 00 ADD
                                D1 => sum_res(i),   -- 01 SUB
                                D2 => and_res(i),   -- 10 AND
                                D3 => or_res(i),    -- 11 OR
                                SEL => OP, Y => res_int(i) );
    end generate GEN_BIT;

    RESULT <= res_int;
    COUT   <= cout_add and (not OP(1));              -- carry only meaningful for ADD/SUB
    ZERO   <= '1' when res_int = "00000000" else '0';

end Structural;

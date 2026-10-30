library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity alu_8bit_tb is
end alu_8bit_tb;

architecture Behavioral of alu_8bit_tb is

    component alu_8bit
        Port ( A      : in  STD_LOGIC_VECTOR (7 downto 0);
               B      : in  STD_LOGIC_VECTOR (7 downto 0);
               OP     : in  STD_LOGIC_VECTOR (1 downto 0);
               RESULT : out STD_LOGIC_VECTOR (7 downto 0);
               COUT   : out STD_LOGIC;
               ZERO   : out STD_LOGIC);
    end component;

    signal A_tb      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal B_tb      : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    signal OP_tb     : STD_LOGIC_VECTOR (1 downto 0) := "00";
    signal RESULT_tb : STD_LOGIC_VECTOR (7 downto 0);
    signal COUT_tb   : STD_LOGIC;
    signal ZERO_tb   : STD_LOGIC;

begin

    UUT: alu_8bit port map ( A => A_tb, B => B_tb, OP => OP_tb,
                             RESULT => RESULT_tb, COUT => COUT_tb, ZERO => ZERO_tb );

    stim_proc: process
        variable errors : integer := 0;

        -- Apply one test vector, compute the expected answer, and compare
        procedure test (a_v : in STD_LOGIC_VECTOR (7 downto 0);
                        b_v : in STD_LOGIC_VECTOR (7 downto 0);
                        op_v : in STD_LOGIC_VECTOR (1 downto 0)) is
            variable exp_res  : STD_LOGIC_VECTOR (7 downto 0);
            variable exp_cout : STD_LOGIC := '0';
            variable wide     : unsigned (8 downto 0);
        begin
            A_tb <= a_v; B_tb <= b_v; OP_tb <= op_v;
            wait for 10 ns;

            case op_v is
                when "00" =>        -- ADD
                    wide     := ('0' & unsigned(a_v)) + ('0' & unsigned(b_v));
                    exp_res  := STD_LOGIC_VECTOR(wide(7 downto 0));
                    exp_cout := wide(8);
                when "01" =>        -- SUB, COUT = 1 means no borrow (A >= B)
                    wide     := ('0' & unsigned(a_v)) + ('0' & unsigned(not b_v)) + 1;
                    exp_res  := STD_LOGIC_VECTOR(wide(7 downto 0));
                    exp_cout := wide(8);
                when "10" =>        -- AND
                    exp_res  := a_v and b_v;
                    exp_cout := '0';
                when others =>      -- OR
                    exp_res  := a_v or b_v;
                    exp_cout := '0';
            end case;

            if RESULT_tb /= exp_res then
                errors := errors + 1;
                report "FAIL: RESULT wrong for OP=" & integer'image(to_integer(unsigned(op_v)))
                       & " A=" & integer'image(to_integer(unsigned(a_v)))
                       & " B=" & integer'image(to_integer(unsigned(b_v))) severity error;
            end if;
            if COUT_tb /= exp_cout then
                errors := errors + 1;
                report "FAIL: COUT wrong for OP=" & integer'image(to_integer(unsigned(op_v)))
                       & " A=" & integer'image(to_integer(unsigned(a_v)))
                       & " B=" & integer'image(to_integer(unsigned(b_v))) severity error;
            end if;
            if (ZERO_tb = '1') /= (exp_res = "00000000") then
                errors := errors + 1;
                report "FAIL: ZERO flag wrong" severity error;
            end if;

            wait for 10 ns;
        end procedure;

    begin
        wait for 10 ns;

        -- ADD (OP = 00)
        test(x"05", x"03", "00");   -- 5 + 3 = 8
        test(x"7F", x"01", "00");   -- 127 + 1 = 128
        test(x"FF", x"01", "00");   -- overflow: result 00, carry = 1, zero = 1
        test(x"00", x"00", "00");   -- zero result

        -- SUB (OP = 01)
        test(x"09", x"04", "01");   -- 9 - 4 = 5
        test(x"04", x"09", "01");   -- 4 - 9 = FB (borrow, carry = 0)
        test(x"55", x"55", "01");   -- equal operands: result 00, zero = 1
        test(x"00", x"01", "01");   -- 0 - 1 = FF

        -- AND (OP = 10)
        test(x"F0", x"3C", "10");   -- F0 AND 3C = 30
        test(x"AA", x"55", "10");   -- AA AND 55 = 00, zero = 1

        -- OR (OP = 11)
        test(x"F0", x"0F", "11");   -- F0 OR 0F = FF
        test(x"AA", x"55", "11");   -- AA OR 55 = FF
        test(x"00", x"00", "11");   -- 00 OR 00 = 00, zero = 1

        if errors = 0 then
            report "PASS: alu_8bit testbench completed with no errors" severity note;
        else
            report "FAIL: alu_8bit testbench found errors" severity error;
        end if;
        wait;
    end process;

end Behavioral;

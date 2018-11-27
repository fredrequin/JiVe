component jive_bootrom is
    port(clk_en_i: in std_logic;
         rd_data_o: out std_logic_vector(31 downto 0);
         wr_data_i: in std_logic_vector(31 downto 0);
         clk_i: in std_logic;
         wr_en_i: in std_logic;
         addr_i: in std_logic_vector(7 downto 0));
end component;

__: jive_bootrom port map(clk_en_i=> , rd_data_o=> , wr_data_i=> , clk_i=> ,
    wr_en_i=> , addr_i=> );
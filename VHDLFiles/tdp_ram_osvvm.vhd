LIBRARY IEEE, OSVVM;
USE ieee.std_logic_1164.ALL;
USE iee.numeric_std.ALL;
USE ieee.math_real.ALL;
CONTEXT OSVVM.OsvvmContext;

ENTITY test_tdp_ram IS
END ENTITY;

ARCHITECTURE test OF test_tdp_ram IS

  CONSTANT data_width       : positive   := 16;
  CONSTANT addr_width       : positive   := 16;
  CONSTANT port_width_power : natural    := 0;

  SIGNAL reset_             : std_ulogic := '0';
  SIGNAL reset_b            : std_ulogic := '0';
  SIGNAL clk_a              : std_ulogic := '0';
  SIGNAL clk_b              : std_ulogic := '0';
  SIGNAL write_enable_a     : std_ulogic := '0';
  SIGNAL write_enable_b     : std_ulogic := '0';
  SIGNAL port_enable_a      : std_ulogic := '0';
  SIGNAL port_enable_b      : std_ulogic := '0';
  SIGNAL data_in_a          : std_ulogic_vector(data_width - 1 DOWNTO 0);
  SIGNAL data_in_b          : std_ulogic_vector((data_width * (2 ** port_width_power)) - 1 DOWNTO 0);
  SIGNAL data_out_a         : std_ulogic_vector(data_width - 1 DOWNTO 0);
  SIGNAL data_out_b         : std_ulogic_vector((data_width * (2 ** port_width_power)) - 1 DOWNTO 0);
  SIGNAL address_a          : std_ulogic_vector(addr_width - 1 DOWNTO 0);
  SIGNAL address_b          : std_ulogic_vector(addr_width - port_width_power - 1 DOWNTO 0); --need to check

  CONSTANT clk_a_period     : time := 3 NS;
  CONSTANT clk_b_period     : time := 3 NS;

  COMPONENT tdp_ram_cmp.tdp_ram
    GENERIC (
      WRITE_MODE_A
      WRITE_MODE_B
      addr_width
      data_width
      port_width_power
      register_ram_out_a
      register_ram_out_b
    );
    PORT (
      reset_a
      reset_b
      clk_a
      clk_b
      write_enable_a
      write_enable_b
      port_enable_a
      port_enable_b
      data_in_a
      data_in_b
      data_out_a
      data_out_b
      address_a
      address_b
    );
  END COMPONENT;

  -- put write and read procedures here

  SIGNAL test_done               : integer_barrier := 1;
  SIGNAL test_active             : boolean         := TRUE;
  SHARED VARIABLE scoreboard_a   : ScoreboardPType;
  SHARED VARIABLE scoreboard_b   : ScoreboardPType;
  SHARED VARIABLE stim_cov_a     : CovPType;
  SHARED VARIABLE stim_cov_b     : CovPType;
  SHARED VARIABLE rand_address_a : integer;

BEGIN

  dut : tdp_ram_cmp.tdp_ram
  GENERIC MAP(
    WRITE_MODE_A       => "WRITE_FIRST",
    WRITE_MODE_B       => "WRITE_FIRST",
    addr_width         => 16,
    data_width         => 16,
    port_width_power   => 0,
    register_ram_out_a => FALSE,
    register_ram_out_b => FALSE
  )
  PORT MAP(
    reset_a        => reset_a,
    reset_b        => reset_b,
    clk_a          => clk_a,
    clk_b          => clk_b,
    write_enable_a => write_enable_a,
    write_enable_b => write_enable_b,
    port_enable_a  => port_enable_a,
    port_enable_b  => port_enable_b,
    data_in_a      => data_in_a,
    data_in_b      => data_in_b,
    data_out_a     => data_out_a,
    data_out_b     => data_out_b,
    address_a      => address_a,
    address_b      => address_b
  );

  CreateClock(clk_a, clk_a_period);
  CreateClock(clk_b, clk_b_period);

  reset_proc_a : PROCESS
  BEGIN
    CreateReset(reset_a, '1', clk_a, 10 ns, 10 ns);
    WAIT;
  END PROCESS reset_proc_a;

  reset_proc_b : PROCESS
  BEGIN
    CreateReset(reset_b, '1', clk_b, 10 ns, 10 ns);
  END PROCESS reset_proc_b;

  control_proc : PROCESS
  BEGIN
    SetAlertLogName("tdp_ram");
    SetLogEnable(PASSED, TRUE);

    -- Wait for two delta cycles for the TB to initialise
    WAIT FOR 0 ns;
    WAIT FOR 0 ns;

    WAIT UNTIL (reset_a = '0') AND (reset_b = '0');
    WAIT UNTIL (rising_edge(clk_a)) AND (rising_edge(clk_b));
    ClearAlerts;

    WaitForBarrier(test_done, 35 ms);
    AlertIf(now >= 35 ms, "Test finished due to timeout");
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");

    print("");
    print("Test Run: " & test_tdp_ram'INSTANCE_NAME & LF & ' ');
    ReportAlerts;
    print("");
    std.env.stop;
    WAIT;
  END PROCESS control_proc;

  stim_proc_a : PROCESS
    VARIABLE rand_data : integer;
  BEGIN
    stim_cov_a.AddCross(GenBin(0, 65535, 1), GenBin(0, 65535, 1));
    stim_cov_a.InitSeed(stim_cov'INSTANCE_NAME);
    stim_cov_a.SetAlertLogID("RAM A Port");

    -- Wait for two delta cycles for the TB to initialise
    WAIT FOR 0 ns;
    WAIT FOR 0 ns;

    WAIT UNTIL (reset_a = '0');
    WAIT UNTIL rising_edge(clk_a);
    WAIT FOR 10 * clk_a_period;
    FOR i IN 0 TO 1000 LOOP
      (rand_data, rand_address_a) := stim_cov_a.RandCovPoint;
      scoreboard_a.Push(to_slv(rand_data), to_slv(rand_address_a));
      stim_cov_a.ICover(rand_data, rand_address_a);
      --write data procedure
      WAIT FOR 10 * clk_a_period;
    END LOOP;
    test_active <= FALSE;
    WaitForBarrier(TestDone);
    WAIT;
  END PROCESS stim_proc_a;

  check_proc_a : PROCESS
  BEGIN
    WAIT FOR 0 ns;
    WAIT FOR 0 ns;
    WAIT UNTIL (reset_a = '0');
    WAIT UNTIL rising_edge(clk_a);
    WAIT FOR 10 * clk_a_period;
    WAIT FOR 5 * clk_a_period;

    WHILE test_active /= FALSE LOOP
      --read data procedue
      scoreboard_a.Check();
    END LOOP;

    WAIT FOR 5 * clk_a_period;
    WaitForBarrier(TestDone);
    WAIT;
  END PROCESS check_proc_a;
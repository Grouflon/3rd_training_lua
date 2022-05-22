adresses = {
  global = {
    -- [byte][read/write] hex value is the decimal display
    character_select_timer = 0x020154FB,
  },
  players = {
    {
      -- [byte][read/write] from 0 to 6
      character_select_row = 0x020154CF, 

      -- [byte][read/write] from 0 to 2
      character_select_col = 0x0201566B,

      -- [byte][read] from 0 to 2
      character_select_sa = 0x020154D3,

      -- [byte][read] from 0 to 6
      character_select_color = 0x02015683,

        -- [byte][read] from 0 to 5
        -- - 0 is no player
        -- - 1 is intro anim
        -- - 2 is character select
        -- - 3 is SA intro anim
        -- - 4 is SA select
        -- - 5 is locked SA
        -- Will always stay at 5 after that and during the match
      character_select_state = 0x0201553D,

      -- [byte] used to overwrite shin gouki id
      character_select_id = 0x02011387,

      -- [byte] number of legs pressed fur Chun's Hyakuretsu Kyaku
      kyaku_l_count = 0x02025A03,
      kyaku_m_count = 0x02025A05,
      kyaku_h_count = 0x02025A07,

      -- [byte] time before Hyakuretsu Kyaku button count reset
      kyaku_reset_time = 0x020259f3,
    },
    {
      character_select_row = 0x020154D1,
      character_select_col = 0x0201566D,
      character_select_sa = 0x020154D5,
      character_select_color = 0x02015684,
      character_select_state = 0x02015545,
      character_select_id = 0x02011388,

      kyaku_l_count = 0x02026023,
      kyaku_m_count = 0x02026025,
      kyaku_h_count = 0x02026027,
      kyaku_reset_time = 0x02026013,
    }
  }
}

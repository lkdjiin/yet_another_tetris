class Levels
  # Frames to wait before a piece drops one row.
  def self.get_frames_for(level)
    return 1 if level > 25
    {
      1 => 50,
      2 => 45,
      3 => 40,
      4 => 35,
      5 => 31,
      6 => 27,
      7 => 23,
      8 => 20,
      9 => 18,
      10 => 16,
      11 => 15,
      12 => 14,
      13 => 13,
      14 => 12,
      15 => 11,
      16 => 10,
      17 => 9,
      18 => 8,
      19 => 7,
      20 => 6,
      21 => 5,
      22 => 4,
      23 => 3,
      24 => 2,
      25 => 1,
    }[level]
  end
end

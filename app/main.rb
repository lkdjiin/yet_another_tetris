require 'app/pieces_states.rb'
require 'app/levels.rb'

class Game
  attr_gtk

  SQUARE_SIDE = 30
  MIN_MOVE_TIME = 10 # Minimum frames between two consecutive moves.

  COLORS = [
    {r: 0, g: 0, b: 0},
    {r: 153, g: 204, b: 255},
    {r: 255, g: 255, b: 153},
    {r: 77, g: 77, b: 255},
    {r: 255, g: 153, b: 77},
    {r: 153, g: 255, b: 77},
    {r: 255, g: 77, b: 77},
    {r: 153, g: 77, b: 255},
  ]

  PIECES = [
    { id: 1, name: :i, col: 3, row: -1, angle: 0, side: 4, },
    { id: 2, name: :o, col: 4, row: 0, angle: 0, side: 2, },
    { id: 3, name: :j, col: 3, row: 0, angle: 0, side: 3, },
    { id: 4, name: :l, col: 3, row: 0, angle: 0, side: 3, },
    { id: 5, name: :s, col: 3, row: 0, angle: 0, side: 3, },
    { id: 6, name: :z, col: 3, row: 0, angle: 0, side: 3, },
    { id: 7, name: :t, col: 3, row: 0, angle: 0, side: 3, },
  ]

  def tick
    defaults
    render
    input
    calc
  end

  def defaults
    return if Kernel.tick_count > 0

    state.background = { x: 0, y: 0, w: 1280, h: 720, r: 77, g: 0, b: 77 }
    state.walls = [
      { x: 490, y: 0, w: 300, h: SQUARE_SIDE, r: 153, g: 77, b: 153 }, # Bottom
      { x: 460, y: 0, w: SQUARE_SIDE, h: 660, r: 153, g: 77, b: 153 }, # Left
      { x: 790, y: 0, w: SQUARE_SIDE, h: 660, r: 153, g: 77, b: 153 }, # Right

      { x: 900, y: 630, w: 160, h: 30, r: 153, g: 77, b: 153 },
      { x: 900, y: 500, w: 160, h: 30, r: 153, g: 77, b: 153 },
      { x: 900, y: 500, w: 30, h: 160, r: 153, g: 77, b: 153 },
      { x: 1030, y: 500, w: 30, h: 160, r: 153, g: 77, b: 153 },
    ]

    init_new_game
    state.game_started = false
  end

  def init_new_game
    # 20 rows x 10 columns
    # Rows are numbered 0 to 19. Columns are numbered 0 to 9.
    state.playfield = Array.new(20) { Array.new(10, 0) }

    state.piece = nil
    state.preview = PIECES.sample.clone
    state.bag_of_pieces = []
    calc_spawn_new_piece
    state.wait_to_spawn_counter = -1

    state.wanna_move = false
    state.last_move_at = -MIN_MOVE_TIME

    state.next_step = Levels.get_frames_for(1)
    state.lines_to_suppress = []
    state.lines_to_suppress_at = 0

    # Scoring
    state.score = 0
    state.lines = 0
    state.level = 1
    state.to_next_level = 10
    state.game_over = false
  end

  def render
    outputs.solids << state.background
    outputs.solids << state.walls

    render_preview
    render_playfield
    render_lines_to_suppress

    outputs.sprites << {
      x: render_col2x(state.piece.col),
      y: render_row2y(state.piece.row, state.piece.side),
      w: state.piece.side * SQUARE_SIDE, h: state.piece.side * SQUARE_SIDE,
      path: "sprites/#{state.piece.name}.png",
      angle: state.piece.angle
    }

    render_score

    if state.game_over
      outputs.solids << {
        x: render_col2x(0), y: render_row2y(19, 2),
        w: SQUARE_SIDE * 10, h: SQUARE_SIDE * 20,
        r: 255, g: 0, b: 0, a: 125
      }
    end

    render_new_game_screen if !state.game_started
  end

  def render_playfield
    19.downto(0) do |row|
      break if state.playfield[row].sum == 0
      10.times do |col|
        if state.playfield[row][col] != 0
          outputs.solids << {
            x: render_col2x(col), y: render_row2y(row, 2),
            w: SQUARE_SIDE, h: SQUARE_SIDE
          }.merge(COLORS[state.playfield[row][col]])
        end
      end
    end
  end

  def render_lines_to_suppress
    state.lines_to_suppress.each do |row|
      outputs.solids << {
        x: render_col2x(0), y: render_row2y(row, 2),
        w: SQUARE_SIDE * 10, h: SQUARE_SIDE,
        r: 255, g: 255, b: 255, a: 125
      }
    end
  end

  def render_col2x(col)
    490 + col * SQUARE_SIDE
  end

  def render_row2y(row, side)
    660 - (row * SQUARE_SIDE) - (side * SQUARE_SIDE)
  end

  def render_preview
    outputs.sprites << {
      x: 940, y: 540,
      w: 80, h: 80,
      path: "sprites/#{state.preview.name}.png"
    }
  end

  def render_score
    outputs.labels << {
      x: 200, y: 500, size_px: 40, alignment_enum: 1, r: 255, g: 204, b: 255,
      text: "Score",
    }
    outputs.labels << {
      x: 200, y: 450, size_px: 40, alignment_enum: 1, r: 255, g: 204, b: 255,
      text: state.score,
    }

    outputs.labels << {
      x: 200, y: 380, size_px: 40, alignment_enum: 1, r: 204, g: 153, b: 255,
      text: "Level",
    }
    outputs.labels << {
      x: 200, y: 330, size_px: 40, alignment_enum: 1, r: 204, g: 153, b: 255,
      text: state.level,
    }

    outputs.labels << {
      x: 200, y: 260, size_px: 40, alignment_enum: 1, r: 153, g: 153, b: 255,
      text: "Lines",
    }
    outputs.labels << {
      x: 200, y: 210, size_px: 40, alignment_enum: 1, r: 153, g: 153, b: 255,
      text: state.lines,
    }
  end

  def render_new_game_screen
    outputs.solids << {
      x: 280, y: 120,
      w: 720, h: 480,
      a: 100, r: 0, g: 0, b: 0
    }
    outputs.labels << {
      x: 640, y: 360, size_px: 40, alignment_enum: 1, r: 255, g: 255, b: 255,
      text: "Press space to play"
    }
  end

  def input
    return unless state.lines_to_suppress.empty?

    if !state.game_started
      if inputs.keyboard.space
        init_new_game
        state.game_started = true
      end
      return
    end

    state.wanna_move = false

    if inputs.left && state.last_move_at.elapsed_time > MIN_MOVE_TIME
      state.wanna_move = :left
    elsif inputs.right && state.last_move_at.elapsed_time > MIN_MOVE_TIME
      state.wanna_move = :right
    elsif (inputs.keyboard.control || inputs.controller_one.y) && state.last_move_at.elapsed_time > MIN_MOVE_TIME
      state.wanna_move = :rotate
    elsif inputs.down
      state.wanna_move = :soft_drop
    end

    state.last_move_at = Kernel.tick_count if state.wanna_move
  end

  def calc
    return if state.game_over
    return if !state.game_started

    state.next_step -= 1

    calc_lines

    unless state.lines_to_suppress.empty?
      if state.lines_to_suppress_at.elapsed_time > 20
        state.lines += state.lines_to_suppress.size
        state.to_next_level -= state.lines_to_suppress.size
        if state.to_next_level <= 0
          outputs.sounds << "sounds/level_up.wav"
          state.level += 1
          state.to_next_level = 10 + state.to_next_level
        end

        case state.lines_to_suppress.size
        when 1 then state.score += 40
        when 2 then state.score += 100
        when 3 then state.score += 300
        when 4 then state.score += 1200
        end

        outputs.sounds << "sounds/line.wav"
        state.lines_to_suppress.reverse.each do |row|
          state.playfield[row] = nil
          state.playfield.compact!
          state.playfield.prepend([0,0,0,0,0,0,0,0,0,0])
        end
        state.lines_to_suppress = []
      end
    end

    if state.next_step <= 0 && state.wait_to_spawn_counter <= 0
      state.game_over = calc_gravity
      if state.game_over
        outputs.sounds << "sounds/game_over.wav"
        state.game_started = false
      end
      state.score += 1 if state.wanna_move == :soft_drop
    end

    state.wait_to_spawn_counter -= 1
    if state.wait_to_spawn_counter == 0
      calc_spawn_new_piece
    end

    # Moves from player.
    case state.wanna_move
    when :rotate then calc_rotate
    when :left then calc_shift_left
    when :right then calc_shift_right
    when :soft_drop then state.next_step -= 10
    end
  end

  # Returns true if game over. False otherwise.
  def calc_gravity
    if calc_above_is_blocked
      return true if state.piece.row <= 0

      outputs.sounds << "sounds/lock.wav"
      calc_add_to_playfield # Piece is locked up.

      state.wait_to_spawn_counter = 25
    else
      state.piece.row +=1
    end
    state.next_step = Levels.get_frames_for(state.level)

    false
  end

  def calc_above_is_blocked
    locations = calc_above_locations_that_must_be_free
    locations.map do |loc|
      row = state.playfield[loc.first]
      row ? row[loc.last] : 99
    end.sum != 0
  end

  def calc_above_locations_that_must_be_free
    states = PiecesStates.get(state.piece.name, state.piece.angle)
    states = states.group_by { |coord| coord.last }
    to_test = states.each_value.map {|v| v.max_by {|x| x.first} }
    to_test.map do |coord|
      row = state.piece.row + coord.first + 1
      col = state.piece.col + coord.last
      [row, col]
    end
  end

  def calc_shift_left
    state.piece.col -= 1 unless calc_left_is_blocked
  end

  def calc_left_is_blocked
    locations = calc_left_locations_that_must_be_free
    locations.map do |loc|
      loc.last >= 0 ? state.playfield[loc.first][loc.last] : 99
    end.sum != 0
  end

  def calc_left_locations_that_must_be_free
    states = PiecesStates.get(state.piece.name, state.piece.angle)
    states = states.group_by { |coord| coord.first }
    to_test = states.each_value.map {|v| v.min_by {|x| x.last} }
    to_test.map do |coord|
      row = state.piece.row + coord.first
      col = state.piece.col + coord.last - 1
      [row, col]
    end
  end

  def calc_rotate
    if !calc_rotation_is_blocked
      state.piece.angle = calc_next_angle(state.piece.angle)
    elsif !calc_kick_to_the_right_is_blocked
      state.piece.angle = calc_next_angle(state.piece.angle)
      state.piece.col += 1
    elsif !calc_kick_to_the_right_for_i_exception_is_blocked
      state.piece.angle = calc_next_angle(state.piece.angle)
      state.piece.col += 2
    elsif !calc_kick_to_the_left_is_blocked
      state.piece.angle = calc_next_angle(state.piece.angle)
      state.piece.col -= 1
    elsif !calc_kick_to_the_left_for_i_exception_is_blocked
      state.piece.angle = calc_next_angle(state.piece.angle)
      state.piece.col -= 2
    elsif !calc_kick_to_the_top_is_blocked
      state.piece.angle = calc_next_angle(state.piece.angle)
      state.piece.row += 1
    elsif !calc_kick_to_the_top_for_i_exception_is_blocked
      state.piece.angle = calc_next_angle(state.piece.angle)
      state.piece.row += 2
    elsif !calc_kick_to_the_bottom_is_blocked
      state.piece.angle = calc_next_angle(state.piece.angle)
      state.piece.row -= 1
    elsif !calc_kick_to_the_bottom_for_i_exception_is_blocked
      state.piece.angle = calc_next_angle(state.piece.angle)
      state.piece.row -= 2
    end
  end

  def calc_generic_locations_are_blocked(locations)
    locations.map do |loc|
      row = state.playfield[loc.first]
      # If row is nil it's blocked
      # If loc.last < 0 it's blocked
      # If loc.last >= 10 it's blocked
      if row.nil?
        99
      elsif loc.last < 0
        99
      elsif loc.last >= 10
        99
      else
        row[loc.last]
      end
    end.sum != 0
  end

  def calc_rotation_is_blocked
    locations = calc_generic_locations_that_must_be_free([0,0])
    calc_generic_locations_are_blocked(locations)
  end

  def calc_kick_to_the_right_is_blocked
    locations = calc_generic_locations_that_must_be_free([0,1])
    calc_generic_locations_are_blocked(locations)
  end

  def calc_kick_to_the_right_for_i_exception_is_blocked
    return true if state.piece.name != :i

    locations = calc_generic_locations_that_must_be_free([0,2])
    calc_generic_locations_are_blocked(locations)
  end

  def calc_kick_to_the_left_is_blocked
    locations = calc_generic_locations_that_must_be_free([0,-1])
    calc_generic_locations_are_blocked(locations)
  end

  def calc_kick_to_the_left_for_i_exception_is_blocked
    return true if state.piece.name != :i

    locations = calc_generic_locations_that_must_be_free([0,-2])
    calc_generic_locations_are_blocked(locations)
  end

  def calc_kick_to_the_bottom_is_blocked
    locations = calc_generic_locations_that_must_be_free([-1,0])
    calc_generic_locations_are_blocked(locations)
  end

  def calc_kick_to_the_bottom_for_i_exception_is_blocked
    return true if state.piece.name != :i

    locations = calc_generic_locations_that_must_be_free([-2,0])
    calc_generic_locations_are_blocked(locations)
  end

  def calc_kick_to_the_top_is_blocked
    locations = calc_generic_locations_that_must_be_free([+1,0])
    calc_generic_locations_are_blocked(locations)
  end

  def calc_kick_to_the_top_for_i_exception_is_blocked
    return true if state.piece.name != :i

    locations = calc_generic_locations_that_must_be_free([+2,0])
    calc_generic_locations_are_blocked(locations)
  end

  # translations - [y, x]
  def calc_generic_locations_that_must_be_free(translations)
    angle_to_try = calc_next_angle(state.piece.angle)
    states = PiecesStates.get(state.piece.name, angle_to_try)
    states.map do |coord|
      row = state.piece.row + coord.first + translations.first
      col = state.piece.col + coord.last + translations.last
      [row, col]
    end
  end

  def calc_next_angle(angle)
    angle += 90
    angle > 270 ? 0 : angle
  end

  def calc_shift_right
    state.piece.col += 1 unless calc_right_is_blocked
  end

  def calc_right_is_blocked
    locations = calc_right_locations_that_must_be_free
    locations.map do |loc|
      loc.last < 10 ? state.playfield[loc.first][loc.last] : 99
    end.sum != 0
  end

  def calc_right_locations_that_must_be_free
    states = PiecesStates.get(state.piece.name, state.piece.angle)
    states = states.group_by { |coord| coord.first }
    to_test = states.each_value.map {|v| v.max_by {|x| x.last} }
    to_test.map do |coord|
      row = state.piece.row + coord.first
      col = state.piece.col + coord.last + 1
      [row, col]
    end
  end

  def calc_spawn_new_piece
    if state.bag_of_pieces.empty?
      PIECES.each { |p| state.bag_of_pieces << p.clone }
      PIECES.each { |p| state.bag_of_pieces << p.clone }
      state.bag_of_pieces.shuffle!
    end

    state.piece = state.preview
    state.preview = state.bag_of_pieces.shift
    outputs.sounds << "sounds/spawn.wav"
  end

  def calc_add_to_playfield
    PiecesStates.get(state.piece.name, state.piece.angle).each do |ps|
      state.playfield[state.piece.row + ps.first][state.piece.col + ps.second] = state.piece.id
    end

    # puts "============================================"
    # state.playfield.each {|row| p row}
    # puts "============================================"
  end

  def calc_lines
    return unless state.lines_to_suppress.empty?

    19.downto(0) do |row|
      break if state.playfield[row].sum == 0
      if state.playfield[row].none? { |i| i == 0 }
        state.lines_to_suppress << row
        state.lines_to_suppress_at = Kernel.tick_count
      end
    end
  end
end

$game = Game.new

def tick(args)
  $game.args = args
  $game.tick
end

defmodule Ash.CanvasTest do
  use ExUnit.Case
  use TestMacros

  test "basic canvas check" do
    # X walks the path.
    canvas1 = Canvas.new(0, 1)
    canvas2 = Canvas.write(canvas1, " ")

    assert Canvas.diff(canvas1, canvas2) == [
             {:x, 1}
           ]

    # Spaces match with default cell.
    canvas1 = Canvas.new(2, 1)
    canvas2 = Canvas.write(canvas1, "a ")

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:x, 2}
           ]

    # Data encoding should maximize readability.

    # No repeats.
    canvas1 = Canvas.new(3, 1)
    canvas2 = Canvas.write(canvas1, "abc")

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'abc'}
           ]

    # Single repeat.
    canvas1 = Canvas.new(3, 1)
    canvas2 = Canvas.write(canvas1, "aaa")

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, {'a', 3}}
           ]

    # Multiple repeats.
    canvas1 = Canvas.new(10, 1)
    canvas2 = Canvas.write(canvas1, "aabcccdefg")

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, {'a', 2}},
             {:d, 'b'},
             {:d, {'c', 3}},
             {:d, 'defg'}
           ]

    # Opaque true.
    canvas1 = Canvas.new(1, 1)
    canvas2 = Canvas.back(canvas1, @red)
    canvas2 = Canvas.write(canvas2, "a")

    assert Canvas.diff(canvas1, canvas2) == [
             {:b, @red},
             {:d, 'a'}
           ]

    # Opaque false.
    canvas1 = Canvas.new(2, 1)
    canvas2 = Canvas.back(canvas1, @red)
    canvas2 = Canvas.write(canvas2, "ab")
    canvas2 = Canvas.move(canvas2, 0, 0)
    canvas2 = Canvas.back(canvas2, @green)
    canvas2 = Canvas.write(canvas2, "c")
    canvas2 = Canvas.back(canvas2, nil)
    canvas2 = Canvas.write(canvas2, "d")

    assert Canvas.diff(canvas1, canvas2) == [
             {:b, @green},
             {:d, 'c'},
             {:b, @red},
             {:d, 'd'},
             {:b, @green}
           ]

    # Backcolor.
    canvas1 = Canvas.new(2, 1)
    canvas2 = Canvas.write(canvas1, "a")
    canvas2 = Canvas.back(canvas2, @red)
    canvas2 = Canvas.write(canvas2, "b")

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:b, @red},
             {:d, 'b'}
           ]

    canvas2 = Canvas.back(canvas2, @green)

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:b, @red},
             {:d, 'b'},
             {:b, @green}
           ]

    canvas1 = Canvas.back(canvas1, @green)

    assert Canvas.diff(canvas1, canvas2) == [
             {:b, @black},
             {:d, 'a'},
             {:b, @red},
             {:d, 'b'},
             {:b, @green}
           ]

    # Forecolor.
    canvas1 = Canvas.new(2, 1)
    canvas2 = Canvas.write(canvas1, "a")
    canvas2 = Canvas.fore(canvas2, @red)
    canvas2 = Canvas.write(canvas2, "b")

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:f, @red},
             {:d, 'b'}
           ]

    canvas2 = Canvas.fore(canvas2, @green)

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:f, @red},
             {:d, 'b'},
             {:f, @green}
           ]

    canvas1 = Canvas.fore(canvas1, @green)

    assert Canvas.diff(canvas1, canvas2) == [
             {:f, @white},
             {:d, 'a'},
             {:f, @red},
             {:d, 'b'},
             {:f, @green}
           ]

    # Font.
    canvas1 = Canvas.new(2, 1)
    canvas2 = Canvas.write(canvas1, "a")
    canvas2 = Canvas.font(canvas2, 1)
    canvas2 = Canvas.write(canvas2, "b")

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:n, 1},
             {:d, 'b'}
           ]

    canvas2 = Canvas.font(canvas2, 2)

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:n, 1},
             {:d, 'b'},
             {:n, 2}
           ]

    canvas1 = Canvas.font(canvas1, 2)

    assert Canvas.diff(canvas1, canvas2) == [
             {:n, 0},
             {:d, 'a'},
             {:n, 1},
             {:d, 'b'},
             {:n, 2}
           ]

    # Factor.
    canvas1 = Canvas.new(2, 1)
    canvas2 = Canvas.write(canvas1, "a")
    canvas2 = Canvas.factor(canvas2, 2, 0, 0)
    canvas2 = Canvas.write(canvas2, "b")

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:e, {2, 0, 0}},
             {:d, 'b'}
           ]

    canvas2 = Canvas.factor(canvas2, 3, 0, 0)

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:e, {2, 0, 0}},
             {:d, 'b'},
             {:e, {3, 0, 0}}
           ]

    canvas1 = Canvas.factor(canvas1, 3, 0, 0)

    assert Canvas.diff(canvas1, canvas2) == [
             {:e, {1, 0, 0}},
             {:d, 'a'},
             {:e, {2, 0, 0}},
             {:d, 'b'},
             {:e, {3, 0, 0}}
           ]

    # Cursor.
    canvas1 = Canvas.new(3, 1)
    canvas2 = Canvas.write(canvas1, "a")

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'}
           ]

    canvas2 = Canvas.cursor(canvas2, 2, 0)

    assert Canvas.diff(canvas1, canvas2) == [
             {:d, 'a'},
             {:c, true},
             {:x, 2}
           ]

    canvas1 = Canvas.cursor(canvas1, 2, 0)

    assert Canvas.diff(canvas1, canvas2) == [
             {:x, 0},
             {:d, 'a'},
             {:x, 2}
           ]

    # Clipping.
    canvas = Canvas.new(10, 10)
    assert {0, 0, 10, 10} == canvas.clip
    canvas = Canvas.push(canvas, {1, 2, 7, 6})
    assert {1, 2, 7, 6} == canvas.clip
    assert Canvas.push(canvas, {0, 1, 2, 3}).clip == {1, 3, 2, 3}
    assert Canvas.push(canvas, {0, 1, 10, 10}).clip == {1, 3, 7, 5}
    assert Canvas.push(canvas, {1, 0, 10, 10}).clip == {2, 2, 6, 6}
    assert Canvas.push(canvas, {7, 6, 10, 10}).clip == {8, 8, 0, 0}
    assert Canvas.push(canvas, {6, 6, 10, 10}).clip == {7, 8, 1, 0}
    assert Canvas.push(canvas, {7, 5, 10, 10}).clip == {8, 7, 0, 1}
    assert Canvas.push(canvas, {8, 7, 10, 10}).clip == {9, 9, -1, -1}

    canvas1 = Canvas.new(10, 10)
    canvas2 = Canvas.push(canvas1, {1, 0, 3, 1})
    # xy shifted on move or reset, xy=0 here
    # Reset must be issued after clipping for a control.
    canvas2 = Canvas.write(canvas2, "abcd")

    assert Canvas.diff(canvas1, canvas2) == [
             {:x, 1},
             {:d, 'bcd'}
           ]

    canvas1 = Canvas.new(10, 10)
    canvas2 = Canvas.push(canvas1, {1, 2, 3, 1})
    canvas2 = Canvas.reset(canvas2)
    # xy shifted on move or reset, xy=(1, 2) here
    canvas2 = Canvas.write(canvas2, "abc")

    assert Canvas.diff(canvas1, canvas2) == [
             {:x, 1},
             {:y, 2},
             {:d, 'abc'}
           ]

    canvas1 = Canvas.new(10, 10)
    canvas2 = Canvas.push(canvas1, {1, 2, 3, 1})
    canvas2 = Canvas.move(canvas2, 0, 0)
    # xy shifted on move or reset, xy=(1, 2) here
    canvas2 = Canvas.write(canvas2, "abc")

    assert Canvas.diff(canvas1, canvas2) == [
             {:x, 1},
             {:y, 2},
             {:d, 'abc'}
           ]
  end
end

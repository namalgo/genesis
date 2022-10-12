# ------------------------------------------------------------------------------
#
# Copyright 2022 Nameless Algorithm
# See https://namelessalgorithm.com/ for more information.
#
# LICENSE
# You may use this source code for any purpose. If you do so, please attribute
# 'Nameless Algorithm' in your source, or mention us in your game/demo credits.
# Thank you.
#
# ------------------------------------------------------------------------------

lines=File.readlines("rom.lst")
mode=:skip
lines.each do |line|
  if line == "Symbols:\n" then
    mode=:symbols
  end

  if mode == :symbols then
    if line.include?("LAB")
      words = line.split(" LAB ")
      addr = words[1][3..-2].to_i(16).to_s(16)
      puts "comadd #{addr},#{words[0]}"
    end
  end
end

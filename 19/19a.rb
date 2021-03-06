require 'set'

COMMON_BEACONS = 12

ROTATE_X = [
	#[0, 1, -0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1], # 0
	[0, 0, -1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1], # 90
	[0, -1, -0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 1], # 180
	[0, 0, 1, 0, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1], # 270
]

ROTATE_Y = [
	[-0, 0, 1, 0, 1, 0, 0 ,0, 0, 1, 0, 0, 0, 0, 0, 1], # 0
	[-1, 0, 0, 0, 0, 0, 1 ,0, 0, 1, 0, 0, 0, 0, 0, 1], # 90
	[-0, 0, -1, 0, -1, 0, 0 ,0, 0, 1, 0, 0, 0, 0, 0, 1], # 180
	[1, 0, 0, 0, 0, 0, -1 ,0, 0, 1, 0, 0, 0, 0, 0, 1], # 270
]

ROTATE_Z = [
	[1, -0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], # 0
	[0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], # 90
	[-1, -0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], # 180
	[0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], # 270
]

def mul_matrix(v, w)
	[
		v[0] * w[0] + v[4] * w[1] + v[8] * w[2] + v[12] * w[3],
		v[1] * w[0] + v[5] * w[1] + v[9] * w[2] + v[13] * w[3],
		v[2] * w[0] + v[6] * w[1] + v[10] * w[2] + v[14] * w[3],
		v[3] * w[0] + v[7] * w[1] + v[11] * w[2] + v[15] * w[3],
		v[0] * w[4] + v[4] * w[5] + v[8] * w[6] + v[12] * w[7],
		v[1] * w[4] + v[5] * w[5] + v[9] * w[6] + v[13] * w[7],
		v[2] * w[4] + v[6] * w[5] + v[10] * w[6] + v[14] * w[7],
		v[3] * w[4] + v[7] * w[5] + v[11] * w[6] + v[15] * w[7],
		v[0] * w[8] + v[4] * w[9] + v[8] * w[10] + v[12] * w[11],
		v[1] * w[8] + v[5] * w[9] + v[9] * w[10] + v[13] * w[11],
		v[2] * w[8] + v[6] * w[9] + v[10] * w[10] + v[14] * w[11],
		v[3] * w[8] + v[7] * w[9] + v[11] * w[10] + v[15] * w[11],
		v[0] * w[12] + v[4] * w[13] + v[8] * w[14] + v[12] * w[15],
		v[1] * w[12] + v[5] * w[13] + v[9] * w[14] + v[13] * w[15],
		v[2] * w[12] + v[6] * w[13] + v[10] * w[14] + v[14] * w[15],
		v[3] * w[12] + v[7] * w[13] + v[11] * w[14] + v[15] * w[15],
	]
end

$rotations = Array.new
ROTATE_X.each do |rx|
	ROTATE_Y.each do |ry|
		ROTATE_Z.each do |rz|
			$rotations << mul_matrix(mul_matrix(rx, ry), rz)
			$rotations << mul_matrix(mul_matrix(ry, rx), rz)
			$rotations << mul_matrix(rz, mul_matrix(rx, ry))
			$rotations << mul_matrix(rz, mul_matrix(ry, rz))
		end
	end
end
#puts "#{$rotations.size} rotations"
$rotations = $rotations.to_set.to_a

#puts "#{$rotations.size} unique rotations"

Beacon = Struct.new(:v) do
	def to_s
		"#{v[0]},#{v[1]},#{v[2]}"
	end

	def mul(m)
		Beacon.new([
			v[0] * m[0] + v[1] * m[1] + v[2] * m[2] + m[3],
			v[0] * m[4] + v[1] * m[5] + v[2] * m[6] + m[7],
			v[0] * m[8] + v[1] * m[9] + v[2] * m[10] + m[11]
		])
	end

	def translate(dx, dy, dz)
		mul([1, 0, 0, dx, 0, 1, 0, dy, 0, 0, 1, dz, 0, 0, 0, 1])
	end
end

Scanner = Struct.new(:beacons) do
	def to_s
		beacons.map { |c| c.to_s }.join("\n")
	end

	def rotateAll
		scanners = Array.new
		$rotations.each do |r|
			scanners << Scanner.new(beacons.map { |c| c.mul(r) })
		end
		scanners
	end

	def translate(dx, dy, dz)
		Scanner.new(beacons.map { |c| c.translate(dx, dy, dz) })
	end

	def nextTo?(otherScanner)
		rotateAll.each do |rs|
			rs.beacons.each_with_index do |c1, i|
				otherScanner.beacons.each_with_index do |c2, j|
					if (j > i)
						rst = rs.translate(c2.v[0] - c1.v[0], c2.v[1] - c1.v[1], c2.v[2] - c1.v[2])
						uniqueCoordinates = (rst.beacons + otherScanner.beacons).to_set
						if (rst.beacons.size + otherScanner.beacons.size - uniqueCoordinates.size >= COMMON_BEACONS)
							return rst
						end
					end
				end
			end
		end
		nil
	end
end

scanners = Array.new
scanner = nil
ARGF.readlines.each do |l|
	if (l.include? "scanner")
		if (scanner != nil)
			scanners << Scanner.new(scanner)
		end
		scanner = Array.new
	elsif (l =~ /.+,.+,.+/)
		v = l.chomp.split(",").map { |c| c.to_i }
		scanner << Beacon.new(v)
	end
end
scanners << Scanner.new(scanner)

scanner0 = scanners[0]
scannersSystem = [scanner0]

i = 0
while (!scanners.empty?)
	i = (i + 1) % scanners.size
	canditate = scanners[i]
	scannersSystem.each do |s1|
		rs = canditate.nextTo? s1
		if (rs != nil)
			puts "Found #{scannersSystem.size}!"
			scannersSystem << rs
			scanners.delete_at(i)
			break
		end
	end
end

uniqueCoordinates = Set.new
scannersSystem.each do |s|
	s.beacons.each do |c|
		uniqueCoordinates << c
	end
end

puts uniqueCoordinates.size

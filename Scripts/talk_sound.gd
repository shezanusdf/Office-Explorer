extends AudioStreamPlayer

# Simple talk sound generator
var sample_rate := 22050.0
var frequency := 400.0

func _ready():
	# Create a simple beep sound
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = int(sample_rate)
	audio.stereo = false

	# Generate a short blip sound (0.05 seconds)
	var num_samples = int(sample_rate * 0.05)
	var data = PackedByteArray()
	data.resize(num_samples)

	for i in range(num_samples):
		var t = float(i) / sample_rate
		# Simple sine wave with envelope
		var envelope = 1.0 - (float(i) / num_samples)  # Fade out
		var sample = sin(t * frequency * TAU) * envelope
		# Convert to 8-bit unsigned (0-255, centered at 128)
		data[i] = int((sample * 0.5 + 0.5) * 255)

	audio.data = data
	stream = audio

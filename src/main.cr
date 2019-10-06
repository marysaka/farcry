require "./gdt"

Serial.puts "Welcome to FarCry\n"

Serial.puts "Setup GDT\n"
gdt = Pointer(GDT).new 0x800
gdt.value.setup_gdt
gdt.value.flush
Serial.puts "GDT Setup done\n"

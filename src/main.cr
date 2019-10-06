require "./gdt"

Serial.puts "Welcome to FarCry\n"

Serial.puts "Setup GDT\n"
GDT.setup_gdt
GDT.flush
Serial.puts "GDT Setup done\n"